// SPDX-License-Identifier: MPL-2.0

//! PanLL Valence Shell Module — Rust backend for the terminal/PTY panel.
//!
//! Provides Tauri commands for PTY session management, asciicast recording,
//! checkpoint/restore, and terminal screenshots. All persistent state is
//! stored under `/tmp/panll/` (recordings and checkpoints).
//!
//! Real PTY integration will be added via `tauri-plugin-shell` in a future
//! iteration; the current implementation uses stubs that return plausible
//! responses so the ReScript frontend can be developed in parallel.

pub mod commands;
