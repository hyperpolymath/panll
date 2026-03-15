// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Soak Monitor Model — long-running session tracking and memory leak detection.
/// This module has NO dependencies on other PanLL modules.

/// A memory trend data point.
type memoryTrendPoint = {
  timestamp: float,
  heapUsedBytes: int,
  heapTotalBytes: int,
  gcCount: int,
  gcPauseMs: float,
}

/// Leak detection result.
type leakSuspect = {
  source: string,
  growthRatePerHour: int,
  confidence: float,
  firstSeen: float,
  samples: int,
}

/// Session status.
type soakSessionStatus =
  | SoakRunning
  | SoakCompleted
  | SoakAborted(string)

/// Soak session summary.
type soakSession = {
  id: string,
  startedAt: float,
  endedAt: option<float>,
  durationMinutes: float,
  peakMemoryBytes: int,
  leakSuspects: array<leakSuspect>,
  gcFrequencyPerMinute: float,
  status: soakSessionStatus,
}

/// Active tab.
type soakTab =
  | TabLiveMonitor
  | TabTrends
  | TabLeakDetection
  | TabHistory

/// Soak monitor state.
type soakMonitorState = {
  activeTab: soakTab,
  currentSession: option<soakSession>,
  trendData: array<memoryTrendPoint>,
  leakSuspects: array<leakSuspect>,
  sessions: array<soakSession>,
  monitoring: bool,
  sampleIntervalMs: int,
  leakThresholdBytes: int,
  error: option<string>,
}
