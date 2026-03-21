// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Agent OODA command wrappers — Tauri invoke bridge for the
/// OODA session monitor panel.
///
/// All commands invoke BoJ cartridge endpoints for agent OODA session
/// management. Uses `Tea_Cmd.call` for async operations.

@val external invoke: (string, 'a) => promise<string> = "__TAURI__.core.invoke"

/// List all active OODA sessions.
/// Returns JSON array of session summary objects.
let listSessions = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("agent_ooda_list_sessions", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list OODA sessions")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get detailed information for a specific OODA session.
/// Returns JSON with full session detail including transition history.
let sessionDetail = (
  sessionId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("agent_ooda_session_detail", {"session_id": sessionId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch session detail")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Manually advance an agent session to the next OODA state.
/// Returns JSON with the updated session state.
let advance = (
  sessionId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("agent_ooda_advance", {"session_id": sessionId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to advance session")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Halt an agent session immediately.
/// Returns JSON confirming the halt.
let halt = (
  sessionId: string,
  reason: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("agent_ooda_halt", {"session_id": sessionId, "reason": reason})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to halt session")))
      Promise.resolve()
    })
    ->ignore
  })
}
