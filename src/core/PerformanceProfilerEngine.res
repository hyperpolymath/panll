// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Performance Profiler Engine — pure computation and helpers for the
/// Performance Profiler panel. Provides default state, frame timing statistics,
/// FPS calculation, memory analysis, GC pressure metrics, and alert management.

open PerformanceProfilerModel

/// Default initial state for the Performance Profiler panel.
/// Targets 60 FPS with a 16.67ms frame budget and 100ms sample interval.
let defaultState: performanceProfilerState = {
  activeTab: TabFrameBudget,
  frameSamples: [],
  memorySnapshots: [],
  gcEvents: [],
  alerts: [],
  profiling: false,
  targetFps: 60.0,
  frameBudgetMs: 16.67,
  sampleInterval: 100,
  thresholds: None,
  error: None,
}

/// Human-readable label for each tab in the Performance Profiler panel.
let tabLabel = (tab: performanceTab): string =>
  switch tab {
  | TabFrameBudget => "Frame Budget"
  | TabMemory => "Memory"
  | TabGcPressure => "GC Pressure"
  | TabAlerts => "Alerts"
  | TabFlamegraph => "Flamegraph"
  }

/// All tabs in display order.
let allTabs: array<performanceTab> = [
  TabFrameBudget,
  TabMemory,
  TabGcPressure,
  TabAlerts,
  TabFlamegraph,
]

/// Calculate average frame time across all samples.
let avgFrameTime = (samples: array<frameSample>): float => {
  let count = samples->Array.length
  if count == 0 {
    0.0
  } else {
    let sum = samples->Array.reduce(0.0, (acc, s) => acc +. s.totalMs)
    sum /. Float.fromInt(count)
  }
}

/// Calculate current effective FPS from frame samples.
let currentFps = (samples: array<frameSample>): float => {
  let avg = avgFrameTime(samples)
  if avg <= 0.0 {
    0.0
  } else {
    1000.0 /. avg
  }
}

/// Count frames that exceeded the budget.
let framesOverBudget = (samples: array<frameSample>, budgetMs: float): int =>
  samples->Array.filter(s => s.totalMs > budgetMs)->Array.length

/// Percentage of frames over budget.
let overBudgetPercent = (samples: array<frameSample>, budgetMs: float): float => {
  let total = Array.length(samples)
  if total == 0 {
    0.0
  } else {
    Float.fromInt(framesOverBudget(samples, budgetMs)) /. Float.fromInt(total) *. 100.0
  }
}

/// Maximum frame time observed.
let maxFrameTime = (samples: array<frameSample>): float =>
  samples->Array.reduce(0.0, (acc, s) =>
    if s.totalMs > acc {
      s.totalMs
    } else {
      acc
    }
  )

/// Average render time (PixiJS render phase only).
let avgRenderTime = (samples: array<frameSample>): float => {
  let count = samples->Array.length
  if count == 0 {
    0.0
  } else {
    let sum = samples->Array.reduce(0.0, (acc, s) => acc +. s.renderMs)
    sum /. Float.fromInt(count)
  }
}

/// Average update (logic) time.
let avgUpdateTime = (samples: array<frameSample>): float => {
  let count = samples->Array.length
  if count == 0 {
    0.0
  } else {
    let sum = samples->Array.reduce(0.0, (acc, s) => acc +. s.updateMs)
    sum /. Float.fromInt(count)
  }
}

/// Latest memory usage in MB.
let latestMemoryMb = (snapshots: array<memorySnapshot>): float => {
  let count = snapshots->Array.length
  if count == 0 {
    0.0
  } else {
    let latest = snapshots->Array.getUnsafe(count - 1)
    Float.fromInt(latest.heapUsedBytes) /. 1048576.0
  }
}

/// Peak memory usage across all snapshots in MB.
let peakMemoryMb = (snapshots: array<memorySnapshot>): float =>
  snapshots->Array.reduce(0.0, (acc, s) => {
    let mb = Float.fromInt(s.heapUsedBytes) /. 1048576.0
    if mb > acc {
      mb
    } else {
      acc
    }
  })

/// Total GC pause time across all events.
let totalGcPauseMs = (events: array<gcEvent>): float =>
  events->Array.reduce(0.0, (acc, e) => acc +. e.pauseMs)

/// Average GC pause duration.
let avgGcPauseMs = (events: array<gcEvent>): float => {
  let count = events->Array.length
  if count == 0 {
    0.0
  } else {
    totalGcPauseMs(events) /. Float.fromInt(count)
  }
}

/// Human-readable alert severity label.
let severityLabel = (s: perfAlertSeverity): string =>
  switch s {
  | PerfInfo => "Info"
  | PerfWarning => "Warning"
  | PerfCritical => "Critical"
  }

/// CSS colour class for alert severity.
let severityColor = (s: perfAlertSeverity): string =>
  switch s {
  | PerfInfo => "text-blue-400"
  | PerfWarning => "text-yellow-400"
  | PerfCritical => "text-red-400"
  }

/// Count alerts by severity.
let alertCount = (alerts: array<perfAlert>, severity: perfAlertSeverity): int =>
  alerts->Array.filter(a => a.severity == severity)->Array.length

/// Total bytes reclaimed by GC.
let totalBytesReclaimed = (events: array<gcEvent>): int =>
  events->Array.reduce(0, (acc, e) => acc + e.reclaimedBytes)
