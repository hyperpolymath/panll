// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! PanLL Gossamer backend — testable logic library.
//!
//! This crate holds the backend logic that does **not** depend on the
//! Gossamer webview shell (`gossamer-rs`) or the GTK/WebKit native stack.
//! Keeping it as a library means `cargo test --lib` builds and runs the unit
//! suite without linking `libgossamer` or `libgtk-3` / `libwebkit2gtk`.
//!
//! The `panll-gossamer` binary (`main.rs`) depends on this library for all
//! business logic and adds only the IPC/webview wiring and the
//! GTK-coupled `system_tray` module.

/// Shared HTTP client for backend service connections.
pub mod http_client;

/// Service Registry — centralized lifecycle management for backend services.
pub mod service_registry;

/// Settings — user configuration persistence and management.
pub mod settings;

/// Identity — named identity snapshots and team replication.
pub mod identity;

/// Groove — Gossamer groove discovery endpoint (port 8000).
pub mod groove;

/// LLM Coding — multi-session Claude/LLM coordinator.
pub mod llm_coding;

/// Coprocessor — external compute control plane + Zig FFI data plane.
///
/// Previously orphaned (declared by no crate root, so never compiled). Wired
/// into the library here so it builds, lints, and its tests run. Note: the
/// async command handlers are not yet registered in the binary's IPC table —
/// that integration is tracked as follow-up debt (see TECHNICAL_DEBT.md).
pub mod coprocessor;
