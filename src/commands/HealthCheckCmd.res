// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Health Check Command — generic Tauri command for checking if an
/// HTTP service is reachable. Used by all panels with backend services.
///
/// Each panel calls `checkEndpoint` with its service URL and a tagger
/// function that wraps the result into its own message type.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Check if an HTTP endpoint responds with a 2xx status.
/// The Tauri backend makes a GET request and returns the response body
/// (or an error message).
///
/// `endpoint` — full URL to health check (e.g. "http://localhost:8080/health")
/// `tagger` — function to wrap result<string, string> into the panel's msg type
let checkEndpoint = (
  endpoint: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("health_check", {"endpoint": endpoint})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Service unreachable: ${endpoint}`)))
      Promise.resolve()
    })
    ->ignore
  })
}
