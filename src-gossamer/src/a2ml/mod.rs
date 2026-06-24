// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! A2ML — AI Manifest parsing and validation module.
//!
//! Provides Tauri command handlers for loading, validating, and listing A2ML
//! manifest files. A2ML files are the universal AI agent entry point for
//! hyperpolymath repositories, containing canonical locations, critical
//! invariants, lifecycle hooks, and project metadata.
//!
//! The Rust backend handles filesystem I/O and basic structural validation.
//! Deeper semantic parsing and validation is performed client-side by the
//! ReScript A2mlEngine module.

pub mod commands;
