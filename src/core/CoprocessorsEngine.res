// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Coprocessors Engine — pure computation and helpers for the
/// IDApTIK coprocessor monitoring dashboard.

open CoprocessorsModel

/// Human-readable labels for category tabs.
let categoryLabel = (cat: coprocessorsCategory): string =>
  switch cat {
  | CoprocDashboard => "Dashboard"
  | CoprocCallLog => "Call Log"
  | CoprocHeatmap => "Heatmap"
  | CoprocSettings => "Settings"
  }

/// Human-readable labels for coprocessor backends.
let backendLabel = (backend: coprocessorBackend): string =>
  switch backend {
  | CoprocMaths => "Maths"
  | CoprocVector => "Vector"
  | CoprocTensor => "Tensor"
  | CoprocPhysics => "Physics"
  | CoprocCrypto => "Crypto"
  | CoprocNeural => "Neural"
  | CoprocQuantum => "Quantum"
  | CoprocAudio => "Audio"
  | CoprocGraphics => "Graphics"
  | CoprocIO => "I/O"
  }

/// Short labels for compact display.
let backendShortLabel = (backend: coprocessorBackend): string =>
  switch backend {
  | CoprocMaths => "MAT"
  | CoprocVector => "VEC"
  | CoprocTensor => "TEN"
  | CoprocPhysics => "PHY"
  | CoprocCrypto => "CRY"
  | CoprocNeural => "NEU"
  | CoprocQuantum => "QUA"
  | CoprocAudio => "AUD"
  | CoprocGraphics => "GFX"
  | CoprocIO => "I/O"
  }

/// Tailwind colour class for each backend.
let backendColour = (backend: coprocessorBackend): string =>
  switch backend {
  | CoprocMaths => "text-blue-400"
  | CoprocVector => "text-cyan-400"
  | CoprocTensor => "text-indigo-400"
  | CoprocPhysics => "text-amber-400"
  | CoprocCrypto => "text-red-400"
  | CoprocNeural => "text-emerald-400"
  | CoprocQuantum => "text-purple-400"
  | CoprocAudio => "text-pink-400"
  | CoprocGraphics => "text-orange-400"
  | CoprocIO => "text-gray-400"
  }

/// Health status label.
let healthLabel = (health: coprocHealth): string =>
  switch health {
  | CoprocHealthy => "Healthy"
  | CoprocDegraded => "Degraded"
  | CoprocFailed => "Failed"
  | CoprocDisabled => "Disabled"
  }

/// Health status colour.
let healthColour = (health: coprocHealth): string =>
  switch health {
  | CoprocHealthy => "text-emerald-400"
  | CoprocDegraded => "text-amber-400"
  | CoprocFailed => "text-red-400"
  | CoprocDisabled => "text-gray-500"
  }

/// All coprocessor backends.
let allBackends: array<coprocessorBackend> = [
  CoprocMaths,
  CoprocVector,
  CoprocTensor,
  CoprocPhysics,
  CoprocCrypto,
  CoprocNeural,
  CoprocQuantum,
  CoprocAudio,
  CoprocGraphics,
  CoprocIO,
]

/// Filter call log by backend.
let filterByBackend = (log: array<coprocCallEntry>, backend: coprocessorBackend): array<coprocCallEntry> =>
  log->Array.filter(entry => entry.backend === backend)

/// Human-readable label for a compute engine.
let engineLabel = (engine: computeEngine): string =>
  switch engine {
  | EngineAxiom => "Axiom.jl"
  | EngineBoJ => "BoJ Cartridge"
  | EngineLocal => "Local CPU/WASM"
  }

/// Parse a compute engine query result from JSON.
let parseComputeResult = (json: string, engine: computeEngine): result<computeQueryResult, string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let getString = (key: string): string =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => s
            | _ => ""
            }
          | None => ""
          }
        let getFloat = (key: string): float =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => n
            | _ => 0.0
            }
          | None => 0.0
          }
        let getBool = (key: string): bool =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Bool(b) => b
            | _ => false
            }
          | None => false
          }
        Ok({
          engineId: engine,
          operation: getString("operation"),
          result: getString("result"),
          durationMs: getFloat("duration_ms"),
          success: getBool("success"),
        })
      }
    | _ => Error("Expected JSON object for compute result")
    }
  } catch {
  | _ => Error("Failed to parse compute result JSON")
  }
}

/// Parse discovered devices from JSON array.
let parseDevices = (json: string): array<computeDevice> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Array(items) =>
      items->Array.filterMap(item => {
        switch JSON.Classify.classify(item) {
        | Object(obj) => {
            let getString = (key: string): string =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | String(s) => s
                | _ => ""
                }
              | None => ""
              }
            let getBool = (key: string): bool =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Bool(b) => b
                | _ => false
                }
              | None => false
              }
            let engineStr = getString("engine")
            let engineId = switch engineStr {
            | "axiom" => EngineAxiom
            | "boj" => EngineBoJ
            | _ => EngineLocal
            }
            Some({
              engineId,
              deviceName: getString("device_name"),
              deviceType: getString("device_type"),
              available: getBool("available"),
              capabilities: [],
            })
          }
        | _ => None
        }
      })
    | _ => []
    }
  } catch {
  | _ => []
  }
}

/// Human-readable label for a routing strategy.
let routingLabel = (strategy: routingStrategy): string =>
  switch strategy {
  | RouteLocal => "Local (Zig FFI)"
  | RouteRemote => "Remote (Axiom.jl)"
  | RouteBoj => "BoJ Cartridge"
  | RouteAutomatic => "Automatic"
  }

/// Tailwind colour class for a routing strategy.
let routingColour = (strategy: routingStrategy): string =>
  switch strategy {
  | RouteLocal => "text-emerald-400"
  | RouteRemote => "text-blue-400"
  | RouteBoj => "text-amber-400"
  | RouteAutomatic => "text-purple-400"
  }

/// Check if an operation can be handled locally by the Zig FFI (Phase 2).
/// Operations involving math, vector, and tensor work are local-capable.
let canHandleLocally = (localDispatch: localDispatchState, operation: string): bool => {
  if !localDispatch.ffiLoaded {
    false
  } else {
    let op = operation->String.toLowerCase
    op->String.includes("math") ||
    op->String.includes("vector") ||
    op->String.includes("tensor") ||
    op->String.includes("matrix") ||
    op->String.includes("linear") ||
    op->String.includes("arithmetic")
  }
}

/// Estimate latency for each routing option in milliseconds.
let rec estimateLatency = (state: coprocessorsState, route: routingStrategy): float => {
  switch route {
  | RouteLocal =>
    if state.localDispatch.ffiLoaded {
      // Local FFI is sub-millisecond for most operations.
      0.1 +. Float.fromInt(state.localDispatch.pendingDispatches) *. 0.05
    } else {
      // FFI not loaded — effectively infinite.
      99999.0
    }
  | RouteRemote =>
    // Network round-trip to Axiom.jl (local socket or HTTP).
    let hasRemote =
      state.discoveredDevices->Array.some(d => d.engineId === EngineAxiom && d.available)
    if hasRemote {
      5.0
    } else {
      99999.0
    }
  | RouteBoj =>
    // BoJ cartridge via HTTP on localhost.
    let hasBoj =
      state.discoveredDevices->Array.some(d => d.engineId === EngineBoJ && d.available)
    if hasBoj {
      3.0
    } else {
      99999.0
    }
  | RouteAutomatic =>
    // Automatic routes to the best option — estimate as the minimum.
    let local = estimateLatency(state, RouteLocal)
    let remote = estimateLatency(state, RouteRemote)
    let boj = estimateLatency(state, RouteBoj)
    Math.minMany([local, remote, boj])
  }
}

/// Decide which route to use for a compute operation (Phase 3).
/// Considers: FFI availability, device capabilities, CPU load, operation type.
let selectRoute = (state: coprocessorsState, operation: string): routingDecision => {
  let now = Date.now()
  let op = operation->String.toLowerCase

  let (chosenRoute, reason) = switch state.routingStrategy {
  | RouteAutomatic => {
      // Smart routing: check local first, then remote, then BoJ fallback.
      let localOk =
        canHandleLocally(state.localDispatch, operation) &&
        state.localDispatch.cpuUtilisation < 0.8
      let isNeural = op->String.includes("neural") || op->String.includes("quantum")
      let hasRemote =
        state.discoveredDevices->Array.some(d => d.engineId === EngineAxiom && d.available)
      let hasBoj =
        state.discoveredDevices->Array.some(d => d.engineId === EngineBoJ && d.available)

      if localOk {
        (RouteLocal, "FFI loaded, math/vector op, CPU utilisation below threshold")
      } else if isNeural && hasRemote {
        (RouteRemote, "Neural/quantum operation requires remote Axiom.jl capabilities")
      } else if hasBoj {
        (RouteBoj, "BoJ cartridge available as unified fallback")
      } else if hasRemote {
        (RouteRemote, "Remote engine available, no local or BoJ option")
      } else {
        (RouteBoj, "No preferred route available — defaulting to BoJ")
      }
    }
  | RouteLocal =>
    if state.localDispatch.ffiLoaded {
      (RouteLocal, "Explicit local routing — FFI available")
    } else {
      (RouteBoj, "Local routing requested but FFI not loaded — falling back to BoJ")
    }
  | RouteRemote => {
      let hasRemote =
        state.discoveredDevices->Array.some(d => d.engineId === EngineAxiom && d.available)
      if hasRemote {
        (RouteRemote, "Explicit remote routing — Axiom.jl available")
      } else {
        (RouteBoj, "Remote routing requested but Axiom.jl not available — falling back to BoJ")
      }
    }
  | RouteBoj => (RouteBoj, "Explicit BoJ routing")
  }

  let latencyEstimateMs = estimateLatency(state, chosenRoute)

  {
    operation,
    chosenRoute,
    reason,
    latencyEstimateMs,
    timestamp: now,
  }
}

/// Default local dispatch state (Phase 2).
let defaultLocalDispatch: localDispatchState = {
  ffiLoaded: false,
  ffiPath: "/var/mnt/eclipse/repos/panll/ffi/zig/zig-out/lib/libpanll_compute.so",
  localDevices: [],
  cpuUtilisation: 0.0,
  gpuMemoryMb: 0,
  pendingDispatches: 0,
}

/// Parse local dispatch state from JSON.
let parseLocalDispatchState = (json: string): localDispatchState => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let getBool = (key: string): bool =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Bool(b) => b
            | _ => false
            }
          | None => false
          }
        let getString = (key: string): string =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => s
            | _ => ""
            }
          | None => ""
          }
        let getFloat = (key: string): float =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => n
            | _ => 0.0
            }
          | None => 0.0
          }
        let getInt = (key: string): int =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Number(n) => Float.toInt(n)
            | _ => 0
            }
          | None => 0
          }
        {
          ffiLoaded: getBool("ffi_loaded"),
          ffiPath: getString("ffi_path"),
          localDevices: [],
          cpuUtilisation: getFloat("cpu_utilisation"),
          gpuMemoryMb: getInt("gpu_memory_mb"),
          pendingDispatches: getInt("pending_dispatches"),
        }
      }
    | _ => defaultLocalDispatch
    }
  } catch {
  | _ => defaultLocalDispatch
  }
}

/// Default state for the Coprocessors panel.
let defaultState: coprocessorsState = {
  activeCategory: CoprocDashboard,
  metrics: [],
  callLog: [],
  heatmap: [],
  enabledBackends: allBackends,
  selectedBackend: None,
  filterText: "",
  autoRefresh: true,
  refreshIntervalMs: 2000,
  loading: false,
  error: None,
  discoveredDevices: [],
  lastComputeResult: None,
  bojRouting: false,
  localDispatch: defaultLocalDispatch,
  routingStrategy: RouteAutomatic,
  routingHistory: [],
}
