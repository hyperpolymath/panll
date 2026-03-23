// SPDX-License-Identifier: PMPL-1.0-or-later

//! Watcher types — filesystem event representation.
//!
//! These types are serialised to JSON and emitted as Tauri events. The
//! ReScript frontend deserialises them into the TEA message stream.

use serde::{Deserialize, Serialize};

/// The kind of filesystem change detected.
///
/// Mapped from `notify::EventKind` into a simplified enum that the
/// frontend can pattern-match without knowing inotify internals.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum WatchEventKind {
    /// A new file or directory was created.
    Created,
    /// An existing file was modified (content change).
    Modified,
    /// A file or directory was removed.
    Removed,
    /// A file or directory was renamed (old path → new path).
    Renamed,
    /// Something changed but we can't classify it further.
    Other,
}

/// A single filesystem event, debounced and enriched with metadata.
///
/// This is the payload emitted on the `watcher://event` Tauri event channel.
/// The ReScript layer receives this as a JSON object and routes it to
/// interested panels via the Watcher message type.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WatchEvent {
    /// The absolute path that changed.
    pub path: String,
    /// What kind of change occurred.
    pub kind: WatchEventKind,
    /// Whether the path is a directory (true) or file (false).
    pub is_dir: bool,
    /// Unix timestamp (seconds since epoch) when the event was detected.
    pub timestamp: f64,
    /// The file extension, if any (e.g., "rs", "res", "toml"). Empty string
    /// for directories or files without extensions.
    pub extension: String,
    /// The filename component (e.g., "Cargo.toml", "main.rs").
    pub filename: String,
}

/// Current state of the watcher subsystem, returned by `watcher_status`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WatcherStatus {
    /// Whether the watcher is currently running.
    pub running: bool,
    /// Paths currently being watched.
    pub watched_paths: Vec<String>,
    /// Total number of events emitted since the watcher started.
    pub event_count: u64,
}
