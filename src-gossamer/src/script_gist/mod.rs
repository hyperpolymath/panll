// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Script Gist Module — Persistent storage and execution dispatch
//! for portable computation gists.
//!
//! Saves gist state as timestamped JSON files under `~/.panll/gists/`.
//! Execution is dispatched to the appropriate backend target via BoJ
//! cartridge invocation or local subprocess.

pub mod commands;
