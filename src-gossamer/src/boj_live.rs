// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Live BoJ-server connection module (async).
//!
//! Connects to the BoJ-server gateway at localhost:7700 for real
//! cartridge invocation, health checks, and topology queries.
//!
//! This module parallels `boj::commands` but uses async reqwest via the
//! shared [`http_client`] module instead of blocking calls. Panels that
//! need non-blocking BoJ access (v0.2.0+) should prefer these commands.

use crate::http_client::{self, ServiceEndpoint};
use serde::{Deserialize, Serialize};
use serde_json::json;

// panic-attack:allow insecure-protocol — localhost dev endpoint
/// Default BoJ-server base URL.
const DEFAULT_BOJ_URL: &str = "http://localhost:7700";

/// Build the BoJ endpoint, respecting the `BOJ_URL` environment variable
/// if set, otherwise falling back to [`DEFAULT_BOJ_URL`].
fn boj_endpoint() -> ServiceEndpoint {
    let url = std::env::var("BOJ_URL").unwrap_or_else(|_| DEFAULT_BOJ_URL.to_string());
    ServiceEndpoint::new(&url)
}

/// BoJ health check response shape.
///
/// Mirrors the JSON envelope returned by `GET /health` on the BoJ server.
/// Optional fields are absent when the server is freshly started or running
/// in minimal mode.
#[derive(Debug, Deserialize, Serialize)]
pub struct BojHealth {
    /// Top-level status string (e.g. "ok", "degraded").
    pub status: String,
    /// Semantic version of the running BoJ server.
    pub version: Option<String>,
    /// Number of loaded cartridges.
    pub cartridges: Option<usize>,
    /// Human-readable uptime (e.g. "2h 14m").
    pub uptime: Option<String>,
}

/// Check BoJ-server health (async).
///
/// `GET /health` — returns the full health envelope as a JSON string.

pub async fn boj_live_health() -> Result<String, String> {
    let endpoint = boj_endpoint();
    let health: BojHealth = http_client::get_json(&endpoint, "/health")
        .await
        .map_err(|e| format!("BoJ server unreachable: {}", e))?;
    serde_json::to_string(&health).map_err(|e| format!("Serialization failed: {}", e))
}

/// List available cartridges from BoJ-server (async).
///
/// `GET /cartridges` — returns the cartridge array as a JSON string.

pub async fn boj_live_cartridges() -> Result<String, String> {
    let endpoint = boj_endpoint();
    let cartridges: serde_json::Value = http_client::get_json(&endpoint, "/cartridges")
        .await
        .map_err(|e| format!("Failed to list cartridges: {}", e))?;
    serde_json::to_string(&cartridges).map_err(|e| format!("Serialization failed: {}", e))
}

/// Invoke a BoJ cartridge tool (async).
///
/// `POST /cartridges/{cartridge}/invoke` — sends `{"tool": ..., "args": ...}`
/// and returns the invocation result as a JSON string.

pub async fn boj_live_invoke(
    cartridge: String,
    tool: String,
    params: String,
) -> Result<String, String> {
    let endpoint = boj_endpoint();
    let parsed_params: serde_json::Value =
        serde_json::from_str(&params).unwrap_or(json!({}));
    let body = json!({
        "tool": tool,
        "args": parsed_params,
    });
    let result: serde_json::Value = http_client::post_json(
        &endpoint,
        &format!("/cartridges/{}/invoke", cartridge),
        &body,
    )
    .await
    .map_err(|e| format!("Cartridge invoke failed: {}", e))?;
    serde_json::to_string(&result).map_err(|e| format!("Serialization failed: {}", e))
}

/// Get BoJ topology / cartridge dependency graph (async).
///
/// `GET /topology` — returns the topology matrix as a JSON string.

pub async fn boj_live_topology() -> Result<String, String> {
    let endpoint = boj_endpoint();
    let topology: serde_json::Value = http_client::get_json(&endpoint, "/topology")
        .await
        .map_err(|e| format!("Failed to get topology: {}", e))?;
    serde_json::to_string(&topology).map_err(|e| format!("Serialization failed: {}", e))
}

/// Check if BoJ-server is reachable (async health probe).
///
/// Returns `{"reachable": bool, "endpoint": "..."}` as a JSON string.
/// Panels use this for connection-dot indicators in the panel bar.

pub async fn boj_live_check() -> Result<String, String> {
    let endpoint = boj_endpoint();
    let reachable = http_client::check_health(&endpoint, "/health").await?;
    let url = std::env::var("BOJ_URL").unwrap_or_else(|_| DEFAULT_BOJ_URL.to_string());
    Ok(json!({
        "reachable": reachable,
        "endpoint": url,
    })
    .to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Verify the endpoint builder respects BOJ_URL and strips trailing slashes.
    #[test]
    fn boj_endpoint_default_and_override() {
        std::env::remove_var("BOJ_URL");
        let ep = boj_endpoint();
        assert_eq!(ep.base_url, DEFAULT_BOJ_URL);

        std::env::set_var("BOJ_URL", "http://boj.local:9999/v2/");
        let ep2 = boj_endpoint();
        assert_eq!(ep2.base_url, "http://boj.local:9999/v2");
        std::env::remove_var("BOJ_URL");
    }
}
