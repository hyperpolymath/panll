// SPDX-License-Identifier: PMPL-1.0-or-later

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
}
