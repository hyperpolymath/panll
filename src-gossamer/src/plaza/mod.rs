// SPDX-License-Identifier: MPL-2.0

//! PanLL Palimpsest Plaza Module — Rust backend for the PMPL licensing panel.
//!
//! Scans repositories for PMPL compliance (SPDX headers, LICENSE files,
//! exhibits, provenance signatures) and provides adoption statistics.
//! Uses the local `pmpl-audit` CLI tool when available, with a built-in
//! fallback scanner for basic checks.

pub mod types;
pub mod commands;
