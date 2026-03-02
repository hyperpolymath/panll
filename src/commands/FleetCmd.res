// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Fleet Commands — Tauri command wrappers for Gitbot-Fleet.
///
/// The fleet backend connects to the gitbot-fleet Axum dashboard API
/// at :8080 for bot status, findings, and dispatch operations.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Fetch the current status of all 6 bots.
let fetchBots = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("fleet_get_bots", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch bot status")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fetch the findings queue.
let fetchFindings = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("fleet_get_findings", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch findings")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Dispatch a finding to a specific bot for processing.
let dispatchFinding = (
  findingId: string,
  botId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("fleet_dispatch", {"findingId": findingId, "botId": botId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Dispatch failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
