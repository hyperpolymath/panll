// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
//! Tauri compatibility shim for Gossamer migration.
//!
//! Provides `AppHandle` and `Emitter` replacements so that modules which
//! previously relied on `tauri::AppHandle` for event emission can continue
//! working with minimal changes. Events are delivered to the frontend via
//! Gossamer's `gossamer_eval()` (injecting JS into the webview), which is
//! functionally equivalent to Tauri's event system.
//!
//! This shim is intentionally minimal — it covers only the patterns used
//! in the PanLL codebase (emit string events, spawn async tasks). Modules
//! that need richer capabilities should be refactored to use gossamer-rs
//! directly.

use std::sync::{Arc, Mutex};
use once_cell::sync::Lazy;
use serde::Serialize;

/// Global event bus — collects events that the main loop will flush to the webview.
///
/// In the Tauri architecture, `app.emit("channel", payload)` pushes an event
/// through Tauri's internal IPC. Here we queue events and the Gossamer main
/// loop (or a dedicated flush thread) will deliver them via `gossamer_eval()`.
static EVENT_BUS: Lazy<Arc<Mutex<Vec<PendingEvent>>>> =
    Lazy::new(|| Arc::new(Mutex::new(Vec::new())));

/// A queued event waiting to be delivered to the frontend.
#[derive(Debug, Clone)]
pub struct PendingEvent {
    /// Event channel name (e.g. "watcher://event", "ai:stream-chunk").
    pub channel: String,
    /// JSON-serialised payload.
    pub payload: String,
}

/// Gossamer-compatible application handle.
///
/// Drop-in replacement for `tauri::AppHandle`. Cloneable and Send + Sync
/// so it can be passed to background threads and async tasks.
#[derive(Clone)]
pub struct AppHandle {
    // Reserved for future Gossamer handle reference.
    _phantom: (),
}

impl AppHandle {
    /// Create a new AppHandle (called once during startup).
    pub fn new() -> Self {
        Self { _phantom: () }
    }
}

/// Emitter trait — mirrors `tauri::Emitter` for event emission.
///
/// Modules that `use tauri::Emitter;` can instead `use crate::compat::Emitter;`
/// and the `app_handle.emit(channel, payload)` calls compile unchanged.
pub trait Emitter {
    /// Emit an event to the frontend.
    fn emit<S: Serialize>(&self, channel: &str, payload: &S) -> Result<(), String>;
}

impl Emitter for AppHandle {
    fn emit<S: Serialize>(&self, channel: &str, payload: &S) -> Result<(), String> {
        let json = serde_json::to_string(payload)
            .map_err(|e| format!("Event serialisation error: {e}"))?;
        let event = PendingEvent {
            channel: channel.to_string(),
            payload: json,
        };
        EVENT_BUS
            .lock()
            .map_err(|e| format!("Event bus lock error: {e}"))?
            .push(event);
        Ok(())
    }
}

/// Drain all pending events from the bus.
///
/// Called by the Gossamer main loop to deliver queued events to the webview.
/// Each event is injected as:
///   `window.dispatchEvent(new CustomEvent(channel, { detail: payload }))`
pub fn drain_events() -> Vec<PendingEvent> {
    EVENT_BUS
        .lock()
        .map(|mut bus| std::mem::take(&mut *bus))
        .unwrap_or_default()
}

/// Spawn an async task on the Tokio runtime.
///
/// Replaces `tauri::async_runtime::spawn()`. Uses the global Tokio runtime
/// initialised in main.rs.
pub fn spawn_async<F>(future: F)
where
    F: std::future::Future<Output = ()> + Send + 'static,
{
    tokio::spawn(future);
}
