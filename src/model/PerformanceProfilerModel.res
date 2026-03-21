// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Performance Profiler Model — frame budget tracking, GC pressure
/// gauging, and memory flamegraphs for IDApTIK's PixiJS render loop.
///
/// Integrates with the PixiJS render loop to capture per-frame timings,
/// monitors V8 heap usage and GC activity, and raises alerts when metrics
/// exceed configured thresholds (e.g., frame budget, GC pause ceiling).
///
/// Clade: Inspector. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Frame Timing
// ============================================================================

/// A single frame timing sample from the PixiJS render loop.
type frameSample = {
  /// Frame sequence number.
  frameNumber: int,
  /// Time spent in the render phase in milliseconds.
  renderMs: float,
  /// Time spent in the update (logic) phase in milliseconds.
  updateMs: float,
  /// Time spent in garbage collection pauses in milliseconds.
  gcMs: float,
  /// Total frame time (render + update + gc + overhead) in milliseconds.
  totalMs: float,
  /// Epoch timestamp of this sample.
  timestamp: float,
}

// ============================================================================
// Memory Tracking
// ============================================================================

/// A snapshot of V8 heap memory usage.
type memorySnapshot = {
  /// Bytes used on the V8 heap.
  heapUsedBytes: int,
  /// Total V8 heap allocation in bytes.
  heapTotalBytes: int,
  /// External memory (C++ objects tracked by V8) in bytes.
  externalBytes: int,
  /// ArrayBuffer memory in bytes.
  arrayBufferBytes: int,
  /// Epoch timestamp of this snapshot.
  timestamp: float,
}

// ============================================================================
// GC Events
// ============================================================================

/// A garbage collection event captured from the V8 runtime.
type gcEvent = {
  /// GC type (e.g., "scavenge", "mark-sweep").
  kind: string,
  /// Pause duration in milliseconds.
  pauseMs: float,
  /// Bytes reclaimed by this GC cycle.
  reclaimedBytes: int,
  /// Epoch timestamp of this event.
  timestamp: float,
}

// ============================================================================
// Performance Alerts
// ============================================================================

/// Severity classification for performance alerts.
type perfAlertSeverity =
  /// Informational — metric approaching threshold.
  | PerfInfo
  /// Warning — metric has breached the warning threshold.
  | PerfWarning
  /// Critical — metric has breached the critical threshold, action required.
  | PerfCritical

/// A performance alert triggered when a metric exceeds its threshold.
type perfAlert = {
  /// Alert severity.
  severity: perfAlertSeverity,
  /// Human-readable alert message.
  message: string,
  /// Name of the metric that triggered the alert (e.g., "frame_time").
  metric: string,
  /// Current value of the metric.
  value: float,
  /// Threshold that was exceeded.
  threshold: float,
  /// Epoch timestamp of the alert.
  timestamp: float,
}

/// Performance threshold configuration for alert triggering.
type perfThresholds = {
  /// Frame time warning threshold in milliseconds (default: frameBudgetMs * 1.2).
  frameTimeWarnMs: float,
  /// Frame time critical threshold in milliseconds (default: frameBudgetMs * 2.0).
  frameTimeCritMs: float,
  /// GC pause warning threshold in milliseconds.
  gcPauseWarnMs: float,
  /// Heap usage warning threshold in bytes.
  heapWarnBytes: int,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Performance Profiler panel.
type performanceTab =
  /// Frame Budget — per-frame timing breakdown with budget line.
  | TabFrameBudget
  /// Memory — heap usage timeline and allocation trends.
  | TabMemory
  /// GC Pressure — GC event frequency and pause duration chart.
  | TabGcPressure
  /// Alerts — performance alerts triggered by threshold breaches.
  | TabAlerts
  /// Flamegraph — hierarchical breakdown of frame time by subsystem.
  | TabFlamegraph

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Performance Profiler panel.
type performanceProfilerState = {
  /// Active tab within the panel.
  activeTab: performanceTab,
  /// Recent frame timing samples (ring buffer, last N frames).
  frameSamples: array<frameSample>,
  /// Memory usage snapshots over time.
  memorySnapshots: array<memorySnapshot>,
  /// GC events captured during profiling.
  gcEvents: array<gcEvent>,
  /// Performance alerts triggered during the session.
  alerts: array<perfAlert>,
  /// Whether profiling is actively capturing samples.
  profiling: bool,
  /// Target frames per second (default: 60.0).
  targetFps: float,
  /// Per-frame budget in milliseconds (default: 16.67 for 60 FPS).
  frameBudgetMs: float,
  /// Sampling interval in milliseconds (default: 100).
  sampleInterval: int,
  /// Alert threshold configuration.
  thresholds: option<perfThresholds>,
  /// Error from the last operation.
  error: option<string>,
}
