// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Observatory Model — integrative dashboard state.
///
/// Aggregates health, connection status, resource usage, and ambient
/// metrics across all panels. The observatory is the single pane of glass
/// for operational awareness.
///
/// This module has NO dependencies on other PanLL modules.

/// Service health status for a monitored endpoint.
type serviceHealth =
  | Healthy
  | Degraded(string)
  | Unreachable
  | Unknown

/// Resource usage snapshot for a panel or service.
type resourceSnapshot = {
  /// Panel or service name.
  name: string,
  /// Estimated memory usage in bytes (0 if unknown).
  memoryBytes: int,
  /// Whether the panel is currently active (visible/foreground).
  active: bool,
  /// Connection health for backend-dependent panels.
  health: serviceHealth,
  /// Last checked timestamp (ISO 8601).
  lastChecked: string,
}

/// Observatory dashboard tabs.
type observatoryTab =
  | TabOverview    // Summary grid of all panels + services
  | TabServices    // Service endpoint health checks
  | TabResources   // Memory, CPU, process budgets
  | TabActivity    // Recent panel activity log

/// Activity log entry.
type activityEntry = {
  /// Timestamp (ISO 8601).
  timestamp: string,
  /// Panel name that generated the event.
  panelName: string,
  /// Event description.
  event: string,
}

/// Root state for the Observatory panel.
type observatoryState = {
  /// Active tab.
  activeTab: observatoryTab,
  /// Resource snapshots for all panels.
  snapshots: array<resourceSnapshot>,
  /// Recent activity log.
  activity: array<activityEntry>,
  /// Whether a health check sweep is in progress.
  checking: bool,
  /// Error from last health check sweep.
  error: option<string>,
  /// System-level CPU percentage (0.0-100.0).
  systemCpu: float,
  /// System-level memory usage in bytes.
  systemMemory: int,
  /// System-level memory total in bytes.
  systemMemoryTotal: int,
  /// Structured debug log entries routed through Observatory.
  debugLog: array<DebugLogger.logEntry>,
}
