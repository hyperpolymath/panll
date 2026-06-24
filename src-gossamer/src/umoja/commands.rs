// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Umoja peer management Tauri commands — federation lifecycle operations.
//!
//! Provides add/disconnect/gossip/sync/metrics controls for the Umoja
//! gossip-based federation layer. These commands proxy to the BoJ server's
//! Umoja endpoints at /umoja/*.
//!
//! All commands currently return mock JSON responses for front-end
//! development; the BoJ server integration will be wired when the
//! real Umoja REST API is finalised.

use serde_json::json;

/// Add a new peer to the Umoja federation by address.
///
/// Mock response: returns the new peer's assigned node ID and initial state.

pub async fn umoja_add_peer(address: String) -> Result<String, String> {
    if address.is_empty() {
        return Err("Peer address must not be empty".to_string());
    }
    // Mock: generate a deterministic node ID from the address.
    let node_id = format!(
        "node-{:08x}",
        address.bytes().fold(0u32, |acc, b| acc.wrapping_mul(31).wrapping_add(b as u32))
    );
    let response = json!({
        "ok": true,
        "nodeId": node_id,
        "address": address,
        "state": "Pending",
        "message": format!("Peer {} added at {}", node_id, address),
    });
    Ok(response.to_string())
}

/// Disconnect a peer from the Umoja federation by node ID.
///
/// Mock response: confirms disconnection and reports the peer as Stale.

pub async fn umoja_disconnect_peer(node_id: String) -> Result<String, String> {
    if node_id.is_empty() {
        return Err("Node ID must not be empty".to_string());
    }
    let response = json!({
        "ok": true,
        "nodeId": node_id,
        "state": "Stale",
        "message": format!("Peer {} disconnected", node_id),
    });
    Ok(response.to_string())
}

/// Trigger a manual gossip round across the Umoja federation.
///
/// Mock response: returns the new round number and peer count.

pub async fn umoja_trigger_gossip() -> Result<String, String> {
    let response = json!({
        "ok": true,
        "round": 42,
        "peersContacted": 3,
        "message": "Gossip round triggered successfully",
    });
    Ok(response.to_string())
}

/// Request a catalogue sync with a specific peer by node ID.
///
/// Mock response: returns sync status and digest comparison.

pub async fn umoja_sync_catalogue(node_id: String) -> Result<String, String> {
    if node_id.is_empty() {
        return Err("Node ID must not be empty".to_string());
    }
    let response = json!({
        "ok": true,
        "nodeId": node_id,
        "localDigest": "a1b2c3d4e5f6",
        "remoteDigest": "a1b2c3d4e5f6",
        "inSync": true,
        "cartridgesSynced": 17,
        "message": format!("Catalogue synced with peer {}", node_id),
    });
    Ok(response.to_string())
}

/// Retrieve metrics for a specific peer by node ID.
///
/// Mock response: returns latency, uptime, and gossip round data.

pub async fn umoja_peer_metrics(node_id: String) -> Result<String, String> {
    if node_id.is_empty() {
        return Err("Node ID must not be empty".to_string());
    }
    let response = json!({
        "ok": true,
        "nodeId": node_id,
        "latencyMs": 12.5,
        "uptimeSeconds": 86400,
        "gossipRoundsSeen": 142,
        "lastGossipRound": 42,
        "catalogueDigest": "a1b2c3d4e5f6",
        "cartridgeCount": 17,
        "bytesExchanged": 524288,
        "message": format!("Metrics for peer {}", node_id),
    });
    Ok(response.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn add_peer_returns_node_id() {
        let result = umoja_add_peer("192.168.1.100:9876".to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["ok"], true);
        assert!(json["nodeId"].as_str().unwrap().starts_with("node-"));
        assert_eq!(json["state"], "Pending");
        assert_eq!(json["address"], "192.168.1.100:9876");
    }

    #[tokio::test]
    async fn add_peer_rejects_empty_address() {
        let result = umoja_add_peer("".to_string()).await;
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "Peer address must not be empty");
    }

    #[tokio::test]
    async fn disconnect_peer_marks_stale() {
        let result = umoja_disconnect_peer("node-abc123".to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["ok"], true);
        assert_eq!(json["state"], "Stale");
        assert_eq!(json["nodeId"], "node-abc123");
    }

    #[tokio::test]
    async fn disconnect_peer_rejects_empty_id() {
        let result = umoja_disconnect_peer("".to_string()).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn trigger_gossip_returns_round() {
        let result = umoja_trigger_gossip().await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["ok"], true);
        assert_eq!(json["round"], 42);
        assert!(json["peersContacted"].as_i64().unwrap() > 0);
    }

    #[tokio::test]
    async fn sync_catalogue_returns_digest() {
        let result = umoja_sync_catalogue("node-abc123".to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["ok"], true);
        assert_eq!(json["inSync"], true);
        assert_eq!(json["nodeId"], "node-abc123");
        assert!(json["localDigest"].as_str().is_some());
    }

    #[tokio::test]
    async fn sync_catalogue_rejects_empty_id() {
        let result = umoja_sync_catalogue("".to_string()).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn peer_metrics_returns_data() {
        let result = umoja_peer_metrics("node-abc123".to_string()).await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert_eq!(json["ok"], true);
        assert_eq!(json["nodeId"], "node-abc123");
        assert!(json["latencyMs"].as_f64().unwrap() > 0.0);
        assert!(json["uptimeSeconds"].as_i64().unwrap() > 0);
        assert!(json["gossipRoundsSeen"].as_i64().unwrap() > 0);
    }

    #[tokio::test]
    async fn peer_metrics_rejects_empty_id() {
        let result = umoja_peer_metrics("".to_string()).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn add_peer_deterministic_node_id() {
        // Same address should produce the same node ID.
        let r1 = umoja_add_peer("10.0.0.1:5000".to_string()).await.unwrap();
        let r2 = umoja_add_peer("10.0.0.1:5000".to_string()).await.unwrap();
        let j1: serde_json::Value = serde_json::from_str(&r1).unwrap();
        let j2: serde_json::Value = serde_json::from_str(&r2).unwrap();
        assert_eq!(j1["nodeId"], j2["nodeId"]);
    }
}
