// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Performance Profiler Engine — pure functions for frame budget and memory analysis.

open PerformanceProfilerModel

/// Default initial state.
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
  error: None,
}

/// Tab label for display.
let tabLabel = (tab: performanceTab): string =>
  switch tab {
  | TabFrameBudget => "Frame Budget"
  | TabMemory => "Memory"
  | TabGcPressure => "GC Pressure"
  | TabAlerts => "Alerts"
  | TabFlamegraph => "Flamegraph"
  }

/// All tabs for rendering.
let allTabs: array<performanceTab> = [TabFrameBudget, TabMemory, TabGcPressure, TabAlerts, TabFlamegraph]

/// Calculate average frame time.
let avgFrameTime = (samples: array<frameSample>): float => {
  let count = samples->Array.length
  if count == 0 { 0.0 }
  else {
    let sum = samples->Array.reduce(0.0, (acc, s) => acc +. s.totalMs)
    sum /. Float.fromInt(count)
  }
}

/// Calculate FPS from frame samples.
let currentFps = (samples: array<frameSample>): float => {
  let avg = avgFrameTime(samples)
  if avg <= 0.0 { 0.0 } else { 1000.0 /. avg }
}

/// Count frames over budget.
let framesOverBudget = (samples: array<frameSample>, budgetMs: float): int =>
  samples->Array.filter(s => s.totalMs > budgetMs)->Array.length

/// Latest memory usage in MB.
let latestMemoryMb = (snapshots: array<memorySnapshot>): float => {
  let count = snapshots->Array.length
  if count == 0 { 0.0 }
  else {
    let latest = snapshots->Array.getUnsafe(count - 1)
    Float.fromInt(latest.heapUsedBytes) /. 1048576.0
  }
}

/// Alert severity label.
let severityLabel = (s: perfAlertSeverity): string =>
  switch s { | PerfInfo => "Info" | PerfWarning => "Warning" | PerfCritical => "Critical" }

/// Count alerts by severity.
let alertCount = (alerts: array<perfAlert>, severity: perfAlertSeverity): int =>
  alerts->Array.filter(a => a.severity == severity)->Array.length
