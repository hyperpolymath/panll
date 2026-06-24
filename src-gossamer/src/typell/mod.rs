// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! TypeLL — Type-Level Language server bridge module.
//!
//! Provides Tauri command handlers for interacting with the TypeLL server,
//! which manages dependent type checking, refinement types, and type-level
//! computation for the PanLL environment.
//!
//! Default endpoint: http://localhost:7800/api/v1

pub mod commands;
