// SPDX-License-Identifier: PMPL-1.0-or-later

/// TauriEvents — Tauri backend event subscriptions for real-time neurosymbolic streaming.
///
/// Wraps Tauri's `listen` API as TEA subscriptions so backend events
/// (ECHIDNA proof progress, agent broadcasts, FFI state changes) are
/// automatically dispatched into the TEA update loop.
///
/// S2: Bridges the gap between the Tauri backend (async, event-driven)
/// and the TEA frontend (synchronous, message-driven).
///
/// In browser-only mode (no Tauri runtime), all subscriptions gracefully
/// degrade to no-ops instead of crashing on missing __TAURI_INTERNALS__.

/// Detect whether the Tauri runtime is available. Returns false in
/// browser-only mode (dev server, headless testing, etc.).
%%raw(`
function isTauriAvailable() {
  return typeof window !== 'undefined'
    && window.__TAURI_INTERNALS__ != null
    && !window.__TAURI_INTERNALS__.__BROWSER_SHIM__;
}
`)
@val external isTauriAvailable: unit => bool = "isTauriAvailable"

/// Safe wrapper around Tauri.listen that returns a no-op subscription
/// when the Tauri runtime is absent. Prevents transformCallback crashes
/// in browser-only mode.
let safeListen = (key: string, eventName: string, tagger: string => 'msg): Tea_Sub.t<'msg> => {
  if !isTauriAvailable() {
    Tea_Sub.none
  } else {
    Tea_Sub.registration(key, dispatch => {
      let cleanup = ref(() => ())
      Tauri.listen(eventName, evt => {
        dispatch(tagger(evt.payload))
      })
      ->Promise.then(unlisten => {
        cleanup := unlisten
        Promise.resolve()
      })
      ->ignore
      () => cleanup.contents()
    })
  }
}

/// Listen for ECHIDNA proof progress events from the Rust backend.
/// The backend emits these when a proof session advances phases.
let onEchidnaProgress = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("tauri:echidna-progress", "echidna:proof-progress", tagger)
}

/// Listen for ECHIDNA tactic suggestions pushed from the backend.
let onEchidnaTactics = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("tauri:echidna-tactics", "echidna:tactic-suggestions", tagger)
}

/// Listen for Tentacles agent phase changes from the FFI bridge.
/// Emitted when an agent transitions between OODA phases.
let onTentaclesPhaseChange = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("tauri:tentacles-phase", "tentacles:phase-change", tagger)
}

/// Listen for Tentacles agent broadcast messages.
let onTentaclesBroadcast = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("tauri:tentacles-broadcast", "tentacles:broadcast", tagger)
}

/// Listen for VeriSimDB drift alerts pushed from the backend.
let onVeriSimDBDrift = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("tauri:verisimdb-drift", "verisimdb:drift-alert", tagger)
}

/// Listen for Hypatia neural network status changes.
let onHypatiaStatus = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("tauri:hypatia-status", "hypatia:network-status", tagger)
}

/// Listen for governance halt/resume signals from the backend.
let onGovernanceSignal = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("tauri:governance-signal", "governance:signal", tagger)
}

/// Listen for AI streaming chunks from the Anthropic SSE provider.
/// Each chunk is a JSON-serialised StreamChunk from the Rust backend.
/// The frontend parses these in the AI update handler.
let onAiStreamChunk = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("tauri:ai-stream-chunk", "ai:stream-chunk", tagger)
}

/// Listen for filesystem watcher events from the Rust backend.
/// The watcher runs in a background thread and emits events on
/// `watcher://event` when files are created, modified, removed, or renamed.
/// Panels like Farm, Hypatia, Reposystem, and Plaza subscribe to these
/// for automatic refresh when project files change on disk.
let onWatcherEvent = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("tauri:watcher-event", "watcher://event", tagger)
}

/// Listen for watcher error events from the Rust backend.
/// Emitted when the watcher encounters a non-fatal error (permission denied,
/// path not found, etc.). Displayed in the Observatory activity log.
let onWatcherError = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("tauri:watcher-error", "watcher://error", tagger)
}

/// Listen for panel lifecycle events from the Tauri backend.
/// Emitted when panels are opened/closed, allowing backends to
/// start/stop expensive operations (e.g., watcher paths, polling).
let onPanelLifecycle = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("tauri:panel-lifecycle", "panel://lifecycle", tagger)
}
