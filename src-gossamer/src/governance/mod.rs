// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Governance — Nesy-MCP bridge module.
//!
//! Provides Tauri command handlers for routing governance decisions through
//! the BoJ nesy-mcp cartridge. When GovernanceEngine's `evaluateWithCmd`
//! encounters borderline conditions it cannot resolve purely, these commands
//! consult the neural subsystem for real-time validation.
//!
//! Default endpoint: http://localhost:7700/api/v1 (shared with BoJ server)

pub mod commands;
