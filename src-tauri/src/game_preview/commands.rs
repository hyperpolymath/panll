// SPDX-License-Identifier: PMPL-1.0-or-later

//! Game Preview Tauri commands — dev-server lifecycle, engine control, recording,
//! screenshots, render stats, and clip management.
//!
//! Commands:
//!   - `game_preview_check_server`: Probe a dev-server URL for connectivity.
//!   - `game_preview_start_server`: Spawn a Vite/Deno dev-server process.
//!   - `game_preview_stop_server`: Kill the tracked dev-server process.
//!   - `game_preview_control`: Send pause/resume/step commands to the engine.
//!   - `game_preview_record_start`: Begin a named game recording session.
//!   - `game_preview_record_stop`: End the current recording session.
//!   - `game_preview_screenshot`: Capture the current game frame.
//!   - `game_preview_stats`: Return render statistics (FPS, draw calls, etc.).
//!   - `game_preview_clips_list`: List saved clips on disk.
//!   - `game_preview_clip_delete`: Delete a clip by ID.
//!
//! Engine bridge protocol:
//!   When a dev server is running, `control`, `screenshot`, and `stats` commands
//!   attempt to reach the IDApTIK Vite plugin's `/__engine/*` endpoints. If the
//!   endpoints are unavailable (plugin not loaded, server not running), they fall
//!   back to local stub responses with `stub: true`.

use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};

use once_cell::sync::Lazy;
use serde_json::json;

/// Tracked Vite dev-server child process and its associated URL.
/// When `game_preview_start_server` spawns a Vite process we stash its PID
/// here so `game_preview_stop_server` can kill it cleanly.
struct DevServerState {
    /// OS process ID of the spawned Vite dev-server.
    pid: Option<u32>,
    /// URL the server was started on (e.g. "http://localhost:5173").
    url: Option<String>,
    /// Absolute path to the project directory passed at start time.
    project_dir: Option<String>,
}

impl DevServerState {
    fn new() -> Self {
        Self {
            pid: None,
            url: None,
            project_dir: None,
        }
    }
}

static DEV_SERVER: Lazy<Mutex<DevServerState>> = Lazy::new(|| Mutex::new(DevServerState::new()));

/// Base directory for game clip storage.
const CLIPS_DIR: &str = "/tmp/panll/game-clips";

/// Ensure the clips directory exists, creating it lazily if needed.
fn ensure_clips_dir() -> Result<PathBuf, String> {
    let path = PathBuf::from(CLIPS_DIR);
    fs::create_dir_all(&path)
        .map_err(|e| format!("Cannot create clips directory {CLIPS_DIR}: {e}"))?;
    Ok(path)
}

/// Generate a timestamp-based recording ID.
fn generate_recording_id() -> String {
    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis();
    format!("clip-{ts}")
}

/// Check if a dev server is running at the given URL.
///
/// Makes a GET request with a short timeout and returns connectivity status.
/// The frontend uses this to show the connection indicator in the Game Preview
/// panel header.
#[tauri::command]
pub async fn game_preview_check_server(url: String) -> Result<String, String> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build()
        .map_err(|e| format!("HTTP client error: {e}"))?;

    match client.get(&url).send().await {
        Ok(resp) => {
            let status = resp.status().as_u16();
            let result = json!({
                "connected": resp.status().is_success(),
                "status": status,
            });
            serde_json::to_string(&result)
                .map_err(|e| format!("Serialisation error: {e}"))
        }
        Err(_) => {
            let result = json!({
                "connected": false,
                "status": 0,
            });
            serde_json::to_string(&result)
                .map_err(|e| format!("Serialisation error: {e}"))
        }
    }
}

/// Start a Vite dev-server for the game project.
///
/// Spawns `npx vite` (or `deno task dev` if a `deno.json` is present) in the
/// given `project_dir`. The server process runs in the background; its PID is
/// tracked so `game_preview_stop_server` can kill it later.
///
/// Prerequisites:
///   - A valid IDApTIK game project directory with a `package.json` or `deno.json`.
///   - `npx` (from Node/Deno) available on `$PATH`.
///
/// Returns JSON with `pid`, `url`, and `projectDir` on success.
#[tauri::command]
pub async fn game_preview_start_server(
    project_dir: String,
    port: Option<u16>,
) -> Result<String, String> {
    let dir = PathBuf::from(&project_dir);
    if !dir.is_dir() {
        return Err(format!("Project directory does not exist: {project_dir}"));
    }

    // Check if a server is already running.
    {
        let state = DEV_SERVER.lock().map_err(|e| format!("Lock error: {e}"))?;
        if let Some(pid) = state.pid {
            return Err(format!(
                "Dev server already running (PID {pid}). Stop it first.",
            ));
        }
    }

    let server_port = port.unwrap_or(5173);
    let server_url = format!("http://localhost:{server_port}");

    // Decide launch command: prefer deno.json, fall back to npx vite.
    let has_deno_json = dir.join("deno.json").exists() || dir.join("deno.jsonc").exists();

    let child = if has_deno_json {
        Command::new("deno")
            .args(["task", "dev", "--port", &server_port.to_string()])
            .current_dir(&dir)
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn()
    } else {
        Command::new("npx")
            .args(["vite", "--port", &server_port.to_string()])
            .current_dir(&dir)
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn()
    };

    let child = child.map_err(|e| {
        format!(
            "Failed to spawn dev server in {project_dir}: {e}. \
             Ensure 'deno' or 'npx' is on $PATH."
        )
    })?;

    let pid = child.id();

    {
        let mut state = DEV_SERVER.lock().map_err(|e| format!("Lock error: {e}"))?;
        state.pid = Some(pid);
        state.url = Some(server_url.clone());
        state.project_dir = Some(project_dir.clone());
    }

    let result = json!({
        "pid": pid,
        "url": server_url,
        "projectDir": project_dir,
        "status": "started",
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Stop the running Vite dev-server.
///
/// Sends SIGTERM (Unix) or taskkill (Windows) to the tracked dev-server
/// process. Clears the tracked state afterwards regardless of kill outcome
/// so a new server can be started.
#[tauri::command]
pub async fn game_preview_stop_server() -> Result<String, String> {
    let (pid, url) = {
        let state = DEV_SERVER.lock().map_err(|e| format!("Lock error: {e}"))?;
        match state.pid {
            Some(pid) => (pid, state.url.clone().unwrap_or_default()),
            None => return Err("No dev server is currently running".to_string()),
        }
    };

    // Kill the process tree. On Unix we send SIGTERM to the process group
    // so child processes (the actual Vite server) are also terminated.
    #[cfg(unix)]
    {
        // Send SIGTERM to the process group (negative PID).
        let kill_result = unsafe { libc::kill(-(pid as i32), libc::SIGTERM) };
        if kill_result != 0 {
            // Fall back to killing just the process if group kill fails.
            unsafe { libc::kill(pid as i32, libc::SIGTERM) };
        }
    }

    #[cfg(windows)]
    {
        let _ = Command::new("taskkill")
            .args(["/F", "/T", "/PID", &pid.to_string()])
            .output();
    }

    // Clear state so a new server can be started.
    {
        let mut state = DEV_SERVER.lock().map_err(|e| format!("Lock error: {e}"))?;
        state.pid = None;
        state.url = None;
        state.project_dir = None;
    }

    let result = json!({
        "stopped": true,
        "pid": pid,
        "url": url,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Send a control command to the game engine.
///
/// Accepted commands: `"pause"`, `"resume"`, `"step"`.
/// Forwards the command to the dev server's engine control endpoint at
/// `<server_url>/__engine/control`. If no dev server is running or the
/// endpoint is unreachable, falls back to echoing the requested state.
///
/// The engine control endpoint is expected to be provided by an IDApTIK
/// Vite plugin that injects `/__engine/*` routes into the dev server.
#[tauri::command]
pub async fn game_preview_control(command: String) -> Result<String, String> {
    let valid_commands = ["pause", "resume", "step"];
    if !valid_commands.contains(&command.as_str()) {
        return Err(format!(
            "Unknown control command: {command}. Expected one of: pause, resume, step"
        ));
    }

    // Try to forward to the running dev server's engine endpoint.
    let server_url = {
        let state = DEV_SERVER.lock().map_err(|e| format!("Lock error: {e}"))?;
        state.url.clone()
    };

    if let Some(url) = server_url {
        let control_url = format!("{url}/__engine/control");
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(3))
            .build()
            .map_err(|e| format!("HTTP client error: {e}"))?;

        let body = json!({ "command": command });
        match client.post(&control_url).json(&body).send().await {
            Ok(resp) if resp.status().is_success() => {
                let text = resp.text().await.unwrap_or_default();
                // If the engine returns valid JSON, use it directly.
                if serde_json::from_str::<serde_json::Value>(&text).is_ok() {
                    return Ok(text);
                }
                // Otherwise wrap in our standard response.
                let result = json!({ "state": command, "engineResponse": text });
                return serde_json::to_string(&result)
                    .map_err(|e| format!("Serialisation error: {e}"));
            }
            _ => {
                // Engine endpoint not available — fall through to local echo.
            }
        }
    }

    // Fallback: echo the command state locally.
    let result = json!({ "state": command });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Start a named game recording session.
///
/// Creates a marker file in `/tmp/panll/game-clips/` to track the recording.
/// Returns the generated recording ID so the frontend can reference it later.
#[tauri::command]
pub async fn game_preview_record_start(name: String) -> Result<String, String> {
    let clips_dir = ensure_clips_dir()?;
    let id = generate_recording_id();
    let marker_path = clips_dir.join(format!("{id}.recording"));

    let metadata = json!({
        "id": id,
        "name": name,
        "started_at": SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs(),
        "status": "recording",
    });

    fs::write(&marker_path, serde_json::to_string_pretty(&metadata).unwrap_or_default())
        .map_err(|e| format!("Cannot write recording marker: {e}"))?;

    let result = json!({
        "id": id,
        "name": name,
        "status": "recording",
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Stop the current game recording session.
///
/// Finds the active `.recording` marker, renames it to `.clip`, and returns
/// clip metadata. If no active recording is found, returns an error.
#[tauri::command]
pub async fn game_preview_record_stop() -> Result<String, String> {
    let clips_dir = ensure_clips_dir()?;

    // Find the most recent .recording marker file.
    let mut recordings: Vec<_> = fs::read_dir(&clips_dir)
        .map_err(|e| format!("Cannot read clips directory: {e}"))?
        .filter_map(|entry| entry.ok())
        .filter(|entry| {
            entry.path().extension()
                .map(|ext| ext == "recording")
                .unwrap_or(false)
        })
        .collect();

    if recordings.is_empty() {
        return Err("No active recording found".to_string());
    }

    // Sort by name (timestamp-based) so we get the latest.
    recordings.sort_by_key(|e| e.file_name());
    // SAFETY: `recordings` is guaranteed non-empty — checked at line 146.
    let latest = recordings.last().expect("recordings: non-empty after is_empty guard");
    let recording_path = latest.path();

    // Read the recording metadata.
    let content = fs::read_to_string(&recording_path)
        .map_err(|e| format!("Cannot read recording marker: {e}"))?;
    let mut metadata: serde_json::Value = serde_json::from_str(&content)
        .map_err(|e| format!("Cannot parse recording marker: {e}"))?;

    // Update status and add end timestamp.
    metadata["status"] = json!("complete");
    metadata["ended_at"] = json!(
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs()
    );

    // Rename .recording → .clip
    let clip_path = recording_path.with_extension("clip");
    fs::write(&clip_path, serde_json::to_string_pretty(&metadata).unwrap_or_default())
        .map_err(|e| format!("Cannot write clip file: {e}"))?;
    fs::remove_file(&recording_path)
        .map_err(|e| format!("Cannot remove recording marker: {e}"))?;

    serde_json::to_string(&metadata)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Capture the current game frame as a screenshot.
///
/// Requests a frame capture from the running game's engine endpoint at
/// `<server_url>/__engine/screenshot`. If the engine provides raw PNG
/// bytes, they are saved to `/tmp/panll/game-clips/screenshot-<ts>.png`.
///
/// If no dev server is running or the endpoint is unavailable, returns a
/// placeholder path with `stub: true` so the frontend can show a fallback.
///
/// Prerequisites:
///   - Dev server running (via `game_preview_start_server`).
///   - IDApTIK Vite plugin providing the `/__engine/screenshot` endpoint.
#[tauri::command]
pub async fn game_preview_screenshot() -> Result<String, String> {
    let clips_dir = ensure_clips_dir()?;
    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis();
    let filename = format!("screenshot-{ts}.png");
    let path = clips_dir.join(&filename);

    // Try to capture from the running engine.
    let server_url = {
        let state = DEV_SERVER.lock().map_err(|e| format!("Lock error: {e}"))?;
        state.url.clone()
    };

    if let Some(url) = server_url {
        let screenshot_url = format!("{url}/__engine/screenshot");
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(5))
            .build()
            .map_err(|e| format!("HTTP client error: {e}"))?;

        if let Ok(resp) = client.get(&screenshot_url).send().await {
            if resp.status().is_success() {
                if let Ok(bytes) = resp.bytes().await {
                    if !bytes.is_empty() {
                        fs::write(&path, &bytes)
                            .map_err(|e| format!("Cannot write screenshot: {e}"))?;

                        let result = json!({
                            "path": path.to_string_lossy(),
                            "filename": filename,
                            "sizeBytes": bytes.len(),
                            "stub": false,
                        });
                        return serde_json::to_string(&result)
                            .map_err(|e| format!("Serialisation error: {e}"));
                    }
                }
            }
        }
    }

    // Fallback: return placeholder path.
    let result = json!({
        "path": path.to_string_lossy(),
        "filename": filename,
        "stub": true,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Return render statistics from the game engine.
///
/// Queries the running dev server's engine stats endpoint at
/// `<server_url>/__engine/stats`. If the engine provides JSON metrics
/// (FPS, draw calls, texture memory, sprite count), those are returned
/// directly.
///
/// If no dev server is running or the endpoint is unavailable, returns
/// placeholder values with `stub: true` so the frontend can indicate
/// that the engine is not providing live data.
///
/// Prerequisites:
///   - Dev server running (via `game_preview_start_server`).
///   - IDApTIK Vite plugin providing the `/__engine/stats` endpoint.
#[tauri::command]
pub async fn game_preview_stats() -> Result<String, String> {
    // Try to fetch live stats from the running engine.
    let server_url = {
        let state = DEV_SERVER.lock().map_err(|e| format!("Lock error: {e}"))?;
        state.url.clone()
    };

    if let Some(url) = server_url {
        let stats_url = format!("{url}/__engine/stats");
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(3))
            .build()
            .map_err(|e| format!("HTTP client error: {e}"))?;

        if let Ok(resp) = client.get(&stats_url).send().await {
            if resp.status().is_success() {
                if let Ok(text) = resp.text().await {
                    if serde_json::from_str::<serde_json::Value>(&text).is_ok() {
                        return Ok(text);
                    }
                }
            }
        }
    }

    // Fallback: return placeholder stats.
    let result = json!({
        "fps": 60.0,
        "drawCalls": 150,
        "textureMemory": 48.5,
        "spriteCount": 342,
        "stub": true,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// List all saved clips from `/tmp/panll/game-clips/`.
///
/// Reads `.clip` files from the clips directory and returns their metadata
/// as a JSON array. Clips are sorted by ID (timestamp-based, newest first).
#[tauri::command]
pub async fn game_preview_clips_list() -> Result<String, String> {
    let clips_dir = ensure_clips_dir()?;

    let mut clips: Vec<serde_json::Value> = fs::read_dir(&clips_dir)
        .map_err(|e| format!("Cannot read clips directory: {e}"))?
        .filter_map(|entry| entry.ok())
        .filter(|entry| {
            entry.path().extension()
                .map(|ext| ext == "clip")
                .unwrap_or(false)
        })
        .filter_map(|entry| {
            let content = fs::read_to_string(entry.path()).ok()?;
            serde_json::from_str(&content).ok()
        })
        .collect();

    // Sort by ID descending (newest first) since IDs are timestamp-based.
    clips.sort_by(|a, b| {
        let id_a = a.get("id").and_then(|v| v.as_str()).unwrap_or("");
        let id_b = b.get("id").and_then(|v| v.as_str()).unwrap_or("");
        id_b.cmp(id_a)
    });

    serde_json::to_string(&clips)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Delete a clip by its ID.
///
/// Removes the corresponding `.clip` file from the clips directory.
/// Returns confirmation JSON on success.
#[tauri::command]
pub async fn game_preview_clip_delete(id: String) -> Result<String, String> {
    let clips_dir = ensure_clips_dir()?;
    let clip_path = clips_dir.join(format!("{id}.clip"));

    if !clip_path.exists() {
        return Err(format!("Clip not found: {id}"));
    }

    fs::remove_file(&clip_path)
        .map_err(|e| format!("Cannot delete clip {id}: {e}"))?;

    let result = json!({
        "deleted": id,
        "success": true,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Helper: create a tokio runtime for async command tests.
    /// Binary crate submodules cannot use `#[tokio::test]` directly because
    /// the dev-dependency is not linked into the binary test harness.
    fn rt() -> tokio::runtime::Runtime {
        tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .expect("Failed to create tokio runtime for tests")
    }

    #[test]
    fn test_generate_recording_id() {
        let id = generate_recording_id();
        assert!(id.starts_with("clip-"), "ID should start with 'clip-': {id}");
        // ID should contain a numeric timestamp after the prefix.
        let timestamp_part = &id[5..];
        assert!(
            timestamp_part.parse::<u128>().is_ok(),
            "Timestamp portion should be numeric: {timestamp_part}"
        );
    }

    #[test]
    fn test_ensure_clips_dir() {
        let result = ensure_clips_dir();
        assert!(result.is_ok(), "Should create clips directory");
        let path = result.unwrap();
        assert!(path.exists(), "Clips directory should exist after creation");
    }

    #[test]
    fn test_game_preview_control_valid() {
        rt().block_on(async {
            let result = game_preview_control("pause".to_string()).await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["state"], "pause");
        });
    }

    #[test]
    fn test_game_preview_control_invalid() {
        rt().block_on(async {
            let result = game_preview_control("explode".to_string()).await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("Unknown control command"));
        });
    }

    #[test]
    fn test_game_preview_stats() {
        rt().block_on(async {
            let result = game_preview_stats().await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            // Without a running dev server the fallback stub values are returned.
            assert_eq!(json["fps"], 60.0);
            assert_eq!(json["drawCalls"], 150);
            assert_eq!(json["textureMemory"], 48.5);
            assert_eq!(json["spriteCount"], 342);
            assert_eq!(json["stub"], true);
        });
    }

    #[test]
    fn test_game_preview_screenshot() {
        rt().block_on(async {
            let result = game_preview_screenshot().await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert!(json["stub"].as_bool().unwrap());
            assert!(json["filename"].as_str().unwrap().starts_with("screenshot-"));
            assert!(json["filename"].as_str().unwrap().ends_with(".png"));
        });
    }

    #[test]
    fn test_game_preview_check_server_unreachable() {
        rt().block_on(async {
            // Connecting to a non-existent server should return connected: false.
            let result = game_preview_check_server("http://127.0.0.1:19999".to_string()).await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["connected"], false);
        });
    }

    #[test]
    fn test_game_preview_record_lifecycle() {
        rt().block_on(async {
            // Start a recording.
            let start_result = game_preview_record_start("test-clip".to_string()).await;
            assert!(start_result.is_ok());
            let start_json: serde_json::Value =
                serde_json::from_str(&start_result.unwrap()).unwrap();
            assert_eq!(start_json["status"], "recording");
            let clip_id = start_json["id"].as_str().unwrap().to_string();

            // Stop the recording.
            let stop_result = game_preview_record_stop().await;
            assert!(stop_result.is_ok());
            let stop_json: serde_json::Value =
                serde_json::from_str(&stop_result.unwrap()).unwrap();
            assert_eq!(stop_json["status"], "complete");

            // Clip should appear in the list.
            let list_result = game_preview_clips_list().await;
            assert!(list_result.is_ok());
            let clips: Vec<serde_json::Value> =
                serde_json::from_str(&list_result.unwrap()).unwrap();
            assert!(clips.iter().any(|c| c["id"].as_str() == Some(&clip_id)));

            // Delete the clip.
            let delete_result = game_preview_clip_delete(clip_id.clone()).await;
            assert!(delete_result.is_ok());
            let del_json: serde_json::Value =
                serde_json::from_str(&delete_result.unwrap()).unwrap();
            assert_eq!(del_json["success"], true);

            // Clip should no longer exist.
            let delete_again = game_preview_clip_delete(clip_id).await;
            assert!(delete_again.is_err());
        });
    }

    #[test]
    fn test_game_preview_clip_delete_not_found() {
        rt().block_on(async {
            let result = game_preview_clip_delete("nonexistent-clip".to_string()).await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("Clip not found"));
        });
    }

    #[test]
    fn test_game_preview_start_server_bad_dir() {
        // Reset dev server state to ensure clean test.
        {
            let mut state = DEV_SERVER.lock().unwrap();
            state.pid = None;
            state.url = None;
            state.project_dir = None;
        }
        rt().block_on(async {
            let result = game_preview_start_server(
                "/tmp/panll-nonexistent-project-dir-12345".to_string(),
                None,
            )
            .await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("does not exist"));
        });
    }

    #[test]
    fn test_game_preview_stop_server_not_running() {
        // Ensure no server is tracked.
        {
            let mut state = DEV_SERVER.lock().unwrap();
            state.pid = None;
            state.url = None;
            state.project_dir = None;
        }
        rt().block_on(async {
            let result = game_preview_stop_server().await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("No dev server"));
        });
    }
}
