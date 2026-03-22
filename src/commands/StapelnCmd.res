// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Stapeln Commands — backend invoke wrappers for the container
/// assembly pipeline. These call into the Rust backend which proxies
/// to the Stapeln server API (default http://localhost:8420/api/v1).

let invoke = RuntimeBridge.invoke

/// Connect to the stapeln backend and check availability.
let connect = (
  url: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("stapeln_health", {"url": url})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Cannot reach stapeln backend")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Request validation of the current assembly from the backend.
let requestValidation = (
  url: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("stapeln_validate", {"url": url})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Validation request failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Request artifact generation from the backend.
let requestGenerate = (
  url: string,
  format: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("stapeln_generate", {"url": url, "format": format})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Artifact generation failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Refresh pipeline status from the backend.
let refreshStatus = (
  url: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("stapeln_status", {"url": url})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Status refresh failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
