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
