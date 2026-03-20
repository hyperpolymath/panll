// SPDX-License-Identifier: PMPL-1.0-or-later

//! Multiplayer Monitor Tauri commands — Phoenix sync server connectivity,
//! player state inspection, state diff analysis, ETS cache, and reconnection.
//!
//! Commands:
//!   - `multiplayer_connect`: Connect to the Phoenix WebSocket sync server.
//!   - `multiplayer_disconnect`: Disconnect from the sync server.
//!   - `multiplayer_read_state`: Read current multiplayer state (players, channels, locks).
//!   - `multiplayer_read_diffs`: Read state diffs between local and remote.
//!   - `multiplayer_read_ets`: Read ETS cache entries for inspection.
//!   - `multiplayer_reconnection_test`: Trigger a reconnection test cycle.

use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};

use once_cell::sync::Lazy;
use serde_json::json;

/// In-memory connection state for the multiplayer monitor.
/// Tracks whether we have an active connection and to which server.
struct ConnectionState {
    connected: bool,
    server_url: Option<String>,
    connected_at: Option<u64>,
}

impl ConnectionState {
    fn new() -> Self {
        Self {
            connected: false,
            server_url: None,
            connected_at: None,
        }
    }
}

static CONNECTION_STATE: Lazy<Mutex<ConnectionState>> = Lazy::new(|| {
    Mutex::new(ConnectionState::new())
});

/// Serialises tests that share `CONNECTION_STATE` so they cannot race.
#[cfg(test)]
static TEST_LOCK: Lazy<Mutex<()>> = Lazy::new(|| Mutex::new(()));

/// Return the current Unix timestamp in seconds.
fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

/// Connect to the Phoenix WebSocket sync server.
///
/// Validates the URL and records the connection in memory. Currently a stub
/// that simulates a successful WebSocket handshake. When the real Phoenix
/// bridge is implemented, this will open a persistent WebSocket connection.
#[tauri::command]
pub async fn multiplayer_connect(url: String) -> Result<String, String> {
    if url.is_empty() {
        return Err("Server URL cannot be empty".to_string());
    }

    let mut state = CONNECTION_STATE.lock().map_err(|e| format!("Lock error: {e}"))?;
    state.connected = true;
    state.server_url = Some(url.clone());
    state.connected_at = Some(now_secs());

    let result = json!({
        "connected": true,
        "serverUrl": url,
        "wsState": "connected",
        "connectedAt": state.connected_at,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Disconnect from the sync server.
///
/// Clears the in-memory connection state. When the real bridge is
/// implemented, this will close the WebSocket and clean up channels.
#[tauri::command]
pub async fn multiplayer_disconnect() -> Result<String, String> {
    let mut state = CONNECTION_STATE.lock().map_err(|e| format!("Lock error: {e}"))?;
    let was_connected = state.connected;
    state.connected = false;
    state.server_url = None;
    state.connected_at = None;

    let result = json!({
        "disconnected": true,
        "wasConnected": was_connected,
        "wsState": "disconnected",
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Read the current multiplayer state (players, channels, locks).
///
/// Returns stub data representing a typical multiplayer session with two
/// players, two channels, and one device lock. When the real bridge is
/// implemented, this will query the live Phoenix server state.
#[tauri::command]
pub async fn multiplayer_read_state() -> Result<String, String> {
    let state = CONNECTION_STATE.lock().map_err(|e| format!("Lock error: {e}"))?;
    let ts = now_secs() as f64;

    let result = json!({
        "connected": state.connected,
        "serverUrl": state.server_url,
        "players": [
            {
                "playerId": "player-1",
                "displayName": "Host Player",
                "deviceId": "device-a",
                "latencyMs": 12,
                "lamportClock": 42,
                "lastHeartbeat": ts,
                "isHost": true,
                "isSpectator": false,
            },
            {
                "playerId": "player-2",
                "displayName": "Guest Player",
                "deviceId": "device-b",
                "latencyMs": 34,
                "lamportClock": 41,
                "lastHeartbeat": ts - 1.5,
                "isHost": false,
                "isSpectator": false,
            },
        ],
        "channels": [
            {
                "topic": "game:lobby",
                "joinedAt": ts - 120.0,
                "messageCount": 47,
                "lastMessageAt": ts - 0.5,
            },
            {
                "topic": "game:match:1",
                "joinedAt": ts - 60.0,
                "messageCount": 215,
                "lastMessageAt": ts - 0.1,
            },
        ],
        "deviceLocks": [
            {
                "deviceId": "device-a",
                "lockedBy": "player-1",
                "lockedAt": ts - 90.0,
                "contestedBy": [],
            },
        ],
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Read state diffs between local and remote.
///
/// Returns stub diff entries showing typical sync divergence scenarios.
/// When the real bridge is implemented, this will compare local ETS state
/// against the server's authoritative state.
#[tauri::command]
pub async fn multiplayer_read_diffs() -> Result<String, String> {
    let ts = now_secs() as f64;

    let result = json!({
        "diffs": [
            {
                "timestamp": ts - 2.0,
                "playerId": "player-2",
                "field": "position.x",
                "localValue": "142",
                "remoteValue": "145",
                "resolved": false,
            },
            {
                "timestamp": ts - 5.0,
                "playerId": "player-1",
                "field": "score",
                "localValue": "1200",
                "remoteValue": "1200",
                "resolved": true,
            },
        ],
        "totalUnresolved": 1,
        "totalResolved": 1,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Read ETS cache entries for inspection.
///
/// Returns stub ETS table entries representing typical Erlang Term Storage
/// data from the Phoenix server. When the real bridge is implemented, this
/// will query the server's ETS tables via the debug API.
#[tauri::command]
pub async fn multiplayer_read_ets() -> Result<String, String> {
    let result = json!({
        "entries": [
            {
                "table": "player_sessions",
                "key": "player-1",
                "value": "{pid, <0.456.0>, connected, true}",
                "size": 128,
            },
            {
                "table": "player_sessions",
                "key": "player-2",
                "value": "{pid, <0.789.0>, connected, true}",
                "size": 128,
            },
            {
                "table": "game_state",
                "key": "match:1",
                "value": "{round, 3, phase, action}",
                "size": 256,
            },
        ],
        "tableCount": 2,
        "totalEntries": 3,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Trigger a reconnection test cycle.
///
/// Simulates a disconnect-reconnect sequence and reports the results.
/// When the real bridge is implemented, this will actually drop and
/// re-establish the WebSocket connection, measuring reconnection latency
/// and state recovery.
#[tauri::command]
pub async fn multiplayer_reconnection_test() -> Result<String, String> {
    let state = CONNECTION_STATE.lock().map_err(|e| format!("Lock error: {e}"))?;

    if !state.connected {
        return Err("Cannot run reconnection test: not connected".to_string());
    }

    let result = json!({
        "testPassed": true,
        "disconnectLatencyMs": 5,
        "reconnectLatencyMs": 120,
        "stateRecovered": true,
        "channelsRejoined": 2,
        "messagesLost": 0,
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Helper: create a tokio runtime for async command tests.
    /// Binary crate submodules cannot use `#[tokio::test]` directly because
    /// the dev-dependency is not linked into the binary test harness.
    fn rt() -> tokio::runtime::Runtime {
        tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .expect("Failed to create tokio runtime for tests")
    }

    /// Reset connection state between tests.
    /// Uses `unwrap_or_else` to recover from poisoned mutexes — a previous
    /// test panic should not cascade into subsequent test failures.
    fn reset_state() {
        let mut state = CONNECTION_STATE
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        state.connected = false;
        state.server_url = None;
        state.connected_at = None;
    }

    /// Acquire the test lock, recovering from poison if a previous test panicked.
    fn acquire_test_lock() -> std::sync::MutexGuard<'static, ()> {
        TEST_LOCK
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
    }

    #[test]
    fn test_multiplayer_connect_success() {
        let _guard = acquire_test_lock();
        reset_state();
        rt().block_on(async {
            let result = multiplayer_connect("ws://localhost:4000/socket".to_string()).await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["connected"], true);
            assert_eq!(json["wsState"], "connected");
            assert_eq!(json["serverUrl"], "ws://localhost:4000/socket");
        });
    }

    #[test]
    fn test_multiplayer_connect_empty_url() {
        let _guard = acquire_test_lock();
        reset_state();
        rt().block_on(async {
            let result = multiplayer_connect("".to_string()).await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("cannot be empty"));
        });
    }

    #[test]
    fn test_multiplayer_disconnect() {
        let _guard = acquire_test_lock();
        reset_state();
        rt().block_on(async {
            // Connect first, then disconnect.
            let _ = multiplayer_connect("ws://localhost:4000/socket".to_string()).await;
            let result = multiplayer_disconnect().await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["disconnected"], true);
            assert_eq!(json["wasConnected"], true);
            assert_eq!(json["wsState"], "disconnected");
        });
    }

    #[test]
    fn test_multiplayer_read_state() {
        let _guard = acquire_test_lock();
        reset_state();
        rt().block_on(async {
            let result = multiplayer_read_state().await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            let players = json["players"].as_array().unwrap();
            assert_eq!(players.len(), 2);
            assert_eq!(players[0]["isHost"], true);
            assert_eq!(players[1]["isHost"], false);
            let channels = json["channels"].as_array().unwrap();
            assert_eq!(channels.len(), 2);
        });
    }

    #[test]
    fn test_multiplayer_read_diffs() {
        let _guard = acquire_test_lock();
        reset_state();
        rt().block_on(async {
            let result = multiplayer_read_diffs().await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["totalUnresolved"], 1);
            assert_eq!(json["totalResolved"], 1);
            let diffs = json["diffs"].as_array().unwrap();
            assert_eq!(diffs.len(), 2);
        });
    }

    #[test]
    fn test_multiplayer_read_ets() {
        let _guard = acquire_test_lock();
        reset_state();
        rt().block_on(async {
            let result = multiplayer_read_ets().await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["tableCount"], 2);
            assert_eq!(json["totalEntries"], 3);
            let entries = json["entries"].as_array().unwrap();
            assert_eq!(entries.len(), 3);
        });
    }

    #[test]
    fn test_multiplayer_reconnection_test_not_connected() {
        let _guard = acquire_test_lock();
        reset_state();
        rt().block_on(async {
            let result = multiplayer_reconnection_test().await;
            assert!(result.is_err());
            assert!(result.unwrap_err().contains("not connected"));
        });
    }

    #[test]
    fn test_multiplayer_reconnection_test_connected() {
        let _guard = acquire_test_lock();
        reset_state();
        rt().block_on(async {
            let _ = multiplayer_connect("ws://localhost:4000/socket".to_string()).await;
            let result = multiplayer_reconnection_test().await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            assert_eq!(json["testPassed"], true);
            assert_eq!(json["stateRecovered"], true);
            assert_eq!(json["messagesLost"], 0);
        });
    }
}
