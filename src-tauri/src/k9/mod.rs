// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! K9 — Contractile validation and layout management module.
//!
//! Provides Tauri command handlers for loading, validating, and applying K9
//! contractile files (.k9.ncl). K9 files are Nickel-based self-validating
//! components with three security levels:
//!   - Kennel: Pure data, no execution
//!   - Yard: Configuration with Nickel contracts
//!   - Hunt: Full execution with Just recipes (requires signature)
//!
//! K9 layout presets define PanLL panel arrangements for different disciplines
//! (protocol design, database work, logic & proofs, language design).

pub mod commands;
