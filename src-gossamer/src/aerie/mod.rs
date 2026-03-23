// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Aerie Module — Rust backend for network diagnostics.
//!
//! Provides latency measurement via std::net::TcpStream and download speed
//! testing via reqwest. These are lightweight probes that run directly from
//! the Tauri backend without requiring an external service.

pub mod commands;
