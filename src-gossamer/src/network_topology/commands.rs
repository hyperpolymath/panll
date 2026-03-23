// SPDX-License-Identifier: PMPL-1.0-or-later

//! Network Topology Tauri commands — topology graph, DNS table, packet flow,
//! and SVG export for the IDApTIK in-game network viewer.
//!
//! Commands:
//!   - `read_network_topology`: Read the current device/connection graph.
//!   - `read_dns_table`: Read DNS resolution entries from the game.
//!   - `read_packet_flow`: Read packet flow events for animation.
//!   - `export_topology_svg`: Export the topology as an SVG string.

use serde_json::json;

/// Read the current network topology from the running IDApTIK instance.
///
/// Returns a JSON object containing `devices` (array of network devices with
/// zone, security level, position, and defence flags) and `connections` (array
/// of edges with protocol, encryption, latency, and packet count).
///
/// Currently returns stub data representing a small sample network. When the
/// IDApTIK engine bridge is implemented this will query the live game state.

pub async fn read_network_topology() -> Result<String, String> {
    let result = json!({
        "devices": [
            {
                "id": "dev-router-01",
                "name": "Core Router",
                "deviceType": "router",
                "zone": "Internal",
                "securityLevel": 3,
                "x": 400.0,
                "y": 300.0,
                "defenceFlags": ["Firewall", "AuditLog", "Segmentation"],
                "compromised": false,
                "active": true
            },
            {
                "id": "dev-server-01",
                "name": "Web Server",
                "deviceType": "server",
                "zone": "Dmz",
                "securityLevel": 2,
                "x": 200.0,
                "y": 150.0,
                "defenceFlags": ["Firewall", "IDS", "Patching"],
                "compromised": false,
                "active": true
            },
            {
                "id": "dev-db-01",
                "name": "Database",
                "deviceType": "database",
                "zone": "Restricted",
                "securityLevel": 5,
                "x": 600.0,
                "y": 450.0,
                "defenceFlags": ["Encryption", "AccessControl", "Backup", "MFA"],
                "compromised": false,
                "active": true
            },
            {
                "id": "dev-workstation-01",
                "name": "Admin Workstation",
                "deviceType": "workstation",
                "zone": "Internal",
                "securityLevel": 4,
                "x": 350.0,
                "y": 500.0,
                "defenceFlags": ["MFA", "Encryption"],
                "compromised": false,
                "active": true
            }
        ],
        "connections": [
            {
                "sourceId": "dev-router-01",
                "targetId": "dev-server-01",
                "protocol": "HTTPS",
                "encrypted": true,
                "packetCount": 1024,
                "latencyMs": 2.5,
                "active": true
            },
            {
                "sourceId": "dev-router-01",
                "targetId": "dev-db-01",
                "protocol": "SSH",
                "encrypted": true,
                "packetCount": 256,
                "latencyMs": 1.2,
                "active": true
            },
            {
                "sourceId": "dev-workstation-01",
                "targetId": "dev-router-01",
                "protocol": "SSH",
                "encrypted": true,
                "packetCount": 512,
                "latencyMs": 0.8,
                "active": true
            }
        ]
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Read DNS resolution entries from the running game.
///
/// Returns a JSON array of DNS entries, each with hostname, resolved IP,
/// record type, and TTL. Currently returns stub data representing a sample
/// DNS table from the IDApTIK game world.

pub async fn read_dns_table() -> Result<String, String> {
    let result = json!({
        "entries": [
            {
                "hostname": "core-router.idaptik.local",
                "resolvedIp": "10.0.1.1",
                "recordType": "A",
                "ttl": 3600
            },
            {
                "hostname": "web.idaptik.local",
                "resolvedIp": "10.0.2.10",
                "recordType": "A",
                "ttl": 1800
            },
            {
                "hostname": "db.idaptik.local",
                "resolvedIp": "10.0.3.50",
                "recordType": "A",
                "ttl": 7200
            },
            {
                "hostname": "admin.idaptik.local",
                "resolvedIp": "10.0.1.100",
                "recordType": "A",
                "ttl": 900
            },
            {
                "hostname": "mail.idaptik.local",
                "resolvedIp": "10.0.2.25",
                "recordType": "MX",
                "ttl": 3600
            }
        ]
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Read packet flow events from the running game for animation.
///
/// Returns a JSON array of recent packet flow events, each tied to a
/// connection ID with timestamp, size, and blocked status. Currently
/// returns stub data representing sample network traffic.

pub async fn read_packet_flow() -> Result<String, String> {
    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs_f64();

    let result = json!({
        "events": [
            {
                "connectionId": "dev-router-01:dev-server-01",
                "timestamp": ts - 2.0,
                "size": 1500,
                "blocked": false
            },
            {
                "connectionId": "dev-router-01:dev-db-01",
                "timestamp": ts - 1.5,
                "size": 512,
                "blocked": false
            },
            {
                "connectionId": "dev-workstation-01:dev-router-01",
                "timestamp": ts - 1.0,
                "size": 64,
                "blocked": false
            },
            {
                "connectionId": "dev-router-01:dev-server-01",
                "timestamp": ts - 0.5,
                "size": 2048,
                "blocked": true
            }
        ]
    });
    serde_json::to_string(&result)
        .map_err(|e| format!("Serialisation error: {e}"))
}

/// Export the current topology as an SVG string.
///
/// Generates a minimal SVG representation of the network topology with
/// devices as circles and connections as lines. Currently returns a stub
/// SVG with placeholder geometry. When the engine bridge is implemented,
/// this will render the live topology graph.

pub async fn export_topology_svg() -> Result<String, String> {
    let svg = r#"<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600">
  <title>IDApTIK Network Topology</title>
  <style>
    .device { fill: #4a9eff; stroke: #2d6bb4; stroke-width: 2; }
    .device-label { font-family: monospace; font-size: 12px; fill: #333; text-anchor: middle; }
    .connection { stroke: #999; stroke-width: 1.5; stroke-dasharray: 5,3; }
  </style>
  <!-- Connections -->
  <line class="connection" x1="400" y1="300" x2="200" y2="150"/>
  <line class="connection" x1="400" y1="300" x2="600" y2="450"/>
  <line class="connection" x1="350" y1="500" x2="400" y2="300"/>
  <!-- Devices -->
  <circle class="device" cx="400" cy="300" r="20"/>
  <text class="device-label" x="400" y="335">Core Router</text>
  <circle class="device" cx="200" cy="150" r="20"/>
  <text class="device-label" x="200" y="185">Web Server</text>
  <circle class="device" cx="600" cy="450" r="20"/>
  <text class="device-label" x="600" y="485">Database</text>
  <circle class="device" cx="350" cy="500" r="20"/>
  <text class="device-label" x="350" y="535">Admin WS</text>
</svg>"#;

    let result = json!({
        "svg": svg,
        "deviceCount": 4,
        "connectionCount": 3,
        "stub": true,
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

    #[test]
    fn test_read_network_topology() {
        rt().block_on(async {
            let result = read_network_topology().await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            let devices = json["devices"].as_array().unwrap();
            assert_eq!(devices.len(), 4, "Should have 4 stub devices");
            let connections = json["connections"].as_array().unwrap();
            assert_eq!(connections.len(), 3, "Should have 3 stub connections");
            // Verify first device fields.
            let router = &devices[0];
            assert_eq!(router["id"], "dev-router-01");
            assert_eq!(router["zone"], "Internal");
            assert_eq!(router["compromised"], false);
            assert_eq!(router["active"], true);
        });
    }

    #[test]
    fn test_read_dns_table() {
        rt().block_on(async {
            let result = read_dns_table().await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            let entries = json["entries"].as_array().unwrap();
            assert_eq!(entries.len(), 5, "Should have 5 stub DNS entries");
            // Verify first entry fields.
            let first = &entries[0];
            assert_eq!(first["hostname"], "core-router.idaptik.local");
            assert_eq!(first["recordType"], "A");
            assert!(first["ttl"].as_i64().unwrap() > 0);
        });
    }

    #[test]
    fn test_read_packet_flow() {
        rt().block_on(async {
            let result = read_packet_flow().await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            let events = json["events"].as_array().unwrap();
            assert_eq!(events.len(), 4, "Should have 4 stub packet events");
            // Verify event fields.
            let first = &events[0];
            assert!(first["connectionId"].as_str().is_some());
            assert!(first["timestamp"].as_f64().unwrap() > 0.0);
            assert!(first["size"].as_i64().unwrap() > 0);
        });
    }

    #[test]
    fn test_export_topology_svg() {
        rt().block_on(async {
            let result = export_topology_svg().await;
            assert!(result.is_ok());
            let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
            let svg = json["svg"].as_str().unwrap();
            assert!(svg.contains("<svg"), "SVG should contain opening tag");
            assert!(svg.contains("</svg>"), "SVG should contain closing tag");
            assert_eq!(json["deviceCount"], 4);
            assert_eq!(json["connectionCount"], 3);
            assert_eq!(json["stub"], true);
        });
    }
}
