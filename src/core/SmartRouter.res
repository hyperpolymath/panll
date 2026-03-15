// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Smart Router — per-operation intelligent compute dispatch.
///
/// Mirrors Axiom.jl's SmartBackend pattern: each operation is routed
/// to the fastest available backend based on operation type, data size,
/// and backend availability. Pure functions only — no side effects.

open CoprocessorsModel

/// Operation category for routing decisions.
/// Each category has a preferred backend based on benchmarked latency.
type operationCategory =
  /// Matrix multiplication — prefer Axiom.jl (BLAS/LAPACK).
  | MatMul
  /// Neural activation functions — prefer Zig FFI (SIMD vectorised).
  | Activation
  /// Layer/batch normalisation — prefer Zig FFI (SIMD).
  | Normalization
  /// Cryptographic hashing — prefer local FFI (constant-time, no network).
  | Hashing
  /// Formal proof validation — prefer local FFI (deterministic).
  | Validation
  /// Database query — prefer BoJ (database-mcp cartridge).
  | Query
  /// Statistical analysis/simulation — prefer Axiom.jl.
  | Analysis
  /// General compute — automatic, prefer lowest latency.
  | General

/// Backend health snapshot used by the smart router.
type backendHealth = {
  /// Backend identifier: "local_ffi" | "axiom_http" | "boj_cartridge".
  name: string,
  /// Whether the backend is currently reachable.
  available: bool,
  /// Rolling average latency in milliseconds.
  avgLatencyMs: float,
  /// Error rate (0.0–1.0) over the observation window.
  errorRate: float,
  /// Timestamp of last health check.
  lastChecked: float,
}

/// Human-readable label for an operation category.
let categoryLabel = (cat: operationCategory): string =>
  switch cat {
  | MatMul => "Matrix Multiply"
  | Activation => "Activation"
  | Normalization => "Normalization"
  | Hashing => "Hashing"
  | Validation => "Validation"
  | Query => "Query"
  | Analysis => "Analysis"
  | General => "General"
  }

/// Tailwind colour class for an operation category.
let categoryColour = (cat: operationCategory): string =>
  switch cat {
  | MatMul => "text-indigo-400"
  | Activation => "text-emerald-400"
  | Normalization => "text-cyan-400"
  | Hashing => "text-red-400"
  | Validation => "text-amber-400"
  | Query => "text-blue-400"
  | Analysis => "text-purple-400"
  | General => "text-gray-400"
  }

/// Classify an operation string into a category by keyword matching.
/// Case-insensitive — callers should pass lowercase or this normalises.
let classifyOperation = (op: string): operationCategory => {
  let lower = op->String.toLowerCase
  if (
    lower->String.includes("matmul") ||
    lower->String.includes("multiply") ||
    lower->String.includes("gemm") ||
    lower->String.includes("dot_product")
  ) {
    MatMul
  } else if (
    lower->String.includes("relu") ||
    lower->String.includes("sigmoid") ||
    lower->String.includes("gelu") ||
    lower->String.includes("tanh") ||
    lower->String.includes("softmax")
  ) {
    Activation
  } else if (
    lower->String.includes("norm") ||
    lower->String.includes("layernorm") ||
    lower->String.includes("batchnorm") ||
    lower->String.includes("groupnorm")
  ) {
    Normalization
  } else if (
    lower->String.includes("hash") ||
    lower->String.includes("sha") ||
    lower->String.includes("blake") ||
    lower->String.includes("hmac")
  ) {
    Hashing
  } else if (
    lower->String.includes("validate") ||
    lower->String.includes("verify") ||
    lower->String.includes("proof") ||
    lower->String.includes("check_type")
  ) {
    Validation
  } else if (
    lower->String.includes("query") ||
    lower->String.includes("select") ||
    lower->String.includes("insert") ||
    lower->String.includes("fetch")
  ) {
    Query
  } else if (
    lower->String.includes("analyze") ||
    lower->String.includes("statistics") ||
    lower->String.includes("simulate") ||
    lower->String.includes("regress")
  ) {
    Analysis
  } else {
    General
  }
}

/// Preferred route name for each operation category.
/// Returns the ideal backend name assuming all backends are available.
let preferredRoute = (cat: operationCategory): string =>
  switch cat {
  | MatMul => "axiom_http"
  | Activation => "local_ffi"
  | Normalization => "local_ffi"
  | Hashing => "local_ffi"
  | Validation => "local_ffi"
  | Query => "boj_cartridge"
  | Analysis => "axiom_http"
  | General => "local_ffi"
  }

/// Build backend health snapshots from the current coprocessors state.
/// Synthesises health from discoveredDevices and localDispatch.
let buildBackendHealth = (state: coprocessorsState): array<backendHealth> => {
  let now = Date.now()

  let ffiHealth: backendHealth = {
    name: "local_ffi",
    available: state.localDispatch.ffiLoaded,
    avgLatencyMs: if state.localDispatch.ffiLoaded {
      0.5 +. Float.fromInt(state.localDispatch.pendingDispatches) *. 0.1
    } else {
      99999.0
    },
    errorRate: 0.0,
    lastChecked: now,
  }

  let axiomAvailable =
    state.discoveredDevices->Array.some(d => d.engineId === EngineAxiom && d.available)
  let axiomHealth: backendHealth = {
    name: "axiom_http",
    available: axiomAvailable,
    avgLatencyMs: if axiomAvailable { 15.0 } else { 99999.0 },
    errorRate: 0.0,
    lastChecked: now,
  }

  let bojAvailable =
    state.discoveredDevices->Array.some(d => d.engineId === EngineBoJ && d.available)
  let bojHealth: backendHealth = {
    name: "boj_cartridge",
    available: bojAvailable,
    avgLatencyMs: if bojAvailable { 10.0 } else { 99999.0 },
    errorRate: 0.0,
    lastChecked: now,
  }

  [ffiHealth, axiomHealth, bojHealth]
}

/// Core smart routing function. Given an operation, backend health array,
/// and strategy override, returns a routingDecision using the existing
/// CoprocessorsModel.routingDecision type.
///
/// When strategy is RouteAutomatic, uses per-category preference tables
/// with fallback chains:
///   MatMul/Analysis: Axiom -> FFI -> BoJ
///   Activation/Norm/Hash/Validation: FFI -> Axiom -> BoJ
///   Query: BoJ -> Axiom -> FFI
///   General: FFI -> Axiom -> BoJ
let smartRoute = (
  op: string,
  backends: array<backendHealth>,
  strategy: routingStrategy,
): routingDecision => {
  let timestamp = Date.now()

  /// Look up whether a named backend is available and healthy.
  let isAvailable = (name: string): bool =>
    backends->Array.some(b => b.name == name && b.available && b.errorRate < 0.5)

  /// Estimate latency for a named backend.
  let latencyFor = (name: string): float =>
    backends
    ->Array.find(b => b.name == name)
    ->Option.mapOr(99999.0, b => b.avgLatencyMs)

  let ffiOk = isAvailable("local_ffi")
  let axiomOk = isAvailable("axiom_http")
  let bojOk = isAvailable("boj_cartridge")

  switch strategy {
  | RouteLocal => {
      operation: op,
      chosenRoute: RouteLocal,
      reason: "Forced local FFI by strategy override",
      latencyEstimateMs: latencyFor("local_ffi"),
      timestamp,
    }
  | RouteRemote => {
      operation: op,
      chosenRoute: RouteRemote,
      reason: "Forced remote Axiom.jl by strategy override",
      latencyEstimateMs: latencyFor("axiom_http"),
      timestamp,
    }
  | RouteBoj => {
      operation: op,
      chosenRoute: RouteBoj,
      reason: "Forced BoJ cartridge by strategy override",
      latencyEstimateMs: latencyFor("boj_cartridge"),
      timestamp,
    }
  | RouteAutomatic => {
      let category = classifyOperation(op)
      let catLabel = categoryLabel(category)

      /// Try a prioritised fallback chain: first, second, third.
      let tryChain = (
        ~first: (string, routingStrategy),
        ~second: (string, routingStrategy),
        ~third: (string, routingStrategy),
      ): (routingStrategy, string, float) => {
        let (firstName, firstRoute) = first
        let (secondName, secondRoute) = second
        let (thirdName, thirdRoute) = third
        if isAvailable(firstName) {
          (firstRoute, `${catLabel}: preferred ${firstName}`, latencyFor(firstName))
        } else if isAvailable(secondName) {
          (secondRoute, `${catLabel}: fallback to ${secondName} (${firstName} unavailable)`, latencyFor(secondName))
        } else if isAvailable(thirdName) {
          (thirdRoute, `${catLabel}: last-resort ${thirdName}`, latencyFor(thirdName))
        } else {
          // All backends down — still return BoJ as the default sink.
          (RouteBoj, `${catLabel}: no backends available, defaulting to BoJ`, 99999.0)
        }
      }

      let (chosenRoute, reason, latency) = switch category {
      | MatMul | Analysis =>
        tryChain(
          ~first=("axiom_http", RouteRemote),
          ~second=("local_ffi", RouteLocal),
          ~third=("boj_cartridge", RouteBoj),
        )
      | Activation | Normalization | Hashing | Validation =>
        tryChain(
          ~first=("local_ffi", RouteLocal),
          ~second=("axiom_http", RouteRemote),
          ~third=("boj_cartridge", RouteBoj),
        )
      | Query =>
        tryChain(
          ~first=("boj_cartridge", RouteBoj),
          ~second=("axiom_http", RouteRemote),
          ~third=("local_ffi", RouteLocal),
        )
      | General =>
        // For general ops, prefer local if available (lowest latency),
        // but also consider CPU load via latency estimate.
        if ffiOk && latencyFor("local_ffi") < 5.0 {
          (RouteLocal, `${catLabel}: local FFI (lowest latency)`, latencyFor("local_ffi"))
        } else if axiomOk {
          (RouteRemote, `${catLabel}: Axiom.jl (local FFI busy or unavailable)`, latencyFor("axiom_http"))
        } else if bojOk {
          (RouteBoj, `${catLabel}: BoJ cartridge fallback`, latencyFor("boj_cartridge"))
        } else {
          (RouteBoj, `${catLabel}: no backends available`, 99999.0)
        }
      }

      {
        operation: op,
        chosenRoute,
        reason,
        latencyEstimateMs: latency,
        timestamp,
      }
    }
  }
}

/// Maximum number of routing decisions to retain in the audit ring buffer.
let maxDecisions = 200

/// Append a routing decision to the ring buffer, evicting oldest if full.
let addDecision = (
  decisions: array<routingDecision>,
  decision: routingDecision,
): array<routingDecision> => {
  let next = Array.concat(decisions, [decision])
  if Array.length(next) > maxDecisions {
    next->Array.sliceToEnd(~start=Array.length(next) - maxDecisions)
  } else {
    next
  }
}

/// Route distribution statistics — (route_label, count, avg_latency_ms).
let routeStats = (decisions: array<routingDecision>): array<(string, int, float)> => {
  let routes: array<(string, routingStrategy)> = [
    ("Local FFI", RouteLocal),
    ("Axiom.jl", RouteRemote),
    ("BoJ Cartridge", RouteBoj),
  ]
  routes->Array.map(((label, strategy)) => {
    let matching = decisions->Array.filter(d => d.chosenRoute === strategy)
    let count = Array.length(matching)
    let avgLatency = if count == 0 {
      0.0
    } else {
      matching->Array.reduce(0.0, (acc, d) => acc +. d.latencyEstimateMs) /. Float.fromInt(count)
    }
    (label, count, avgLatency)
  })
}

/// Category distribution — (category_label, count).
let categoryStats = (decisions: array<routingDecision>): array<(string, int)> => {
  let categories: array<operationCategory> = [
    MatMul, Activation, Normalization, Hashing, Validation, Query, Analysis, General,
  ]
  categories->Array.filterMap(cat => {
    let catOps = decisions->Array.filter(d => classifyOperation(d.operation) === cat)
    let count = Array.length(catOps)
    if count > 0 {
      Some((categoryLabel(cat), count))
    } else {
      None
    }
  })
}
