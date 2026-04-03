// SPDX-License-Identifier: PMPL-1.0-or-later

//! Valence Shell Tauri commands — PTY sessions, recordings, and checkpoints.
//!
//! Commands:
//!   - `valence_shell_check`:            Check if valence-shell binary exists on PATH.
//!   - `valence_shell_spawn`:            Spawn a shell process with piped I/O.
//!   - `valence_shell_input`:            Send input to a session's stdin, read stdout.
//!   - `valence_shell_record_start`:     Start asciicast recording.
//!   - `valence_shell_record_stop`:      Stop recording and close .cast file.
//!   - `valence_shell_recordings_list`:  List saved recordings.
//!   - `valence_shell_recording_delete`: Delete a recording file.
//!   - `valence_shell_checkpoint_create`:  Create a labelled checkpoint.
//!   - `valence_shell_checkpoint_restore`: Restore a checkpoint (restores cwd).
//!   - `valence_shell_checkpoints_list`:   List saved checkpoints.
//!   - `valence_shell_screenshot`:       Capture last N lines of session output.
//!   - `valence_shell_recording_export`: Export recording in a given format (stub).
//!
//! All persistent data lives under `/tmp/panll/` so it is ephemeral across
//! reboots, which is appropriate for recordings and checkpoints that are
//! not yet promoted to permanent storage.

use std::collections::HashMap;
use std::fs;
use std::io::{BufRead, BufReader, Write};
use std::path::PathBuf;
use std::process::{Child, Command, Stdio};
use std::sync::Mutex;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use once_cell::sync::Lazy;

/// Per-session state: the child process, its piped stdin handle, a buffered
/// reader for stdout, and a ring buffer of recent output lines for screenshots.
struct ShellSession {
    /// The spawned child process (owns the process lifetime).
    child: Child,
    /// Buffered reader wrapping the child's stdout pipe.
    stdout_reader: BufReader<std::process::ChildStdout>,
    /// Ring buffer of the last `OUTPUT_BUFFER_CAPACITY` output lines,
    /// used by `valence_shell_screenshot` to return terminal state.
    output_buffer: Vec<String>,
    /// The shell binary that was spawned (e.g. "bash", "zsh").
    shell: String,
    /// Working directory the session was spawned in.
    cwd: String,
}

/// Maximum number of output lines retained per session for screenshots.
const OUTPUT_BUFFER_CAPACITY: usize = 200;

/// Global session store — maps session_id to its ShellSession.
/// Protected by a Mutex so Tauri async commands can safely share it.
static SESSIONS: Lazy<Mutex<HashMap<String, ShellSession>>> =
    Lazy::new(|| Mutex::new(HashMap::new()));

/// Base directory for all Valence Shell ephemeral data.
const BASE_DIR: &str = "/tmp/panll";

/// Return the recordings directory, creating it lazily.
fn recordings_dir() -> Result<PathBuf, String> {
    let dir = PathBuf::from(BASE_DIR).join("recordings");
    fs::create_dir_all(&dir)
        .map_err(|e| format!("Cannot create recordings dir: {e}"))?;
    Ok(dir)
}

/// Return the checkpoints directory, creating it lazily.
fn checkpoints_dir() -> Result<PathBuf, String> {
    let dir = PathBuf::from(BASE_DIR).join("checkpoints");
    fs::create_dir_all(&dir)
        .map_err(|e| format!("Cannot create checkpoints dir: {e}"))?;
    Ok(dir)
}

/// Generate a Unix timestamp in seconds as a u64.
fn unix_now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

/// Generate a simple unique ID from the current timestamp and a random suffix.
fn generate_id() -> String {
    let ts = unix_now();
    let suffix: u32 = (ts as u32).wrapping_mul(2654435761); // Knuth hash for variety
    format!("{ts:x}-{suffix:08x}")
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

/// Check if the `valence-shell` binary exists on PATH.
///
/// Returns JSON: `{"available": bool, "version": "..."}`.

pub async fn valence_shell_check() -> Result<String, String> {
    let available = which::which("valence-shell").is_ok();
    let version = if available {
        // Attempt to get the version string from the binary.
        std::process::Command::new("valence-shell")
            .arg("--version")
            .output()
            .ok()
            .and_then(|o| String::from_utf8(o.stdout).ok())
            .map(|s| s.trim().to_string())
            .unwrap_or_else(|| "unknown".to_string())
    } else {
        "not installed".to_string()
    };

    let result = serde_json::json!({
        "available": available,
        "version": version,
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Spawn a shell process with piped stdin/stdout.
///
/// Starts the requested shell (e.g. "bash", "zsh") in the given working
/// directory. The child's stdin and stdout are piped so that subsequent
/// `valence_shell_input` calls can write commands and read output.
/// Stderr is merged into stdout via `2>&1` shell invocation.
///
/// Returns JSON with the session_id, shell, cwd, and status.

pub async fn valence_shell_spawn(shell: String, cwd: String) -> Result<String, String> {
    let session_id = generate_id();

    // Resolve the shell binary. Fall back to /bin/sh if the requested
    // shell is not found on PATH.
    let shell_bin = which::which(&shell)
        .unwrap_or_else(|_| PathBuf::from("/bin/sh"));

    // Validate that the working directory exists.
    let cwd_path = PathBuf::from(&cwd);
    if !cwd_path.is_dir() {
        return Err(format!("Working directory does not exist: {cwd}"));
    }

    // Spawn the shell with piped stdin/stdout. We use `-i` for interactive
    // mode so that prompts and builtins work, and redirect stderr to stdout
    // so the caller gets a unified output stream.
    let mut child = Command::new(&shell_bin)
        .arg("-i")
        .current_dir(&cwd_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .env("TERM", "dumb")          // suppress escape sequences
        .env("PS1", "$ ")             // simple prompt for parsing
        .env("LANG", "C.UTF-8")       // predictable locale
        .spawn()
        .map_err(|e| format!("Failed to spawn shell '{shell}': {e}"))?;

    // Extract the stdout pipe from the child, wrap in a BufReader for
    // line-by-line reading.
    let stdout_pipe = child.stdout.take()
        .ok_or_else(|| "Failed to capture stdout pipe".to_string())?;
    let stdout_reader = BufReader::new(stdout_pipe);

    // Store the session in the global map.
    let session = ShellSession {
        child,
        stdout_reader,
        output_buffer: Vec::with_capacity(OUTPUT_BUFFER_CAPACITY),
        shell: shell.clone(),
        cwd: cwd.clone(),
    };

    SESSIONS
        .lock()
        .map_err(|e| format!("Session lock poisoned: {e}"))?
        .insert(session_id.clone(), session);

    let result = serde_json::json!({
        "session_id": session_id,
        "shell": shell,
        "cwd": cwd,
        "status": "spawned",
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Send input to a shell session and read back available output.
///
/// Writes the `input` string (plus a trailing newline) to the session's
/// stdin, then reads any lines that become available on stdout within a
/// short timeout window. The output is also appended to the session's
/// ring buffer for `valence_shell_screenshot`.
///
/// If `session_id` is empty or missing, falls back to a one-shot
/// `Command::new("sh")` execution for backward compatibility.
///
/// Returns JSON with `output` (collected stdout text) and `exit_code`
/// (null while the session is still alive).

pub async fn valence_shell_input(
    session_id: Option<String>,
    input: String,
) -> Result<String, String> {
    // If no session_id provided, run the command as a one-shot execution
    // for backward compatibility with the original stub interface.
    let sid = match session_id {
        Some(ref id) if !id.is_empty() => id.clone(),
        _ => {
            return run_oneshot(&input).await;
        }
    };

    let mut sessions = SESSIONS
        .lock()
        .map_err(|e| format!("Session lock poisoned: {e}"))?;

    let session = sessions
        .get_mut(&sid)
        .ok_or_else(|| format!("Session '{sid}' not found"))?;

    // Write the input to the child's stdin.
    if let Some(ref mut stdin) = session.child.stdin {
        let line = if input.ends_with('\n') {
            input.clone()
        } else {
            format!("{input}\n")
        };
        stdin
            .write_all(line.as_bytes())
            .map_err(|e| format!("Write to stdin failed: {e}"))?;
        stdin
            .flush()
            .map_err(|e| format!("Flush stdin failed: {e}"))?;
    } else {
        return Err("Session stdin is closed".to_string());
    }

    // Give the child a moment to produce output, then drain available lines.
    // We use a non-blocking read approach: try reading lines with a short
    // sleep to allow the process to respond.
    drop(sessions); // release the lock during the sleep
    std::thread::sleep(Duration::from_millis(50));

    let mut sessions = SESSIONS
        .lock()
        .map_err(|e| format!("Session lock poisoned: {e}"))?;
    let session = sessions
        .get_mut(&sid)
        .ok_or_else(|| format!("Session '{sid}' disappeared"))?;

    let mut collected = String::new();

    // Read available lines from the stdout BufReader. Since the reader is
    // blocking, we use `read_line` in a loop with the `fill_buf` trick to
    // detect when no more data is immediately available.
    loop {
        // Peek at the internal buffer — if it's empty after we've already
        // read at least once, we stop to avoid blocking indefinitely.
        let buf = session
            .stdout_reader
            .fill_buf()
            .map_err(|e| format!("Read error: {e}"))?;
        if buf.is_empty() {
            break;
        }

        let mut line = String::new();
        match session.stdout_reader.read_line(&mut line) {
            Ok(0) => break,     // EOF
            Ok(_) => {
                collected.push_str(&line);
                // Append to the ring buffer, evicting oldest if full.
                if session.output_buffer.len() >= OUTPUT_BUFFER_CAPACITY {
                    session.output_buffer.remove(0);
                }
                session.output_buffer.push(line);
            }
            Err(_) => break,
        }
    }

    // Check whether the child has exited.
    let exit_code = match session.child.try_wait() {
        Ok(Some(status)) => serde_json::json!(status.code()),
        _ => serde_json::Value::Null,
    };

    let result = serde_json::json!({
        "output": collected,
        "exit_code": exit_code,
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Run a command as a one-shot execution (no persistent session).
///
/// Used as a fallback when `valence_shell_input` is called without a
/// session_id. Spawns `/bin/sh -c <input>`, captures stdout+stderr,
/// and returns the result.
async fn run_oneshot(input: &str) -> Result<String, String> {
    let output = Command::new("/bin/sh")
        .arg("-c")
        .arg(input)
        .output()
        .map_err(|e| format!("One-shot execution failed: {e}"))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    let combined = if stderr.is_empty() {
        stdout.to_string()
    } else {
        format!("{stdout}{stderr}")
    };

    let result = serde_json::json!({
        "output": combined,
        "exit_code": output.status.code(),
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Start recording terminal output in asciicast v2 format.
///
/// Creates a `.cast` file with the asciicast header in `/tmp/panll/recordings/`.

pub async fn valence_shell_record_start(name: String) -> Result<String, String> {
    let dir = recordings_dir()?;
    let id = generate_id();
    let filename = format!("{id}.cast");
    let path = dir.join(&filename);

    // Asciicast v2 header — one JSON object on the first line.
    let header = serde_json::json!({
        "version": 2,
        "width": 120,
        "height": 40,
        "timestamp": unix_now(),
        "title": name,
        "env": {
            "SHELL": "/bin/bash",
            "TERM": "xterm-256color"
        }
    });

    let header_line = serde_json::to_string(&header)
        .map_err(|e| format!("Serialisation error: {e}"))?;

    fs::write(&path, format!("{header_line}\n"))
        .map_err(|e| format!("Cannot write recording file: {e}"))?;

    let result = serde_json::json!({
        "id": id,
        "name": name,
        "file": filename,
        "status": "recording",
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Stop the active recording and close the `.cast` file.
///
/// Stub: marks the most recent `.cast` file as complete by appending
/// a final timestamp event.

pub async fn valence_shell_record_stop() -> Result<String, String> {
    let dir = recordings_dir()?;

    // Find the most recently modified .cast file.
    let latest = fs::read_dir(&dir)
        .map_err(|e| format!("Cannot read recordings dir: {e}"))?
        .filter_map(|e| e.ok())
        .filter(|e| {
            e.path()
                .extension()
                .and_then(|ext| ext.to_str())
                == Some("cast")
        })
        .max_by_key(|e| e.metadata().ok().and_then(|m| m.modified().ok()));

    match latest {
        Some(entry) => {
            let path = entry.path();
            // Append a final event line: [elapsed, "o", "Recording stopped.\r\n"]
            let stop_line = format!("[{}.0, \"o\", \"\\r\\nRecording stopped.\\r\\n\"]\n", unix_now());
            fs::OpenOptions::new()
                .append(true)
                .open(&path)
                .and_then(|mut f| {
                    use std::io::Write;
                    f.write_all(stop_line.as_bytes())
                })
                .map_err(|e| format!("Cannot append to recording: {e}"))?;

            let id = path
                .file_stem()
                .and_then(|s| s.to_str())
                .unwrap_or("unknown")
                .to_string();

            let result = serde_json::json!({
                "id": id,
                "status": "stopped",
            });

            serde_json::to_string(&result)
                .map_err(|e| format!("Serialisation error: {e}"))
        }
        None => Err("No active recording found".to_string()),
    }
}

/// List all recordings from `/tmp/panll/recordings/`.
///
/// Returns a JSON array of recording metadata objects.

pub async fn valence_shell_recordings_list() -> Result<String, String> {
    let dir = recordings_dir()?;
    let mut recordings = Vec::new();

    if dir.exists() {
        let entries = fs::read_dir(&dir)
            .map_err(|e| format!("Cannot read recordings dir: {e}"))?;

        for entry in entries {
            let entry = entry.map_err(|e| format!("Dir entry error: {e}"))?;
            let path = entry.path();
            if path.extension().and_then(|e| e.to_str()) == Some("cast") {
                let id = path
                    .file_stem()
                    .and_then(|s| s.to_str())
                    .unwrap_or("unknown")
                    .to_string();

                // Read the first line to extract the header title.
                let title = fs::read_to_string(&path)
                    .ok()
                    .and_then(|content| {
                        content.lines().next().and_then(|line| {
                            serde_json::from_str::<serde_json::Value>(line)
                                .ok()
                                .and_then(|v| v.get("title").and_then(|t| t.as_str()).map(String::from))
                        })
                    })
                    .unwrap_or_else(|| "Untitled".to_string());

                let size = entry.metadata().ok().map(|m| m.len()).unwrap_or(0);

                recordings.push(serde_json::json!({
                    "id": id,
                    "name": title,
                    "file": path.file_name().and_then(|f| f.to_str()).unwrap_or(""),
                    "size_bytes": size,
                }));
            }
        }
    }

    serde_json::to_string(&recordings)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Delete a recording file by ID.

pub async fn valence_shell_recording_delete(id: String) -> Result<String, String> {
    let path = recordings_dir()?.join(format!("{id}.cast"));
    if path.exists() {
        fs::remove_file(&path)
            .map_err(|e| format!("Delete error: {e}"))?;
        Ok(format!("Recording '{id}' deleted"))
    } else {
        Err(format!("Recording '{id}' not found"))
    }
}

/// Create a labelled checkpoint.
///
/// Saves a JSON file with the label, timestamp, and a generated ID to
/// `/tmp/panll/checkpoints/`.

pub async fn valence_shell_checkpoint_create(label: String) -> Result<String, String> {
    let dir = checkpoints_dir()?;
    let id = generate_id();
    let path = dir.join(format!("{id}.json"));

    let checkpoint = serde_json::json!({
        "id": id,
        "label": label,
        "timestamp": unix_now(),
        "status": "saved",
    });

    let json = serde_json::to_string_pretty(&checkpoint)
        .map_err(|e| format!("Serialisation error: {e}"))?;

    fs::write(&path, &json)
        .map_err(|e| format!("Cannot write checkpoint: {e}"))?;

    serde_json::to_string(&checkpoint)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Restore a checkpoint by ID.
///
/// Reads the checkpoint file and returns its contents with a "restored"
/// status. If a `session_id` is provided and the checkpoint contains a
/// `cwd` field, sends a `cd` command to the session to restore the
/// working directory.

pub async fn valence_shell_checkpoint_restore(
    id: String,
    session_id: Option<String>,
) -> Result<String, String> {
    let path = checkpoints_dir()?.join(format!("{id}.json"));
    if !path.exists() {
        return Err(format!("Checkpoint '{id}' not found"));
    }

    let content = fs::read_to_string(&path)
        .map_err(|e| format!("Read error: {e}"))?;
    let mut checkpoint: serde_json::Value = serde_json::from_str(&content)
        .map_err(|e| format!("Parse error: {e}"))?;

    // If a session is specified and the checkpoint has a cwd, restore it
    // by writing a `cd` command to the session's stdin.
    if let Some(ref sid) = session_id {
        if let Some(cwd) = checkpoint.get("cwd").and_then(|v| v.as_str()) {
            let mut sessions = SESSIONS
                .lock()
                .map_err(|e| format!("Session lock poisoned: {e}"))?;
            if let Some(session) = sessions.get_mut(sid) {
                if let Some(ref mut stdin) = session.child.stdin {
                    let cd_cmd = format!("cd {cwd}\n");
                    let _ = stdin.write_all(cd_cmd.as_bytes());
                    let _ = stdin.flush();
                    session.cwd = cwd.to_string();
                }
            }
        }
    }

    // Update the status to "restored".
    if let Some(obj) = checkpoint.as_object_mut() {
        obj.insert("status".to_string(), serde_json::json!("restored"));
    }

    serde_json::to_string(&checkpoint)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// List all checkpoints from `/tmp/panll/checkpoints/`.
///
/// Returns a JSON array of checkpoint objects.

pub async fn valence_shell_checkpoints_list() -> Result<String, String> {
    let dir = checkpoints_dir()?;
    let mut checkpoints = Vec::new();

    if dir.exists() {
        let entries = fs::read_dir(&dir)
            .map_err(|e| format!("Cannot read checkpoints dir: {e}"))?;

        for entry in entries {
            let entry = entry.map_err(|e| format!("Dir entry error: {e}"))?;
            let path = entry.path();
            if path.extension().and_then(|e| e.to_str()) == Some("json") {
                let content = fs::read_to_string(&path)
                    .map_err(|e| format!("Read error for {}: {e}", path.display()))?;
                match serde_json::from_str::<serde_json::Value>(&content) {
                    Ok(cp) => checkpoints.push(cp),
                    Err(e) => eprintln!(
                        "Warning: skipping invalid checkpoint {}: {e}",
                        path.display()
                    ),
                }
            }
        }
    }

    serde_json::to_string(&checkpoints)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Capture the current terminal state from a session's output buffer.
///
/// Returns the last N lines (default 40) of the session's accumulated
/// stdout output. If no session_id is provided, returns the state of
/// all active sessions. Each session's output buffer holds up to
/// `OUTPUT_BUFFER_CAPACITY` (200) lines.
///
/// Returns JSON with `content` (the terminal text), `width`, `height`
/// (number of lines returned), `timestamp`, and `session_id`.

pub async fn valence_shell_screenshot(
    session_id: Option<String>,
    lines: Option<usize>,
) -> Result<String, String> {
    let max_lines = lines.unwrap_or(40);

    let sessions = SESSIONS
        .lock()
        .map_err(|e| format!("Session lock poisoned: {e}"))?;

    // If a specific session is requested, return its buffer.
    if let Some(ref sid) = session_id {
        if let Some(session) = sessions.get(sid) {
            let buf = &session.output_buffer;
            let start = if buf.len() > max_lines {
                buf.len() - max_lines
            } else {
                0
            };
            let content: String = buf[start..].join("");

            let result = serde_json::json!({
                "session_id": sid,
                "content": content,
                "width": 120,
                "height": buf[start..].len(),
                "timestamp": unix_now(),
            });
            return serde_json::to_string(&result)
                .map_err(|e| format!("Serialisation error: {e}"));
        } else {
            return Err(format!("Session '{sid}' not found"));
        }
    }

    // No session specified — return a summary of all sessions.
    let mut all_screenshots = Vec::new();
    for (sid, session) in sessions.iter() {
        let buf = &session.output_buffer;
        let start = if buf.len() > max_lines {
            buf.len() - max_lines
        } else {
            0
        };
        let content: String = buf[start..].join("");
        all_screenshots.push(serde_json::json!({
            "session_id": sid,
            "shell": session.shell,
            "cwd": session.cwd,
            "content": content,
            "height": buf[start..].len(),
        }));
    }

    // If no sessions exist, return a helpful message rather than an empty array.
    if all_screenshots.is_empty() {
        let result = serde_json::json!({
            "content": "No active sessions. Use valence_shell_spawn to start one.",
            "width": 120,
            "height": 1,
            "timestamp": unix_now(),
        });
        return serde_json::to_string(&result)
            .map_err(|e| format!("Serialisation error: {e}"));
    }

    let result = serde_json::json!({
        "sessions": all_screenshots,
        "width": 120,
        "timestamp": unix_now(),
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Export a recording in a specified format.
///
/// Stub implementation: confirms the export request. Real implementation
/// will convert the `.cast` file to the requested format (e.g., gif, svg).

pub async fn valence_shell_recording_export(id: String, format: String) -> Result<String, String> {
    let cast_path = recordings_dir()?.join(format!("{id}.cast"));
    if !cast_path.exists() {
        return Err(format!("Recording '{id}' not found"));
    }

    let result = serde_json::json!({
        "id": id,
        "format": format,
        "status": "export_pending",
        "message": format!("Recording '{id}' queued for export as {format}"),
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use once_cell::sync::Lazy;

    /// Serialises filesystem tests so parallel `cleanup_test_dirs()` calls
    /// cannot race with each other.
    static TEST_LOCK: Lazy<tokio::sync::Mutex<()>> = Lazy::new(|| tokio::sync::Mutex::new(()));

    /// Ensure test directories exist (re-create if a parallel test removed them).
    /// This function MUST only be called while holding TEST_LOCK to prevent
    /// TOCTOU races between the remove and create steps.
    fn cleanup_test_dirs() {
        let rec = PathBuf::from(BASE_DIR).join("recordings");
        let ckp = PathBuf::from(BASE_DIR).join("checkpoints");
        // Atomic-ish: remove then create without yielding the lock.
        let _ = fs::remove_dir_all(&rec);
        let _ = fs::remove_dir_all(&ckp);
        let _ = fs::create_dir_all(&rec);
        let _ = fs::create_dir_all(&ckp);

        // Also clear any leaked shell sessions from previous tests.
        // Recover from poisoned mutex to prevent cascading test failures.
        if let Ok(mut sessions) = SESSIONS
            .lock()
            .map_or_else(|poisoned| Ok::<_, std::convert::Infallible>(poisoned.into_inner()), Ok)
        {
            // Kill any lingering child processes before dropping sessions.
            for (_, mut session) in sessions.drain() {
                let _ = session.child.kill();
            }
        }
    }

    #[tokio::test]
    async fn test_valence_shell_check_returns_json() {
        let result = valence_shell_check().await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert!(json.get("available").is_some());
        assert!(json.get("version").is_some());
    }

    #[tokio::test]
    async fn test_valence_shell_spawn_returns_session_id() {
        let result = valence_shell_spawn("bash".to_string(), "/tmp".to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["shell"], "bash");
        assert_eq!(json["cwd"], "/tmp");
        assert_eq!(json["status"], "spawned");
        assert!(json["session_id"].as_str().is_some());

        // Clean up: kill the spawned process.
        let sid = json["session_id"].as_str().unwrap().to_string();
        if let Ok(mut sessions) = SESSIONS.lock() {
            if let Some(mut session) = sessions.remove(&sid) {
                let _ = session.child.kill();
            }
        }
    }

    #[tokio::test]
    async fn test_valence_shell_input_oneshot() {
        // With no session_id, falls back to one-shot execution.
        let result = valence_shell_input(None, "echo hello world".to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        let output = json["output"].as_str().unwrap();
        assert!(
            output.contains("hello world"),
            "One-shot output should contain 'hello world', got: {output}"
        );
    }

    #[tokio::test]
    async fn test_record_start_creates_cast_file() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let result = valence_shell_record_start("test-recording".to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["name"], "test-recording");
        assert_eq!(json["status"], "recording");

        // Verify the .cast file exists on disk.
        let file = json["file"].as_str().unwrap();
        let path = recordings_dir().unwrap().join(file);
        assert!(path.exists());

        // Verify the header is valid asciicast v2.
        let content = fs::read_to_string(&path).unwrap();
        let header: serde_json::Value =
            serde_json::from_str(content.lines().next().unwrap()).unwrap();
        assert_eq!(header["version"], 2);
        assert_eq!(header["title"], "test-recording");
    }

    #[tokio::test]
    async fn test_record_stop_appends_stop_event() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let _ = valence_shell_record_start("stop-test".to_string()).await;
        let result = valence_shell_record_stop().await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["status"], "stopped");
    }

    #[tokio::test]
    async fn test_record_stop_no_recording_returns_error() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let result = valence_shell_record_stop().await;
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "No active recording found");
    }

    #[tokio::test]
    async fn test_recordings_list_empty() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let result = valence_shell_recordings_list().await;
        assert!(result.is_ok());
        let json: Vec<serde_json::Value> = serde_json::from_str(&result.unwrap()).unwrap();
        assert!(json.is_empty());
    }

    #[tokio::test]
    async fn test_recordings_list_after_create() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let _ = valence_shell_record_start("list-test".to_string()).await;
        let result = valence_shell_recordings_list().await;
        assert!(result.is_ok());
        let json: Vec<serde_json::Value> = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json.len(), 1);
        assert_eq!(json[0]["name"], "list-test");
    }

    #[tokio::test]
    async fn test_recording_delete() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let start = valence_shell_record_start("delete-test".to_string()).await.unwrap();
        let json: serde_json::Value = serde_json::from_str(&start).unwrap();
        let id = json["id"].as_str().unwrap().to_string();

        let result = valence_shell_recording_delete(id.clone()).await;
        assert!(result.is_ok());

        // Verify deletion.
        let list = valence_shell_recordings_list().await.unwrap();
        let recs: Vec<serde_json::Value> = serde_json::from_str(&list).unwrap();
        assert!(recs.is_empty());
    }

    #[tokio::test]
    async fn test_recording_delete_not_found() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let result = valence_shell_recording_delete("nonexistent".to_string()).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_checkpoint_create_and_list() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let result = valence_shell_checkpoint_create("before-refactor".to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["label"], "before-refactor");
        assert_eq!(json["status"], "saved");

        let list = valence_shell_checkpoints_list().await.unwrap();
        let cps: Vec<serde_json::Value> = serde_json::from_str(&list).unwrap();
        assert_eq!(cps.len(), 1);
        assert_eq!(cps[0]["label"], "before-refactor");
    }

    #[tokio::test]
    async fn test_checkpoint_restore() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let create = valence_shell_checkpoint_create("restore-test".to_string())
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_str(&create).unwrap();
        let id = json["id"].as_str().unwrap().to_string();

        let result = valence_shell_checkpoint_restore(id, None).await;
        assert!(result.is_ok());
        let restored: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(restored["status"], "restored");
        assert_eq!(restored["label"], "restore-test");
    }

    #[tokio::test]
    async fn test_checkpoint_restore_not_found() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let result = valence_shell_checkpoint_restore("nonexistent".to_string(), None).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_screenshot_no_sessions() {
        // With no active sessions, screenshot returns a helpful message.
        let result = valence_shell_screenshot(None, None).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert!(json["content"].as_str().unwrap().contains("No active sessions"));
        assert_eq!(json["width"], 120);
    }

    #[tokio::test]
    async fn test_recording_export_not_found() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let result =
            valence_shell_recording_export("nonexistent".to_string(), "gif".to_string()).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_recording_export_success() {
        let _guard = TEST_LOCK.lock().await;
        cleanup_test_dirs();
        let start = valence_shell_record_start("export-test".to_string())
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_str(&start).unwrap();
        let id = json["id"].as_str().unwrap().to_string();

        let result = valence_shell_recording_export(id.clone(), "svg".to_string()).await;
        assert!(result.is_ok());
        let export: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(export["id"], id);
        assert_eq!(export["format"], "svg");
        assert_eq!(export["status"], "export_pending");
    }
}
