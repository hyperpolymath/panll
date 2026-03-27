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
  | CoprocRouting => "Routing"
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
let filterByBackend = (log: array<coprocCallEntry>, backend: coprocessorBackend): array<
  coprocCallEntry,
> => log->Array.filter(entry => entry.backend === backend)

/// Human-readable label for a compute engine.
let engineLabel = (engine: computeEngine): string =>
  switch engine {
  | EngineAxiom => "Axiom.jl"
  | EngineBoJ => "BoJ Cartridge"
  | EngineLocal => "Local CPU/WASM"
  }

/// Parse a compute engine string into a computeEngine variant.
let parseEngineId = (s: string): computeEngine =>
  switch s {
  | "axiom" => EngineAxiom
  | "boj" => EngineBoJ
  | _ => EngineLocal
  }

/// Tea_Json decoder for a compute query result (parameterised by engine).
let computeResultDecoder = (engine: computeEngine): Tea_Json.decoder<computeQueryResult> => {
  open Decoders
  open Tea_Json
  map4((operation, result, durationMs, success): computeQueryResult => {
    engineId: engine,
    operation,
    result,
    durationMs,
    success,
  }, stringField(
    "operation",
  ), stringField("result"), floatField("duration_ms"), boolField("success"))
}

/// Parse a compute engine query result from JSON.
let parseComputeResult = (json: string, engine: computeEngine): result<
  computeQueryResult,
  string,
> => Decoders.decode(computeResultDecoder(engine), json)

/// Tea_Json decoder for a single compute device.
let deviceDecoder: Tea_Json.decoder<computeDevice> = {
  open Decoders
  open Tea_Json
  map4((engineStr, deviceName, deviceType, available): computeDevice => {
    engineId: parseEngineId(engineStr),
    deviceName,
    deviceType,
    available,
    capabilities: [],
  }, stringField(
    "engine",
  ), stringField("device_name"), stringField("device_type"), boolField("available"))
}

/// Parse discovered devices from JSON array.
let parseDevices = (json: string): array<computeDevice> =>
  Decoders.decodeWithDefault(Decoders.lenientArray(deviceDecoder), [], json)

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
    let hasBoj = state.discoveredDevices->Array.some(d => d.engineId === EngineBoJ && d.available)
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
        canHandleLocally(state.localDispatch, operation) && state.localDispatch.cpuUtilisation < 0.8
      let isNeural = op->String.includes("neural") || op->String.includes("quantum")
      let hasRemote =
        state.discoveredDevices->Array.some(d => d.engineId === EngineAxiom && d.available)
      let hasBoj = state.discoveredDevices->Array.some(d => d.engineId === EngineBoJ && d.available)

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
  ffiPath: "ffi/zig/zig-out/lib/libpanll_copro.so",
  ffiLibPath: None,
  localDevices: [],
  cpuUtilisation: 0.0,
  gpuMemoryMb: 0,
  pendingDispatches: 0,
  cpuCores: 0,
  availableBackends: [],
}

/// Tea_Json decoder for local dispatch state from coprocessor_ffi_status JSON.
let localDispatchDecoder: Tea_Json.decoder<localDispatchState> = {
  open Decoders
  open Tea_Json
  map5((ffiLoaded, ffiLibPath, cpuUtilisation, gpuMemoryMb, cpuCores): localDispatchState => {
    ffiLoaded,
    ffiPath: defaultLocalDispatch.ffiPath,
    ffiLibPath: if ffiLibPath === "" {
      None
    } else {
      Some(ffiLibPath)
    },
    localDevices: [],
    cpuUtilisation,
    gpuMemoryMb,
    pendingDispatches: 0,
    cpuCores,
    availableBackends: [],
  }, boolField(
    "ffi_loaded",
  ), stringField(
    "ffi_lib_path",
  ), floatField("cpu_utilisation"), intField("gpu_memory_mb"), intField("cpu_cores"))
}

/// Parse local dispatch state from JSON.
let parseLocalDispatchState = (json: string): localDispatchState =>
  Decoders.decodeWithDefault(localDispatchDecoder, defaultLocalDispatch, json)

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

/// Smart-route an operation using the SmartRouter module.
/// Builds backend health from current state, routes, and appends to history.
let smartRouteAndRecord = (state: coprocessorsState, operation: string): (
  routingDecision,
  array<routingDecision>,
) => {
  let backends = SmartRouter.buildBackendHealth(state)
  let decision = SmartRouter.smartRoute(operation, backends, state.routingStrategy)
  let updatedHistory = SmartRouter.addDecision(state.routingHistory, decision)
  (decision, updatedHistory)
}

/// Human-readable label for the chosen route in a routing decision.
let routeDecisionLabel = (decision: routingDecision): string => routingLabel(decision.chosenRoute)

/// Route distribution from the current history.
let currentRouteStats = (state: coprocessorsState): array<(string, int, float)> =>
  SmartRouter.routeStats(state.routingHistory)

/// Category distribution from the current history.
let currentCategoryStats = (state: coprocessorsState): array<(string, int)> =>
  SmartRouter.categoryStats(state.routingHistory)
