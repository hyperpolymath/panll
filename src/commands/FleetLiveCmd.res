// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// Gitbot-Fleet Live Commands — async fleet connection via direct HTTP fetch.
///
/// These provide live connections to the gitbot-fleet Axum dashboard API
/// for bot status, findings, dispatch operations, and fleet health monitoring.
/// Falls back to direct fetch() in browser-only mode (no desktop runtime).
///
/// All commands talk to the gitbot-fleet API at ServiceEndpoints.fleet
/// (default http://localhost:8090/api/v1).
///
/// In browser-only mode (no desktop runtime), commands fall back to direct
/// fetch() calls against the fleet server URL.

let hasDesktopRuntime = RuntimeBridge.hasDesktopRuntime

/// GET helper for fleet direct fetch (bypasses backend invoke).
/// panic-attack:allow insecure-protocol — localhost development endpoint.
let fetchGet: string => promise<string> = %raw(`
  function(path) {
    return fetch("http://localhost:8090/api/v1" + path)
      .then(function(r) {
        if (!r.ok) throw new Error("Fleet returned " + r.status);
        return r.text();
      });
  }
`)

/// POST helper for fleet direct fetch (bypasses backend invoke).
/// panic-attack:allow insecure-protocol — localhost development endpoint.
let fetchPost: (string, string) => promise<string> = %raw(`
  function(path, body) {
    return fetch("http://localhost:8090/api/v1" + path, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: body
    }).then(function(r) {
      if (!r.ok) throw new Error("Fleet returned " + r.status);
      return r.text();
    });
  }
`)

/// Check gitbot-fleet server health (async endpoint).
/// Calls `fleet_live_health` which hits `GET /health` on the fleet server.
/// Returns a JSON string with server status, uptime, and bot count.
///
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let checkHealth = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("fleet_live_health", ())
    } else {
      fetchGet("/health")
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Fleet server unreachable")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fetch the current status of all 6 bots (async endpoint).
/// Calls `fleet_live_bots` which hits `GET /bots` on the fleet server.
/// Returns a JSON array of bot objects with status, last-run, and findings count.
///
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let fetchBots = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("fleet_live_bots", ())
    } else {
      fetchGet("/bots")
    }
    p
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

/// Fetch the findings queue (async endpoint).
/// Calls `fleet_live_findings` which hits `GET /findings` on the fleet server.
/// Returns a JSON array of finding objects with severity, target repo, and
/// assigned bot.
///
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let fetchFindings = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("fleet_live_findings", ())
    } else {
      fetchGet("/findings")
    }
    p
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

/// Dispatch a finding to a specific bot for processing (async endpoint).
/// Calls `fleet_live_dispatch` which hits `POST /dispatch` on the fleet server.
///
/// @param findingId — the finding to dispatch
/// @param botId — the target bot (e.g., "rhodibot", "echidnabot")
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let dispatchFinding = (
  findingId: string,
  botId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("fleet_live_dispatch", {"finding_id": findingId, "bot_id": botId})
    } else {
      fetchPost(
        "/dispatch",
        `{"finding_id":${JSON.stringifyAny(findingId)->Option.getOr("\"\"")},` ++
        `"bot_id":${JSON.stringifyAny(botId)->Option.getOr("\"\"")}}`,
      )
    }
    p
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

/// Check if gitbot-fleet is reachable (async health probe).
/// Wraps checkHealth but normalises the result into a reachability flag.
/// Returns `{"reachable": true/false, "endpoint": "..."}` — useful for panel bar
/// connection-dot indicators (green/red).
///
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let checkReachable = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("fleet_live_health", ())
    } else {
      fetchGet("/health")
    }
    p
    ->Promise.then(_result => {
      callbacks.enqueue(tagger(Ok(`{"reachable":true,"endpoint":"${ServiceEndpoints.fleet}"}`)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Ok(`{"reachable":false,"endpoint":"${ServiceEndpoints.fleet}"}`)))
      Promise.resolve()
    })
    ->ignore
  })
}
