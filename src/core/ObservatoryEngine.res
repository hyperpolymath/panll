// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Observatory Engine — pure helpers for the integrative dashboard.
///
/// The Observatory is the single pane of glass for operational awareness across
/// all PanLL panels. It aggregates:
///   - Panel health status (Healthy / Degraded / Unreachable / Unknown)
///   - System resource usage (CPU, memory)
///   - Activity logs from all panels
///   - Structured debug log entries (routed via DebugLogger)
///
/// All functions are pure — no side effects, no Tauri invocations.
/// Command wrappers for health-check polling and system stats live in
/// ObservatoryCmd.res (if present).

open ObservatoryModel

// ============================================================================
// Default State
// ============================================================================

/// Default initial state. All panels start with empty snapshots and the
/// overview tab selected. System metrics are zeroed until the first poll.
let defaultState: observatoryState = {
  activeTab: TabOverview,
  snapshots: [],
  activity: [],
  checking: false,
  error: None,
  systemCpu: 0.0,
  systemMemory: 0,
  systemMemoryTotal: 0,
  debugLog: [],
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Human-readable label for each observatory tab.
let tabLabel = (tab: observatoryTab): string => {
  switch tab {
  | TabOverview => "Overview"
  | TabServices => "Services"
  | TabResources => "Resources"
  | TabActivity => "Activity"
  }
}

/// Complete list of tabs in display order. Used by the tab bar renderer
/// to iterate all available views.
let allTabs: array<observatoryTab> = [TabOverview, TabServices, TabResources, TabActivity]

/// Switch to a specific tab, returning an updated state.
let switchTab = (state: observatoryState, tab: observatoryTab): observatoryState => {
  {...state, activeTab: tab}
}

// ============================================================================
// Health Status Helpers
// ============================================================================

/// Human-readable label for a service health status. Degraded includes
/// its reason string for contextual display in the dashboard.
let healthLabel = (h: serviceHealth): string => {
  switch h {
  | Healthy => "Healthy"
  | Degraded(reason) => "Degraded: " ++ reason
  | Unreachable => "Unreachable"
  | Unknown => "Unknown"
  }
}

/// CSS-compatible severity class for a health status. Useful for mapping
/// health values to colour-coded indicators in the UI.
let healthSeverityClass = (h: serviceHealth): string => {
  switch h {
  | Healthy => "severity-ok"
  | Degraded(_) => "severity-warn"
  | Unreachable => "severity-critical"
  | Unknown => "severity-unknown"
  }
}

/// Numeric severity ranking for sorting (lower is healthier).
/// Healthy=0, Degraded=1, Unknown=2, Unreachable=3.
let healthSeverity = (h: serviceHealth): int => {
  switch h {
  | Healthy => 0
  | Degraded(_) => 1
  | Unknown => 2
  | Unreachable => 3
  }
}

/// Check whether a health status is considered "unhealthy" — meaning it
/// requires attention. Degraded and Unreachable both qualify.
let isUnhealthy = (h: serviceHealth): bool => {
  switch h {
  | Healthy | Unknown => false
  | Degraded(_) | Unreachable => true
  }
}

/// Whether the given health status represents a fully healthy service.
/// Returns true only for the `Healthy` variant; Degraded, Unreachable,
/// and Unknown are all considered not healthy.
let isHealthy = (health: serviceHealth): bool => {
  switch health {
  | Healthy => true
  | Degraded(_) | Unreachable | Unknown => false
  }
}

/// Tailwind CSS class for a health status badge background colour.
/// Maps each health variant to a distinct Tailwind utility class:
/// - Healthy: green-500
/// - Degraded: yellow-500 (amber warning)
/// - Unreachable: red-500 (critical)
/// - Unknown: gray-400 (indeterminate)
let healthColor = (health: serviceHealth): string => {
  switch health {
  | Healthy => "bg-green-500"
  | Degraded(_) => "bg-yellow-500"
  | Unreachable => "bg-red-500"
  | Unknown => "bg-gray-400"
  }
}

/// Unicode icon for inline health status display.
/// Returns a standard emoji for cross-platform rendering:
/// - Healthy: check mark
/// - Degraded: warning triangle
/// - Unreachable: cross mark
/// - Unknown: question mark
let healthIcon = (health: serviceHealth): string => {
  switch health {
  | Healthy => "\u{2705}"
  | Degraded(_) => "\u{26A0}\u{FE0F}"
  | Unreachable => "\u{274C}"
  | Unknown => "\u{2753}"
  }
}

/// Whether the service can be reached at all. Returns true for Healthy,
/// Degraded, and Unknown (assumed reachable until proven otherwise).
/// Only Unreachable returns false.
let isReachable = (health: serviceHealth): bool => {
  switch health {
  | Healthy | Degraded(_) | Unknown => true
  | Unreachable => false
  }
}

/// Human-readable reason string explaining why a service is not fully healthy.
/// Returns an empty string for Healthy. For Degraded, returns the embedded
/// reason. For Unreachable and Unknown, returns a generic explanation.
let degradationReason = (health: serviceHealth): string => {
  switch health {
  | Healthy => ""
  | Degraded(reason) => reason
  | Unreachable => "Service is unreachable"
  | Unknown => "Health status has not been determined"
  }
}

// ============================================================================
// Snapshot Queries
// ============================================================================

/// Count panels whose health matches a target status.
let countByHealth = (snapshots: array<resourceSnapshot>, target: serviceHealth): int => {
  snapshots->Array.filter(s => s.health == target)->Array.length
}

/// Count panels that are in any unhealthy state (Degraded or Unreachable).
let countUnhealthy = (snapshots: array<resourceSnapshot>): int => {
  snapshots->Array.filter(s => isUnhealthy(s.health))->Array.length
}

/// Total memory usage in bytes across all panel snapshots.
let totalMemory = (snapshots: array<resourceSnapshot>): int => {
  snapshots->Array.reduce(0, (acc, s) => acc + s.memoryBytes)
}

/// Average memory usage per panel in bytes. Returns 0 for empty arrays.
let averageMemory = (snapshots: array<resourceSnapshot>): int => {
  let count = snapshots->Array.length
  if count == 0 {
    0
  } else {
    totalMemory(snapshots) / count
  }
}

/// Peak (maximum) memory usage in bytes among all snapshots.
/// Returns 0 if the snapshots array is empty.
let peakMemory = (snapshots: array<resourceSnapshot>): int => {
  snapshots->Array.reduce(0, (acc, s) => {
    if s.memoryBytes > acc {
      s.memoryBytes
    } else {
      acc
    }
  })
}

/// Memory usage as a percentage (0.0 to 100.0). Returns 0.0 if `total`
/// is zero to avoid division by zero. Both `used` and `total` should be
/// in the same unit (bytes).
let memoryPercentage = (used: int, total: int): float => {
  if total == 0 {
    0.0
  } else {
    Float.fromInt(used) /. Float.fromInt(total) *. 100.0
  }
}

/// Count of snapshots whose health status is not Healthy.
/// Includes Degraded, Unreachable, and Unknown statuses. Differs from
/// `countUnhealthy` which excludes Unknown.
let unhealthyCount = (snapshots: array<resourceSnapshot>): int => {
  snapshots->Array.filter(s => !isHealthy(s.health))->Array.length
}

/// Count of snapshots whose service is reachable (not Unreachable).
/// Healthy, Degraded, and Unknown are all considered reachable.
let reachableCount = (snapshots: array<resourceSnapshot>): int => {
  snapshots->Array.filter(s => isReachable(s.health))->Array.length
}

/// Count of snapshots whose panel is currently active (visible/foreground).
/// Uses the `active` field from each resourceSnapshot.
let activeCount = (snapshots: array<resourceSnapshot>): int => {
  snapshots->Array.filter(s => s.active)->Array.length
}

/// Find the panel consuming the most memory. Returns None for empty arrays.
let highestMemoryPanel = (snapshots: array<resourceSnapshot>): option<resourceSnapshot> => {
  snapshots->Array.reduce(None, (acc, s) => {
    switch acc {
    | None => Some(s)
    | Some(current) =>
      if s.memoryBytes > current.memoryBytes {
        Some(s)
      } else {
        acc
      }
    }
  })
}

/// Find all panels exceeding a memory threshold (in bytes).
/// Useful for flagging panels that may have memory leaks.
let panelsExceedingMemory = (snapshots: array<resourceSnapshot>, thresholdBytes: int): array<
  resourceSnapshot,
> => {
  snapshots->Array.filter(s => s.memoryBytes > thresholdBytes)
}

/// Filter snapshots to only those with active (visible/foreground) panels.
let activeSnapshots = (snapshots: array<resourceSnapshot>): array<resourceSnapshot> => {
  snapshots->Array.filter(s => s.active)
}

/// Filter snapshots to only those with inactive (background) panels.
let inactiveSnapshots = (snapshots: array<resourceSnapshot>): array<resourceSnapshot> => {
  snapshots->Array.filter(s => !s.active)
}

/// Sort snapshots by health severity (worst first), then by name alphabetically.
/// This places Unreachable and Degraded panels at the top for quick triage.
let sortByHealthSeverity = (snapshots: array<resourceSnapshot>): array<resourceSnapshot> => {
  snapshots->Array.toSorted((a, b) => {
    let severityDiff = Float.fromInt(healthSeverity(b.health) - healthSeverity(a.health))
    if severityDiff !== 0.0 {
      severityDiff
    } // Alphabetical tiebreaker for panels at the same severity.
    else if a.name < b.name {
      -1.0
    } else if a.name > b.name {
      1.0
    } else {
      0.0
    }
  })
}

/// Sort snapshots by health status with Healthy first and Unknown last.
/// Order: Healthy(0) -> Degraded(1) -> Unreachable(2) -> Unknown(3).
/// Within the same health tier, original order is preserved.
let sortByHealth = (snapshots: array<resourceSnapshot>): array<resourceSnapshot> => {
  let priority = (h: serviceHealth): int => {
    switch h {
    | Healthy => 0
    | Degraded(_) => 1
    | Unreachable => 2
    | Unknown => 3
    }
  }
  snapshots->Array.toSorted((a, b) => {
    Float.fromInt(priority(a.health) - priority(b.health))
  })
}

/// Filter snapshots to only those matching a specific health status.
/// Uses structural equality on the serviceHealth variant.
let panelsByHealth = (snapshots: array<resourceSnapshot>, health: serviceHealth): array<
  resourceSnapshot,
> => {
  snapshots->Array.filter(s => s.health == health)
}

/// Sort snapshots by memory usage (highest first). Useful for the
/// Resources tab to highlight memory-hungry panels.
let sortByMemoryDesc = (snapshots: array<resourceSnapshot>): array<resourceSnapshot> => {
  snapshots->Array.toSorted((a, b) => {
    Float.fromInt(b.memoryBytes - a.memoryBytes)
  })
}

/// Find a snapshot by panel name. Returns None if not found.
let findSnapshot = (snapshots: array<resourceSnapshot>, panelName: string): option<
  resourceSnapshot,
> => {
  snapshots->Array.find(s => s.name === panelName)
}

// ============================================================================
// Snapshot Updates
// ============================================================================

/// Upsert a resource snapshot — updates the entry for a panel if it exists,
/// or appends it if it does not. This is the primary way panels report
/// their status to the Observatory.
let upsertSnapshot = (state: observatoryState, snapshot: resourceSnapshot): observatoryState => {
  let exists = state.snapshots->Array.some(s => s.name === snapshot.name)
  let updatedSnapshots = if exists {
    state.snapshots->Array.map(s =>
      if s.name === snapshot.name {
        snapshot
      } else {
        s
      }
    )
  } else {
    Array.concat(state.snapshots, [snapshot])
  }
  {...state, snapshots: updatedSnapshots}
}

/// Remove a snapshot by panel name. Used when a panel is unloaded or
/// removed from the workspace.
let removeSnapshot = (state: observatoryState, panelName: string): observatoryState => {
  {...state, snapshots: state.snapshots->Array.filter(s => s.name !== panelName)}
}

/// Replace all snapshots at once (bulk update from a health-check sweep).
let replaceAllSnapshots = (
  state: observatoryState,
  snapshots: array<resourceSnapshot>,
): observatoryState => {
  {...state, snapshots}
}

// ============================================================================
// System Health Summary
// ============================================================================

/// Whether CPU usage exceeds the warning threshold (80%).
/// Returns true when the system should display a CPU warning indicator.
let cpuWarning = (cpu: float): bool => {
  cpu > 80.0
}

/// Whether memory usage exceeds the warning threshold (90%).
/// Computed from raw byte values via `memoryPercentage`. Returns false
/// if `total` is zero (avoids division by zero).
let memoryWarning = (used: int, total: int): bool => {
  memoryPercentage(used, total) > 90.0
}

/// Compute a system health badge string based on CPU and memory metrics.
/// Three tiers:
/// - "Critical": CPU > 90% or memory > 95%
/// - "Warning": CPU > 80% or memory > 90%
/// - "Healthy": all metrics within normal range
let systemHealthBadge = (cpu: float, memory: int, memoryTotal: int): string => {
  let memPct = memoryPercentage(memory, memoryTotal)
  if cpu > 90.0 || memPct > 95.0 {
    "Critical"
  } else if cpu > 80.0 || memPct > 90.0 {
    "Warning"
  } else {
    "Healthy"
  }
}

/// Whether the system is operating within normal parameters.
/// Returns true only when neither CPU nor memory warnings are triggered.
let systemOkay = (cpu: float, memory: int, memoryTotal: int): bool => {
  !cpuWarning(cpu) && !memoryWarning(memory, memoryTotal)
}

// ============================================================================
// System Metrics
// ============================================================================

/// Update the system-level CPU percentage (0.0-100.0).
let updateSystemCpu = (state: observatoryState, cpuPercent: float): observatoryState => {
  {...state, systemCpu: cpuPercent}
}

/// Update the system-level memory usage and total (both in bytes).
let updateSystemMemory = (
  state: observatoryState,
  usedBytes: int,
  totalBytes: int,
): observatoryState => {
  {...state, systemMemory: usedBytes, systemMemoryTotal: totalBytes}
}

/// Compute the system memory usage as a percentage (0.0-100.0).
/// Returns 0.0 if the total is zero (not yet polled).
let systemMemoryPercent = (state: observatoryState): float => {
  if state.systemMemoryTotal == 0 {
    0.0
  } else {
    Float.fromInt(state.systemMemory) /. Float.fromInt(state.systemMemoryTotal) *. 100.0
  }
}

/// Determine overall system health based on CPU and memory thresholds.
/// Returns Healthy if both are below warning levels, Degraded if either
/// exceeds a warning threshold, Unreachable should not occur for system metrics.
let systemHealthFromMetrics = (state: observatoryState): serviceHealth => {
  let memPercent = systemMemoryPercent(state)
  let cpuHigh = state.systemCpu > 90.0
  let memHigh = memPercent > 90.0
  let cpuWarn = state.systemCpu > 75.0
  let memWarn = memPercent > 75.0
  if cpuHigh && memHigh {
    Degraded("CPU and memory critically high")
  } else if cpuHigh {
    Degraded("CPU critically high (" ++ Float.toFixed(state.systemCpu, ~digits=1) ++ "%)")
  } else if memHigh {
    Degraded("Memory critically high (" ++ Float.toFixed(memPercent, ~digits=1) ++ "%)")
  } else if cpuWarn || memWarn {
    Degraded("Resource pressure elevated")
  } else {
    Healthy
  }
}

// ============================================================================
// Health Check Sweep Lifecycle
// ============================================================================

/// Mark that a health-check sweep has started. Clears any previous error.
let beginHealthCheck = (state: observatoryState): observatoryState => {
  {...state, checking: true, error: None}
}

/// Mark that a health-check sweep completed successfully.
let completeHealthCheck = (state: observatoryState): observatoryState => {
  {...state, checking: false}
}

/// Mark that a health-check sweep failed with an error message.
let failHealthCheck = (state: observatoryState, errorMsg: string): observatoryState => {
  {...state, checking: false, error: Some(errorMsg)}
}

// ============================================================================
// Activity Log
// ============================================================================

/// Maximum number of activity entries to retain. Older entries are
/// evicted when new ones arrive to prevent unbounded growth.
let maxActivityEntries = 500

/// Append an activity entry to the log. If the log exceeds the maximum
/// size, the oldest entries are removed to make room.
let addActivity = (state: observatoryState, entry: activityEntry): observatoryState => {
  let updated = Array.concat(state.activity, [entry])
  let trimmed = if updated->Array.length > maxActivityEntries {
    // Keep only the most recent entries by slicing from the end.
    updated->Array.slice(
      ~start=updated->Array.length - maxActivityEntries,
      ~end=updated->Array.length,
    )
  } else {
    updated
  }
  {...state, activity: trimmed}
}

/// Add an activity entry to a raw log array. The new entry is prepended
/// (most recent first) and the log is capped at 200 entries to prevent
/// unbounded growth. Returns a new array; the original is not mutated.
/// This standalone variant operates on the array directly, unlike
/// `addActivity` which operates on state.
let addActivityEntry = (
  log: array<activityEntry>,
  timestamp: string,
  panelName: string,
  event: string,
): array<activityEntry> => {
  let entry: activityEntry = {timestamp, panelName, event}
  let combined = Array.concat([entry], log)
  if combined->Array.length > 200 {
    combined->Array.slice(~start=0, ~end=200)
  } else {
    combined
  }
}

/// Create and append an activity entry in one step.
let logActivity = (
  state: observatoryState,
  ~timestamp: string,
  ~panelName: string,
  ~event: string,
): observatoryState => {
  let entry: activityEntry = {
    timestamp,
    panelName,
    event,
  }
  addActivity(state, entry)
}

/// Filter activity entries for a specific panel.
let activityForPanel = (activity: array<activityEntry>, panelName: string): array<
  activityEntry,
> => {
  activity->Array.filter(a => a.panelName === panelName)
}

/// Get the N most recent activity entries.
let recentActivity = (activity: array<activityEntry>, count: int): array<activityEntry> => {
  let len = activity->Array.length
  if len <= count {
    activity
  } else {
    activity->Array.slice(~start=len - count, ~end=len)
  }
}

/// Clear all activity entries.
let clearActivity = (state: observatoryState): observatoryState => {
  {...state, activity: []}
}

// ============================================================================
// Debug Log Integration
// ============================================================================

/// Maximum number of debug log entries to retain.
let maxDebugLogEntries = 1000

/// Append a structured debug log entry. Evicts oldest entries when
/// the log exceeds the maximum size.
let addDebugEntry = (state: observatoryState, entry: DebugLogger.logEntry): observatoryState => {
  let updated = Array.concat(state.debugLog, [entry])
  let trimmed = if updated->Array.length > maxDebugLogEntries {
    updated->Array.slice(
      ~start=updated->Array.length - maxDebugLogEntries,
      ~end=updated->Array.length,
    )
  } else {
    updated
  }
  {...state, debugLog: trimmed}
}

/// Filter debug log entries by minimum severity level.
/// Debug < Info < Warn < Error.
let debugEntriesAtLevel = (
  entries: array<DebugLogger.logEntry>,
  minLevel: DebugLogger.logLevel,
): array<DebugLogger.logEntry> => {
  let minSeverity = DebugLogger.levelToOtelSeverity(minLevel)
  entries->Array.filter(e => DebugLogger.levelToOtelSeverity(e.level) >= minSeverity)
}

/// Filter debug log entries by source module name.
let debugEntriesFromSource = (entries: array<DebugLogger.logEntry>, source: string): array<
  DebugLogger.logEntry,
> => {
  entries->Array.filter(e => e.source === source)
}

/// Count debug log entries by level. Returns a tuple of
/// (debugCount, infoCount, warnCount, errorCount).
let debugLogCounts = (entries: array<DebugLogger.logEntry>): (int, int, int, int) => {
  entries->Array.reduce((0, 0, 0, 0), ((d, i, w, e), entry) => {
    switch entry.level {
    | Debug => (d + 1, i, w, e)
    | Info => (d, i + 1, w, e)
    | Warn => (d, i, w + 1, e)
    | Error => (d, i, w, e + 1)
    }
  })
}

/// Return the most recent `count` debug log entries. Since entries are
/// stored chronologically (oldest first), this returns the last `count`
/// entries from the array. Returns the full array if `count` exceeds length.
let recentDebugEntries = (log: array<DebugLogger.logEntry>, count: int): array<
  DebugLogger.logEntry,
> => {
  let len = log->Array.length
  if count >= len {
    log
  } else {
    log->Array.slice(~start=len - count, ~end=len)
  }
}

/// Clear all debug log entries.
let clearDebugLog = (state: observatoryState): observatoryState => {
  {...state, debugLog: []}
}

// ============================================================================
// Dashboard Summary Helpers
// ============================================================================

/// Produce a concise text summary of the current observatory state.
/// Designed for the Overview tab's status badge and tooltip.
///
/// Example outputs:
///   "All 12 panels healthy"
///   "2 of 12 panels unhealthy — CPU 82.3%"
///   "No panels registered"
let overviewSummary = (state: observatoryState): string => {
  let total = state.snapshots->Array.length
  if total == 0 {
    "No panels registered"
  } else {
    let unhealthy = countUnhealthy(state.snapshots)
    let baseMsg = if unhealthy == 0 {
      "All " ++ Int.toString(total) ++ " panels healthy"
    } else {
      Int.toString(unhealthy) ++ " of " ++ Int.toString(total) ++ " panels unhealthy"
    }
    // Append system resource note if under pressure.
    let memPercent = systemMemoryPercent(state)
    if state.systemCpu > 75.0 || memPercent > 75.0 {
      baseMsg ++ " — CPU " ++ Float.toFixed(state.systemCpu, ~digits=1) ++ "%"
    } else {
      baseMsg
    }
  }
}

/// Determine whether the observatory should display an alert indicator.
/// True if any panel is unhealthy or system resources are under pressure.
let hasAlerts = (state: observatoryState): bool => {
  let unhealthy = countUnhealthy(state.snapshots) > 0
  let cpuPressure = state.systemCpu > 90.0
  let memPressure = systemMemoryPercent(state) > 90.0
  let hasErrors = state.error->Option.isSome
  unhealthy || cpuPressure || memPressure || hasErrors
}

/// Count the total number of active alerts (unhealthy panels + resource warnings + errors).
let alertCount = (state: observatoryState): int => {
  let unhealthyPanels = countUnhealthy(state.snapshots)
  let cpuAlert = if state.systemCpu > 90.0 {
    1
  } else {
    0
  }
  let memAlert = if systemMemoryPercent(state) > 90.0 {
    1
  } else {
    0
  }
  let errorAlert = switch state.error {
  | Some(_) => 1
  | None => 0
  }
  unhealthyPanels + cpuAlert + memAlert + errorAlert
}

// ============================================================================
// Formatting Utilities
// ============================================================================

/// Format a byte count as a human-readable string (B, KB, MB, GB).
/// Uses binary units (1 KB = 1024 bytes).
let formatBytes = (bytes: int): string => {
  let b = Float.fromInt(bytes)
  if b >= 1073741824.0 {
    Float.toFixed(b /. 1073741824.0, ~digits=2) ++ " GB"
  } else if b >= 1048576.0 {
    Float.toFixed(b /. 1048576.0, ~digits=1) ++ " MB"
  } else if b >= 1024.0 {
    Float.toFixed(b /. 1024.0, ~digits=0) ++ " KB"
  } else {
    Int.toString(bytes) ++ " B"
  }
}

/// Format a CPU percentage with one decimal place and a percent sign.
let formatCpu = (cpuPercent: float): string => {
  Float.toFixed(cpuPercent, ~digits=1) ++ "%"
}

/// Format a memory ratio as "used / total" with human-readable byte units.
let formatMemoryRatio = (usedBytes: int, totalBytes: int): string => {
  formatBytes(usedBytes) ++ " / " ++ formatBytes(totalBytes)
}
