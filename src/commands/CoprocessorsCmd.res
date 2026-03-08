// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Coprocessors Commands — Tauri invoke wrappers for reading
/// coprocessor metrics, call logs, and backend health from the
/// running IDApTIK game instance.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Read metrics for all coprocessor backends.
let readMetrics = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("read_coprocessor_metrics", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read coprocessor metrics")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read the coprocessor call log.
let readCallLog = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("read_coprocessor_call_log", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read call log")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read the heatmap data (call frequency over time).
let readHeatmap = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("read_coprocessor_heatmap", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read heatmap")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Toggle a coprocessor backend on/off.
let toggleBackend = (
  backendId: string,
  enabled: bool,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("toggle_coprocessor_backend", {"backendId": backendId, "enabled": enabled})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to toggle backend")))
      Promise.resolve()
    })
    ->ignore
  })
}
