// SPDX-License-Identifier: PMPL-1.0-or-later

//! Watcher Tauri commands — start/stop/manage filesystem observation.
//!
//! The watcher runs on a background thread using `notify-debouncer-mini` and
//! emits `watcher://event` Tauri events that the ReScript TEA loop subscribes
//! to. Commands are designed to be safe to call multiple times (idempotent
//! start/stop) and to survive the watched directory not existing yet.
//!
//! We use `notify` (https://docs.rs/notify) which wraps inotify/FSEvents/
//! ReadDirectoryChangesW per-platform behind a unified API. The alternative
//! in Go (`fsnotify`) has a long history of goroutine leaks on recursive
//! watches and platform-specific edge cases that silently drop events. Rust's
//! ownership model means the watcher thread cleans up deterministically when
//! stopped — no finalizer, no GC delay, no leaked file descriptors. The
//! `Arc<Mutex<WatcherState>>` below looks verbose, but the compiler proves
//! at compile time that no two threads access state simultaneously. Try
//! getting that guarantee from a Go `sync.Mutex` — you'll get a runtime
//! panic if you're lucky, a silent data race if you're not.

use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use notify::RecursiveMode;
use notify_debouncer_mini::{new_debouncer, DebouncedEventKind};
use once_cell::sync::Lazy;
use serde_json::json;
use crate::compat::Emitter;

use super::types::{WatchEvent, WatchEventKind, WatcherStatus};

/// Global watcher state — holds the debouncer handle and watched paths.
///
/// Using a Mutex rather than Tauri managed state so that commands can be
/// registered as plain functions without needing the app handle at registration
/// time. The watcher thread holds a clone of the AppHandle for event emission.
struct WatcherState {
    /// The debouncer handle. `Some` when running, `None` when stopped.
    debouncer: Option<notify_debouncer_mini::Debouncer<notify::RecommendedWatcher>>,
    /// Paths currently being watched.
    watched_paths: Vec<PathBuf>,
    /// Total events emitted since last start.
    event_count: u64,
}

static WATCHER: Lazy<Arc<Mutex<WatcherState>>> = Lazy::new(|| {
    Arc::new(Mutex::new(WatcherState {
        debouncer: None,
        watched_paths: Vec::new(),
        event_count: 0,
    }))
});

/// Convert a `notify_debouncer_mini::DebouncedEventKind` into our simplified enum.
fn classify_event(kind: &DebouncedEventKind) -> WatchEventKind {
    match kind {
        DebouncedEventKind::Any => WatchEventKind::Modified,
        DebouncedEventKind::AnyContinuous => WatchEventKind::Modified,
        _ => WatchEventKind::Other,
    }
}

/// Build a `WatchEvent` from a debounced event path and kind.
fn build_watch_event(path: &std::path::Path, kind: WatchEventKind) -> WatchEvent {
    let is_dir = path.is_dir();
    let extension = path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_string();
    let filename = path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("")
        .to_string();
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs_f64())
        .unwrap_or(0.0);

    WatchEvent {
        path: path.to_string_lossy().to_string(),
        kind,
        is_dir,
        timestamp,
        extension,
        filename,
    }
}

/// Start the filesystem watcher on the given paths.
///
/// If the watcher is already running, this stops it first and restarts with
/// the new path set. Debounce interval is 500ms to coalesce rapid writes.
///
/// Events are emitted on the `watcher://event` channel as JSON-serialised
/// `WatchEvent` objects that the ReScript `WatcherCmd.listen` function
/// deserialises into TEA messages.

pub async fn watcher_start(
    app: crate::compat::AppHandle,
    paths: Vec<String>,
) -> Result<String, String> {
    let mut state = WATCHER.lock().map_err(|e| format!("Lock error: {e}"))?;

    // Stop existing watcher if running.
    state.debouncer = None;
    state.watched_paths.clear();
    state.event_count = 0;

    let app_handle = app.clone();
    let event_counter = Arc::clone(&WATCHER);

    // Create debounced watcher with 500ms debounce interval.
    let mut debouncer = new_debouncer(
        Duration::from_millis(500),
        move |result: Result<Vec<notify_debouncer_mini::DebouncedEvent>, notify::Error>| {
            match result {
                Ok(events) => {
                    for event in events {
                        let kind = classify_event(&event.kind);
                        let watch_event = build_watch_event(&event.path, kind);

                        // Increment event counter.
                        if let Ok(mut s) = event_counter.lock() {
                            s.event_count += 1;
                        }

                        // Emit to the frontend via Tauri event bus.
                        let payload = serde_json::to_string(&watch_event).unwrap_or_default();
                        let _ = app_handle.emit("watcher://event", payload);
                    }
                }
                Err(e) => {
                    let _ = app_handle.emit(
                        "watcher://error",
                        json!({ "error": format!("{e}") }).to_string(),
                    );
                }
            }
        },
    )
    .map_err(|e| format!("Failed to create watcher: {e}"))?;

    // Watch each path recursively.
    let mut watched = Vec::new();
    for path_str in &paths {
        let path = PathBuf::from(path_str);
        if path.exists() {
            debouncer
                .watcher()
                .watch(&path, RecursiveMode::Recursive)
                .map_err(|e| format!("Failed to watch {path_str}: {e}"))?;
            watched.push(path);
        }
        // Skip non-existent paths silently — they may appear later.
    }

    let count = watched.len();
    state.watched_paths = watched;
    state.debouncer = Some(debouncer);

    Ok(json!({
        "status": "started",
        "watching": count,
        "paths": paths,
    })
    .to_string())
}

/// Stop the filesystem watcher.
///
/// Idempotent — safe to call even if the watcher is not running.

pub async fn watcher_stop() -> Result<String, String> {
    let mut state = WATCHER.lock().map_err(|e| format!("Lock error: {e}"))?;
    state.debouncer = None;
    state.watched_paths.clear();

    Ok(json!({ "status": "stopped" }).to_string())
}

/// Add a path to the running watcher.
///
/// If the watcher is not running, returns an error suggesting `watcher_start`
/// should be called first. The path is watched recursively.

pub async fn watcher_add_path(path: String) -> Result<String, String> {
    let mut state = WATCHER.lock().map_err(|e| format!("Lock error: {e}"))?;

    let debouncer = state
        .debouncer
        .as_mut()
        .ok_or("Watcher not running — call watcher_start first")?;

    let watch_path = PathBuf::from(&path);
    if !watch_path.exists() {
        return Err(format!("Path does not exist: {path}"));
    }

    debouncer
        .watcher()
        .watch(&watch_path, RecursiveMode::Recursive)
        .map_err(|e| format!("Failed to watch {path}: {e}"))?;

    state.watched_paths.push(watch_path);

    Ok(json!({
        "status": "added",
        "path": path,
        "total_watched": state.watched_paths.len(),
    })
    .to_string())
}

/// Remove a path from the running watcher.
///
/// If the watcher is not running or the path is not being watched, this
/// returns gracefully without error (idempotent).

pub async fn watcher_remove_path(path: String) -> Result<String, String> {
    let mut state = WATCHER.lock().map_err(|e| format!("Lock error: {e}"))?;

    if let Some(debouncer) = state.debouncer.as_mut() {
        let watch_path = PathBuf::from(&path);
        // Unwatch — ignore errors if path wasn't watched.
        let _ = debouncer.watcher().unwatch(&watch_path);
        state.watched_paths.retain(|p| p != &watch_path);
    }

    Ok(json!({
        "status": "removed",
        "path": path,
        "total_watched": state.watched_paths.len(),
    })
    .to_string())
}

/// Get the current watcher status.
///
/// Returns whether the watcher is running, which paths are watched, and
/// the total event count since last start.

pub async fn watcher_status() -> Result<String, String> {
    let state = WATCHER.lock().map_err(|e| format!("Lock error: {e}"))?;

    let status = WatcherStatus {
        running: state.debouncer.is_some(),
        watched_paths: state
            .watched_paths
            .iter()
            .map(|p| p.to_string_lossy().to_string())
            .collect(),
        event_count: state.event_count,
    };

    serde_json::to_string(&status).map_err(|e| format!("Serialise error: {e}"))
}
