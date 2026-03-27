// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Coprocessors Commands — backend invoke wrappers for reading
/// coprocessor metrics, call logs, and backend health from the
/// running IDApTIK game instance.

let invoke = RuntimeBridge.invoke

/// Read metrics for all coprocessor backends.
let readMetrics = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
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
let readCallLog = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
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
let readHeatmap = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
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

/// Query an external compute engine (control plane).
let queryComputeEngine = (
  engineId: string,
  operation: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("query_compute_engine", {"engineId": engineId, "operation": operation})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to query compute engine")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Discover available compute devices from all engines.
let discoverDevices = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("discover_compute_devices", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to discover compute devices")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Dispatch a compute operation to local Zig FFI (Phase 2).
let dispatchLocal = (
  operation: string,
  input: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("coprocessor_dispatch_local", {"operation": operation, "input": input})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to dispatch local compute operation")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Check local FFI availability — is the .so loaded? (Phase 2).
let checkFfiStatus = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("coprocessor_check_ffi", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to check FFI status")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Benchmark local compute — run standard test suite (Phase 2).
let benchmarkLocal = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("coprocessor_benchmark", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to run local benchmark")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Phase 2: Load the Zig FFI shared library for local GPU/CPU dispatch.
/// Returns JSON with load status, available devices, and library version.
let loadLocalFfi = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("coprocessor_load_ffi", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load Zig FFI library")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Phase 2: Query local system resources (CPU utilisation, GPU memory).
let queryLocalResources = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("coprocessor_local_resources", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to query local resources")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Phase 3: Smart dispatch — auto-selects local vs remote based on load,
/// capability, and availability. The backend implements the routing logic.
let smartDispatch = (
  operation: string,
  payload: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("coprocessor_smart_dispatch", {"operation": operation, "payload": payload})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error(`Smart dispatch failed: ${operation}`)))
      Promise.resolve()
    })
    ->ignore
  })
}
