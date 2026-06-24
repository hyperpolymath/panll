// SPDX-License-Identifier: MPL-2.0

/// PanLL Soak Monitor Model — long-running session tracking, memory leak
/// detection, and trend analysis for IDApTIK extended play sessions.
///
/// Runs overnight or over many hours, sampling memory usage, GC activity,
/// and resource consumption. Flags monotonic growth patterns as potential
/// leaks and attributes them to likely sources.
///
/// Clade: Inspector. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Memory Trend Data
// ============================================================================

/// A single memory trend data point sampled at a fixed interval.
type memoryTrendPoint = {
  /// Timestamp in epoch milliseconds.
  timestamp: float,
  /// Bytes currently used on the JS heap.
  heapUsedBytes: int,
  /// Total JS heap size (allocated by V8).
  heapTotalBytes: int,
  /// Number of GC cycles since last sample.
  gcCount: int,
  /// Total GC pause time since last sample in milliseconds.
  gcPauseMs: float,
}

// ============================================================================
// Leak Detection
// ============================================================================

/// A suspected memory leak identified by monotonic growth analysis.
type leakSuspect = {
  /// Human-readable source attribution (e.g., "PixiJS texture cache").
  source: string,
  /// Estimated growth rate in bytes per hour.
  growthRatePerHour: int,
  /// Confidence score (0.0 to 1.0) that this is a genuine leak.
  confidence: float,
  /// Timestamp when this leak was first detected.
  firstSeen: float,
  /// Number of data points contributing to this detection.
  samples: int,
}

/// Leak severity classification based on growth rate and duration.
type leakSeverity =
  /// Negligible — growth under 1 MB/hour, likely allocation noise.
  | LeakNegligible
  /// Moderate — growth 1-10 MB/hour, will exhaust memory in long sessions.
  | LeakModerate
  /// Severe — growth over 10 MB/hour, requires immediate investigation.
  | LeakSevere

// ============================================================================
// Soak Sessions
// ============================================================================

/// Session execution status.
type soakSessionStatus =
  /// Session is actively running and collecting samples.
  | SoakRunning
  /// Session completed its configured duration.
  | SoakCompleted
  /// Session was manually aborted (payload is reason).
  | SoakAborted(string)

/// Summary record for a soak test session.
type soakSession = {
  /// Unique session identifier.
  id: string,
  /// Epoch timestamp when the session started.
  startedAt: float,
  /// Epoch timestamp when the session ended (None if still running).
  endedAt: option<float>,
  /// Total session duration in minutes.
  durationMinutes: float,
  /// Peak heap usage observed during the session in bytes.
  peakMemoryBytes: int,
  /// Memory leak suspects detected during this session.
  leakSuspects: array<leakSuspect>,
  /// Average GC frequency during the session (cycles per minute).
  gcFrequencyPerMinute: float,
  /// Session execution status.
  status: soakSessionStatus,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Soak Monitor panel.
type soakTab =
  /// Live Monitor — real-time memory usage gauge and trend line.
  | TabLiveMonitor
  /// Trends — historical memory trend charts with regression lines.
  | TabTrends
  /// Leak Detection — suspected leak list with confidence scores.
  | TabLeakDetection
  /// History — past soak session summaries with comparison.
  | TabHistory

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Soak Monitor panel.
type soakMonitorState = {
  /// Active tab within the panel.
  activeTab: soakTab,
  /// Currently running soak session (None if idle).
  currentSession: option<soakSession>,
  /// Memory trend data points for the current session.
  trendData: array<memoryTrendPoint>,
  /// Currently detected leak suspects.
  leakSuspects: array<leakSuspect>,
  /// Historical soak session records.
  sessions: array<soakSession>,
  /// Whether monitoring is actively sampling.
  monitoring: bool,
  /// Sampling interval in milliseconds (default 5000 = 5 seconds).
  sampleIntervalMs: int,
  /// Threshold in bytes above which growth is flagged as a leak (default 1 MB).
  leakThresholdBytes: int,
  /// Error from the last operation.
  error: option<string>,
}
