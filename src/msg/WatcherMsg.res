// SPDX-License-Identifier: PMPL-1.0-or-later

/// Watcher messages -- filesystem observation infrastructure.
/// The watcher runs in a Rust background thread and emits events via the
/// Gossamer event bus. These messages handle lifecycle (start/stop/status)
/// and incoming filesystem events that panels can react to.

open Model

type watcherMsg =
  /// Start watching the given paths.
  | StartWatcher(array<string>)
  /// Stop the filesystem watcher.
  | StopWatcher
  /// Request current watcher status.
  | RequestStatus
  /// Watcher lifecycle result (start/stop/add/remove responses).
  | WatcherResult(result<string, string>)
  /// Status response from the backend.
  | StatusLoaded(result<string, string>)
  /// A filesystem event arrived from the Rust watcher.
  | FileEvent(watchEvent)
