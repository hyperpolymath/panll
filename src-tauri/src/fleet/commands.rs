// SPDX-License-Identifier: PMPL-1.0-or-later

//! Fleet Tauri commands — bridge to the gitbot-fleet Axum API.
//!
//! Commands:
//!   - `fleet_get_bots`: Fetch bot status from fleet API; fallback to all-offline.
//!   - `fleet_get_findings`: Fetch findings queue; fallback to empty array.
//!   - `fleet_dispatch`: Dispatch a finding to a bot; return error on failure.
//!
//! The fleet API runs on http://localhost:8080/api/v1 (configurable via
//! FLEET_URL environment variable).

use serde_json::json;

/// Base URL for the fleet API. Override with FLEET_URL env var.
fn fleet_url() -> String {
    std::env::var("FLEET_URL")
        .unwrap_or_else(|_| "http://localhost:8080/api/v1".to_string())
}

/// HTTP client with a 5-second timeout — fleet is local, should be fast.
fn client() -> Result<reqwest::Client, String> {
    reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build()
        .map_err(|e| format!("HTTP client error: {e}"))
}

/// Fetch the current status of all 6 bots.
///
/// On connection failure, returns a JSON array with all 6 canonical bots in
/// "offline" status so the panel always has something to render. The bot list
/// is: rhodibot, echidnabot, sustainabot, glambot, seambot, finishbot.
#[tauri::command]
pub async fn fleet_get_bots() -> Result<String, String> {
    let url = format!("{}/bots", fleet_url());
    let client = client()?;

    match client.get(&url).send().await {
        Ok(resp) if resp.status().is_success() => {
            resp.text().await.map_err(|e| format!("Body read error: {e}"))
        }
        _ => {
            // Fleet server unreachable — return all bots as offline.
            let fallback = json!([
                { "id": "rhodibot",     "name": "Rhodibot",     "status": "offline", "role": "standards" },
                { "id": "echidnabot",   "name": "Echidnabot",   "status": "offline", "role": "verification" },
                { "id": "sustainabot",  "name": "Sustainabot",  "status": "offline", "role": "sustainability" },
                { "id": "glambot",      "name": "Glambot",      "status": "offline", "role": "presentation" },
                { "id": "seambot",      "name": "Seambot",      "status": "offline", "role": "integration" },
                { "id": "finishbot",    "name": "Finishbot",    "status": "offline", "role": "completion" },
            ]);
            Ok(fallback.to_string())
        }
    }
}

/// Fetch the findings queue from the fleet API.
///
/// On failure, returns an empty JSON array rather than an error so the panel
/// renders an empty table instead of an error banner.
#[tauri::command]
pub async fn fleet_get_findings() -> Result<String, String> {
    let url = format!("{}/findings", fleet_url());
    let client = client()?;

    match client.get(&url).send().await {
        Ok(resp) if resp.status().is_success() => {
            resp.text().await.map_err(|e| format!("Body read error: {e}"))
        }
        _ => Ok("[]".to_string()),
    }
}

/// Dispatch a finding to a specific bot for processing.
///
/// Unlike the read commands, dispatch failures are surfaced as errors because
/// the user explicitly triggered an action and needs to know it failed.
#[tauri::command]
pub async fn fleet_dispatch(finding_id: String, bot_id: String) -> Result<String, String> {
    let url = format!("{}/dispatch", fleet_url());
    let client = client()?;

    let payload = json!({
        "findingId": finding_id,
        "botId": bot_id,
    });

    let resp = client
        .post(&url)
        .json(&payload)
        .send()
        .await
        .map_err(|e| format!("Fleet dispatch failed (server unreachable): {e}"))?;

    if resp.status().is_success() {
        resp.text().await.map_err(|e| format!("Body read error: {e}"))
    } else {
        Err(format!("Fleet dispatch returned HTTP {}", resp.status()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_fleet_get_bots_fallback() {
        // With no fleet server running, should return 6 offline bots.
        let result = fleet_get_bots().await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        let bots = json.as_array().unwrap();
        assert_eq!(bots.len(), 6);
        assert_eq!(bots[0]["status"], "offline");
    }

    #[tokio::test]
    async fn test_fleet_get_findings_fallback() {
        // With no fleet server running, should return empty array.
        let result = fleet_get_findings().await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "[]");
    }

    #[tokio::test]
    async fn test_fleet_dispatch_fails_without_server() {
        // Dispatch should return an error when the server is unreachable.
        let result = fleet_dispatch("finding-1".into(), "rhodibot".into()).await;
        assert!(result.is_err());
    }
}
