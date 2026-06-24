// SPDX-License-Identifier: MPL-2.0

/// PanLL BoJ Commands — backend invoke wrappers for the Bundle of Joy
/// cartridge server. These call into the Rust backend at src-gossamer/src/boj/commands.rs
/// which proxies to the BoJ server at BOJ_URL (default http://localhost:7700/api/v1).

let invoke = RuntimeBridge.invoke

/// Check BoJ server health.
let health = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_health", {"_": true})
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

/// List all cartridges from the BoJ server.
let listCartridges = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_list_cartridges", {"_": true})
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

/// Get detailed info for a specific cartridge.
let getCartridge = (name: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_get_cartridge", {"name": name})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to get cartridge: ${name}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load (mount) a cartridge into the BoJ runtime.
let loadCartridge = (name: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_load_cartridge", {"name": name})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to load cartridge: ${name}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Unload (unmount) a cartridge from the BoJ runtime.
let unloadCartridge = (name: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_unload_cartridge", {"name": name})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Failed to unload cartridge: ${name}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get the full topology (architecture diagram data).
let topology = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_topology", {"_": true})
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

/// Invoke a tool on a specific cartridge.
let invokeCartridge = (
  name: string,
  tool: string,
  args: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_invoke", {"name": name, "tool": tool, "args": args})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Invocation failed: ${name}/${tool}`)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Invoke a tool on a cartridge with latency measurement.
/// Fires both the result tagger and a latency tagger with (cartridge, tool, elapsed ms).
let invokeCartridgeWithLatency = (
  name: string,
  tool: string,
  args: string,
  resultTagger: result<string, string> => 'msg,
  latencyTagger: (string, string, float) => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let startTime = Date.now()
    invoke("boj_invoke", {"name": name, "tool": tool, "args": args})
    ->Promise.then(result => {
      let elapsed = Date.now() -. startTime
      callbacks.enqueue(resultTagger(Ok(result)))
      callbacks.enqueue(latencyTagger(name, tool, elapsed))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      let elapsed = Date.now() -. startTime
      callbacks.enqueue(resultTagger(Error(`Invocation failed: ${name}/${tool}`)))
      callbacks.enqueue(latencyTagger(name, tool, elapsed))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Type-safe cartridge invocation — compile-time validated via CartridgeAbi.
/// Prefer this over the raw string-based invokeCartridge/invokeCartridgeWithLatency.
/// Usage: BojCmd.invokeTyped(Database(ExecuteVcl), args, resultTagger, latencyTagger)
let invokeTyped = (
  inv: CartridgeAbi.invocation,
  args: string,
  resultTagger: result<string, string> => 'msg,
  latencyTagger: (string, string, float) => 'msg,
): Tea_Cmd.t<'msg> => {
  let (name, tool) = CartridgeAbi.toWire(inv)
  invokeCartridgeWithLatency(name, tool, args, resultTagger, latencyTagger)
}

/// Type-safe cartridge invocation without latency tracking.
/// Usage: BojCmd.invokeTypedSimple(Nesy(Harmonize), args, resultTagger)
let invokeTypedSimple = (
  inv: CartridgeAbi.invocation,
  args: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let (name, tool) = CartridgeAbi.toWire(inv)
  invokeCartridge(name, tool, args, tagger)
}

/// Get Umoja federation status.
let umojaStatus = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("boj_umoja_status", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get Umoja status")))
      Promise.resolve()
    })
    ->ignore
  })
}
