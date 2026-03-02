// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Watcher — Filesystem observation infrastructure.
//!
//! Uses the `notify` crate (inotify on Linux, FSEvents on macOS, ReadDirectoryChanges
//! on Windows) to watch directories for changes and emit Tauri events that the
//! ReScript TEA loop can subscribe to. Every panel can react to relevant file
//! events: Farm sees new repos, Plaza detects LICENSE changes, Hypatia re-scans
//! on code modifications, Reposystem checks compliance on file additions.
//!
//! Architecture:
//!   1. `watcher_start` — Tauri command that spawns a background watcher thread
//!   2. `watcher_stop`  — Tauri command that stops the background watcher
//!   3. `watcher_add_path` / `watcher_remove_path` — Dynamic path management
//!   4. Events emitted as `watcher://event` on the Tauri event bus
//!
//! The watcher is debounced (500ms) to avoid flooding the TEA loop with
//! rapid successive events from editors that write-then-rename.

pub mod types;
pub mod commands;
