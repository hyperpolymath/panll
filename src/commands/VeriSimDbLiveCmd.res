// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// VeriSimDB Live Commands — async VeriSimDB connection via the shared HTTP client.
///
/// These wrap the async backend commands from `verisimdb_live.rs` and provide the same
/// TEA-compatible callback interface used throughout PanLL. Panels can switch between
/// mock and live backends by routing through the panel config's routing flag.
///
/// All commands talk to the VeriSimDB server at ServiceEndpoints.verisimdb
/// (default http://localhost:8080/api/v1).
///
/// In browser-only mode (no desktop runtime), commands fall back to direct
/// fetch() calls against the VeriSimDB server URL.

let hasDesktopRuntime = RuntimeBridge.hasDesktopRuntime

/// GET helper for VeriSimDB direct fetch (bypasses backend invoke).
/// panic-attack:allow insecure-protocol — localhost development endpoint.
let fetchGet: string => promise<string> = %raw(`
  function(path) {
    return fetch("http://localhost:8080/api/v1" + path)
      .then(function(r) {
        if (!r.ok) throw new Error("VeriSimDB returned " + r.status);
        return r.text();
      });
  }
`)

/// POST helper for VeriSimDB direct fetch (bypasses backend invoke).
/// panic-attack:allow insecure-protocol — localhost development endpoint.
let fetchPost: (string, string) => promise<string> = %raw(`
  function(path, body) {
    return fetch("http://localhost:8080/api/v1" + path, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: body
    }).then(function(r) {
      if (!r.ok) throw new Error("VeriSimDB returned " + r.status);
      return r.text();
    });
  }
`)

/// Check VeriSimDB server health (async endpoint).
/// Calls `verisimdb_live_health` which hits `GET /health` on the VeriSimDB server.
/// Returns a JSON string with server status, uptime, and octad store metrics.
///
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let checkHealth = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("verisimdb_live_health", ())
    } else {
      fetchGet("/health")
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("VeriSimDB server unreachable")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List all octads in the VeriSimDB store (async endpoint).
/// Calls `verisimdb_live_list_octads` which hits `GET /octads` on the VeriSimDB server.
/// Returns a JSON array of octad summaries (id, name, modality counts).
///
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let listOctads = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("verisimdb_live_list_octads", ())
    } else {
      fetchGet("/octads")
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list octads")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Execute a VQL query against VeriSimDB (async endpoint).
/// Calls `verisimdb_live_query` which hits `POST /query` on the VeriSimDB server.
/// The query string is a VQL-UT expression that selects across octad modalities.
///
/// @param query — VQL-UT query string (e.g. "SELECT * FROM octad WHERE modality = 'text'")
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let executeQuery = (query: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("verisimdb_live_query", {"query": query})
    } else {
      fetchPost("/query", `{"query":${JSON.stringifyAny(query)->Option.getOr("\"\"")}}`)
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("VeriSimDB query failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Retrieve a specific octad by ID (async endpoint).
/// Calls `verisimdb_live_get_octad` which hits `GET /octads/{id}` on the VeriSimDB server.
/// Returns the full octad structure including all 8 modality slots.
///
/// @param id — the octad identifier (UUID or slug)
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let getOctad = (id: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("verisimdb_live_get_octad", {"id": id})
    } else {
      fetchGet("/octads/" ++ id)
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get octad: " ++ id)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Check if VeriSimDB is reachable (async health probe).
/// Wraps checkHealth but normalises the result into a reachability flag.
/// Returns `{"reachable": true/false, "endpoint": "..."}` — useful for panel bar
/// connection-dot indicators (green/red).
///
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let checkReachable = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("verisimdb_live_health", ())
    } else {
      fetchGet("/health")
    }
    p
    ->Promise.then(_result => {
      callbacks.enqueue(tagger(Ok(`{"reachable":true,"endpoint":"${ServiceEndpoints.verisimdb}"}`)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(
        tagger(Ok(`{"reachable":false,"endpoint":"${ServiceEndpoints.verisimdb}"}`)),
      )
      Promise.resolve()
    })
    ->ignore
  })
}
