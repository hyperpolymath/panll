// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Live ECHIDNA theorem prover connection module (async).
//!
//! Connects to the ECHIDNA prover REST API at localhost:9000 for
//! tactic selection, proof obligation dispatch, and prover health
//! monitoring.
//!
//! ECHIDNA uses a multi-prover architecture where tactics are selected
//! based on obligation shape and historical win rates. This module
//! exposes that functionality to PanLL panels.

use crate::http_client::{self, ServiceEndpoint};
use serde::{Deserialize, Serialize};
use serde_json::json;

// panic-attack:allow insecure-protocol — localhost dev endpoint
/// Default ECHIDNA base URL.
const DEFAULT_ECHIDNA_URL: &str = "http://localhost:9000";

/// Build the ECHIDNA endpoint, respecting the `ECHIDNA_URL`
/// environment variable if set.
fn echidna_endpoint() -> ServiceEndpoint {
    let url = std::env::var("ECHIDNA_URL").unwrap_or_else(|_| DEFAULT_ECHIDNA_URL.to_string());
    ServiceEndpoint::new(&url)
}

/// ECHIDNA health check response.
#[derive(Debug, Deserialize, Serialize)]
pub struct EchidnaHealth {
    /// Top-level status (e.g. "ok", "busy", "error").
    pub status: String,
    /// Number of available prover backends.
    pub prover_count: Option<usize>,
    /// Number of pending obligations in the queue.
    pub pending_obligations: Option<usize>,
    /// Human-readable uptime.
    pub uptime: Option<String>,
}

/// Tactic recommendation from ECHIDNA.
#[derive(Debug, Deserialize, Serialize)]
pub struct TacticRecommendation {
    /// Recommended tactic name.
    pub tactic: String,
    /// Confidence score (0.0 to 1.0).
    pub confidence: f64,
    /// Historical win rate for this tactic on similar obligations.
    pub win_rate: f64,
    /// Prover backend that would execute this tactic.
    pub prover: String,
}

/// Proof result from ECHIDNA.
#[derive(Debug, Deserialize, Serialize)]
pub struct ProofResult {
    /// Whether the obligation was discharged.
    pub discharged: bool,
    /// Tactic that succeeded (if any).
    pub winning_tactic: Option<String>,
    /// Time taken in milliseconds.
    pub elapsed_ms: f64,
    /// Proof certificate (if discharged).
    pub certificate: Option<String>,
}

/// Check ECHIDNA health (async).
///
/// `GET /health` — returns the prover health envelope.
#[tauri::command]
pub async fn echidna_live_health() -> Result<String, String> {
    let endpoint = echidna_endpoint();
    let health: EchidnaHealth = http_client::get_json(&endpoint, "/health").await?;
    serde_json::to_string(&health).map_err(|e| format!("JSON serialise error: {}", e))
}

/// Get tactic recommendations for an obligation (async).
///
/// `POST /api/tactics/recommend` — given an obligation shape, returns
/// ranked tactic recommendations with confidence scores.
#[tauri::command]
pub async fn echidna_live_recommend_tactics(obligation: String) -> Result<String, String> {
    let endpoint = echidna_endpoint();
    let body = json!({ "obligation": obligation });
    http_client::post_json_raw(&endpoint, "/api/tactics/recommend", &body).await
}

/// Submit a proof obligation to ECHIDNA (async).
///
/// `POST /api/obligations/submit` — queues an obligation for the
/// prover pool to attempt. Returns a tracking ID.
#[tauri::command]
pub async fn echidna_live_submit_obligation(obligation: String) -> Result<String, String> {
    let endpoint = echidna_endpoint();
    let body = json!({ "obligation": obligation });
    http_client::post_json_raw(&endpoint, "/api/obligations/submit", &body).await
}

/// Get the status/result of a submitted obligation (async).
///
/// `GET /api/obligations/:id` — returns the proof result if complete.
#[tauri::command]
pub async fn echidna_live_get_result(obligation_id: String) -> Result<String, String> {
    let endpoint = echidna_endpoint();
    let path = format!("/api/obligations/{}", obligation_id);
    http_client::get_raw(&endpoint, &path).await
}

/// Get prover statistics — win rates, queue depth, load (async).
///
/// `GET /api/stats` — aggregate prover performance metrics.
#[tauri::command]
pub async fn echidna_live_stats() -> Result<String, String> {
    let endpoint = echidna_endpoint();
    http_client::get_raw(&endpoint, "/api/stats").await
}
