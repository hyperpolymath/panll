// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
//! Backend → frontend event bus and async-spawn helpers.
//!
//! Provides an `AppHandle` and an `Emitter` trait so backend modules can emit
//! events without depending on the webview shell. Events are queued here and
//! delivered to the frontend via Gossamer's `gossamer_eval()` (injecting JS
//! into the webview).
//!
//! This layer is intentionally minimal — it covers only the patterns used
//! in the PanLL codebase (emit string events, spawn async tasks). Modules
//! that need richer capabilities should be refactored to use gossamer-rs
//! directly.

use once_cell::sync::Lazy;
use serde::Serialize;
use std::sync::{Arc, Mutex};

/// Global event bus — collects events that the main loop will flush to the webview.
///
/// `app.emit("channel", payload)` queues an event here; the Gossamer main
/// loop (or a dedicated flush thread) delivers it via `gossamer_eval()`.
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

/// Application handle used to emit events to the frontend.
///
/// Cloneable and Send + Sync so it can be passed to background threads and
/// async tasks.
#[derive(Clone, Default)]
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

/// Emitter trait — event emission to the frontend.
///
/// Modules `use crate::compat::Emitter;` and call
/// `app_handle.emit(channel, payload)`.
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
/// Must be called from within a Tokio runtime context (`tokio::spawn` panics
/// otherwise).
pub fn spawn_async<F>(future: F)
where
    F: std::future::Future<Output = ()> + Send + 'static,
{
    tokio::spawn(future);
}
