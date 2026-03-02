// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL WatcherModel — Filesystem observation state types.
///
/// The Watcher is CORE INFRASTRUCTURE, not a panel. It feeds events into the
/// TEA loop so every panel can react to filesystem changes: Farm sees new repos,
/// Plaza detects LICENSE changes, Hypatia re-scans on code modifications,
/// Reposystem checks compliance when files are added or removed.
///
/// Events arrive via Tauri's event bus (`watcher://event`) and are debounced
/// at 500ms on the Rust side to avoid flooding the TEA loop.

/// The kind of filesystem change detected by the watcher.
///
/// Simplified from the full `notify::EventKind` taxonomy into categories
/// that panels can meaningfully react to.
type watchEventKind =
  /// A new file or directory was created.
  | Created
  /// An existing file's content was modified.
  | Modified
  /// A file or directory was removed.
  | Removed
  /// A file or directory was renamed.
  | Renamed
  /// Something changed but classification is uncertain.
  | Other

/// A single filesystem event, debounced and enriched with metadata.
///
/// This is the payload received from the Rust watcher via the Tauri event bus.
/// Each event carries enough information for panels to decide whether they
/// care about it (extension, filename, path prefix matching).
type watchEvent = {
  /// The absolute path that changed.
  path: string,
  /// What kind of change occurred.
  kind: watchEventKind,
  /// Whether the changed path is a directory.
  isDir: bool,
  /// Unix timestamp (seconds) when the event was detected.
  timestamp: float,
  /// File extension without dot (e.g., "rs", "res", "toml"). Empty for
  /// directories or files without extensions.
  extension: string,
  /// Filename component (e.g., "Cargo.toml", "LICENSE").
  filename: string,
}

/// Current operational state of the Watcher subsystem.
type watcherState = {
  /// Whether the Rust watcher is currently running.
  running: bool,
  /// Paths currently being watched (absolute paths).
  watchedPaths: array<string>,
  /// Total events received since the watcher was last started.
  eventCount: int,
  /// Most recent events (ring buffer, last 50).
  recentEvents: array<watchEvent>,
  /// Last error from the watcher, if any.
  error: option<string>,
}
