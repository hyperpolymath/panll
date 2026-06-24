// SPDX-License-Identifier: MPL-2.0
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

/// Blocking (synchronous) HTTP helpers for use in Gossamer command handlers.
///
/// Gossamer command closures are synchronous; the async functions above cannot
/// be used there. This module provides thin blocking wrappers around
/// `reqwest::blocking` that share the same `ServiceEndpoint` configuration.
pub mod blocking {
    use super::ServiceEndpoint;
    use serde::Serialize;
    use std::time::Duration;

    /// GET a service path and return the raw response body.
    pub fn get_raw(endpoint: &ServiceEndpoint, path: &str) -> Result<String, String> {
        let url = format!("{}{}", endpoint.base_url, path);
        let client = reqwest::blocking::Client::builder()
            .timeout(endpoint.timeout)
            .build()
            .map_err(|e| format!("Failed to create HTTP client: {}", e))?;
        let resp = client
            .get(&url)
            .send()
            .map_err(|e| format!("Request to {} failed: {}", url, e))?;
        if !resp.status().is_success() {
            return Err(format!("HTTP {} from {}", resp.status(), url));
        }
        resp.text()
            .map_err(|e| format!("Failed to read response from {}: {}", url, e))
    }

    /// POST a JSON body to a service path and return the raw response body.
    pub fn post_raw<B: Serialize>(
        endpoint: &ServiceEndpoint,
        path: &str,
        body: &B,
    ) -> Result<String, String> {
        let url = format!("{}{}", endpoint.base_url, path);
        let client = reqwest::blocking::Client::builder()
            .timeout(endpoint.timeout)
            .build()
            .map_err(|e| format!("Failed to create HTTP client: {}", e))?;
        let resp = client
            .post(&url)
            .json(body)
            .send()
            .map_err(|e| format!("Request to {} failed: {}", url, e))?;
        if !resp.status().is_success() {
            let status = resp.status();
            let body_text = resp.text().unwrap_or_default();
            return Err(format!("HTTP {} from {}: {}", status, url, body_text));
        }
        resp.text()
            .map_err(|e| format!("Failed to read response from {}: {}", url, e))
    }

    /// Probe a health endpoint; returns `true` on 2xx, `false` on any failure.
    ///
    /// Uses a fixed 5-second timeout — health probes should be fast.
    pub fn check_health(endpoint: &ServiceEndpoint, health_path: &str) -> bool {
        let url = format!("{}{}", endpoint.base_url, health_path);
        let client = match reqwest::blocking::Client::builder()
            .timeout(Duration::from_secs(5))
            .build()
        {
            Ok(c) => c,
            Err(_) => return false,
        };
        matches!(client.get(&url).send(), Ok(resp) if resp.status().is_success())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn endpoint_strips_trailing_slash() {
        let e = ServiceEndpoint::new("http://localhost:8080/");
        assert_eq!(e.base_url, "http://localhost:8080");
        // Multiple trailing slashes are all stripped.
        let e2 = ServiceEndpoint::new("http://localhost:8080///");
        assert_eq!(e2.base_url, "http://localhost:8080");
    }

    #[test]
    fn endpoint_preserves_path_without_trailing_slash() {
        let e = ServiceEndpoint::new("http://localhost:8080/api");
        assert_eq!(e.base_url, "http://localhost:8080/api");
    }

    #[test]
    fn endpoint_default_timeout_is_ten_seconds() {
        let e = ServiceEndpoint::new("http://x");
        assert_eq!(e.timeout, Duration::from_secs(DEFAULT_TIMEOUT_SECS));
        assert_eq!(e.timeout, Duration::from_secs(10));
    }

    #[test]
    fn with_timeout_overrides_default() {
        let e = ServiceEndpoint::new("http://x").with_timeout(3);
        assert_eq!(e.timeout, Duration::from_secs(3));
    }

    #[test]
    fn blocking_get_raw_errors_on_unreachable_host() {
        // 127.0.0.1:1 is reserved/closed — connection is refused fast, so this
        // exercises the error path deterministically without a live server.
        let e = ServiceEndpoint::new("http://127.0.0.1:1").with_timeout(2);
        let result = blocking::get_raw(&e, "/health");
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("127.0.0.1:1"));
    }

    #[test]
    fn blocking_check_health_false_on_unreachable_host() {
        let e = ServiceEndpoint::new("http://127.0.0.1:1").with_timeout(2);
        assert!(!blocking::check_health(&e, "/health"));
    }
}
