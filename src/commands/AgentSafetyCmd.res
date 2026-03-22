// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Agent Safety command wrappers — invoke bridge for the
/// safety gate panel.
///
/// All commands invoke BoJ cartridge endpoints for agent tool call
/// safety management. Uses `Tea_Cmd.call` for async operations.

let invoke = RuntimeBridge.invoke

/// Fetch all pending safety events awaiting human review.
/// Returns JSON array of safety event objects.
let pending = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("agent_safety_pending", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch pending safety events")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Approve a pending safety event, allowing the tool call to proceed.
/// Returns JSON confirming the approval.
let approve = (
  eventId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("agent_safety_approve", {"event_id": eventId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to approve safety event")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Deny a pending safety event, blocking the tool call.
/// Returns JSON confirming the denial.
let deny = (
  eventId: string,
  reason: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("agent_safety_deny", {"event_id": eventId, "reason": reason})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to deny safety event")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fetch historical safety events.
/// Returns JSON array of safety event objects sorted by timestamp.
let history = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("agent_safety_history", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch safety history")))
      Promise.resolve()
    })
    ->ignore
  })
}
