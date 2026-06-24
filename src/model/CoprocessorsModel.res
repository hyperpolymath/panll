// SPDX-License-Identifier: MPL-2.0

/// PanLL Coprocessors Model — types for monitoring IDApTIK's coprocessor
/// backends (Compute, Security, I/O). Call log, heatmap, performance
/// metrics, backend toggles, and health status.

/// Coprocessor backend identity.
type coprocessorBackend =
  | CoprocMaths
  | CoprocVector
  | CoprocTensor
  | CoprocPhysics
  | CoprocCrypto
  | CoprocNeural
  | CoprocQuantum
  | CoprocAudio
  | CoprocGraphics
  | CoprocIO

/// Coprocessor health status.
type coprocHealth =
  | CoprocHealthy
  | CoprocDegraded
  | CoprocFailed
  | CoprocDisabled

/// A call log entry from a coprocessor invocation.
type coprocCallEntry = {
  id: int,
  backend: coprocessorBackend,
  operation: string,
  inputSummary: string,
  outputSummary: string,
  durationMs: float,
  timestamp: float,
  success: bool,
}

/// Performance metrics for a coprocessor backend.
type coprocMetrics = {
  backend: coprocessorBackend,
  totalCalls: int,
  avgDurationMs: float,
  maxDurationMs: float,
  errorRate: float,
  lastCallTimestamp: float,
  health: coprocHealth,
}

/// Heatmap cell — represents call frequency for a backend over a time slot.
type heatmapCell = {
  backend: coprocessorBackend,
  timeSlot: int,
  callCount: int,
  avgDuration: float,
}

/// Category tabs for the Coprocessors panel.
type coprocessorsCategory =
  | CoprocDashboard
  | CoprocCallLog
  | CoprocHeatmap
  | CoprocRouting
  | CoprocSettings

/// Compute engine identity — external services that provide compute.
type computeEngine =
  /// Axiom.jl — Julia-based multi-backend compute with SmartBackend dispatch.
  | EngineAxiom
  /// BoJ cartridge — Zig FFI compute via cartridge ABI.
  | EngineBoJ
  /// Local CPU/WASM — direct in-process compute (Phase 2).
  | EngineLocal

/// A discovered compute device from a compute engine.
type computeDevice = {
  engineId: computeEngine,
  deviceName: string,
  deviceType: string,
  available: bool,
  capabilities: array<string>,
}

/// A compute query result from an engine.
type computeQueryResult = {
  engineId: computeEngine,
  operation: string,
  result: string,
  durationMs: float,
  success: bool,
}

/// Routing strategy for compute dispatch.
type routingStrategy =
  /// Use local Zig FFI (fastest, no network).
  | RouteLocal
  /// Use remote Axiom.jl (most capable).
  | RouteRemote
  /// Use BoJ cartridge (unified API).
  | RouteBoj
  /// Smart routing — engine decides based on load, capabilities, availability.
  | RouteAutomatic

/// Local dispatch state for Phase 2.
type localDispatchState = {
  /// Whether the Zig FFI shared library (.so) is loaded.
  ffiLoaded: bool,
  /// Path to the Zig FFI .so file.
  ffiPath: string,
  /// Filesystem path passed to coprocessor_load_ffi (may differ from ffiPath
  /// if the user specified a custom location).
  ffiLibPath: option<string>,
  /// Available local devices (GPU, CPU cores).
  localDevices: array<computeDevice>,
  /// Current CPU utilisation (0.0–1.0).
  cpuUtilisation: float,
  /// Available GPU memory in MB (0 if no GPU).
  gpuMemoryMb: int,
  /// Number of pending local dispatches.
  pendingDispatches: int,
  /// Number of CPU cores available for local dispatch.
  cpuCores: int,
  /// Backend names available through the loaded FFI library.
  availableBackends: array<string>,
}

/// Routing decision record — tracks why a particular route was chosen.
type routingDecision = {
  /// The operation that was routed.
  operation: string,
  /// The route that was chosen.
  chosenRoute: routingStrategy,
  /// Human-readable reason for the choice.
  reason: string,
  /// Estimated latency for this route in milliseconds.
  latencyEstimateMs: float,
  /// Timestamp when the decision was made.
  timestamp: float,
}

/// Root state for the Coprocessors panel.
type coprocessorsState = {
  activeCategory: coprocessorsCategory,
  metrics: array<coprocMetrics>,
  callLog: array<coprocCallEntry>,
  heatmap: array<heatmapCell>,
  enabledBackends: array<coprocessorBackend>,
  selectedBackend: option<coprocessorBackend>,
  filterText: string,
  autoRefresh: bool,
  refreshIntervalMs: int,
  loading: bool,
  error: option<string>,
  /// Control plane: discovered compute devices from external engines.
  discoveredDevices: array<computeDevice>,
  /// Control plane: most recent compute query result.
  lastComputeResult: option<computeQueryResult>,
  /// When true, compute operations route through BoJ agent-mcp cartridge instead of direct HTTP.
  bojRouting: bool,
  /// Phase 2: Local dispatch state.
  localDispatch: localDispatchState,
  /// Phase 3: Active routing strategy.
  routingStrategy: routingStrategy,
  /// Phase 3: Recent routing decisions for audit trail.
  routingHistory: array<routingDecision>,
}
