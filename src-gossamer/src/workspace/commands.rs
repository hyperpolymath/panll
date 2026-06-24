// SPDX-License-Identifier: MPL-2.0

//! Workspace Tauri commands — save/load arrangements and sessions.
//!
//! Arrangements and sessions are persisted as JSON files in the PanLL
//! config directory (~/.config/panll/). This keeps workspace state
//! independent of any loaded repo.

use std::fs;
use std::path::PathBuf;

use super::types::{Arrangement, Session};

/// Get the PanLL config directory, creating it if it doesn't exist.
fn config_dir() -> Result<PathBuf, String> {
    let base = dirs::config_dir()
        .ok_or_else(|| "Cannot determine config directory".to_string())?;
    let panll_dir = base.join("panll");
    fs::create_dir_all(&panll_dir)
        .map_err(|e| format!("Cannot create config dir: {e}"))?;
    Ok(panll_dir)
}

/// Save an arrangement to disk as JSON.

pub async fn save_arrangement(arrangement: Arrangement) -> Result<String, String> {
    let dir = config_dir()?.join("arrangements");
    fs::create_dir_all(&dir)
        .map_err(|e| format!("Cannot create arrangements dir: {e}"))?;

    let path = dir.join(format!("{}.json", arrangement.id));
    let json = serde_json::to_string_pretty(&arrangement)
        .map_err(|e| format!("Serialisation error: {e}"))?;

    fs::write(&path, &json)
        .map_err(|e| format!("Write error: {e}"))?;

    Ok(format!("Arrangement '{}' saved to {}", arrangement.name, path.display()))
}

/// Load all saved arrangements from disk.

pub async fn load_arrangements() -> Result<String, String> {
    let dir = config_dir()?.join("arrangements");
    if !dir.exists() {
        return Ok("[]".to_string());
    }

    let mut arrangements: Vec<Arrangement> = Vec::new();
    let entries = fs::read_dir(&dir)
        .map_err(|e| format!("Cannot read arrangements dir: {e}"))?;

    for entry in entries {
        let entry = entry.map_err(|e| format!("Dir entry error: {e}"))?;
        let path = entry.path();
        if path.extension().and_then(|e| e.to_str()) == Some("json") {
            let content = fs::read_to_string(&path)
                .map_err(|e| format!("Read error for {}: {e}", path.display()))?;
            match serde_json::from_str::<Arrangement>(&content) {
                Ok(arr) => arrangements.push(arr),
                Err(e) => eprintln!("Warning: skipping invalid arrangement {}: {e}", path.display()),
            }
        }
    }

    serde_json::to_string(&arrangements)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Delete an arrangement file from disk.

pub async fn delete_arrangement(arrangement_id: String) -> Result<String, String> {
    let path = config_dir()?.join("arrangements").join(format!("{arrangement_id}.json"));
    if path.exists() {
        fs::remove_file(&path)
            .map_err(|e| format!("Delete error: {e}"))?;
        Ok(format!("Arrangement '{arrangement_id}' deleted"))
    } else {
        Err(format!("Arrangement '{arrangement_id}' not found"))
    }
}

/// Save a session to disk as JSON.

pub async fn save_session(session: Session) -> Result<String, String> {
    let dir = config_dir()?.join("sessions");
    fs::create_dir_all(&dir)
        .map_err(|e| format!("Cannot create sessions dir: {e}"))?;

    let path = dir.join(format!("{}.json", session.id));
    let json = serde_json::to_string_pretty(&session)
        .map_err(|e| format!("Serialisation error: {e}"))?;

    fs::write(&path, &json)
        .map_err(|e| format!("Write error: {e}"))?;

    Ok(format!("Session '{}' saved to {}", session.name, path.display()))
}

/// Load all saved sessions from disk.

pub async fn load_sessions() -> Result<String, String> {
    let dir = config_dir()?.join("sessions");
    if !dir.exists() {
        return Ok("[]".to_string());
    }

    let mut sessions: Vec<Session> = Vec::new();
    let entries = fs::read_dir(&dir)
        .map_err(|e| format!("Cannot read sessions dir: {e}"))?;

    for entry in entries {
        let entry = entry.map_err(|e| format!("Dir entry error: {e}"))?;
        let path = entry.path();
        if path.extension().and_then(|e| e.to_str()) == Some("json") {
            let content = fs::read_to_string(&path)
                .map_err(|e| format!("Read error for {}: {e}", path.display()))?;
            match serde_json::from_str::<Session>(&content) {
                Ok(sess) => sessions.push(sess),
                Err(e) => eprintln!("Warning: skipping invalid session {}: {e}", path.display()),
            }
        }
    }

    serde_json::to_string(&sessions)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Delete a session file from disk.

pub async fn delete_session(session_id: String) -> Result<String, String> {
    let path = config_dir()?.join("sessions").join(format!("{session_id}.json"));
    if path.exists() {
        fs::remove_file(&path)
            .map_err(|e| format!("Delete error: {e}"))?;
        Ok(format!("Session '{session_id}' deleted"))
    } else {
        Err(format!("Session '{session_id}' not found"))
    }
}
