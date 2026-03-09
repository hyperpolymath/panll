// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Fleet Module — Rust backend for the Gitbot-Fleet panel.
//!
//! Connects to the gitbot-fleet Axum dashboard API at :8080 for bot status,
//! findings queue, and dispatch operations. When the fleet server is offline,
//! commands return sensible fallback data (all bots "offline", empty findings)
//! so the panel always renders something useful.

pub mod commands;
