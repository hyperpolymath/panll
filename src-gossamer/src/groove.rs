// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
//! Gossamer Groove endpoint for PanLL.
//!
//! Exposes PanLL's panel-ui capabilities via the groove discovery protocol.
//! Any groove-aware system (Gossamer, Burble, IDApTIK, etc.) can discover
//! PanLL by probing GET /.well-known/groove on port 8000.
//!
//! PanLL works standalone as a Tauri desktop environment. When groove
//! consumers connect, they gain access to PanLL's panel UI infrastructure,
//! including WebSocket-driven panel updates and the panel contract compiler.
//!
//! The groove connector types are formally verified in Gossamer's Groove.idr:
//! - IsSubset proves consumers can only connect if PanLL satisfies their needs
//! - GrooveHandle is linear: consumers MUST disconnect (no dangling grooves)
//!
//! ## Groove Protocol
//!
//! - `GET  /.well-known/groove` — Capability manifest (JSON)
//! - `GET  /health`             — Simple health check
//!
//! ## Capabilities Offered
//!
//! - `panel-ui` — WebSocket-driven panel environment with TEA framework
//!
//! ## Capabilities Consumed (enhanced when available)
//!
//! - `voice` (from Burble) — Voice comms in co-op panels
//! - `text` (from Burble) — Text chat in panel workspace
//! - `presence` (from Burble) — User presence indicators
//! - `integrity` (from Vext) — Hash chain verification for panel data
//! - `octad-storage` (from VeriSimDB) — Persist panel state and arrangements
//! - `scanning` (from Hypatia) — Security scanning results for panic-attack panel

use std::io::{Read, Write};
use std::net::{SocketAddr, TcpListener, TcpStream};
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};

use once_cell::sync::Lazy;

/// Known groove peers for health mesh probing.
/// PanLL probes these ports to discover neighbouring services.
const MESH_PROBE_PORTS: &[u16] = &[6473, 8080, 8081, 8091, 8092, 8093];

/// Cached mesh health state: peer service_id -> status.
static MESH_STATE: Lazy<Mutex<Vec<PeerHealth>>> = Lazy::new(|| Mutex::new(Vec::new()));

/// Health status of a single peer in the mesh.
#[derive(Clone)]
struct PeerHealth {
    /// Peer's self-reported service ID (or "unknown" if probe failed).
    service_id: String,
    /// Port the peer was discovered on.
    port: u16,
    /// "up", "degraded", or "down".
    status: String,
    /// Unix timestamp (milliseconds) of last successful probe.
    last_seen_ms: u64,
}

/// The groove capability manifest for PanLL.
/// Matches Groove.idr panllManifest: offers [PanelUI (websocket, /ws)].
const MANIFEST: &str = r#"{
  "groove_version": "1",
  "service_id": "panll",
  "service_version": "0.1.0",
  "capabilities": {
    "panel_ui": {
      "type": "panel-ui",
      "description": "WebSocket-driven panel environment with TEA framework and panel contract compiler",
      "protocol": "websocket",
      "endpoint": "/ws",
      "requires_auth": false,
      "panel_compatible": true
    },
    "feedback": {
      "type": "feedback",
      "description": "Groove-routed feedback collector — accepts and routes feedback to any mesh service",
      "protocol": "http",
      "endpoint": "/.well-known/groove/feedback",
      "requires_auth": false,
      "panel_compatible": true
    },
    "health_mesh": {
      "type": "health-mesh",
      "description": "Inter-service health mesh — monitors peer status via groove probing",
      "protocol": "http",
      "endpoint": "/.well-known/groove/mesh",
      "requires_auth": false,
      "panel_compatible": true
    }
  },
  "consumes": ["voice", "text", "presence", "integrity", "octad-storage", "scanning"],
  "endpoints": {
    "api": "http://localhost:8000",
    "health": "http://localhost:8000/health"
  },
  "health": "/health",
  "applicability": ["individual", "team", "massive-open"]
}"#;

/// Maximum HTTP request size (16 KiB).
const MAX_REQUEST_SIZE: usize = 16 * 1024;

/// Spawn the groove discovery HTTP server on port 8000 in a background thread.
///
/// This is a minimal blocking HTTP server that handles only the groove protocol
/// endpoints. It runs alongside the main Tauri application, spawned from
/// the `.setup()` hook on a dedicated OS thread (Tauri manages its own
/// async runtime, so we use std::net to avoid tokio dependency conflicts).
///
/// The Tauri app is the real PanLL — this server exists solely for groove
/// discovery by other services in the mesh.
pub fn spawn() {
    std::thread::Builder::new()
        .name("panll-groove".into())
        .spawn(|| {
            if let Err(e) = run() {
                eprintln!("[groove] Server exited with error: {}", e);
            }
        })
        .expect("Failed to spawn groove server thread");

    // Start the mesh health monitor (probes peers every 30s).
    spawn_mesh_monitor();
}

/// Run the groove discovery HTTP server (blocking).
fn run() -> Result<(), Box<dyn std::error::Error>> {
    let addr: SocketAddr = "127.0.0.1:8000".parse()?;
    let listener = TcpListener::bind(addr)?;
    println!("[groove] PanLL groove endpoint listening on {}", addr);

    for stream in listener.incoming() {
        match stream {
            Ok(mut stream) => {
                if let Err(e) = handle_request(&mut stream) {
                    eprintln!("[groove] Request error: {}", e);
                }
            }
            Err(e) => {
                eprintln!("[groove] Accept error: {}", e);
            }
        }
    }

    Ok(())
}

/// Handle a single groove HTTP request.
fn handle_request(stream: &mut TcpStream) -> Result<(), Box<dyn std::error::Error>> {
    let mut buf = vec![0u8; MAX_REQUEST_SIZE];
    let n = stream.read(&mut buf)?;
    let request = std::str::from_utf8(&buf[..n])?;

    let first_line = request.lines().next().unwrap_or("");
    let parts: Vec<&str> = first_line.split_whitespace().collect();
    if parts.len() < 2 {
        send_response(stream, 400, "text/plain", "Bad Request")?;
        return Ok(());
    }

    let method = parts[0];
    let path = parts[1];

    match (method, path) {
        // GET /.well-known/groove — Return the capability manifest.
        ("GET", "/.well-known/groove") => {
            send_response(stream, 200, "application/json", MANIFEST)?;
        }

        // GET /.well-known/groove/status — Health status for mesh probing.
        ("GET", "/.well-known/groove/status") => {
            send_response(
                stream,
                200,
                "application/json",
                r#"{"status":"ok","service":"panll","groove_version":"1"}"#,
            )?;
        }

        // GET /.well-known/groove/mesh — Return the cached mesh health view.
        ("GET", "/.well-known/groove/mesh") => {
            let mesh_json = build_mesh_json();
            send_response(stream, 200, "application/json", &mesh_json)?;
        }

        // POST /.well-known/groove/feedback — Receive feedback routed via Groove.
        //
        // Schema: { "type": "feedback", "target_service": string,
        //           "category": string, "message": string, "metadata": object }
        //
        // If target_service == "panll", saves locally via feedback::commands.
        // Otherwise, routes to the target service through the mesh.
        ("POST", "/.well-known/groove/feedback") => {
            let body = extract_body(request);
            handle_groove_feedback(stream, &body)?;
        }

        // GET /health — Simple health check.
        ("GET", "/health") => {
            send_response(
                stream,
                200,
                "application/json",
                r#"{"status":"ok","service":"panll"}"#,
            )?;
        }

        // Unknown route.
        _ => {
            send_response(stream, 404, "text/plain", "Not Found")?;
        }
    }

    Ok(())
}

/// Extract the HTTP body from a raw request string.
///
/// Finds the blank line separating headers from body and returns everything
/// after it. Returns an empty string if no body is present.
fn extract_body(request: &str) -> String {
    if let Some(idx) = request.find("\r\n\r\n") {
        request[idx + 4..].to_string()
    } else if let Some(idx) = request.find("\n\n") {
        request[idx + 2..].to_string()
    } else {
        String::new()
    }
}

/// Handle a POST /.well-known/groove/feedback request.
///
/// Validates the feedback JSON, saves it locally if targeted at PanLL,
/// or attempts to route it to the target service via the mesh.
fn handle_groove_feedback(
    stream: &mut TcpStream,
    body: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let parsed: Result<serde_json::Value, _> = serde_json::from_str(body);
    let feedback = match parsed {
        Ok(v) => v,
        Err(_) => {
            send_response(stream, 400, "application/json", r#"{"ok":false,"error":"invalid JSON"}"#)?;
            return Ok(());
        }
    };

    let target = feedback
        .get("target_service")
        .and_then(|v| v.as_str())
        .unwrap_or("panll");

    if target == "panll" {
        // Save locally — delegate to feedback module's storage.
        let dir = dirs::home_dir()
            .map(|h| h.join(".panll").join("feedback"))
            .ok_or("Cannot determine home directory")?;
        let _ = std::fs::create_dir_all(&dir);

        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis();

        let wrapped = serde_json::json!({
            "id": format!("groove-feedback-{timestamp}"),
            "timestamp": timestamp,
            "source": "groove",
            "report": feedback,
        });

        let filepath = dir.join(format!("{timestamp}.json"));
        let content = serde_json::to_string_pretty(&wrapped).unwrap_or_default();
        let _ = std::fs::write(&filepath, content);

        let resp = serde_json::json!({
            "ok": true,
            "routed_to": "panll",
            "id": format!("groove-feedback-{timestamp}"),
        });
        send_response(stream, 200, "application/json", &resp.to_string())?;
    } else {
        // Route to the target service via the mesh.
        match route_feedback_to_peer(target, body) {
            Ok(()) => {
                let resp = serde_json::json!({
                    "ok": true,
                    "routed_to": target,
                });
                send_response(stream, 200, "application/json", &resp.to_string())?;
            }
            Err(e) => {
                let resp = serde_json::json!({
                    "ok": false,
                    "error": format!("routing failed: {e}"),
                    "target_service": target,
                });
                send_response(stream, 502, "application/json", &resp.to_string())?;
            }
        }
    }

    Ok(())
}

/// Attempt to route feedback to a peer service in the mesh.
///
/// Looks up the peer's port from the cached mesh state and POSTs the
/// feedback to their `/.well-known/groove/feedback` endpoint.
fn route_feedback_to_peer(target: &str, body: &str) -> Result<(), Box<dyn std::error::Error>> {
    let peers = MESH_STATE.lock().map_err(|_| "mesh lock poisoned")?;
    let peer = peers
        .iter()
        .find(|p| p.service_id == target && p.status == "up")
        .ok_or_else(|| format!("peer '{target}' not found or not up in mesh"))?;

    let addr = format!("127.0.0.1:{}", peer.port);
    let mut stream = TcpStream::connect(&addr)?;
    stream.set_write_timeout(Some(std::time::Duration::from_secs(2)))?;
    stream.set_read_timeout(Some(std::time::Duration::from_secs(2)))?;

    let request = format!(
        "POST /.well-known/groove/feedback HTTP/1.0\r\nHost: {}\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
        addr,
        body.len(),
        body
    );
    stream.write_all(request.as_bytes())?;
    Ok(())
}

/// Build a JSON string representing the current mesh health view.
fn build_mesh_json() -> String {
    let peers = MESH_STATE.lock().unwrap_or_else(|e| e.into_inner());
    let now_ms = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64;

    let peer_entries: Vec<String> = peers
        .iter()
        .map(|p| {
            format!(
                r#"{{"service_id":"{}","port":{},"status":"{}","last_seen_ms":{}}}"#,
                p.service_id, p.port, p.status, p.last_seen_ms
            )
        })
        .collect();

    format!(
        r#"{{"service_id":"panll","timestamp_ms":{},"peers":[{}]}}"#,
        now_ms,
        peer_entries.join(",")
    )
}

/// Probe known groove peers and update the cached mesh state.
///
/// Called periodically from the mesh monitor thread. For each port in
/// `MESH_PROBE_PORTS`, sends `GET /.well-known/groove/status` and records
/// the result (up/down + service_id).
pub fn probe_mesh_peers() {
    let now_ms = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64;

    let mut results = Vec::new();

    for &port in MESH_PROBE_PORTS {
        // Skip our own port.
        if port == 8000 {
            continue;
        }

        let addr = format!("127.0.0.1:{}", port);
        let status = match TcpStream::connect_timeout(
            &addr.parse().unwrap(),
            std::time::Duration::from_millis(500),
        ) {
            Ok(mut stream) => {
                stream
                    .set_read_timeout(Some(std::time::Duration::from_millis(500)))
                    .ok();
                stream
                    .set_write_timeout(Some(std::time::Duration::from_millis(500)))
                    .ok();

                let request = format!(
                    "GET /.well-known/groove/status HTTP/1.0\r\nHost: {}\r\nConnection: close\r\n\r\n",
                    addr
                );
                if stream.write_all(request.as_bytes()).is_ok() {
                    let mut buf = vec![0u8; 4096];
                    let service_id = match stream.read(&mut buf) {
                        Ok(n) if n > 0 => {
                            let resp = String::from_utf8_lossy(&buf[..n]);
                            // Extract service_id from JSON body.
                            extract_service_id_from_response(&resp)
                        }
                        _ => "unknown".to_string(),
                    };
                    PeerHealth {
                        service_id,
                        port,
                        status: "up".to_string(),
                        last_seen_ms: now_ms,
                    }
                } else {
                    PeerHealth {
                        service_id: "unknown".to_string(),
                        port,
                        status: "down".to_string(),
                        last_seen_ms: 0,
                    }
                }
            }
            Err(_) => PeerHealth {
                service_id: "unknown".to_string(),
                port,
                status: "down".to_string(),
                last_seen_ms: 0,
            },
        };

        // Only include peers that responded (up or previously known).
        if status.status == "up" {
            results.push(status);
        }
    }

    if let Ok(mut state) = MESH_STATE.lock() {
        *state = results;
    }
}

/// Extract the service_id field from a groove status JSON response.
///
/// Performs a simple substring search to avoid pulling in a full JSON parser
/// for probe responses. Falls back to "unknown" if not found.
fn extract_service_id_from_response(response: &str) -> String {
    // Find the JSON body (after headers).
    let body = if let Some(idx) = response.find("\r\n\r\n") {
        &response[idx + 4..]
    } else if let Some(idx) = response.find("\n\n") {
        &response[idx + 2..]
    } else {
        response
    };

    // Try to parse as JSON for the service_id field.
    if let Ok(v) = serde_json::from_str::<serde_json::Value>(body) {
        if let Some(id) = v.get("service").and_then(|s| s.as_str()) {
            return id.to_string();
        }
        if let Some(id) = v.get("service_id").and_then(|s| s.as_str()) {
            return id.to_string();
        }
    }

    "unknown".to_string()
}

/// Spawn the mesh health monitor thread.
///
/// Probes known groove peers every 30 seconds and updates the cached mesh
/// state. This runs alongside the groove HTTP server.
pub fn spawn_mesh_monitor() {
    std::thread::Builder::new()
        .name("panll-mesh-monitor".into())
        .spawn(|| {
            loop {
                probe_mesh_peers();
                std::thread::sleep(std::time::Duration::from_secs(30));
            }
        })
        .expect("Failed to spawn mesh monitor thread");
}

/// Send an HTTP response with the given content type and body.
fn send_response(
    stream: &mut TcpStream,
    status: u16,
    content_type: &str,
    body: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let status_text = match status {
        200 => "OK",
        204 => "No Content",
        400 => "Bad Request",
        404 => "Not Found",
        502 => "Bad Gateway",
        _ => "Unknown",
    };
    let response = format!(
        "HTTP/1.0 {} {}\r\nContent-Type: {}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
        status,
        status_text,
        content_type,
        body.len(),
        body
    );
    stream.write_all(response.as_bytes())?;
    Ok(())
}
