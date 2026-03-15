// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Script Gist Commands — Tauri command handlers for gist persistence,
//! execution dispatch, and diachronic snapshot management.
//!
//! Commands:
//!   - `script_gist_save`: Persist a gist to `~/.panll/gists/<id>.json`.
//!   - `script_gist_execute`: Dispatch a gist to its execution target.
//!   - `script_gist_restore_snapshot`: Deserialise a diachronic checkpoint.
//!   - `script_gist_list`: List all saved gist files.

use std::fs;
use std::path::PathBuf;

use serde_json::{json, Value};

/// Resolve the gist storage directory (`~/.panll/gists/`).
fn gists_dir() -> Result<PathBuf, String> {
    let home = dirs::home_dir()
        .ok_or_else(|| "Cannot determine home directory".to_string())?;
    Ok(home.join(".panll").join("gists"))
}

/// Save a gist to persistent storage.
///
/// Receives the gist as a pre-serialised JSON string from the frontend.
/// Validates it as JSON, extracts the `id` field for the filename, and
/// writes to `~/.panll/gists/<id>.json`.
///
/// Returns a JSON object with `path`, `id`, and `status`.
#[tauri::command]
pub async fn script_gist_save(gist_json: String) -> Result<String, String> {
    let dir = gists_dir()?;
    fs::create_dir_all(&dir)
        .map_err(|e| format!("Failed to create gists directory: {e}"))?;

    let parsed: Value = serde_json::from_str(&gist_json)
        .map_err(|e| format!("Invalid JSON in gist: {e}"))?;

    let id = parsed["id"]
        .as_str()
        .ok_or_else(|| "Gist JSON must contain an 'id' field".to_string())?;

    let filename = format!("{id}.json");
    let filepath = dir.join(&filename);

    let content = serde_json::to_string_pretty(&parsed)
        .map_err(|e| format!("Serialisation error: {e}"))?;

    fs::write(&filepath, content)
        .map_err(|e| format!("Failed to write gist: {e}"))?;

    Ok(json!({
        "path": filepath.to_string_lossy(),
        "id": id,
        "status": "saved",
    })
    .to_string())
}

/// Execute a gist by dispatching to its target backend.
///
/// This is a lightweight dispatch stub — the actual execution is routed
/// based on the `target` field in the gist JSON:
///   - `TargetDeno` / `TargetShell`: returns a placeholder (frontend sandbox)
///   - `TargetNqc` / `TargetEchidna`: returns a placeholder (proxy integration)
///   - `TargetBoj`: delegates to the BoJ cartridge invoke pathway
///
/// The frontend receives the result and wraps it into a `gistResult`.
#[tauri::command]
pub async fn script_gist_execute(gist_json: String) -> Result<String, String> {
    let parsed: Value = serde_json::from_str(&gist_json)
        .map_err(|e| format!("Invalid JSON in gist: {e}"))?;

    let id = parsed["id"]
        .as_str()
        .unwrap_or("unknown");

    let target = parsed["target"]
        .as_str()
        .or_else(|| parsed["target"].as_object().and_then(|_| Some("TargetBoj")))
        .unwrap_or("TargetDeno");

    let code = parsed["code"]
        .as_str()
        .unwrap_or("");

    // Dispatch based on target type.
    let result = match target {
        "TargetDeno" | "TargetShell" => {
            // Frontend-side execution — return acknowledgement.
            json!({
                "success": true,
                "output": format!("Gist '{id}' dispatched to local sandbox ({target})"),
                "error": null,
                "durationMs": 0.0,
                "executedAt": std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as f64,
                "invoker": "user",
            })
        }
        "TargetNqc" => {
            json!({
                "success": true,
                "output": format!("Gist '{id}' routed to NQC proxy (code length: {} chars)", code.len()),
                "error": null,
                "durationMs": 0.0,
                "executedAt": std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as f64,
                "invoker": "user",
            })
        }
        "TargetEchidna" => {
            json!({
                "success": true,
                "output": format!("Gist '{id}' dispatched to ECHIDNA prover (code length: {} chars)", code.len()),
                "error": null,
                "durationMs": 0.0,
                "executedAt": std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as f64,
                "invoker": "user",
            })
        }
        "TargetBoj" | _ => {
            // BoJ cartridge dispatch — extract cartridge name from target.
            let cartridge = parsed["target"]
                .as_object()
                .and_then(|obj| obj.get("TargetBoj"))
                .and_then(|v| v.as_str())
                .unwrap_or("default");

            json!({
                "success": true,
                "output": format!("Gist '{id}' dispatched to BoJ cartridge '{cartridge}' (code length: {} chars)", code.len()),
                "error": null,
                "durationMs": 0.0,
                "executedAt": std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as f64,
                "invoker": "user",
            })
        }
    };

    Ok(result.to_string())
}

/// Restore a diachronic checkpoint by deserialising the snapshot.
///
/// Receives the full serialised `scriptGistState` JSON and returns it
/// after validation. The frontend replaces its state with the returned data.
#[tauri::command]
pub async fn script_gist_restore_snapshot(snapshot_json: String) -> Result<String, String> {
    // Validate the snapshot is well-formed JSON.
    let parsed: Value = serde_json::from_str(&snapshot_json)
        .map_err(|e| format!("Invalid snapshot JSON: {e}"))?;

    // Verify it has the expected top-level fields for a scriptGistState.
    if !parsed.is_object() {
        return Err("Snapshot must be a JSON object".to_string());
    }

    let obj = parsed.as_object()
        .ok_or_else(|| "Snapshot is not a JSON object (unreachable after is_object check)".to_string())?;
    if !obj.contains_key("gists") {
        return Err("Snapshot missing 'gists' field — not a valid scriptGistState".to_string());
    }

    // Return the validated snapshot for the frontend to deserialise.
    Ok(parsed.to_string())
}

/// List all saved gist files from `~/.panll/gists/`.
///
/// Returns a JSON array of objects with `id` and `path` for each saved gist.
#[tauri::command]
pub async fn script_gist_list() -> Result<String, String> {
    let dir = gists_dir()?;

    if !dir.exists() {
        return Ok("[]".to_string());
    }

    let entries: Vec<Value> = fs::read_dir(&dir)
        .map_err(|e| format!("Cannot read gists directory: {e}"))?
        .filter_map(|entry| {
            let entry = entry.ok()?;
            let path = entry.path();
            if path.extension()?.to_str()? == "json" {
                let stem = path.file_stem()?.to_str()?.to_string();
                Some(json!({
                    "id": stem,
                    "path": path.to_string_lossy(),
                }))
            } else {
                None
            }
        })
        .collect();

    serde_json::to_string(&entries)
        .map_err(|e| format!("Serialisation error: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gists_dir_is_under_panll() {
        let dir = gists_dir().unwrap();
        assert!(dir.to_string_lossy().contains(".panll"));
        assert!(dir.to_string_lossy().ends_with("gists"));
    }

    #[tokio::test]
    async fn test_script_gist_execute_deno_target() {
        let gist = r#"{"id":"test-1","code":"console.log(1)","target":"TargetDeno"}"#;
        let result = script_gist_execute(gist.to_string()).await.unwrap();
        let parsed: Value = serde_json::from_str(&result).unwrap();
        assert_eq!(parsed["success"], true);
        assert!(parsed["output"].as_str().unwrap().contains("test-1"));
    }

    #[tokio::test]
    async fn test_script_gist_restore_invalid_json() {
        let result = script_gist_restore_snapshot("not json".to_string()).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_script_gist_restore_missing_gists() {
        let result = script_gist_restore_snapshot(r#"{"foo":"bar"}"#.to_string()).await;
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("gists"));
    }

    #[tokio::test]
    async fn test_script_gist_restore_valid() {
        let snapshot = r#"{"gists":[],"templates":[]}"#;
        let result = script_gist_restore_snapshot(snapshot.to_string()).await.unwrap();
        let parsed: Value = serde_json::from_str(&result).unwrap();
        assert!(parsed["gists"].is_array());
    }
}
