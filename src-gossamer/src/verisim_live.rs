// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Live VeriSimDB connection module (async).
//!
//! Connects to VeriSimDB at localhost:8080 for proof-carrying data
//! operations: octad CRUD, VCL queries, proof verification, and
//! health monitoring.
//!
//! This module uses the shared [`http_client`] infrastructure for
//! consistent timeout handling and error reporting.

use crate::http_client::{self, ServiceEndpoint};
use serde::{Deserialize, Serialize};
use serde_json::json;

// panic-attack:allow insecure-protocol — localhost dev endpoint
/// Default VeriSimDB base URL.
const DEFAULT_VERISIMDB_URL: &str = "http://localhost:8080";

/// Build the VeriSimDB endpoint, respecting the `VERISIMDB_URL`
/// environment variable if set.
fn verisim_endpoint() -> ServiceEndpoint {
    let url =
        std::env::var("VERISIMDB_URL").unwrap_or_else(|_| DEFAULT_VERISIMDB_URL.to_string());
    ServiceEndpoint::new(&url)
}

/// VeriSimDB health check response.
#[derive(Debug, Deserialize, Serialize)]
pub struct VeriSimHealth {
    /// Top-level status (e.g. "ok", "degraded").
    pub status: String,
    /// Semantic version of the running VeriSimDB instance.
    pub version: Option<String>,
    /// Number of stored octads.
    pub octad_count: Option<usize>,
    /// Number of proof certificates.
    pub proof_count: Option<usize>,
}

/// VeriSimDB octad summary.
#[derive(Debug, Deserialize, Serialize)]
pub struct OctadSummary {
    /// Octad identifier.
    pub id: String,
    /// Display name.
    pub name: String,
    /// Number of modality entries.
    pub modality_count: usize,
    /// Whether the octad has a proof certificate.
    pub has_proof: bool,
}

/// Check VeriSimDB health (async).
///
/// `GET /health` — returns the full health envelope as a JSON string.

pub async fn verisim_live_health() -> Result<String, String> {
    let endpoint = verisim_endpoint();
    let health: VeriSimHealth = http_client::get_json(&endpoint, "/health").await?;
    serde_json::to_string(&health).map_err(|e| format!("JSON serialise error: {}", e))
}

/// List octads from VeriSimDB (async).
///
/// `GET /api/octads` — returns a JSON array of octad summaries.

pub async fn verisim_live_list_octads() -> Result<String, String> {
    let endpoint = verisim_endpoint();
    let octads: Vec<OctadSummary> = http_client::get_json(&endpoint, "/api/octads").await?;
    serde_json::to_string(&octads).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Execute a VCL query against VeriSimDB (async).
///
/// `POST /api/vcl` with a JSON body containing the query string.
/// Returns the query result as a JSON string.

pub async fn verisim_live_query(query: String) -> Result<String, String> {
    let endpoint = verisim_endpoint();
    let body = json!({ "query": query });
    http_client::post_json_raw(&endpoint, "/api/vcl", &body).await
}

/// Get a single octad by ID (async).
///
/// `GET /api/octads/:id` — returns the octad with all modalities.

pub async fn verisim_live_get_octad(id: String) -> Result<String, String> {
    let endpoint = verisim_endpoint();
    let path = format!("/api/octads/{}", id);
    http_client::get_raw(&endpoint, &path).await
}
