// SPDX-License-Identifier: PMPL-1.0-or-later

//! Hypatia Tauri commands — bridge to the Hypatia Elixir Phoenix API.
//!
//! Commands:
//!   - `hypatia_get_networks`: Fetch neural network status; fallback to empty array.
//!   - `hypatia_get_scans`: Fetch scan results; fallback to empty array.
//!   - `hypatia_scan_repo`: Trigger a scan on a specific repo; error on failure.
//!
//! The Hypatia API runs on http://localhost:4040/api/v1 (configurable via
//! HYPATIA_URL environment variable).

use serde_json::json;

/// Base URL for the Hypatia API. Override with HYPATIA_URL env var.
fn hypatia_url() -> String {
    std::env::var("HYPATIA_URL")
        .unwrap_or_else(|_| "http://localhost:4040/api/v1".to_string())
}

/// HTTP client with a 10-second timeout — scans can take a moment.
fn client() -> Result<reqwest::Client, String> {
    reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("HTTP client error: {e}"))
}

/// Fetch the status of all 5 neural networks.
///
/// Returns a JSON array of network objects with name, status, and accuracy
/// fields. On connection failure, returns an empty array.

pub async fn hypatia_get_networks() -> Result<String, String> {
    let url = format!("{}/networks", hypatia_url());
    let client = client()?;

    match client.get(&url).send().await {
        Ok(resp) if resp.status().is_success() => {
            resp.text().await.map_err(|e| format!("Body read error: {e}"))
        }
        _ => Ok("[]".to_string()),
    }
}

/// Fetch scan results across all repos.
///
/// Returns a JSON array of scan result objects. On connection failure, returns
/// an empty array so the panel renders an empty table.

pub async fn hypatia_get_scans() -> Result<String, String> {
    let url = format!("{}/scans", hypatia_url());
    let client = client()?;

    match client.get(&url).send().await {
        Ok(resp) if resp.status().is_success() => {
            resp.text().await.map_err(|e| format!("Body read error: {e}"))
        }
        _ => Ok("[]".to_string()),
    }
}

/// Trigger a scan on a specific repo by name.
///
/// Unlike the read commands, scan failures are surfaced as errors because
/// the user explicitly triggered an action. The repo_name parameter matches
/// the ReScript frontend's `repoName` field (camelCase in JSON, snake_case
/// in Rust via Tauri's automatic rename).

pub async fn hypatia_scan_repo(repo_name: String) -> Result<String, String> {
    let url = format!("{}/scans", hypatia_url());
    let client = client()?;

    let payload = json!({
        "repoName": repo_name,
    });

    let resp = client
        .post(&url)
        .json(&payload)
        .send()
        .await
        .map_err(|e| format!("Hypatia scan failed (server unreachable): {e}"))?;

    if resp.status().is_success() {
        resp.text().await.map_err(|e| format!("Body read error: {e}"))
    } else {
        Err(format!("Hypatia scan returned HTTP {}", resp.status()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_hypatia_get_networks_fallback() {
        // With no Hypatia server running, should return empty array.
        let result = hypatia_get_networks().await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "[]");
    }

    #[tokio::test]
    async fn test_hypatia_get_scans_fallback() {
        let result = hypatia_get_scans().await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "[]");
    }

    #[tokio::test]
    async fn test_hypatia_scan_repo_fails_without_server() {
        let result = hypatia_scan_repo("test-repo".into()).await;
        assert!(result.is_err());
    }

    /// Verify the default Hypatia URL is the expected localhost endpoint.
    #[test]
    fn smoke_hypatia_url_default() {
        // Unset the env var to ensure we get the hardcoded default.
        std::env::remove_var("HYPATIA_URL");
        let url = hypatia_url();
        assert_eq!(url, "http://localhost:4040/api/v1");
    }

    /// Verify that HYPATIA_URL env var overrides the default.
    #[test]
    fn smoke_hypatia_url_override() {
        std::env::set_var("HYPATIA_URL", "http://custom-host:9999/api/v2");
        let url = hypatia_url();
        assert_eq!(url, "http://custom-host:9999/api/v2");
        std::env::remove_var("HYPATIA_URL");
    }
}
