// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Shared HTTP client for backend service connections.
//!
//! Provides a common reqwest-based async HTTP client that all panel backends
//! use to talk to external services (BoJ-server, VeriSimDB, ECHIDNA, etc.).
//! Centralises timeout, error handling, and connection pooling.

use serde::de::DeserializeOwned;
use std::time::Duration;

/// Default timeout for HTTP requests (10 seconds).
const DEFAULT_TIMEOUT_SECS: u64 = 10;

/// Service endpoint configuration.
///
/// Wraps a base URL and request timeout for a single backend service.
/// Use [`ServiceEndpoint::new`] for defaults or chain [`ServiceEndpoint::with_timeout`]
/// to customise the deadline per-service.
pub struct ServiceEndpoint {
    /// Base URL of the service, without trailing slash.
    pub base_url: String,
    /// Per-request timeout applied to every call through this endpoint.
    pub timeout: Duration,
}

impl ServiceEndpoint {
    /// Create a new endpoint with the default 10-second timeout.
    ///
    /// Trailing slashes are stripped from `base_url` to prevent double-slash
    /// issues when paths are appended.
    pub fn new(base_url: &str) -> Self {
        Self {
            base_url: base_url.trim_end_matches('/').to_string(),
            timeout: Duration::from_secs(DEFAULT_TIMEOUT_SECS),
        }
    }

    /// Override the default timeout (builder pattern).
    pub fn with_timeout(mut self, secs: u64) -> Self {
        self.timeout = Duration::from_secs(secs);
        self
    }
}

/// Make a GET request to a service endpoint and deserialise the JSON response.
///
/// # Errors
///
/// Returns a human-readable `String` error on:
/// - Client construction failure
/// - Network / timeout errors
/// - Non-2xx HTTP status codes
/// - JSON deserialisation mismatches
pub async fn get_json<T: DeserializeOwned>(
    endpoint: &ServiceEndpoint,
    path: &str,
) -> Result<T, String> {
    let url = format!("{}{}", endpoint.base_url, path);
    let client = reqwest::Client::builder()
        .timeout(endpoint.timeout)
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))?;

    let response = client
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("Request to {} failed: {}", url, e))?;

    if !response.status().is_success() {
        return Err(format!("HTTP {} from {}", response.status(), url));
    }

    response
        .json::<T>()
        .await
        .map_err(|e| format!("Failed to parse response from {}: {}", url, e))
}

/// Make a POST request with a JSON body and deserialise the JSON response.
///
/// # Errors
///
/// Same failure modes as [`get_json`], plus serialisation of `body` and
/// inclusion of the upstream response body in non-2xx error messages.
pub async fn post_json<B: serde::Serialize, T: DeserializeOwned>(
    endpoint: &ServiceEndpoint,
    path: &str,
    body: &B,
) -> Result<T, String> {
    let url = format!("{}{}", endpoint.base_url, path);
    let client = reqwest::Client::builder()
        .timeout(endpoint.timeout)
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))?;

    let response = client
        .post(&url)
        .json(body)
        .send()
        .await
        .map_err(|e| format!("Request to {} failed: {}", url, e))?;

    if !response.status().is_success() {
        let status = response.status();
        let body_text = response.text().await.unwrap_or_default();
        return Err(format!("HTTP {} from {}: {}", status, url, body_text));
    }

    response
        .json::<T>()
        .await
        .map_err(|e| format!("Failed to parse response from {}: {}", url, e))
}

/// Make a GET request and return the raw response body as a String.
///
/// Useful when the caller wants to forward the raw JSON to the frontend
/// without deserialising into a specific Rust type.
pub async fn get_raw(
    endpoint: &ServiceEndpoint,
    path: &str,
) -> Result<String, String> {
    let url = format!("{}{}", endpoint.base_url, path);
    let client = reqwest::Client::builder()
        .timeout(endpoint.timeout)
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))?;

    let response = client
        .get(&url)
        .send()
        .await
        .map_err(|e| format!("Request to {} failed: {}", url, e))?;

    if !response.status().is_success() {
        return Err(format!("HTTP {} from {}", response.status(), url));
    }

    response
        .text()
        .await
        .map_err(|e| format!("Failed to read response from {}: {}", url, e))
}

/// Make a POST request with a JSON body and return the raw response body.
///
/// Like [`post_json`] but returns the raw response text instead of
/// deserialising into a specific type.
pub async fn post_json_raw<B: serde::Serialize>(
    endpoint: &ServiceEndpoint,
    path: &str,
    body: &B,
) -> Result<String, String> {
    let url = format!("{}{}", endpoint.base_url, path);
    let client = reqwest::Client::builder()
        .timeout(endpoint.timeout)
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))?;

    let response = client
        .post(&url)
        .json(body)
        .send()
        .await
        .map_err(|e| format!("Request to {} failed: {}", url, e))?;

    if !response.status().is_success() {
        let status = response.status();
        let body_text = response.text().await.unwrap_or_default();
        return Err(format!("HTTP {} from {}: {}", status, url, body_text));
    }

    response
        .text()
        .await
        .map_err(|e| format!("Failed to read response from {}: {}", url, e))
}

/// Check if a service is reachable (simple health probe).
///
/// Uses a short 5-second timeout regardless of the endpoint's configured
/// timeout — health checks should be fast or not at all.
///
/// Returns `Ok(true)` if the endpoint responds with 2xx, `Ok(false)` if
/// the request fails or returns a non-success status.
pub async fn check_health(
    endpoint: &ServiceEndpoint,
    health_path: &str,
) -> Result<bool, String> {
    let url = format!("{}{}", endpoint.base_url, health_path);
    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(5))
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))?;

    match client.get(&url).send().await {
        Ok(resp) => Ok(resp.status().is_success()),
        Err(_) => Ok(false),
    }
}
