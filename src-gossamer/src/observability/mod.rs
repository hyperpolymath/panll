// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Observability — observe-mcp BoJ cartridge bridge module.
//!
//! Provides Tauri command handlers for SARIF export, OpenTelemetry trace
//! collection, and observability summary via the observe-mcp cartridge.
//!
//! Routes through the BoJ server when bojRouting is enabled, otherwise
//! operates standalone with mock responses.

pub mod commands;
