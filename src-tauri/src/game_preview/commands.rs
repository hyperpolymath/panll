// SPDX-License-Identifier: PMPL-1.0-or-later

//! Game Preview Tauri commands — dev-server health, engine control, recording,
//! screenshots, render stats, and clip management.
//!
//! Commands:
//!   - `game_preview_check_server`: Probe a dev-server URL for connectivity.
//!   - `game_preview_control`: Send pause/resume/step commands to the engine.
//!   - `game_preview_record_start`: Begin a named game recording session.
//!   - `game_preview_record_stop`: End the current recording session.
//!   - `game_preview_screenshot`: Capture the current game frame.
//!   - `game_preview_stats`: Return render statistics (FPS, draw calls, etc.).
//!   - `game_preview_clips_list`: List saved clips on disk.
//!   - `game_preview_clip_delete`: Delete a clip by ID.

use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

use serde_json::json;

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

/// Send a control command to the game engine.
///
/// Accepted commands: `"pause"`, `"resume"`, `"step"`.
/// Currently a stub that echoes the requested state back. When the engine
/// WebSocket bridge is implemented this will forward commands to the running
/// game instance.
#[tauri::command]
pub async fn game_preview_control(command: String) -> Result<String, String> {
    let valid_commands = ["pause", "resume", "step"];
    if !valid_commands.contains(&command.as_str()) {
        return Err(format!(
            "Unknown control command: {command}. Expected one of: pause, resume, step"
        ));
    }

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
    let latest = recordings.last().unwrap();
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
/// Currently a stub that returns a placeholder path. When the engine bridge
/// is implemented, this will request a frame capture from the running game
/// and save it as a PNG.
#[tauri::command]
pub async fn game_preview_screenshot() -> Result<String, String> {
    let clips_dir = ensure_clips_dir()?;
    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis();
    let filename = format!("screenshot-{ts}.png");
    let path = clips_dir.join(&filename);

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
/// Currently returns stub values. When the engine bridge is implemented,
/// this will query the running game for real-time performance metrics.
#[tauri::command]
pub async fn game_preview_stats() -> Result<String, String> {
    let result = json!({
        "fps": 60.0,
        "drawCalls": 150,
        "textureMemory": 48.5,
        "spriteCount": 342,
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
            assert_eq!(json["fps"], 60.0);
            assert_eq!(json["drawCalls"], 150);
            assert_eq!(json["textureMemory"], 48.5);
            assert_eq!(json["spriteCount"], 342);
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
}
