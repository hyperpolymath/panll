// SPDX-License-Identifier: PMPL-1.0-or-later

//! Tauri commands for scanning `.a2ml` clade definition files.

use serde_json::json;
use std::fs;
use std::path::PathBuf;

/// Resolve the `panel-clades/clades/` directory relative to the project root.
/// In development, this is adjacent to `src-tauri/`; in production, bundled
/// as a Tauri resource.
fn clades_dir() -> PathBuf {
    // Try relative to the binary location (development layout).
    let mut dir = std::env::current_exe()
        .unwrap_or_default()
        .parent()
        .unwrap_or(&PathBuf::from("."))
        .to_path_buf();

    // Walk up from target/debug/ to the project root.
    for _ in 0..4 {
        let candidate = dir.join("panel-clades").join("clades");
        if candidate.is_dir() {
            return candidate;
        }
        dir = dir.parent().unwrap_or(&dir).to_path_buf();
    }

    // Fallback: CWD-based (works when launched from project root).
    PathBuf::from("panel-clades/clades")
}

/// Scan all `.a2ml` clade files and return their contents as a JSON array.
///
/// Each entry is `{"id": "<dir-name>", "content": "<file-content>"}`.
/// Directories without an `.a2ml` file are silently skipped.
#[tauri::command]
pub async fn scan_clade_files() -> Result<String, String> {
    let dir = clades_dir();
    if !dir.is_dir() {
        return Err(format!("Clades directory not found: {}", dir.display()));
    }

    let mut entries = Vec::new();
    let read_dir = fs::read_dir(&dir).map_err(|e| format!("Read dir error: {e}"))?;

    for entry in read_dir.flatten() {
        let path = entry.path();
        if !path.is_dir() {
            continue;
        }

        let dir_name = path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("")
            .to_string();

        // Find *.a2ml files in the directory.
        if let Ok(sub_entries) = fs::read_dir(&path) {
            for sub in sub_entries.flatten() {
                let sub_path = sub.path();
                if sub_path.extension().and_then(|e| e.to_str()) == Some("a2ml") {
                    if let Ok(content) = fs::read_to_string(&sub_path) {
                        entries.push(json!({
                            "id": dir_name,
                            "content": content
                        }));
                    }
                    break; // One .a2ml per directory.
                }
            }
        }
    }

    serde_json::to_string(&entries).map_err(|e| format!("JSON serialization error: {e}"))
}
