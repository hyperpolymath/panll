// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// BoJ Live Commands — async BoJ-server connection via the shared HTTP client.
///
/// These wrap the async backend commands from `boj_live.rs` and provide the same
/// TEA-compatible callback interface as `BojCmd.res`. Panels can switch between
/// mock (BojCmd) and live (BojLiveCmd) backends by routing through the panel
/// config's `bojRouting` flag.
///
/// All commands talk to the BoJ server at BOJ_URL (default localhost:7700).

let invoke = RuntimeBridge.invoke

/// Check BoJ-server health (async endpoint).
/// Calls `boj_live_health` which hits `GET /health` on the BoJ server.
let checkHealth = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_live_health", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("BoJ server unreachable")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List available cartridges (async endpoint).
/// Calls `boj_live_cartridges` which hits `GET /cartridges` on the BoJ server.
let listCartridges = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_live_cartridges", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list cartridges")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Invoke a cartridge tool (async endpoint).
/// Calls `boj_live_invoke` which hits `POST /cartridges/{cartridge}/invoke`.
///
/// @param cartridge — name of the target cartridge (e.g. "database", "nesy")
/// @param tool — tool/function name within the cartridge
/// @param params — JSON string of tool arguments
/// @param tagger — TEA message tagger for the result
let invokeCartridge = (
  cartridge: string,
  tool: string,
  params: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_live_invoke", {"cartridge": cartridge, "tool": tool, "params": params})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Cartridge invoke failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get cartridge topology / dependency graph (async endpoint).
/// Calls `boj_live_topology` which hits `GET /topology` on the BoJ server.
let getTopology = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_live_topology", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get topology")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Check if BoJ-server is reachable (async health probe).
/// Returns `{"reachable": bool, "endpoint": "..."}` — useful for panel bar
/// connection-dot indicators (green/red).
let checkReachable = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_live_check", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Connection check failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
