// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Overlay — Tor, IPFS, and Ethereum overlay network bridge module.
//!
//! Provides Tauri command handlers for interacting with overlay/decentralised
//! network components via the ECHIDNA overlay FFI (libechidna_overlay.so).
//! Each command follows the PanLL pattern: HTTP proxy to a V-lang adapter,
//! with env var overrides for non-default deployments.
//!
//! Networks:
//!   - **Tor**: Hidden service management, circuit status, SOCKS5 proxy
//!   - **IPFS**: Content-addressed storage, pinning, DAG traversal
//!   - **Ethereum**: Proof certificate timestamping (stubbed — Aerie future)

pub mod commands;
