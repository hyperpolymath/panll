// SPDX-License-Identifier: MPL-2.0

//! Feedback Tauri commands — persistent feedback report storage.
//!
//! Commands:
//!   - `feedback_save_report`: Write a feedback report JSON to
//!     `~/.panll/feedback/<timestamp>.json`. Creates directories if needed.
//!
//! Unlike the existing `submit_feedback` (NDJSON append to /tmp), this
//! provides durable per-report files under the user's home directory.

use std::fs;
use std::time::{SystemTime, UNIX_EPOCH};

use serde_json::json;

/// Resolve the persistent feedback directory under the user's home.
fn feedback_dir() -> Result<std::path::PathBuf, String> {
    let home = dirs::home_dir().ok_or("Cannot determine home directory")?;
    Ok(home.join(".panll").join("feedback"))
}

/// Save a feedback report as a timestamped JSON file.
///
/// The `report_json` parameter is a JSON string from the frontend containing
/// the full report payload. This command wraps it with a timestamp and writes
/// it to `~/.panll/feedback/<timestamp>.json`.
///
/// Returns a JSON object with `path` (where the file was saved) and `id`
/// (the timestamp-based identifier).

pub async fn feedback_save_report(report_json: String) -> Result<String, String> {
    let dir = feedback_dir()?;
    fs::create_dir_all(&dir)
        .map_err(|e| format!("Failed to create feedback directory: {e}"))?;

    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|e| format!("Time error: {e}"))?
        .as_millis();

    let filename = format!("{timestamp}.json");
    let filepath = dir.join(&filename);

    // Parse the incoming JSON to validate it, then wrap with metadata.
    let parsed: serde_json::Value = serde_json::from_str(&report_json)
        .map_err(|e| format!("Invalid JSON in report: {e}"))?;

    let wrapped = json!({
        "id": format!("feedback-{timestamp}"),
        "timestamp": timestamp,
        "report": parsed,
    });

    let content = serde_json::to_string_pretty(&wrapped)
        .map_err(|e| format!("Serialisation error: {e}"))?;

    fs::write(&filepath, content)
        .map_err(|e| format!("Failed to write report: {e}"))?;

    Ok(json!({
        "path": filepath.to_string_lossy(),
        "id": format!("feedback-{timestamp}"),
        "status": "saved",
    })
    .to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_feedback_save_report_creates_file() {
        let report = r#"{"type": "bug", "description": "Test report"}"#;
        let result = feedback_save_report(report.to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["status"], "saved");
        let path = json["path"].as_str().unwrap();
        assert!(std::path::Path::new(path).exists());

        // Read the file and verify it contains well-formed wrapped JSON.
        let content = fs::read_to_string(path).unwrap();
        let saved: serde_json::Value = serde_json::from_str(&content).unwrap();
        assert!(saved.get("id").is_some());
        assert!(saved.get("timestamp").is_some());
        assert!(saved.get("report").is_some());
        assert_eq!(saved["report"]["type"], "bug");
        assert_eq!(saved["report"]["description"], "Test report");

        // Clean up.
        let _ = fs::remove_file(path);
    }

    #[tokio::test]
    async fn test_feedback_save_report_rejects_invalid_json() {
        let result = feedback_save_report("not valid json".to_string()).await;
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Invalid JSON"));
    }
}
