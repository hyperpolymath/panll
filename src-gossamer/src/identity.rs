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

use crate::http_client;
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
/// Returns the full snapshot as a JSON Value.
pub fn identity_save(name: &str, panll_state: &str, settings: &str, service_urls: &str) -> Result<serde_json::Value, String> {
    ensure_identities_dir()?;

    let snapshot = IdentitySnapshot {
        id: Uuid::new_v4().to_string(),
        name: name.to_string(),
        created_at: iso_now(),
        panll_state: panll_state.to_string(),
        settings: settings.to_string(),
        service_urls: service_urls.to_string(),
    };

    let json_str = serde_json::to_string_pretty(&snapshot)
        .map_err(|e| format!("JSON serialise error: {}", e))?;

    // Primary: VeriSimDB; fallback to filesystem on any error.
    let verisim_url = std::env::var("VERISIMDB_URL")
        .unwrap_or_else(|_| "http://localhost:8080/api/v1".into());
    let endpoint = http_client::ServiceEndpoint::new(&verisim_url);
    let path = format!("/state/{}", snapshot.id);
    if http_client::blocking::post_raw(&endpoint, &path, &json!({"state": json_str})).is_err() {
        let local_path = identities_dir().join(format!("{}.json", snapshot.id));
        fs::write(&local_path, &json_str)
            .map_err(|e| format!("Failed to write snapshot: {}", e))?;
    }

    serde_json::to_value(&snapshot).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Load an identity snapshot by ID.
///
/// Primary source: VeriSimDB (GET /state/<id>).
/// Fallback: `~/.panll/identities/<id>.json`.
pub fn identity_load(id: &str) -> Result<serde_json::Value, String> {
    let verisim_url = std::env::var("VERISIMDB_URL")
        .unwrap_or_else(|_| "http://localhost:8080/api/v1".into());
    let endpoint = http_client::ServiceEndpoint::new(&verisim_url);
    if let Ok(body) = http_client::blocking::get_raw(&endpoint, &format!("/state/{}", id)) {
        if let Ok(val) = serde_json::from_str::<serde_json::Value>(&body) {
            return Ok(val);
        }
    }

    let path = identities_dir().join(format!("{}.json", id));
    let contents = fs::read_to_string(&path)
        .map_err(|e| format!("Snapshot not found: {}", e))?;
    serde_json::from_str::<serde_json::Value>(&contents)
        .map_err(|e| format!("JSON parse error: {}", e))
}

/// List all identity snapshots (metadata only).
pub fn identity_list() -> Result<serde_json::Value, String> {
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

    serde_json::to_value(&metas).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Delete an identity snapshot by ID.
pub fn identity_delete(id: &str) -> Result<serde_json::Value, String> {
    let path = identities_dir().join(format!("{}.json", id));
    if path.exists() {
        fs::remove_file(&path)
            .map_err(|e| format!("Failed to delete snapshot: {}", e))?;
        Ok(json!({"deleted": id}))
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
pub fn team_broadcast_state(snapshot_json: &str) -> Result<serde_json::Value, String> {
    let burble_url = std::env::var("BURBLE_URL")
        .unwrap_or_else(|_| "http://localhost:6473".into());
    let endpoint = http_client::ServiceEndpoint::new(&burble_url);
    let body = json!({
        "type": "identity_snapshot",
        "payload": snapshot_json
    });
    let response = http_client::blocking::post_raw(&endpoint, "/api/v1/broadcast", &body)?;
    Ok(serde_json::from_str::<serde_json::Value>(&response)
        .unwrap_or_else(|_| json!({"response": response})))
}
