// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Identity — Named identity snapshots for PanLL Connected Workbench.
//!
//! Captures the full user configuration (panel state, settings, service URLs)
//! as a named snapshot that can be restored or broadcast to team members.
//!
//! Storage hierarchy:
//!   1. VeriSimDB (primary) — `POST /api/identity`
//!   2. `~/.panll/identities/` (fallback) — JSON files
//!
//! Part of Connected Workbench v0.2.0.

use serde::{Deserialize, Serialize};
use serde_json::json;
use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;

/// A named identity snapshot.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IdentitySnapshot {
    /// Unique snapshot identifier (UUID v4).
    pub id: String,
    /// Human-readable snapshot name.
    pub name: String,
    /// ISO 8601 creation timestamp.
    pub created_at: String,
    /// Panel state JSON (from Storage.serialize()).
    pub panll_state: String,
    /// Settings JSON (from settings_get()).
    pub settings: String,
    /// Service registry JSON (from service_registry_get()).
    pub service_urls: String,
}

/// Compact snapshot metadata (for listing without full payloads).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SnapshotMeta {
    pub id: String,
    pub name: String,
    pub created_at: String,
}

/// Directory for identity snapshot storage: `~/.panll/identities/`.
fn identities_dir() -> PathBuf {
    dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join(".panll")
        .join("identities")
}

/// Ensure the identities directory exists.
fn ensure_identities_dir() -> Result<(), String> {
    let dir = identities_dir();
    if !dir.exists() {
        fs::create_dir_all(&dir)
            .map_err(|e| format!("Failed to create identities dir: {}", e))?;
    }
    Ok(())
}

/// ISO 8601 timestamp for the current time.
fn iso_now() -> String {
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    // Simple ISO format — sufficient for sorting and display
    format!("{}Z", secs)
}

/// Save a new identity snapshot.
///
/// Primary storage: VeriSimDB (POST /api/identity).
/// Fallback: `~/.panll/identities/<id>.json`.
/// Returns the full snapshot as JSON.
pub fn identity_save(name: &str, panll_state: &str, settings: &str, service_urls: &str) -> Result<String, String> {
    ensure_identities_dir()?;

    let snapshot = IdentitySnapshot {
        id: Uuid::new_v4().to_string(),
        name: name.to_string(),
        created_at: iso_now(),
        panll_state: panll_state.to_string(),
        settings: settings.to_string(),
        service_urls: service_urls.to_string(),
    };

    let json = serde_json::to_string_pretty(&snapshot)
        .map_err(|e| format!("JSON serialise error: {}", e))?;

    // Primary: VeriSimDB
    let verisim_url = std::env::var("VERISIMDB_URL")
        .unwrap_or_else(|_| "http://localhost:8080/api/v1".into());
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    let url = format!("{}/state/{}", verisim_url.trim_end_matches('/'), snapshot.id);
    match client.post(&url).json(&json!({"state": json})).send() {
        Ok(resp) => {
            if !resp.status().is_success() {
                // Fallback to filesystem
                let path = identities_dir().join(format!("{}.json", snapshot.id));
                fs::write(&path, &json)
                    .map_err(|e| format!("Failed to write snapshot: {}", e))?;
            }
        }
        Err(_) => {
            // Fallback to filesystem
            let path = identities_dir().join(format!("{}.json", snapshot.id));
            fs::write(&path, &json)
                .map_err(|e| format!("Failed to write snapshot: {}", e))?;
        }
    }

    Ok(json)
}

/// Load an identity snapshot by ID.
///
/// Primary source: VeriSimDB (GET /state/<id>).
/// Fallback: `~/.panll/identities/<id>.json`.
pub fn identity_load(id: &str) -> Result<String, String> {
    // Primary: VeriSimDB
    let verisim_url = std::env::var("VERISIMDB_URL")
        .unwrap_or_else(|_| "http://localhost:8080/api/v1".into());
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    let url = format!("{}/state/{}", verisim_url.trim_end_matches('/'), id);
    match client.get(&url).send() {
        Ok(resp) => {
            if resp.status().is_success() {
                return resp.text().map_err(|e| format!("Failed to read response: {}", e));
            }
        }
        Err(_) => {}
    }

    // Fallback to filesystem
    let path = identities_dir().join(format!("{}.json", id));
    fs::read_to_string(&path)
        .map_err(|e| format!("Snapshot not found: {}", e))
}

/// List all identity snapshots (metadata only).
pub fn identity_list() -> Result<String, String> {
    ensure_identities_dir()?;

    let dir = identities_dir();
    let mut metas: Vec<SnapshotMeta> = Vec::new();

    let entries = fs::read_dir(&dir)
        .map_err(|e| format!("Failed to read identities dir: {}", e))?;

    for entry in entries.flatten() {
        let path = entry.path();
        if path.extension().map(|e| e == "json").unwrap_or(false) {
            if let Ok(contents) = fs::read_to_string(&path) {
                if let Ok(snapshot) = serde_json::from_str::<IdentitySnapshot>(&contents) {
                    metas.push(SnapshotMeta {
                        id: snapshot.id,
                        name: snapshot.name,
                        created_at: snapshot.created_at,
                    });
                }
            }
        }
    }

    // Sort by creation time (newest first)
    metas.sort_by(|a, b| b.created_at.cmp(&a.created_at));

    serde_json::to_string(&metas).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Delete an identity snapshot by ID.
pub fn identity_delete(id: &str) -> Result<String, String> {
    let path = identities_dir().join(format!("{}.json", id));
    if path.exists() {
        fs::remove_file(&path)
            .map_err(|e| format!("Failed to delete snapshot: {}", e))?;
        Ok(format!("{{\"deleted\":\"{}\"}}", id))
    } else {
        Err(format!("Snapshot not found: {}", id))
    }
}

// =========================================================================
// Team Replication (Phase 5)
// =========================================================================

/// Broadcast an identity snapshot to team members via Burble.
///
/// POST to the Burble server's broadcast endpoint. Team members receive
/// the snapshot and can choose to apply it.
pub fn team_broadcast_state(snapshot_json: &str) -> Result<String, String> {
    let burble_url = std::env::var("BURBLE_URL")
        .unwrap_or_else(|_| "http://localhost:6473".into());
    let url = format!("{}/api/v1/broadcast", burble_url.trim_end_matches('/'));

    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    let payload = serde_json::json!({
        "type": "identity_snapshot",
        "payload": snapshot_json
    });

    match client.post(&url).json(&payload).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Broadcast failed: HTTP {} — {}", status, body))
            }
        }
        Err(e) => Err(format!("Broadcast request failed: {}", e)),
    }
}
