// SPDX-License-Identifier: PMPL-1.0-or-later

/// TauriEvents — Tauri backend event subscriptions for real-time neurosymbolic streaming.
///
/// Wraps Tauri's `listen` API as TEA subscriptions so backend events
/// (ECHIDNA proof progress, agent broadcasts, FFI state changes) are
/// automatically dispatched into the TEA update loop.
///
/// S2: Bridges the gap between the Tauri backend (async, event-driven)
/// and the TEA frontend (synchronous, message-driven).

/// Listen for ECHIDNA proof progress events from the Rust backend.
/// The backend emits these when a proof session advances phases.
let onEchidnaProgress = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("tauri:echidna-progress", dispatch => {
    let cleanup = ref(() => ())
    Tauri.listen("echidna:proof-progress", evt => {
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

/// Listen for ECHIDNA tactic suggestions pushed from the backend.
let onEchidnaTactics = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("tauri:echidna-tactics", dispatch => {
    let cleanup = ref(() => ())
    Tauri.listen("echidna:tactic-suggestions", evt => {
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

/// Listen for Tentacles agent phase changes from the FFI bridge.
/// Emitted when an agent transitions between OODA phases.
let onTentaclesPhaseChange = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("tauri:tentacles-phase", dispatch => {
    let cleanup = ref(() => ())
    Tauri.listen("tentacles:phase-change", evt => {
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

/// Listen for Tentacles agent broadcast messages.
let onTentaclesBroadcast = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("tauri:tentacles-broadcast", dispatch => {
    let cleanup = ref(() => ())
    Tauri.listen("tentacles:broadcast", evt => {
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

/// Listen for VeriSimDB drift alerts pushed from the backend.
let onVeriSimDBDrift = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("tauri:verisimdb-drift", dispatch => {
    let cleanup = ref(() => ())
    Tauri.listen("verisimdb:drift-alert", evt => {
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

/// Listen for Hypatia neural network status changes.
let onHypatiaStatus = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("tauri:hypatia-status", dispatch => {
    let cleanup = ref(() => ())
    Tauri.listen("hypatia:network-status", evt => {
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

/// Listen for governance halt/resume signals from the backend.
let onGovernanceSignal = (tagger: string => 'msg): Tea_Sub.t<'msg> => {
  Tea_Sub.registration("tauri:governance-signal", dispatch => {
    let cleanup = ref(() => ())
    Tauri.listen("governance:signal", evt => {
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
