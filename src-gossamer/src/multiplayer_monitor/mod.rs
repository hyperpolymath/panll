// SPDX-License-Identifier: MPL-2.0

//! Multiplayer Monitor — IDApTIK Phoenix sync server monitoring module.
//!
//! Provides Tauri command handlers for the Multiplayer Monitor panel:
//! WebSocket connectivity to the Elixir/Phoenix sync server, player state
//! inspection, state diff analysis, ETS cache browsing, and reconnection
//! testing.

pub mod commands;
