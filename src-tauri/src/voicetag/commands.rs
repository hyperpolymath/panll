// SPDX-License-Identifier: PMPL-1.0-or-later

//! VoiceTag Tauri commands — filesystem I/O for `.mri.json` sidecar files.
//!
//! The `.mri.json` format is the portable interchange layer for Code MRI tags.
//! PanLL reads/writes these files but does not own the format — any tool can
//! consume them. The ReScript frontend handles JSON serialisation/deserialisation;
//! the Rust side treats content as opaque strings (read/write/delete/scan).

use std::fs;
use std::path::Path;
use walkdir::WalkDir;

/// Load a `.mri.json` sidecar file and return its content as a string.
///
/// Returns the raw JSON content so the ReScript frontend can parse it with
/// its own type-safe deserialiser. If the file does not exist, returns an
/// empty MRI file structure so the frontend can initialise cleanly.
#[tauri::command]
pub async fn voicetag_load(path: String) -> Result<String, String> {
    let p = Path::new(&path);
    if p.exists() {
        fs::read_to_string(p)
            .map_err(|e| format!("Cannot read {}: {}", path, e))
    } else {
        // File doesn't exist yet — return empty structure so the frontend
        // can initialise a new sidecar without special error handling.
        Ok(r#"{"version":"1.0","sourceFile":"","tags":[],"lastModified":0}"#.to_string())
    }
}

/// Save content to a `.mri.json` sidecar file.
///
/// The content is a pre-serialised JSON string from the ReScript frontend.
/// Creates parent directories if they don't exist (handles nested source trees).
#[tauri::command]
pub async fn voicetag_save(path: String, content: String) -> Result<String, String> {
    let p = Path::new(&path);

    // Ensure parent directory exists (source file might be in a nested dir).
    if let Some(parent) = p.parent() {
        if !parent.exists() {
            fs::create_dir_all(parent)
                .map_err(|e| format!("Cannot create directory {}: {}", parent.display(), e))?;
        }
    }

    fs::write(p, &content)
        .map_err(|e| format!("Cannot write {}: {}", path, e))?;

    Ok(format!("Saved {}", path))
}

/// Delete a `.mri.json` sidecar file.
///
/// Called when all tags are removed from a file — no point keeping an empty
/// sidecar around. Silently succeeds if the file doesn't exist (idempotent).
#[tauri::command]
pub async fn voicetag_delete(path: String) -> Result<String, String> {
    let p = Path::new(&path);
    if p.exists() {
        fs::remove_file(p)
            .map_err(|e| format!("Cannot delete {}: {}", path, e))?;
        Ok(format!("Deleted {}", path))
    } else {
        Ok(format!("Already gone: {}", path))
    }
}

/// Scan a directory tree for all `.mri.json` sidecar files.
///
/// Returns a JSON array of objects, each containing the sidecar path and
/// the source file path it annotates. Used for project-wide tag summaries,
/// the Code MRI dashboard, and Vexometer friction calculation.
///
/// Example output:
/// ```json
/// [
///   {"sidecar": "src/Model.res.mri.json", "source": "src/Model.res"},
///   {"sidecar": "src/Update.res.mri.json", "source": "src/Update.res"}
/// ]
/// ```
#[tauri::command]
pub async fn voicetag_scan(path: String) -> Result<String, String> {
    let root = Path::new(&path);
    if !root.is_dir() {
        return Err(format!("Not a directory: {}", path));
    }

    let mut results: Vec<serde_json::Value> = Vec::new();

    for entry in WalkDir::new(root)
        .follow_links(true)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let file_path = entry.path();
        if let Some(name) = file_path.file_name().and_then(|n| n.to_str()) {
            if name.ends_with(".mri.json") {
                let sidecar = file_path.to_string_lossy().to_string();
                // Derive the source file path by stripping `.mri.json` suffix.
                let source = sidecar.strip_suffix(".mri.json")
                    .unwrap_or(&sidecar)
                    .to_string();
                results.push(serde_json::json!({
                    "sidecar": sidecar,
                    "source": source,
                }));
            }
        }
    }

    serde_json::to_string(&results)
        .map_err(|e| format!("Serialisation error: {e}"))
}
