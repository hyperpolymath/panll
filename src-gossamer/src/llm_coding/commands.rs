// SPDX-License-Identifier: PMPL-1.0-or-later
//
// LLM Coding Tauri commands — process spawning, resource monitoring,
// workspace locking, and session coordination.
//
// These commands are invoked by the ReScript frontend via Tauri's invoke
// bridge. They manage the lifecycle of Claude/LLM coding sessions.
//
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

use super::types::*;
use serde_json::json;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};
use once_cell::sync::Lazy;
use uuid::Uuid;

/// Coordination directory for inter-session state.
fn coord_dir() -> PathBuf {
    let dir = dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("/tmp"))
        .join(".claude/coordination");
    fs::create_dir_all(&dir).ok();
    dir
}

/// In-memory session registry (persisted to coordination dir on changes).
static SESSIONS: Lazy<Mutex<HashMap<String, LlmSession>>> =
    Lazy::new(|| Mutex::new(HashMap::new()));

/// Read /proc/meminfo for system memory stats.
fn read_system_memory() -> (u64, u64) {
    let meminfo = fs::read_to_string("/proc/meminfo").unwrap_or_default();
    let mut total_kb = 0u64;
    let mut avail_kb = 0u64;
    for line in meminfo.lines() {
        if line.starts_with("MemTotal:") {
            total_kb = line.split_whitespace().nth(1)
                .and_then(|s| s.parse().ok()).unwrap_or(0);
        } else if line.starts_with("MemAvailable:") {
            avail_kb = line.split_whitespace().nth(1)
                .and_then(|s| s.parse().ok()).unwrap_or(0);
        }
    }
    (avail_kb / 1024, total_kb / 1024)
}

/// Read /proc/<pid>/status for a process's RSS.
fn read_process_memory(pid: u32) -> u64 {
    let status = fs::read_to_string(format!("/proc/{pid}/status")).unwrap_or_default();
    for line in status.lines() {
        if line.starts_with("VmRSS:") {
            return line.split_whitespace().nth(1)
                .and_then(|s| s.parse::<u64>().ok())
                .unwrap_or(0) / 1024; // KB -> MB
        }
    }
    0
}

/// Count child processes of a given PID.
fn count_children(pid: u32) -> u32 {
    let children = fs::read_to_string(format!("/proc/{pid}/task/{pid}/children"))
        .unwrap_or_default();
    children.split_whitespace().count() as u32
}

/// Get current ISO 8601 timestamp.
fn now_iso() -> String {
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    // Simple ISO format — good enough for display
    format!("{secs}")
}

/// Write session state to coordination dir for cross-session visibility.
fn persist_session(session: &LlmSession) {
    let path = coord_dir().join("sessions").join(format!("{}.json", session.id));
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).ok();
    }
    if let Ok(json) = serde_json::to_string_pretty(session) {
        fs::write(&path, &json).ok();
        set_private_permissions(&path);
    }
}

/// Write a lock file to the coordination dir.
fn persist_lock(lock: &WorkspaceLock) {
    let lock_name = lock.path.replace('/', "_");
    let path = coord_dir().join("locks").join(format!("{lock_name}.json"));
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).ok();
    }
    if let Ok(json) = serde_json::to_string_pretty(lock) {
        fs::write(&path, &json).ok();
        set_private_permissions(&path);
    }
}

/// Write a message to the coordination dir.
fn persist_message(msg: &SessionMessage) {
    let dir = coord_dir().join("messages");
    fs::create_dir_all(&dir).ok();
    let filename = format!("{}-{}.json", msg.sent_at, msg.from_session);
    let path = dir.join(&filename);
    if let Ok(json) = serde_json::to_string_pretty(msg) {
        fs::write(&path, &json).ok();
        set_private_permissions(&path);
    }
}

// ============================================================================
// Tauri Commands
// ============================================================================

/// List all managed sessions with updated resource stats.

pub fn llm_coding_list_sessions() -> Result<String, String> {
    let mut sessions = SESSIONS.lock().map_err(|e| e.to_string())?;

    // Update resource stats for alive sessions
    for session in sessions.values_mut() {
        if let Some(pid) = session.pid {
            if matches!(session.state, SessionState::Active | SessionState::Frozen) {
                // Check if process is still alive
                let alive = Path::new(&format!("/proc/{pid}")).exists();
                if !alive {
                    session.state = SessionState::Completed;
                    session.pid = None;
                    persist_session(session);
                } else {
                    session.resources.memory_mb = read_process_memory(pid);
                    session.resources.subagent_count = count_children(pid);
                }
            }
        }
    }

    let list: Vec<&LlmSession> = sessions.values().collect();
    serde_json::to_string(&list).map_err(|e| e.to_string())
}

/// Spawn a new Claude coding session in a Konsole terminal.

pub fn llm_coding_spawn(request: SpawnRequest) -> Result<String, String> {
    let session_id = Uuid::new_v4().to_string();

    // Build the task instruction file
    let task_file = coord_dir()
        .join("tasks")
        .join(format!("{session_id}.md"));
    if let Some(parent) = task_file.parent() {
        fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }

    // Build task content with repo restrictions and coordination awareness
    let task_content = format!(
        r#"# Session: {name}
# ID: {id}
# Allowed repos: {repos}

## COORDINATION RULES
- Before editing any file, check ~/.claude/coordination/locks/ for conflicts
- Write your lock: echo '{{"path":"<repo>","held_by":"{id}","exclusive":true}}' > ~/.claude/coordination/locks/<repo>.json
- When done with a repo, remove your lock file
- Check ~/.claude/coordination/sessions/ for other active sessions
- Write messages to ~/.claude/coordination/messages/ to notify other sessions of changes

## TASKS
{tasks}

## WORKSPACE
Working directory: {work_dir}
Only touch repos: {repos}
"#,
        name = request.name,
        id = session_id,
        repos = request.allowed_repos.join(", "),
        tasks = request.task_list,
        work_dir = request.work_dir,
    );
    fs::write(&task_file, &task_content).map_err(|e| e.to_string())?;

    // Spawn Konsole with Claude
    let prompt = format!(
        "Read the task file at {} and complete all tasks listed there. Follow the coordination rules strictly.",
        task_file.display()
    );

    let child = Command::new("konsole")
        .args([
            "--new-tab",
            "-e",
            "claude",
            "--print",
            &prompt,
        ])
        .current_dir(&request.work_dir)
        .spawn()
        .map_err(|e| format!("Failed to spawn Konsole: {e}"))?;

    let pid = child.id();

    // Parse tasks from the task list text
    let tasks: Vec<SharedTask> = request
        .task_list
        .lines()
        .filter(|line| !line.trim().is_empty())
        .enumerate()
        .map(|(i, line)| SharedTask {
            id: format!("task-{i}"),
            description: line.trim().trim_start_matches("- ").to_string(),
            status: TaskStatus::Pending,
            assigned_to: Some(session_id.clone()),
            completed_at: None,
        })
        .collect();

    let session = LlmSession {
        id: session_id.clone(),
        name: request.name,
        provider: LlmProvider::Claude,
        state: SessionState::Active,
        pid: Some(pid),
        work_dir: request.work_dir,
        allowed_repos: request.allowed_repos,
        resources: ResourceUsage::default(),
        limits: ResourceLimits::default(),
        tasks,
        started_at: now_iso(),
    };

    persist_session(&session);

    // Announce to other sessions
    let msg = SessionMessage {
        from_session: session_id.clone(),
        content: format!("Session '{}' started", session.name),
        sent_at: now_iso(),
    };
    persist_message(&msg);

    SESSIONS.lock().map_err(|e| e.to_string())?
        .insert(session_id.clone(), session);

    Ok(json!({"id": session_id, "pid": pid}).to_string())
}

/// Validate that a PID belongs to a known terminal/claude process.
/// Prevents signalling unrelated processes if PID is stale.
fn validate_pid(pid: u32) -> Result<(), String> {
    let comm_path = format!("/proc/{pid}/comm");
    let comm = fs::read_to_string(&comm_path)
        .map_err(|_| format!("PID {pid} no longer exists"))?;
    let name = comm.trim();
    // Only allow signalling known process types
    let allowed = ["konsole", "claude", "bash", "zsh", "node", "deno"];
    if allowed.iter().any(|a| name.contains(a)) {
        Ok(())
    } else {
        Err(format!("PID {pid} is '{name}', not an LLM session process"))
    }
}

/// Set restrictive permissions on a file (owner read/write only).
fn set_private_permissions(path: &std::path::Path) {
    use std::os::unix::fs::PermissionsExt;
    if let Ok(metadata) = fs::metadata(path) {
        let mut perms = metadata.permissions();
        perms.set_mode(0o600);
        fs::set_permissions(path, perms).ok();
    }
}

/// Freeze (SIGSTOP) a session.

pub fn llm_coding_freeze(session_id: String) -> Result<String, String> {
    let mut sessions = SESSIONS.lock().map_err(|e| e.to_string())?;
    let session = sessions.get_mut(&session_id)
        .ok_or_else(|| format!("Session {session_id} not found"))?;

    if let Some(pid) = session.pid {
        validate_pid(pid)?;
        // SAFETY: PID validated above as belonging to a known process type.
        // Negative PID signals the process group.
        unsafe {
            libc::kill(-(pid as i32), libc::SIGSTOP);
        }
        session.state = SessionState::Frozen;
        persist_session(session);

        let msg = SessionMessage {
            from_session: "supervisor".to_string(),
            content: format!("Session '{}' FROZEN by supervisor", session.name),
            sent_at: now_iso(),
        };
        persist_message(&msg);

        Ok(json!({"status": "frozen", "pid": pid}).to_string())
    } else {
        Err("Session has no PID".to_string())
    }
}

/// Thaw (SIGCONT) a session.

pub fn llm_coding_thaw(session_id: String) -> Result<String, String> {
    let mut sessions = SESSIONS.lock().map_err(|e| e.to_string())?;
    let session = sessions.get_mut(&session_id)
        .ok_or_else(|| format!("Session {session_id} not found"))?;

    if let Some(pid) = session.pid {
        validate_pid(pid)?;
        // SAFETY: PID validated above.
        unsafe {
            libc::kill(-(pid as i32), libc::SIGCONT);
        }
        session.state = SessionState::Active;
        persist_session(session);

        let msg = SessionMessage {
            from_session: "supervisor".to_string(),
            content: format!("Session '{}' THAWED by supervisor", session.name),
            sent_at: now_iso(),
        };
        persist_message(&msg);

        Ok(json!({"status": "active", "pid": pid}).to_string())
    } else {
        Err("Session has no PID".to_string())
    }
}

/// Kill (terminate) a session.

pub fn llm_coding_kill(session_id: String) -> Result<String, String> {
    let mut sessions = SESSIONS.lock().map_err(|e| e.to_string())?;
    let session = sessions.get_mut(&session_id)
        .ok_or_else(|| format!("Session {session_id} not found"))?;

    if let Some(pid) = session.pid {
        validate_pid(pid)?;
        // SAFETY: PID validated. SIGCONT first (can't kill a stopped process cleanly).
        unsafe {
            libc::kill(-(pid as i32), libc::SIGCONT);
        }
        std::thread::sleep(std::time::Duration::from_millis(100));
        // SAFETY: PID validated above, same process.
        unsafe {
            libc::kill(-(pid as i32), libc::SIGTERM);
        }

        session.state = SessionState::Killed;
        session.pid = None;
        persist_session(session);

        // Clean up any locks held by this session
        let locks_dir = coord_dir().join("locks");
        if let Ok(entries) = fs::read_dir(&locks_dir) {
            for entry in entries.flatten() {
                if let Ok(content) = fs::read_to_string(entry.path()) {
                    if content.contains(&session_id) {
                        fs::remove_file(entry.path()).ok();
                    }
                }
            }
        }

        let msg = SessionMessage {
            from_session: "supervisor".to_string(),
            content: format!("Session '{}' KILLED by supervisor", session.name),
            sent_at: now_iso(),
        };
        persist_message(&msg);

        Ok(json!({"status": "killed"}).to_string())
    } else {
        Err("Session has no PID".to_string())
    }
}

/// Get system resource snapshot.

pub fn llm_coding_system_resources() -> Result<String, String> {
    let (avail, total) = read_system_memory();
    let resources = SystemResources {
        memory_available_mb: avail,
        memory_total_mb: total,
        cpu_percent: 0.0, // CPU sampling requires two reads — simplified for now
    };
    serde_json::to_string(&resources).map_err(|e| e.to_string())
}

/// List workspace locks from the coordination directory.

pub fn llm_coding_list_locks() -> Result<String, String> {
    let locks_dir = coord_dir().join("locks");
    let mut locks: Vec<WorkspaceLock> = Vec::new();

    if let Ok(entries) = fs::read_dir(&locks_dir) {
        for entry in entries.flatten() {
            if let Ok(content) = fs::read_to_string(entry.path()) {
                if let Ok(lock) = serde_json::from_str::<WorkspaceLock>(&content) {
                    locks.push(lock);
                }
            }
        }
    }

    serde_json::to_string(&locks).map_err(|e| e.to_string())
}

/// List cross-session messages from the coordination directory.

pub fn llm_coding_list_messages() -> Result<String, String> {
    let msg_dir = coord_dir().join("messages");
    let mut messages: Vec<SessionMessage> = Vec::new();

    if let Ok(entries) = fs::read_dir(&msg_dir) {
        for entry in entries.flatten() {
            if let Ok(content) = fs::read_to_string(entry.path()) {
                if let Ok(msg) = serde_json::from_str::<SessionMessage>(&content) {
                    messages.push(msg);
                }
            }
        }
    }

    // Sort by sent_at (newest last)
    messages.sort_by(|a, b| a.sent_at.cmp(&b.sent_at));

    // Keep only last 50
    if messages.len() > 50 {
        messages = messages.split_off(messages.len() - 50);
    }

    serde_json::to_string(&messages).map_err(|e| e.to_string())
}
