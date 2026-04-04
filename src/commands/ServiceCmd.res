// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// ServiceCmd — TEA command wrappers for the PanLL service registry.
///
/// Provides side-effectful commands that invoke service registry operations
/// through the Gossamer backend. Each command follows the standard pattern:
/// `Tea_Cmd.call` + `RuntimeBridge.invoke` + `Promise.then/catch`.

let invoke = RuntimeBridge.invoke

/// Refresh health status of all registered services.
///
/// Returns the full registry as JSON on success.
let refreshAll = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("service_status_all", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Service registry refresh failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Check health of a single service by key.
///
/// Returns the updated service entry as JSON on success.
let checkService = (serviceKey: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("service_status", {"service_key": serviceKey})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Health check failed for " ++ serviceKey)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Update the URL of a registered service.
///
/// Resets the service status to Stopped after URL change.
let updateServiceUrl = (
  serviceKey: string,
  url: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("service_update_url", {"service_key": serviceKey, "url": url})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("URL update failed for " ++ serviceKey)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load the current registry snapshot from the backend.
let getRegistry = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("service_registry_get", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Registry load failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
