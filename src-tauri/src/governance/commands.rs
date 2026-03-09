// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Governance nesy-MCP Tauri commands.
//!
//! These commands route governance queries through the BoJ nesy-mcp cartridge
//! for real-time neural validation. They share the BoJ server endpoint and
//! invoke the `nesy-mcp` cartridge's tools via the standard invoke API.
//!
//! Currently returns mock responses for development — the BoJ nesy-mcp
//! cartridge will provide real neural validation once connected.

use serde_json::json;

const DEFAULT_BOJ_URL: &str = "http://localhost:7700/api/v1";

fn boj_url() -> String {
    std::env::var("BOJ_URL").unwrap_or_else(|_| DEFAULT_BOJ_URL.to_string())
}

/// Build an async reqwest client with a timeout.
fn async_client(timeout_secs: u64) -> Result<reqwest::Client, String> {
    reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))
}

/// POST to the BoJ nesy-mcp cartridge invoke endpoint.
async fn nesy_invoke(tool: &str, args: serde_json::Value) -> Result<String, String> {
    let url = format!("{}/cartridges/nesy-mcp/invoke", boj_url());
    let client = async_client(30)?;
    let body = json!({
        "tool": tool,
        "args": args,
    });

    match client.post(&url).json(&body).send().await {
        Ok(resp) => {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            if status.is_success() {
                Ok(text)
            } else {
                // Fall back to mock when nesy-mcp cartridge is not available.
                Err(format!("nesy-mcp returned {}: {}", status, text))
            }
        }
        Err(_) => {
            // Server unreachable — return mock response for development.
            Err("nesy-mcp cartridge unreachable".to_string())
        }
    }
}

/// Query the nesy-mcp cartridge for a confidence assessment on a borderline
/// governance decision. Returns JSON with confidence score, recommended
/// action, and reasoning.
///
/// Falls back to a mock response when the BoJ server is unreachable.
#[tauri::command]
pub async fn governance_nesy_query(query: String) -> Result<String, String> {
    match nesy_invoke("confidence-query", json!({"query": query})).await {
        Ok(response) => Ok(response),
        Err(_) => {
            // Mock response for development / offline operation.
            let mock = json!({
                "confidence": 0.65,
                "recommended_action": "maintain_current",
                "reasoning": format!(
                    "Mock nesy-mcp response for query: {}. \
                     Confidence is moderate — recommend maintaining current \
                     governance posture until more data is available.",
                    query
                ),
                "source": "mock",
            });
            Ok(mock.to_string())
        }
    }
}

/// Validate a governance adjustment through the nesy-mcp cartridge before
/// applying it. Used primarily for HaltInference decisions — the neural
/// subsystem can approve or reject with reasoning.
///
/// Falls back to a mock approval when the BoJ server is unreachable.
#[tauri::command]
pub async fn governance_nesy_validate(adjustment: String) -> Result<String, String> {
    match nesy_invoke("validate-adjustment", json!({"adjustment": adjustment})).await {
        Ok(response) => Ok(response),
        Err(_) => {
            // Mock response — approve with caution note.
            let mock = json!({
                "approved": true,
                "reasoning": format!(
                    "Mock validation for adjustment: {}. \
                     Approved with caution — neural subsystem offline, \
                     using conservative defaults.",
                    adjustment
                ),
                "confidence": 0.5,
                "source": "mock",
            });
            Ok(mock.to_string())
        }
    }
}

/// Probe the nesy-mcp cartridge for overall neural stability metrics.
/// Returns coherence, drift magnitude, and a stability recommendation.
///
/// Falls back to a mock neutral report when the BoJ server is unreachable.
#[tauri::command]
pub async fn governance_nesy_probe() -> Result<String, String> {
    match nesy_invoke("stability-probe", json!({})).await {
        Ok(response) => Ok(response),
        Err(_) => {
            // Mock response — report moderate stability.
            let mock = json!({
                "neural_coherence": 0.72,
                "drift_magnitude": 0.15,
                "recommendation": "stable",
                "details": "Mock stability probe — neural subsystem offline. \
                            Reporting moderate coherence with low drift as \
                            conservative default.",
                "source": "mock",
            });
            Ok(mock.to_string())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn boj_url_default() {
        std::env::remove_var("BOJ_URL");
        assert_eq!(boj_url(), DEFAULT_BOJ_URL);
    }

    #[test]
    fn boj_url_override() {
        let custom = "http://nesy.local:8800/v2";
        std::env::set_var("BOJ_URL", custom);
        assert_eq!(boj_url(), custom);
        std::env::remove_var("BOJ_URL");
    }

    #[tokio::test]
    async fn governance_nesy_query_returns_mock_when_offline() {
        // With no server running, should return a mock response (not an error).
        let result = governance_nesy_query("vexation=0.5,stability=0.55".to_string()).await;
        assert!(result.is_ok(), "Expected Ok with mock response");
        let body = result.unwrap();
        assert!(body.contains("confidence"), "Mock should contain confidence field");
        assert!(body.contains("mock"), "Mock should identify itself as mock source");
    }

    #[tokio::test]
    async fn governance_nesy_validate_returns_mock_when_offline() {
        let result = governance_nesy_validate("HaltInference: test reason".to_string()).await;
        assert!(result.is_ok(), "Expected Ok with mock response");
        let body = result.unwrap();
        assert!(body.contains("approved"), "Mock should contain approved field");
        assert!(body.contains("mock"), "Mock should identify itself as mock source");
    }

    #[tokio::test]
    async fn governance_nesy_probe_returns_mock_when_offline() {
        let result = governance_nesy_probe().await;
        assert!(result.is_ok(), "Expected Ok with mock response");
        let body = result.unwrap();
        assert!(
            body.contains("neural_coherence"),
            "Mock should contain neural_coherence field"
        );
        assert!(
            body.contains("recommendation"),
            "Mock should contain recommendation field"
        );
        assert!(body.contains("mock"), "Mock should identify itself as mock source");
    }
}
