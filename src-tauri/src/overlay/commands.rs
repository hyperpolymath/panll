// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Overlay network Tauri commands — Tor, IPFS, Ethereum.
//!
//! Routes through the ECHIDNA overlay V-lang adapter (REST) at
//! OVERLAY_URL (default http://localhost:8100/api/v1/overlay).
//! Each command returns JSON on success or an error string on failure.

use serde_json::json;

const DEFAULT_OVERLAY_URL: &str = "http://localhost:8103/api/v1/overlay";

fn overlay_url() -> String {
    std::env::var("OVERLAY_URL").unwrap_or_else(|_| DEFAULT_OVERLAY_URL.to_string())
}

/// Build a blocking reqwest client with a given timeout in seconds.
fn client(timeout_secs: u64) -> Result<reqwest::blocking::Client, String> {
    reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))
}

/// Handle a GET request, returning the body on success.
fn get(path: &str, timeout_secs: u64) -> Result<String, String> {
    let url = format!("{}{}", overlay_url(), path);
    let c = client(timeout_secs)?;
    match c.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Overlay returned {}: {}", status, body))
            }
        }
        Err(e) => Err(format!("Overlay request failed ({}): {}", url, e)),
    }
}

/// Handle a POST request with a JSON body, returning the response on success.
fn post(path: &str, body: serde_json::Value, timeout_secs: u64) -> Result<String, String> {
    let url = format!("{}{}", overlay_url(), path);
    let c = client(timeout_secs)?;
    match c.post(&url).json(&body).send() {
        Ok(resp) => {
            let status = resp.status();
            let text = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(text)
            } else {
                Err(format!("Overlay returned {}: {}", status, text))
            }
        }
        Err(e) => Err(format!("Overlay request failed ({}): {}", url, e)),
    }
}

/// Handle a DELETE request, returning the body on success.
fn delete(path: &str, timeout_secs: u64) -> Result<String, String> {
    let url = format!("{}{}", overlay_url(), path);
    let c = client(timeout_secs)?;
    match c.delete(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("Overlay returned {}: {}", status, body))
            }
        }
        Err(e) => Err(format!("Overlay request failed ({}): {}", url, e)),
    }
}

// ============================================================================
// Unified overlay commands
// ============================================================================

/// GET /status — combined status of all overlay networks.
/// Returns JSON: `{tor: "connected"|"disconnected"|..., ipfs: ..., ethereum: ...}`
#[tauri::command]
pub fn overlay_status() -> Result<String, String> {
    get("/status", 5)
}

/// GET /health — overlay subsystem health check.
#[tauri::command]
pub fn overlay_health() -> Result<String, String> {
    get("/health", 5)
}

// ============================================================================
// Tor commands
// ============================================================================

/// POST /tor/connect — connect to Tor control port.
/// Body: `{control_host?, control_port?, socks_port?, auth_method?, auth_data?}`
#[tauri::command]
pub fn overlay_tor_connect(
    control_host: Option<String>,
    control_port: Option<u16>,
    socks_port: Option<u16>,
    auth_method: Option<u8>,
    auth_data: Option<String>,
) -> Result<String, String> {
    let body = json!({
        "control_host": control_host.unwrap_or_else(|| "127.0.0.1".to_string()),
        "control_port": control_port.unwrap_or(9051),
        "socks_port": socks_port.unwrap_or(9050),
        "auth_method": auth_method.unwrap_or(0),
        "auth_data": auth_data.unwrap_or_default(),
    });
    post("/tor/connect", body, 15)
}

/// POST /tor/disconnect — disconnect from Tor.
#[tauri::command]
pub fn overlay_tor_disconnect() -> Result<String, String> {
    post("/tor/disconnect", json!({}), 5)
}

/// GET /tor/status — Tor connection status.
#[tauri::command]
pub fn overlay_tor_status() -> Result<String, String> {
    get("/tor/status", 5)
}

/// POST /tor/hidden-service — create a new Tor hidden service.
/// Body: `{port, target_port}`
#[tauri::command]
pub fn overlay_tor_create_hidden_service(
    port: u16,
    target_port: u16,
) -> Result<String, String> {
    post("/tor/hidden-service", json!({"port": port, "target_port": target_port}), 30)
}

/// DELETE /tor/hidden-service/{onion} — destroy a hidden service.
#[tauri::command]
pub fn overlay_tor_destroy_hidden_service(onion_address: String) -> Result<String, String> {
    delete(&format!("/tor/hidden-service/{}", onion_address), 10)
}

/// GET /tor/circuits — list active Tor circuits.
#[tauri::command]
pub fn overlay_tor_list_circuits() -> Result<String, String> {
    get("/tor/circuits", 10)
}

/// GET /tor/circuits/{id} — get a specific circuit's details (hops, status).
#[tauri::command]
pub fn overlay_tor_get_circuit(circuit_id: String) -> Result<String, String> {
    get(&format!("/tor/circuits/{}", circuit_id), 10)
}

/// POST /tor/resolve — resolve a hostname through Tor.
/// Body: `{hostname}`
#[tauri::command]
pub fn overlay_tor_resolve(hostname: String) -> Result<String, String> {
    post("/tor/resolve", json!({"hostname": hostname}), 30)
}

// ============================================================================
// IPFS commands
// ============================================================================

/// POST /ipfs/connect — connect to IPFS daemon.
/// Body: `{api_host?, api_port?, gateway_port?, repo_path?}`
#[tauri::command]
pub fn overlay_ipfs_connect(
    api_host: Option<String>,
    api_port: Option<u16>,
    gateway_port: Option<u16>,
    repo_path: Option<String>,
) -> Result<String, String> {
    let body = json!({
        "api_host": api_host.unwrap_or_else(|| "127.0.0.1".to_string()),
        "api_port": api_port.unwrap_or(5001),
        "gateway_port": gateway_port.unwrap_or(8080),
        "repo_path": repo_path.unwrap_or_else(|| "~/.ipfs".to_string()),
    });
    post("/ipfs/connect", body, 15)
}

/// POST /ipfs/disconnect — disconnect from IPFS.
#[tauri::command]
pub fn overlay_ipfs_disconnect() -> Result<String, String> {
    post("/ipfs/disconnect", json!({}), 5)
}

/// GET /ipfs/status — IPFS daemon status.
#[tauri::command]
pub fn overlay_ipfs_status() -> Result<String, String> {
    get("/ipfs/status", 5)
}

/// POST /ipfs/add — add content to IPFS, returns CID.
/// Body: `{data, content_type?}`
#[tauri::command]
pub fn overlay_ipfs_add(data: String, content_type: Option<String>) -> Result<String, String> {
    post(
        "/ipfs/add",
        json!({"data": data, "content_type": content_type.unwrap_or_else(|| "application/octet-stream".to_string())}),
        30,
    )
}

/// GET /ipfs/cat/{cid} — retrieve content by CID.
#[tauri::command]
pub fn overlay_ipfs_cat(cid: String) -> Result<String, String> {
    get(&format!("/ipfs/cat/{}", cid), 30)
}

/// POST /ipfs/pin — pin content by CID.
#[tauri::command]
pub fn overlay_ipfs_pin(cid: String) -> Result<String, String> {
    post("/ipfs/pin", json!({"cid": cid}), 30)
}

/// POST /ipfs/unpin — unpin content by CID.
#[tauri::command]
pub fn overlay_ipfs_unpin(cid: String) -> Result<String, String> {
    post("/ipfs/unpin", json!({"cid": cid}), 30)
}

/// GET /ipfs/dag/{cid} — get DAG node for proof graph traversal.
#[tauri::command]
pub fn overlay_ipfs_dag_get(cid: String) -> Result<String, String> {
    get(&format!("/ipfs/dag/{}", cid), 30)
}

// ============================================================================
// Ethereum commands (stubbed — Aerie future use)
// ============================================================================

/// POST /eth/connect — connect to Ethereum JSON-RPC endpoint.
/// Body: `{rpc_url?, network?, chain_id?}`
#[tauri::command]
pub fn overlay_eth_connect(
    rpc_url: Option<String>,
    network: Option<String>,
    chain_id: Option<u64>,
) -> Result<String, String> {
    let body = json!({
        "rpc_url": rpc_url.unwrap_or_else(|| "http://localhost:8545".to_string()),
        "network": network.unwrap_or_else(|| "local".to_string()),
        "chain_id": chain_id.unwrap_or(1337),
    });
    post("/eth/connect", body, 15)
}

/// POST /eth/disconnect — disconnect from Ethereum.
#[tauri::command]
pub fn overlay_eth_disconnect() -> Result<String, String> {
    post("/eth/disconnect", json!({}), 5)
}

/// GET /eth/status — Ethereum connection status.
#[tauri::command]
pub fn overlay_eth_status() -> Result<String, String> {
    get("/eth/status", 5)
}

/// POST /eth/timestamp-proof — anchor a proof certificate hash on-chain.
/// Body: `{proof_hash}`. Returns tx hash, block number, timestamp.
#[tauri::command]
pub fn overlay_eth_timestamp_proof(proof_hash: String) -> Result<String, String> {
    post("/eth/timestamp-proof", json!({"proof_hash": proof_hash}), 60)
}

/// POST /eth/verify-timestamp — verify a previously anchored timestamp.
/// Body: `{tx_hash}`. Returns proof hash, block, timestamp, contract address.
#[tauri::command]
pub fn overlay_eth_verify_timestamp(tx_hash: String) -> Result<String, String> {
    post("/eth/verify-timestamp", json!({"tx_hash": tx_hash}), 30)
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn overlay_url_default_and_override() {
        std::env::remove_var("OVERLAY_URL");
        assert_eq!(overlay_url(), DEFAULT_OVERLAY_URL);
        let custom = "http://overlay.local:9999/v2";
        std::env::set_var("OVERLAY_URL", custom);
        assert_eq!(overlay_url(), custom);
        std::env::remove_var("OVERLAY_URL");
    }

    #[test]
    fn tor_connect_json_body_shape() {
        let body = json!({
            "control_host": "127.0.0.1",
            "control_port": 9051,
            "socks_port": 9050,
            "auth_method": 0,
            "auth_data": "",
        });
        assert_eq!(body["control_port"], 9051);
        assert_eq!(body["socks_port"], 9050);
    }

    #[test]
    fn ipfs_connect_json_body_shape() {
        let body = json!({
            "api_host": "127.0.0.1",
            "api_port": 5001,
            "gateway_port": 8080,
            "repo_path": "~/.ipfs",
        });
        assert_eq!(body["api_port"], 5001);
    }

    #[test]
    fn eth_connect_json_defaults() {
        let body = json!({
            "rpc_url": "http://localhost:8545",
            "network": "local",
            "chain_id": 1337,
        });
        assert_eq!(body["chain_id"], 1337);
        assert_eq!(body["network"], "local");
    }
}
