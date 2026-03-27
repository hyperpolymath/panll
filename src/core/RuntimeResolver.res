// SPDX-License-Identifier: PMPL-1.0-or-later

/// RuntimeResolver — Resolves panll:// URIs to the active runtime's IPC.
///
/// Panel manifests use `panll://service-id/path` as runtime-agnostic URIs.
/// This module resolves them to actual IPC calls through the Gossamer runtime,
/// or to direct HTTP in browser mode.
///
/// Used by the panel harness to dispatch data_source fetches and health checks.

/// URI prefix for PanLL runtime-agnostic endpoints.
let panllPrefix = "panll://"

/// URI prefix for Gossamer-specific endpoints.
let gossamerPrefix = "gossamer://"

/// Parse a panll:// URI into service_id and path.
/// Example: "panll://system-update/components" -> ("system-update", "/components")
let parseUri = (uri: string): option<(string, string)> => {
  let stripped = if String.startsWith(uri, panllPrefix) {
    Some(String.sliceToEnd(uri, ~start=String.length(panllPrefix)))
  } else if String.startsWith(uri, gossamerPrefix) {
    Some(String.sliceToEnd(uri, ~start=String.length(gossamerPrefix)))
  } else if String.startsWith(uri, "tauri://") {
    // Legacy tauri:// URIs — resolve to gossamer equivalent.
    Some(String.sliceToEnd(uri, ~start=8))
  } else {
    None
  }

  switch stripped {
  | None => None
  | Some(rest) =>
    let idx = String.indexOf(rest, "/")
    if idx >= 0 {
      let serviceId = String.slice(rest, ~start=0, ~end=idx)
      let path = String.sliceToEnd(rest, ~start=idx)
      Some((serviceId, path))
    } else {
      Some((rest, "/"))
    }
  }
}

/// Resolve a panll:// data source path to an IPC invoke command name.
///
/// Convention: panll://service-id/invoke/command_name -> invoke("command_name")
/// This matches the Gossamer command naming used across all panels.
let resolveInvokeCommand = (uri: string): option<string> => {
  switch parseUri(uri) {
  | None => None
  | Some((_serviceId, path)) =>
    if String.startsWith(path, "/invoke/") {
      Some(String.sliceToEnd(path, ~start=String.length("/invoke/")))
    } else {
      None
    }
  }
}

/// Fetch data from a panll:// data source URI.
/// Routes through RuntimeBridge.invoke to the active runtime.
let fetch = (uri: string, body: option<JSON.t>): promise<string> => {
  switch resolveInvokeCommand(uri) {
  | Some(command) =>
    switch body {
    | Some(payload) => RuntimeBridge.invoke(command, payload)
    | None => RuntimeBridge.invoke(command, ())
    }
  | None => Promise.reject(JsError.throwWithMessage(`Cannot resolve URI: ${uri}`))
  }
}

/// Perform a health check for a service.
/// Uses the service's health_check.path from the manifest.
let healthCheck = (serviceId: string, _healthPath: string): promise<bool> => {
  let command = serviceId ++ "_health"
  RuntimeBridge.invoke(command, ())
  ->Promise.then(_result => Promise.resolve(true))
  ->Promise.catch(_err => Promise.resolve(false))
}

/// Get the runtime-specific endpoint URI for a service.
/// Returns gossamer:// or http:// based on the active runtime.
let resolvedEndpoint = (serviceId: string): string => {
  switch RuntimeBridge.currentRuntime() {
  | RuntimeBridge.Gossamer => gossamerPrefix ++ serviceId ++ "/bridge"
  | RuntimeBridge.BrowserOnly => "http://localhost:8000/api/" ++ serviceId
  }
}
