// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// ECHIDNA Live Commands — async ECHIDNA proof assistant connection via the shared HTTP client.
///
/// These wrap the async Tauri commands from `echidna_live.rs` and provide the same
/// TEA-compatible callback interface used throughout PanLL. Panels can switch between
/// mock and live backends by routing through the panel config's routing flag.
///
/// All commands talk to the ECHIDNA server at ServiceEndpoints.echidna
/// (default http://localhost:9000/api/v1).
///
/// ECHIDNA is the multi-solver dispatch layer — it receives proof obligations,
/// farms them out to Idris2/Lean/Coq/Z3 backends, and returns tactics or results.
///
/// In browser-only mode (no Tauri runtime), commands fall back to direct
/// fetch() calls against the ECHIDNA server URL.

@module("@tauri-apps/api/core")
external invokeRaw: (string, 'a) => promise<'b> = "invoke"

/// Detect whether the real Tauri runtime is available (not the browser shim).
%%raw(`
function hasTauri() {
  return typeof window !== 'undefined'
    && window.__TAURI_INTERNALS__ != null
    && !window.__TAURI_INTERNALS__.__BROWSER_SHIM__;
}
`)
@val external hasTauri: unit => bool = "hasTauri"

/// GET helper for ECHIDNA direct fetch (bypasses Tauri invoke).
/// panic-attack:allow insecure-protocol — localhost development endpoint.
let fetchGet: string => promise<string> = %raw(`
  function(path) {
    return fetch("http://localhost:9000/api/v1" + path)
      .then(function(r) {
        if (!r.ok) throw new Error("ECHIDNA returned " + r.status);
        return r.text();
      });
  }
`)

/// POST helper for ECHIDNA direct fetch (bypasses Tauri invoke).
/// panic-attack:allow insecure-protocol — localhost development endpoint.
let fetchPost: (string, string) => promise<string> = %raw(`
  function(path, body) {
    return fetch("http://localhost:9000/api/v1" + path, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: body
    }).then(function(r) {
      if (!r.ok) throw new Error("ECHIDNA returned " + r.status);
      return r.text();
    });
  }
`)

/// Check ECHIDNA server health (async endpoint).
/// Calls `echidna_live_health` which hits `GET /health` on the ECHIDNA server.
/// Returns a JSON string with server status, connected solvers, and queue depth.
///
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let checkHealth = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasTauri() {
      invokeRaw("echidna_live_health", ())
    } else {
      fetchGet("/health")
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("ECHIDNA server unreachable")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Recommend proof tactics for an obligation (async endpoint).
/// Calls `echidna_live_recommend_tactics` which hits `POST /tactics/recommend`
/// on the ECHIDNA server. The multi-solver dispatch analyses the obligation
/// and returns ranked tactic suggestions from available backends.
///
/// @param obligation — the proof obligation expression (Idris2/Lean/Coq syntax)
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let recommendTactics = (
  obligation: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasTauri() {
      invokeRaw("echidna_live_recommend_tactics", {"obligation": obligation})
    } else {
      fetchPost("/tactics/recommend", `{"obligation":${JSON.stringifyAny(obligation)->Option.getOr("\"\"")}}`)
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Tactic recommendation failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Submit a proof obligation for asynchronous solving (async endpoint).
/// Calls `echidna_live_submit_obligation` which hits `POST /obligations/submit`
/// on the ECHIDNA server. Returns an obligation ID that can be polled via getResult.
///
/// This is the async counterpart to recommendTactics — use this for long-running
/// proofs that may take multiple solver passes.
///
/// @param obligation — the proof obligation expression (Idris2/Lean/Coq syntax)
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let submitObligation = (
  obligation: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasTauri() {
      invokeRaw("echidna_live_submit_obligation", {"obligation": obligation})
    } else {
      fetchPost("/obligations/submit", `{"obligation":${JSON.stringifyAny(obligation)->Option.getOr("\"\"")}}`)
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Obligation submission failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get the result of a previously submitted obligation (async endpoint).
/// Calls `echidna_live_get_result` which hits `GET /obligations/{id}/result`
/// on the ECHIDNA server. Returns the current status (pending/solved/failed)
/// and proof term if solved.
///
/// @param obligationId — the obligation ID returned by submitObligation
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let getResult = (
  obligationId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasTauri() {
      invokeRaw("echidna_live_get_result", {"obligation_id": obligationId})
    } else {
      fetchGet("/obligations/" ++ obligationId ++ "/result")
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get obligation result: " ++ obligationId)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get ECHIDNA solver statistics (async endpoint).
/// Calls `echidna_live_stats` which hits `GET /stats` on the ECHIDNA server.
/// Returns solver utilisation, queue depths, success rates, and LLM integration
/// metrics from the Prover Wars dodeca-API.
///
/// @param tagger — TEA message tagger receiving Ok(json) or Error(reason)
let getStats = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasTauri() {
      invokeRaw("echidna_live_stats", ())
    } else {
      fetchGet("/stats")
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get ECHIDNA stats")))
      Promise.resolve()
    })
    ->ignore
  })
}
