// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! BoJ — Barrel of Jelly server bridge module.
//!
//! Provides Tauri command handlers for interacting with the BoJ cartridge
//! runtime. Each cartridge exposes domain-specific MCP services (data, network,
//! security, etc.) via the BoJ server's REST API.
//!
//! Default endpoint: http://localhost:7700/api/v1

pub mod commands;
