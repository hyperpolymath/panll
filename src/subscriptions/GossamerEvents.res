// SPDX-License-Identifier: PMPL-1.0-or-later

/// GossamerEvents — Backend event subscriptions for real-time neurosymbolic streaming.
///
/// Wraps Gossamer's event API as TEA subscriptions so backend events
/// (ECHIDNA proof progress, agent broadcasts, FFI state changes) are
/// automatically dispatched into the TEA update loop.
///
/// In browser-only mode (no Gossamer runtime), all subscriptions gracefully
/// degrade to no-ops instead of crashing.

/// Detect whether the Gossamer runtime is available.
%%raw(`
function isGossamerAvailable() {
  return typeof window !== 'undefined'
    && typeof window.__gossamer_invoke === 'function';
}
`)
@val external isGossamerAvailable: unit => bool = "isGossamerAvailable"

/// Gossamer event listener binding.
/// Gossamer injects __gossamer_on(eventName, callback) into the webview.
/// Returns an unlisten function.
%%raw(`
function gossamerOn(eventName, callback) {
  if (typeof window !== 'undefined' && typeof window.__gossamer_on === 'function') {
    return window.__gossamer_on(eventName, callback);
  }
  return Promise.resolve(function() {});
}
`)
@val external gossamerOn: (string, string => unit) => promise<unit => unit> = "gossamerOn"

/// Safe wrapper around gossamerOn that returns a no-op subscription
/// when the Gossamer runtime is absent. Prevents crashes in browser-only mode.
let safeListen = (key: string, eventName: string, tagger: string => 'msg): Tea_Sub.t<'msg> => {
  if !isGossamerAvailable() {
    Tea_Sub.none
  } else {
    Tea_Sub.registration(key, dispatch => {
      let cleanup = ref(() => ())
      gossamerOn(eventName, payload => {
        dispatch(tagger(payload))
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
let onEchidnaProgress = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("gossamer:echidna-progress", "echidna:proof-progress", tagger)
}

/// Listen for ECHIDNA tactic suggestions pushed from the backend.
let onEchidnaTactics = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("gossamer:echidna-tactics", "echidna:tactic-suggestions", tagger)
}

/// Listen for Tentacles agent phase changes from the FFI bridge.
let onTentaclesPhaseChange = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("gossamer:tentacles-phase", "tentacles:phase-change", tagger)
}

/// Listen for Tentacles agent broadcast messages.
let onTentaclesBroadcast = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("gossamer:tentacles-broadcast", "tentacles:broadcast", tagger)
}

/// Listen for VeriSimDB drift alerts pushed from the backend.
let onVeriSimDBDrift = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("gossamer:verisimdb-drift", "verisimdb:drift-alert", tagger)
}

/// Listen for Hypatia neural network status changes.
let onHypatiaStatus = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("gossamer:hypatia-status", "hypatia:network-status", tagger)
}

/// Listen for governance halt/resume signals from the backend.
let onGovernanceSignal = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("gossamer:governance-signal", "governance:signal", tagger)
}

/// Listen for AI streaming chunks from the SSE provider.
let onAiStreamChunk = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("gossamer:ai-stream-chunk", "ai:stream-chunk", tagger)
}

/// Listen for filesystem watcher events from the Rust backend.
let onWatcherEvent = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("gossamer:watcher-event", "watcher://event", tagger)
}

/// Listen for watcher error events from the Rust backend.
let onWatcherError = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("gossamer:watcher-error", "watcher://error", tagger)
}

/// Listen for panel lifecycle events from the backend.
let onPanelLifecycle = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  safeListen("gossamer:panel-lifecycle", "panel://lifecycle", tagger)
}
