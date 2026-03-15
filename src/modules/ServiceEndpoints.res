// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Service Endpoints — centralised default URLs for all backend services.
///
/// All hardcoded localhost URLs are defined here so they can be overridden
/// from environment variables or configuration files without modifying
/// individual engine/model files.
///
/// panic-attack:allow insecure-protocol — all URLs are localhost/loopback
/// development endpoints. Local services do not run TLS. Production
/// deployments override these via environment variables or config files.

/// VeriSimDB octad multimodal database.
let verisimdb = "http://localhost:8080/api/v1"

/// QuandleDB algebraic query database.
let quandledb = "http://localhost:8081/api/v1"

/// LithoGlyph graph pattern database.
let lithoglyph = "http://localhost:8082/api/v1"

/// BoJ (Bundle of Joy) cartridge gateway server.
let bojServer = "http://localhost:7700"

/// ECHIDNA proof assistant / multi-solver dispatch.
let echidna = "http://localhost:9000/api/v1"

/// Multiplayer Monitor WebSocket server.
let multiplayerMonitor = "ws://localhost:4000/socket/websocket"

/// Game Preview Vite dev server.
let gamePreviewDev = "http://localhost:8080"

/// Migration backend (VeriSimDB-backed).
let migrationBackend = "http://localhost:8080/api/v1"
