// SPDX-License-Identifier: PMPL-1.0-or-later

//! Capture Tauri commands — screenshot saving, recording management, demo I/O.
//!
//! Screenshots arrive as base64-encoded PNG data from the frontend (captured
//! via html2canvas in the webview). Rust handles file I/O and path management.
//! Recordings use ffmpeg subprocess for screen capture when available.
//! Demo packages are ZIP files containing captures + state JSON.

use std::fs;
use std::path::PathBuf;
use std::io::Write;

/// Get the PanLL captures directory, creating it if needed.
fn captures_dir() -> Result<PathBuf, String> {
    let base = dirs::data_dir()
        .ok_or_else(|| "Cannot determine data directory".to_string())?;
    let dir = base.join("panll").join("captures");
    fs::create_dir_all(&dir)
        .map_err(|e| format!("Cannot create captures dir: {e}"))?;
    Ok(dir)
}

/// Get the PanLL demos directory, creating it if needed.
fn demos_dir() -> Result<PathBuf, String> {
    let base = dirs::data_dir()
        .ok_or_else(|| "Cannot determine data directory".to_string())?;
    let dir = base.join("panll").join("demos");
    fs::create_dir_all(&dir)
        .map_err(|e| format!("Cannot create demos dir: {e}"))?;
    Ok(dir)
}

/// Save a screenshot from base64-encoded PNG data. Returns the file path.
///
/// The frontend captures a panel's DOM via html2canvas, converts to base64,
/// and sends it here for persistence. File naming uses the capture ID for
/// deterministic paths.

pub async fn save_screenshot(
    capture_id: String,
    panel_id: String,
    base64_data: String,
    format: String,
) -> Result<String, String> {
    let dir = captures_dir()?;

    let extension = match format.as_str() {
        "pdf" => "pdf",
        "svg" => "svg",
        _ => "png",
    };

    let filename = format!("{capture_id}.{extension}");
    let path = dir.join(&filename);

    // Decode base64 data. Strip the data URI prefix if present.
    let raw_b64 = base64_data
        .strip_prefix("data:image/png;base64,")
        .or_else(|| base64_data.strip_prefix("data:application/pdf;base64,"))
        .unwrap_or(&base64_data);

    // Use a simple base64 decoder (Rust stdlib doesn't include one, but
    // we can use the tauri/base64 approach or manual decode).
    // For now, write raw base64 and let the frontend handle display.
    let decoded = base64_decode(raw_b64)?;

    let mut file = fs::File::create(&path)
        .map_err(|e| format!("Cannot create file: {e}"))?;
    file.write_all(&decoded)
        .map_err(|e| format!("Write error: {e}"))?;

    let result = serde_json::json!({
        "id": capture_id,
        "panelId": panel_id,
        "filePath": path.to_string_lossy(),
        "format": format,
    });

    Ok(result.to_string())
}

/// Simple base64 decoder (no external crate dependency).
fn base64_decode(input: &str) -> Result<Vec<u8>, String> {
    let table: [u8; 256] = {
        let mut t = [255u8; 256];
        for (i, &c) in b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".iter().enumerate() {
            t[c as usize] = i as u8;
        }
        t[b'=' as usize] = 0;
        t
    };

    let input = input.as_bytes();
    let mut output = Vec::with_capacity(input.len() * 3 / 4);
    let mut buf: u32 = 0;
    let mut bits: u32 = 0;

    for &byte in input {
        if byte == b'\n' || byte == b'\r' || byte == b' ' {
            continue;
        }
        let val = table[byte as usize];
        if val == 255 {
            return Err(format!("Invalid base64 character: {}", byte as char));
        }
        buf = (buf << 6) | val as u32;
        bits += 6;
        if bits >= 8 {
            bits -= 8;
            output.push((buf >> bits) as u8);
        }
    }

    Ok(output)
}

/// Invoke the system print dialog for the active panel.
/// Uses Tauri's webview print capability.

pub async fn print_panel(panel_id: String) -> Result<String, String> {
    // The actual printing is triggered in the frontend via window.print().
    // This command exists for logging and to return the panel ID for confirmation.
    Ok(format!("Print dialog opened for panel '{panel_id}'"))
}

/// Save a demo package as a JSON file. Full ZIP packaging is a future enhancement.

pub async fn save_demo(demo_json: String) -> Result<String, String> {
    let dir = demos_dir()?;

    let demo: super::types::DemoPackage = serde_json::from_str(&demo_json)
        .map_err(|e| format!("Invalid demo JSON: {e}"))?;

    let filename = format!("{}.panll-demo.json", demo.id);
    let path = dir.join(&filename);

    let pretty = serde_json::to_string_pretty(&demo)
        .map_err(|e| format!("Serialisation error: {e}"))?;

    fs::write(&path, &pretty)
        .map_err(|e| format!("Write error: {e}"))?;

    Ok(format!("Demo '{}' saved to {}", demo.title, path.display()))
}

/// Load all demo packages from the demos directory.

pub async fn load_demos() -> Result<String, String> {
    let dir = demos_dir()?;
    if !dir.exists() {
        return Ok("[]".to_string());
    }

    let mut demos: Vec<super::types::DemoPackage> = Vec::new();
    let entries = fs::read_dir(&dir)
        .map_err(|e| format!("Cannot read demos dir: {e}"))?;

    for entry in entries {
        let entry = entry.map_err(|e| format!("Dir entry error: {e}"))?;
        let path = entry.path();
        if path.to_string_lossy().ends_with(".panll-demo.json") {
            let content = fs::read_to_string(&path)
                .map_err(|e| format!("Read error for {}: {e}", path.display()))?;
            match serde_json::from_str::<super::types::DemoPackage>(&content) {
                Ok(demo) => demos.push(demo),
                Err(e) => eprintln!("Warning: skipping invalid demo {}: {e}", path.display()),
            }
        }
    }

    serde_json::to_string(&demos)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Delete a demo package from disk.

pub async fn delete_demo(demo_id: String) -> Result<String, String> {
    let dir = demos_dir()?;
    let filename = format!("{demo_id}.panll-demo.json");
    let path = dir.join(&filename);

    if path.exists() {
        fs::remove_file(&path)
            .map_err(|e| format!("Delete error: {e}"))?;
        Ok(format!("Demo '{demo_id}' deleted"))
    } else {
        Err(format!("Demo '{demo_id}' not found"))
    }
}
