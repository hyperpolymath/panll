// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Performance Profiler Model — frame budget, GC pressure, memory tracking.
/// This module has NO dependencies on other PanLL modules.

/// A single frame timing sample.
type frameSample = {
  frameNumber: int,
  renderMs: float,
  updateMs: float,
  gcMs: float,
  totalMs: float,
  timestamp: float,
}

/// Memory snapshot.
type memorySnapshot = {
  heapUsedBytes: int,
  heapTotalBytes: int,
  externalBytes: int,
  arrayBufferBytes: int,
  timestamp: float,
}

/// GC event.
type gcEvent = {
  kind: string,
  pauseMs: float,
  reclaimedBytes: int,
  timestamp: float,
}

/// Performance alert severity.
type perfAlertSeverity =
  | PerfInfo
  | PerfWarning
  | PerfCritical

/// Performance alert.
type perfAlert = {
  severity: perfAlertSeverity,
  message: string,
  metric: string,
  value: float,
  threshold: float,
  timestamp: float,
}

/// Active tab.
type performanceTab =
  | TabFrameBudget
  | TabMemory
  | TabGcPressure
  | TabAlerts
  | TabFlamegraph

/// Performance profiler state.
type performanceProfilerState = {
  activeTab: performanceTab,
  frameSamples: array<frameSample>,
  memorySnapshots: array<memorySnapshot>,
  gcEvents: array<gcEvent>,
  alerts: array<perfAlert>,
  profiling: bool,
  targetFps: float,
  frameBudgetMs: float,
  sampleInterval: int,
  error: option<string>,
}
