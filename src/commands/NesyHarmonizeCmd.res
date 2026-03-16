// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Harmonization command wrappers — Tauri invoke bridge for the
/// harmonization monitor panel.
///
/// All commands invoke BoJ cartridge endpoints for neural-symbolic
/// harmonization data. Uses `Tea_Cmd.call` for async operations.

@val external invoke: (string, 'a) => promise<string> = "__TAURI__.core.invoke"

/// Fetch current harmonization entries from the BoJ NeSy cartridge.
/// Returns JSON array of harmonization entry objects.
let fetchEntries = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("nesy_harmonize_fetch_entries", {})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch harmonization entries")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Submit a new harmonization request to the BoJ NeSy cartridge.
/// Triggers neural-symbolic verdict fusion for the given input.
/// Returns JSON with the resulting harmonization entry.
let submit = (
  source: string,
  inputData: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("nesy_harmonize_submit", {"source": source, "input_data": inputData})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to submit harmonization request")))
      Promise.resolve()
    })
    ->ignore
  })
}
