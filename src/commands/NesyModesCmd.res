// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Modes command wrappers — Tauri invoke bridge for the
/// reasoning mode selector panel.
///
/// All commands invoke BoJ cartridge endpoints for reasoning mode
/// management. Uses `Tea_Cmd.call` for async operations.

@val external invoke: (string, 'a) => promise<string> = "__TAURI__.core.invoke"

/// Get the currently active reasoning mode.
/// Returns JSON with the mode identifier and metadata.
let getMode = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("nesy_mode_get", {})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get current reasoning mode")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Set the active reasoning mode.
/// Returns JSON confirming the mode switch.
let setMode = (
  modeId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("nesy_mode_set", {"mode_id": modeId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to set reasoning mode")))
      Promise.resolve()
    })
    ->ignore
  })
}
