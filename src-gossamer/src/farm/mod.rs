// SPDX-License-Identifier: MPL-2.0

//! PanLL Farm Module — Rust backend for the Git-Private-Farm panel.
//!
//! Reads the farm manifest from `~/.git-private-farm/farm-manifest.json` and
//! exposes it to the ReScript frontend via Tauri commands. No HTTP service
//! required — this is purely filesystem-based.

pub mod types;
pub mod commands;
