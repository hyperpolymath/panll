// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Drift command wrappers — invoke bridge for the
/// drift dashboard panel.
///
/// All commands invoke BoJ cartridge endpoints for neural model drift
/// detection. Uses `Tea_Cmd.call` for async operations.

let invoke = RuntimeBridge.invoke

/// Run a drift check on all monitored models.
/// Returns JSON with per-model drift status and any new alerts.
let check = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("nesy_drift_check", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to run drift check")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fetch historical drift alerts.
/// Returns JSON array of drift alert objects sorted by timestamp.
let history = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("nesy_drift_history", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch drift history")))
      Promise.resolve()
    })
    ->ignore
  })
}
