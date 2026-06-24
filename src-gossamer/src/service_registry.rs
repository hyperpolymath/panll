// SPDX-License-Identifier: MPL-2.0
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
/// Probes each service endpoint via `http_client::blocking` (5-second timeout).
/// Returns the full registry as a JSON Value.
pub fn check_all_services() -> Result<serde_json::Value, String> {
    let mut reg = REGISTRY.lock().map_err(|e| format!("Registry lock: {}", e))?;

    for (_key, entry) in reg.iter_mut() {
        let endpoint = http_client::ServiceEndpoint::new(&entry.url).with_timeout(5);
        entry.status = match http_client::blocking::get_raw(&endpoint, &entry.health_path) {
            Ok(_) => ServiceStatus::Running,
            Err(msg) => ServiceStatus::Error { message: msg },
        };
    }

    let snapshot: HashMap<String, ServiceEntry> = reg.clone();
    serde_json::to_value(&snapshot).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Check health of a single service by key and update its status.
///
/// Returns the updated entry as a JSON Value, or an error if the key is unknown.
pub fn check_service(service_key: &str) -> Result<serde_json::Value, String> {
    let mut reg = REGISTRY.lock().map_err(|e| format!("Registry lock: {}", e))?;

    let entry = reg
        .get_mut(service_key)
        .ok_or_else(|| format!("Unknown service: {}", service_key))?;

    let endpoint = http_client::ServiceEndpoint::new(&entry.url).with_timeout(5);
    entry.status = match http_client::blocking::get_raw(&endpoint, &entry.health_path) {
        Ok(_) => ServiceStatus::Running,
        Err(msg) => ServiceStatus::Error { message: msg },
    };

    serde_json::to_value(entry.clone()).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Update the URL of a registered service.
///
/// Resets the service status to `Stopped` after URL change (requires re-check).
pub fn update_service_url(service_key: &str, new_url: &str) -> Result<serde_json::Value, String> {
    let mut reg = REGISTRY.lock().map_err(|e| format!("Registry lock: {}", e))?;

    let entry = reg
        .get_mut(service_key)
        .ok_or_else(|| format!("Unknown service: {}", service_key))?;

    entry.url = new_url.trim_end_matches('/').to_string();
    entry.status = ServiceStatus::Stopped;

    serde_json::to_value(entry.clone()).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Get the full registry as a JSON Value.
pub fn get_registry() -> Result<serde_json::Value, String> {
    let reg = REGISTRY.lock().map_err(|e| format!("Registry lock: {}", e))?;
    let snapshot: HashMap<String, ServiceEntry> = reg.clone();
    serde_json::to_value(&snapshot).map_err(|e| format!("JSON serialise error: {}", e))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn registry_contains_all_known_services() {
        let json = get_registry().expect("get_registry should succeed");
        let obj = json.as_object().expect("registry should be a JSON object");
        for key in ["verisim", "echidna", "burble", "boj", "typell"] {
            assert!(obj.contains_key(key), "registry missing service '{}'", key);
        }
    }

    #[test]
    fn check_service_unknown_key_errors() {
        let err = check_service("does-not-exist").unwrap_err();
        assert!(err.contains("Unknown service"), "got: {}", err);
    }

    #[test]
    fn update_service_url_unknown_key_errors() {
        let err = update_service_url("does-not-exist", "http://x").unwrap_err();
        assert!(err.contains("Unknown service"), "got: {}", err);
    }

    #[test]
    fn update_service_url_sets_url_and_resets_status() {
        // Assert on the returned entry (not a shared global re-read) so the
        // test is robust under parallel execution.
        let updated =
            update_service_url("typell", "http://example.test:9999/").expect("update ok");
        assert_eq!(updated["url"], "http://example.test:9999");
        // Status resets to Stopped after a URL change. ServiceStatus is
        // `#[serde(tag = "status")]`, so the unit variant serialises as the
        // nested object {"status":"Stopped"}.
        assert_eq!(updated["status"]["status"], "Stopped");
    }
}
