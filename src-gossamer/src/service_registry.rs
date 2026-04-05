// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Service Registry — Centralized lifecycle management for PanLL backend services.
//!
//! Tracks connection state, URLs, and health for all backend services that PanLL
//! panels communicate with. The registry is initialised from environment variables
//! at startup and can be reconfigured at runtime via the Settings panel.
//!
//! Services tracked:
//! - VeriSimDB (default localhost:8080) — 8-modality versioned database
//! - ECHIDNA (default localhost:9000) — theorem prover dispatch
//! - Burble (default localhost:6473) — voice huddle server
//! - BoJ (default localhost:7700) — cartridge server and protocol gateway
//! - TypeLL (default localhost:7800) — type verification kernel

use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Mutex;

use crate::http_client;

/// Current status of a backend service.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "status")]
pub enum ServiceStatus {
    /// Service responded to health check with 2xx.
    Running,
    /// Service has not been checked or was explicitly stopped.
    Stopped,
    /// Health check is currently in flight.
    Checking,
    /// Service returned an error or is unreachable.
    Error { message: String },
}

/// A registered backend service.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServiceEntry {
    /// Human-readable service name (e.g. "VeriSimDB").
    pub name: String,
    /// Base URL including protocol and port (e.g. "http://localhost:8080").
    pub url: String,
    /// Path to probe for health (e.g. "/health").
    pub health_path: String,
    /// Current connection status.
    pub status: ServiceStatus,
}

/// Global service registry, initialised from environment variables.
///
/// Access via `REGISTRY.lock()`. Each entry is keyed by a short identifier
/// (e.g. "verisim", "echidna") matching the IPC command namespace.
static REGISTRY: Lazy<Mutex<HashMap<String, ServiceEntry>>> = Lazy::new(|| {
    let mut map = HashMap::new();

    map.insert(
        "verisim".into(),
        ServiceEntry {
            name: "VeriSimDB".into(),
            url: std::env::var("VERISIMDB_URL")
                .unwrap_or_else(|_| "http://localhost:8080".into()),
            health_path: "/health".into(),
            status: ServiceStatus::Stopped,
        },
    );

    map.insert(
        "echidna".into(),
        ServiceEntry {
            name: "ECHIDNA".into(),
            url: std::env::var("ECHIDNA_URL")
                .unwrap_or_else(|_| "http://localhost:9000".into()),
            health_path: "/health".into(),
            status: ServiceStatus::Stopped,
        },
    );

    map.insert(
        "burble".into(),
        ServiceEntry {
            name: "Burble".into(),
            url: std::env::var("BURBLE_URL")
                .unwrap_or_else(|_| "http://localhost:6473".into()),
            health_path: "/health".into(),
            status: ServiceStatus::Stopped,
        },
    );

    map.insert(
        "boj".into(),
        ServiceEntry {
            name: "BoJ Server".into(),
            url: std::env::var("BOJ_URL")
                .unwrap_or_else(|_| "http://localhost:7700".into()),
            health_path: "/health".into(),
            status: ServiceStatus::Stopped,
        },
    );

    map.insert(
        "typell".into(),
        ServiceEntry {
            name: "TypeLL".into(),
            url: std::env::var("TYPELL_URL")
                .unwrap_or_else(|_| "http://localhost:7800".into()),
            health_path: "/health".into(),
            status: ServiceStatus::Stopped,
        },
    );

    Mutex::new(map)
});

/// Check health of all registered services and update their status.
///
/// Probes each service endpoint in sequence (5-second timeout per service
/// via `http_client::check_health`). Returns the full registry as JSON.
pub fn check_all_services() -> Result<String, String> {
    let mut reg = REGISTRY.lock().map_err(|e| format!("Registry lock: {}", e))?;

    for (_key, entry) in reg.iter_mut() {
        let endpoint = http_client::ServiceEndpoint::new(&entry.url);
        // Use blocking reqwest since Gossamer command handlers are synchronous
        let client = reqwest::blocking::Client::builder()
            .timeout(std::time::Duration::from_secs(5))
            .build()
            .map_err(|e| format!("HTTP client error: {}", e))?;

        let url = format!("{}{}", endpoint.base_url, entry.health_path);
        entry.status = match client.get(&url).send() {
            Ok(resp) if resp.status().is_success() => ServiceStatus::Running,
            Ok(resp) => ServiceStatus::Error {
                message: format!("HTTP {}", resp.status()),
            },
            Err(e) => ServiceStatus::Error {
                message: format!("{}", e),
            },
        };
    }

    let snapshot: HashMap<String, ServiceEntry> = reg.clone();
    serde_json::to_string(&snapshot).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Check health of a single service by key and update its status.
///
/// Returns the updated entry as JSON, or an error if the key is unknown.
pub fn check_service(service_key: &str) -> Result<String, String> {
    let mut reg = REGISTRY.lock().map_err(|e| format!("Registry lock: {}", e))?;

    let entry = reg
        .get_mut(service_key)
        .ok_or_else(|| format!("Unknown service: {}", service_key))?;

    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    let url = format!("{}{}", entry.url.trim_end_matches('/'), entry.health_path);
    entry.status = match client.get(&url).send() {
        Ok(resp) if resp.status().is_success() => ServiceStatus::Running,
        Ok(resp) => ServiceStatus::Error {
            message: format!("HTTP {}", resp.status()),
        },
        Err(e) => ServiceStatus::Error {
            message: format!("{}", e),
        },
    };

    serde_json::to_string(entry).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Update the URL of a registered service.
///
/// Resets the service status to `Stopped` after URL change (requires re-check).
pub fn update_service_url(service_key: &str, new_url: &str) -> Result<String, String> {
    let mut reg = REGISTRY.lock().map_err(|e| format!("Registry lock: {}", e))?;

    let entry = reg
        .get_mut(service_key)
        .ok_or_else(|| format!("Unknown service: {}", service_key))?;

    entry.url = new_url.trim_end_matches('/').to_string();
    entry.status = ServiceStatus::Stopped;

    serde_json::to_string(entry).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Get the full registry as JSON.
pub fn get_registry() -> Result<String, String> {
    let reg = REGISTRY.lock().map_err(|e| format!("Registry lock: {}", e))?;
    let snapshot: HashMap<String, ServiceEntry> = reg.clone();
    serde_json::to_string(&snapshot).map_err(|e| format!("JSON serialise error: {}", e))
}
