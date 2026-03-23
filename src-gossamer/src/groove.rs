// SPDX-License-Identifier: PMPL-1.0-or-later
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

/// Send an HTTP response with the given content type and body.
fn send_response(
    stream: &mut TcpStream,
    status: u16,
    content_type: &str,
    body: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let status_text = match status {
        200 => "OK",
        400 => "Bad Request",
        404 => "Not Found",
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
