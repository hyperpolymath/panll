// SPDX-License-Identifier: PMPL-1.0-or-later

/// Coprocessors messages -- metrics refresh, call log, heatmap,
/// backend toggling, and filter controls for the IDApTIK coprocessor
/// monitoring dashboard.

open Model

type coprocessorsMsg =
  /// Switch the active category tab.
  | SetCoprocCategory(coprocessorsCategory)
  /// Refresh all metrics.
  | RefreshMetrics
  /// Metrics received.
  | MetricsReceived(result<string, string>)
  /// Refresh the call log.
  | RefreshCallLog
  /// Call log received.
  | CallLogReceived(result<string, string>)
  /// Refresh the heatmap.
  | RefreshHeatmap
  /// Heatmap received.
  | HeatmapReceived(result<string, string>)
  /// Toggle a coprocessor backend on/off.
  | ToggleCoprocBackend(coprocessorBackend)
  /// Backend toggle result.
  | BackendToggled(result<string, string>)
  /// Select a backend filter for the call log.
  | SelectBackendFilter(option<coprocessorBackend>)
  /// Toggle auto-refresh.
  | ToggleAutoRefresh
  /// Dismiss the error banner.
  | DismissCoprocError
  /// Query an external compute engine (Axiom.jl, BoJ cartridge).
  | QueryComputeEngine(string, string)
  /// Compute engine query result.
  | ComputeEngineResult(result<string, string>)
  /// Discover available compute devices.
  | DiscoverDevices
  /// Device discovery result.
  | DevicesDiscovered(result<string, string>)
  /// Toggle BoJ routing for compute operations (agent-mcp cartridge).
  | ToggleCoprocBojRouting
  /// Phase 2: Load the Zig FFI shared library for local GPU/CPU dispatch.
  | LoadLocalFfi
  /// Phase 2: FFI load result.
  | LocalFfiLoaded(result<string, string>)
  /// Phase 2: Dispatch a compute operation to local GPU/CPU via Zig FFI.
  | DispatchLocal(string, string)
  /// Phase 2: Local dispatch result.
  | LocalDispatchResult(result<string, string>)
  /// Phase 2: Query local system resources (CPU, GPU memory).
  | QueryLocalResources
  /// Phase 2: Local resources result.
  | LocalResourcesResult(result<string, string>)
  /// Phase 3: Set the routing strategy.
  | SetRoutingStrategy(routingStrategy)
  /// Phase 3: Smart route a compute operation (auto-selects local vs remote).
  | SmartDispatch(string, string)
  /// Phase 3: Smart routing result.
  | SmartDispatchResult(result<string, string>)
  /// TypeLL cross-panel type check result for compute types.
  | TypeCheckResult(result<string, string>)
