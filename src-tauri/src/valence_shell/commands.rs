// SPDX-License-Identifier: PMPL-1.0-or-later

//! Valence Shell Tauri commands — PTY sessions, recordings, and checkpoints.
//!
//! Commands:
//!   - `valence_shell_check`:            Check if valence-shell binary exists on PATH.
//!   - `valence_shell_spawn`:            Spawn a PTY session (stub).
//!   - `valence_shell_input`:            Send input to PTY (stub: echoes back).
//!   - `valence_shell_record_start`:     Start asciicast recording.
//!   - `valence_shell_record_stop`:      Stop recording and close .cast file.
//!   - `valence_shell_recordings_list`:  List saved recordings.
//!   - `valence_shell_recording_delete`: Delete a recording file.
//!   - `valence_shell_checkpoint_create`:  Create a labelled checkpoint.
//!   - `valence_shell_checkpoint_restore`: Restore a checkpoint (stub).
//!   - `valence_shell_checkpoints_list`:   List saved checkpoints.
//!   - `valence_shell_screenshot`:       Capture terminal state (stub).
//!   - `valence_shell_recording_export`: Export recording in a given format (stub).
//!
//! All persistent data lives under `/tmp/panll/` so it is ephemeral across
//! reboots, which is appropriate for recordings and checkpoints that are
//! not yet promoted to permanent storage.

use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

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
#[tauri::command]
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

/// Spawn a PTY session.
///
/// Stub implementation: returns a session ID immediately. Real PTY
/// integration will be added via `tauri-plugin-shell` in a later phase.
#[tauri::command]
pub async fn valence_shell_spawn(shell: String, cwd: String) -> Result<String, String> {
    let session_id = generate_id();

    let result = serde_json::json!({
        "session_id": session_id,
        "shell": shell,
        "cwd": cwd,
        "status": "spawned",
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Send input to the active PTY session.
///
/// Stub implementation: echoes the input back as simulated output.
#[tauri::command]
pub async fn valence_shell_input(input: String) -> Result<String, String> {
    let result = serde_json::json!({
        "output": format!("echo: {input}"),
        "exit_code": serde_json::Value::Null,
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Start recording terminal output in asciicast v2 format.
///
/// Creates a `.cast` file with the asciicast header in `/tmp/panll/recordings/`.
#[tauri::command]
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
#[tauri::command]
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
#[tauri::command]
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
#[tauri::command]
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
#[tauri::command]
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
/// Stub implementation: reads the checkpoint file and returns its contents
/// with a "restored" status. Real restore logic depends on PTY integration.
#[tauri::command]
pub async fn valence_shell_checkpoint_restore(id: String) -> Result<String, String> {
    let path = checkpoints_dir()?.join(format!("{id}.json"));
    if !path.exists() {
        return Err(format!("Checkpoint '{id}' not found"));
    }

    let content = fs::read_to_string(&path)
        .map_err(|e| format!("Read error: {e}"))?;
    let mut checkpoint: serde_json::Value = serde_json::from_str(&content)
        .map_err(|e| format!("Parse error: {e}"))?;

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
#[tauri::command]
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

/// Capture the current terminal state as a screenshot.
///
/// Stub implementation: returns a placeholder string representing the
/// terminal contents. Real implementation will capture the PTY buffer.
#[tauri::command]
pub async fn valence_shell_screenshot() -> Result<String, String> {
    let result = serde_json::json!({
        "content": "--- Terminal Screenshot (stub) ---\n$ _\n--- End ---",
        "width": 120,
        "height": 40,
        "timestamp": unix_now(),
    });

    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Export a recording in a specified format.
///
/// Stub implementation: confirms the export request. Real implementation
/// will convert the `.cast` file to the requested format (e.g., gif, svg).
#[tauri::command]
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

    /// Ensure test directories exist (re-create if a parallel test removed them).
    fn cleanup_test_dirs() {
        let _ = fs::remove_dir_all(PathBuf::from(BASE_DIR).join("recordings"));
        let _ = fs::remove_dir_all(PathBuf::from(BASE_DIR).join("checkpoints"));
        let _ = fs::create_dir_all(PathBuf::from(BASE_DIR).join("recordings"));
        let _ = fs::create_dir_all(PathBuf::from(BASE_DIR).join("checkpoints"));
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
    }

    #[tokio::test]
    async fn test_valence_shell_input_echoes() {
        let result = valence_shell_input("hello world".to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["output"], "echo: hello world");
    }

    #[tokio::test]
    async fn test_record_start_creates_cast_file() {
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
        cleanup_test_dirs();
    }

    #[tokio::test]
    async fn test_record_stop_appends_stop_event() {
        cleanup_test_dirs();
        let _ = valence_shell_record_start("stop-test".to_string()).await;
        let result = valence_shell_record_stop().await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["status"], "stopped");
        cleanup_test_dirs();
    }

    #[tokio::test]
    async fn test_record_stop_no_recording_returns_error() {
        cleanup_test_dirs();
        let result = valence_shell_record_stop().await;
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "No active recording found");
    }

    #[tokio::test]
    async fn test_recordings_list_empty() {
        cleanup_test_dirs();
        let result = valence_shell_recordings_list().await;
        assert!(result.is_ok());
        let json: Vec<serde_json::Value> = serde_json::from_str(&result.unwrap()).unwrap();
        assert!(json.is_empty());
    }

    #[tokio::test]
    async fn test_recordings_list_after_create() {
        cleanup_test_dirs();
        let _ = valence_shell_record_start("list-test".to_string()).await;
        let result = valence_shell_recordings_list().await;
        assert!(result.is_ok());
        let json: Vec<serde_json::Value> = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json.len(), 1);
        assert_eq!(json[0]["name"], "list-test");
        cleanup_test_dirs();
    }

    #[tokio::test]
    async fn test_recording_delete() {
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
        cleanup_test_dirs();
    }

    #[tokio::test]
    async fn test_recording_delete_not_found() {
        cleanup_test_dirs();
        let result = valence_shell_recording_delete("nonexistent".to_string()).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_checkpoint_create_and_list() {
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
        cleanup_test_dirs();
    }

    #[tokio::test]
    async fn test_checkpoint_restore() {
        cleanup_test_dirs();
        let create = valence_shell_checkpoint_create("restore-test".to_string())
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_str(&create).unwrap();
        let id = json["id"].as_str().unwrap().to_string();

        let result = valence_shell_checkpoint_restore(id).await;
        assert!(result.is_ok());
        let restored: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(restored["status"], "restored");
        assert_eq!(restored["label"], "restore-test");
        cleanup_test_dirs();
    }

    #[tokio::test]
    async fn test_checkpoint_restore_not_found() {
        cleanup_test_dirs();
        let result = valence_shell_checkpoint_restore("nonexistent".to_string()).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_screenshot_returns_stub() {
        let result = valence_shell_screenshot().await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert!(json["content"].as_str().unwrap().contains("stub"));
        assert_eq!(json["width"], 120);
        assert_eq!(json["height"], 40);
    }

    #[tokio::test]
    async fn test_recording_export_not_found() {
        cleanup_test_dirs();
        let result =
            valence_shell_recording_export("nonexistent".to_string(), "gif".to_string()).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_recording_export_success() {
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
        cleanup_test_dirs();
    }
}
