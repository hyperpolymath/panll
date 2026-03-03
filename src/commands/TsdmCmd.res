// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL TSDM command wrappers — persistence for the Triaxial Software
/// Development Methodology directive panel.
///
/// The TSDM panel is a directive panel — it stores user preferences for
/// axis ordering, tier priorities, and cleanup steps. These are persisted
/// to localStorage (fast) and optionally to verisimdb (durable).
///
/// No heavy backend operations — this is mostly client-side state management
/// with optional persistence calls.

@val external invoke: (string, 'a) => promise<string> = "__TAURI__.core.invoke"

/// Save TSDM directive preferences to persistent storage.
/// Accepts JSON-serialised TsdmState.
let saveDirective = (
  directiveJson: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("tsdm_save_directive", {"directive": directiveJson})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to save TSDM directive")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load TSDM directive preferences from persistent storage.
/// Returns JSON-serialised TsdmState or empty string if none saved.
let loadDirective = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("tsdm_load_directive", Dict.make())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load TSDM directive")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Collect work items from all consumer panels.
/// Returns JSON array of classified work items.
let collectWorkItems = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("tsdm_collect_work_items", Dict.make())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to collect work items")))
      Promise.resolve()
    })
    ->ignore
  })
}
