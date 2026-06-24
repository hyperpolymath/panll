// SPDX-License-Identifier: MPL-2.0
//
// LLM Coding Gossamer commands — process spawning, resource monitoring,
// and session coordination.
//
// These commands are invoked by the ReScript frontend via the Gossamer
// command bridge. They manage the lifecycle of Claude/LLM coding sessions.
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

/// Read /proc/[pid]/statm for RSS memory of a single process (MB).
fn read_process_memory(pid: u32) -> u64 {
    let statm = fs::read_to_string(format!("/proc/{pid}/statm")).unwrap_or_default();
    statm.split_whitespace()
        .nth(1)
        .and_then(|s| s.parse::<u64>().ok())
        .map(|pages| pages * 4096 / 1024 / 1024)
        .unwrap_or(0)
}

/// Count child processes of a given PID.
fn count_children(pid: u32) -> usize {
    let tasks = fs::read_dir(format!("/proc/{pid}/task"))
        .ok()
        .into_iter()
        .flatten()
        .count();
    // Subtract 1 for the main thread
    tasks.saturating_sub(1)
}

/// Persist a session to disk.
fn persist_session(session: &LlmSession) {
    let path = coord_dir().join(&session.id);
    let json = serde_json::to_string(session).unwrap_or_default();
    fs::write(path, json).ok();
}

/// Load all persisted sessions at startup.
fn load_sessions() -> HashMap<String, LlmSession> {
    let mut map = HashMap::new();
    let dir = coord_dir();
    if dir.exists() {
        for entry in fs::read_dir(dir).ok().into_iter().flatten() {
            let path = match entry {
                Ok(e) => e.path(),
                Err(_) => continue,
            };
            let path_str = path.to_str().unwrap_or("");
            if let Ok(content) = fs::read_to_string(path_str) {
                if let Ok(session) = serde_json::from_str::<LlmSession>(&content) {
                    map.insert(session.id.clone(), session);
                }
            }
        }
    }
    map
}

/// Initialise the session registry from disk.
pub fn llm_coding_init() -> Result<String, String> {
    let mut sessions = SESSIONS.lock().map_err(|e| e.to_string())?;
    *sessions = load_sessions();
    Ok(json!({"status": "ok", "count": sessions.len()}).to_string())
}

/// Spawn a new Claude coding session in a Konsole terminal.
pub fn llm_coding_spawn(request: SpawnRequest) -> Result<String, String> {
    let session_id = Uuid::new_v4().to_string();

    // Build the task instruction file
    let task_file = coord_dir().join(format!("{}.task", session_id));
    let task_content = format!(
        "{}\n\n---\n\nConstraints:\n{}\n\n---\n\nContext:\n{}",
        request.task,
        request.constraints.unwrap_or_default(),
        request.context.unwrap_or_default()
    );
    let task_file_str = task_file.to_str().unwrap_or("");
    fs::write(task_file_str, task_content).map_err(|e| e.to_string())?;

    // Spawn konsole with claude
    let mut cmd = Command::new("konsole");
    cmd.args([
        "--hold",
        "-e",
        "claude",
        "--task-file",
        task_file_str,
        "--session-id",
        &session_id,
    ]);

    if let Some(profile) = request.profile {
        cmd.args(["--profile", &profile]);
    }

    let child = cmd.spawn().map_err(|e| format!("Failed to spawn: {}", e))?;
    let pid = child.id();

    // Create session record
    let mut session = LlmSession {
        id: session_id.clone(),
        name: request.name,
        provider: LlmProvider::Claude,
        state: SessionState::Active,
        pid: Some(pid),
        work_dir: request.work_dir,
        allowed_repos: request.allowed_repos,
        resources: ResourceUsage {
            memory_mb: 0,
            cpu_percent: 0.0,
            subagent_count: 0,
        },
        limits: ResourceLimits::default(),
        tasks: vec![],
        created_at: SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs(),
        messages: vec![],
    };

    // Initial resource snapshot
    session.resources.memory_mb = read_process_memory(pid);
    session.resources.subagent_count = count_children(pid) as u32;

    // Persist and register
    persist_session(&session);
    SESSIONS.lock().map_err(|e| e.to_string())?
        .insert(session_id.clone(), session);

    Ok(json!({
        "status": "ok",
        "session_id": session_id,
        "pid": pid
    }).to_string())
}

/// Freeze a session (pause resource usage).
pub fn llm_coding_freeze(session_id: String) -> Result<String, String> {
    let mut sessions = SESSIONS.lock().map_err(|e| e.to_string())?;
    if let Some(session) = sessions.get_mut(&session_id) {
        if let Some(pid) = session.pid {
            // SIGSTOP to freeze
            unsafe {
                libc::kill(pid as i32, libc::SIGSTOP);
            }
            session.state = SessionState::Frozen;
            persist_session(session);
            Ok(json!({"status": "ok", "state": "frozen"}).to_string())
        } else {
            Ok(json!({"status": "error", "message": "no pid"}).to_string())
        }
    } else {
        Ok(json!({"status": "error", "message": "not found"}).to_string())
    }
}

/// Thaw a frozen session.
pub fn llm_coding_thaw(session_id: String) -> Result<String, String> {
    let mut sessions = SESSIONS.lock().map_err(|e| e.to_string())?;
    if let Some(session) = sessions.get_mut(&session_id) {
        if let Some(pid) = session.pid {
            // SIGCONT to thaw
            unsafe {
                libc::kill(pid as i32, libc::SIGCONT);
            }
            session.state = SessionState::Active;
            persist_session(session);
            Ok(json!({"status": "ok", "state": "active"}).to_string())
        } else {
            Ok(json!({"status": "error", "message": "no pid"}).to_string())
        }
    } else {
        Ok(json!({"status": "error", "message": "not found"}).to_string())
    }
}

/// Terminate a session.
pub fn llm_coding_terminate(session_id: String) -> Result<String, String> {
    let mut sessions = SESSIONS.lock().map_err(|e| e.to_string())?;
    if let Some(session) = sessions.get_mut(&session_id) {
        if let Some(pid) = session.pid {
            // SIGTERM to terminate gracefully
            unsafe {
                libc::kill(pid as i32, libc::SIGTERM);
            }
            session.state = SessionState::Completed;
            session.pid = None;
            persist_session(session);
            Ok(json!({"status": "ok", "state": "completed"}).to_string())
        } else {
            Ok(json!({"status": "error", "message": "no pid"}).to_string())
        }
    } else {
        Ok(json!({"status": "error", "message": "not found"}).to_string())
    }
}

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
                    session.resources.subagent_count = count_children(pid) as u32;
                }
            }
        }
    }

    let list: Vec<&LlmSession> = sessions.values().collect();
    serde_json::to_string(&list).map_err(|e| e.to_string())
}

/// Get session status by ID.
pub fn llm_coding_session_status(session_id: String) -> Result<String, String> {
    let sessions = SESSIONS.lock().map_err(|e| e.to_string())?;
    match sessions.get(&session_id) {
        Some(session) => Ok(serde_json::to_string(session).map_err(|e| e.to_string())?),
        None => Ok(json!({"status": "error", "message": "not found"}).to_string()),
    }
}

/// Append a message to a session's log.
pub fn llm_coding_append_message(session_id: String, content: String) -> Result<String, String> {
    let mut sessions = SESSIONS.lock().map_err(|e| e.to_string())?;
    if let Some(session) = sessions.get_mut(&session_id) {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        session.messages.push(SessionMessage {
            sent_at: timestamp,
            content,
            from_session: session.id.clone(),
        });
        persist_session(session);
        Ok(json!({"status": "ok"}).to_string())
    } else {
        Ok(json!({"status": "error", "message": "not found"}).to_string())
    }
}

/// Get recent messages for a session (last 50).
pub fn llm_coding_get_messages(session_id: String) -> Result<String, String> {
    let sessions = SESSIONS.lock().map_err(|e| e.to_string())?;
    match sessions.get(&session_id) {
        Some(session) => {
            let mut messages = session.messages.clone();
            // Sort by sent_at (newest last)
            messages.sort_by_key(|m| m.sent_at);
            // Keep only last 50
            if messages.len() > 50 {
                messages = messages.split_off(messages.len() - 50);
            }
            serde_json::to_string(&messages).map_err(|e| e.to_string())
        }
        None => Ok(json!({"status": "error", "message": "not found"}).to_string()),
    }
}

/// Sum of busy + idle jiffies from the aggregate `cpu` line of /proc/stat.
/// Returns `(busy, total)`.
fn read_cpu_jiffies() -> (u64, u64) {
    let stat = fs::read_to_string("/proc/stat").unwrap_or_default();
    let line = stat.lines().next().unwrap_or("");
    let vals: Vec<u64> = line
        .split_whitespace()
        .skip(1)
        .filter_map(|s| s.parse().ok())
        .collect();
    let total: u64 = vals.iter().sum();
    // idle = field 3 (idle) + field 4 (iowait), 0-indexed in `vals`.
    let idle = vals.get(3).copied().unwrap_or(0) + vals.get(4).copied().unwrap_or(0);
    (total.saturating_sub(idle), total)
}

/// Overall host CPU utilisation percentage, sampled over a 100ms window.
fn read_overall_cpu() -> f64 {
    let (busy1, total1) = read_cpu_jiffies();
    std::thread::sleep(std::time::Duration::from_millis(100));
    let (busy2, total2) = read_cpu_jiffies();
    let total_delta = total2.saturating_sub(total1);
    if total_delta == 0 {
        return 0.0;
    }
    let busy_delta = busy2.saturating_sub(busy1);
    (busy_delta as f64 / total_delta as f64) * 100.0
}

/// Host-wide resource snapshot, used by the panel to decide whether the
/// system has headroom to spawn additional sessions/sub-agents.
pub fn llm_coding_system_resources() -> Result<String, String> {
    let (memory_available_mb, memory_total_mb) = read_system_memory();
    let snapshot = SystemResources {
        memory_available_mb,
        memory_total_mb,
        cpu_percent: read_overall_cpu(),
    };
    serde_json::to_string(&snapshot).map_err(|e| e.to_string())
}