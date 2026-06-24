// SPDX-License-Identifier: MPL-2.0

/// PanLL Soak Monitor Engine — pure computation and helpers for the
/// Soak Monitor panel. Provides default state, memory growth analysis,
/// leak severity classification, session formatting, and trend analysis.

open SoakMonitorModel

/// Default state for the Soak Monitor panel.
/// Starts on the Live Monitor tab with a 5-second sample interval
/// and 1 MB leak detection threshold.
let defaultState: soakMonitorState = {
  activeTab: TabLiveMonitor,
  currentSession: None,
  trendData: [],
  leakSuspects: [],
  sessions: [],
  monitoring: false,
  sampleIntervalMs: 5000,
  leakThresholdBytes: 1048576,
  error: None,
}

/// Human-readable label for each tab in the Soak Monitor panel.
let tabLabel = (tab: soakTab): string =>
  switch tab {
  | TabLiveMonitor => "Live Monitor"
  | TabTrends => "Trends"
  | TabLeakDetection => "Leak Detection"
  | TabHistory => "History"
  }

/// All tabs in display order.
let allTabs: array<soakTab> = [TabLiveMonitor, TabTrends, TabLeakDetection, TabHistory]

/// Calculate memory growth rate (bytes per hour) from trend data.
/// Requires at least two data points spanning a non-zero time interval.
let memoryGrowthRate = (data: array<memoryTrendPoint>): float => {
  let count = data->Array.length
  if count < 2 {
    0.0
  } else {
    let first = data->Array.getUnsafe(0)
    let last = data->Array.getUnsafe(count - 1)
    let timeDeltaHours = (last.timestamp -. first.timestamp) /. 3600000.0
    if timeDeltaHours <= 0.0 {
      0.0
    } else {
      Float.fromInt(last.heapUsedBytes - first.heapUsedBytes) /. timeDeltaHours
    }
  }
}

/// Classify leak severity based on growth rate.
let classifyLeakSeverity = (growthRatePerHour: int): leakSeverity => {
  let mbPerHour = Float.fromInt(growthRatePerHour) /. 1048576.0
  if mbPerHour > 10.0 {
    LeakSevere
  } else if mbPerHour > 1.0 {
    LeakModerate
  } else {
    LeakNegligible
  }
}

/// Human-readable label for leak severity.
let leakSeverityLabel = (severity: leakSeverity): string =>
  switch severity {
  | LeakNegligible => "Negligible"
  | LeakModerate => "Moderate"
  | LeakSevere => "Severe"
  }

/// CSS colour class for leak severity.
let leakSeverityColor = (severity: leakSeverity): string =>
  switch severity {
  | LeakNegligible => "text-gray-400"
  | LeakModerate => "text-yellow-400"
  | LeakSevere => "text-red-400"
  }

/// Session duration as human-readable string.
let sessionDuration = (session: soakSession): string => {
  let mins = session.durationMinutes
  if mins < 60.0 {
    Float.toFixed(mins, ~digits=0) ++ "m"
  } else {
    Float.toFixed(mins /. 60.0, ~digits=1) ++ "h"
  }
}

/// Session status label.
let sessionStatusLabel = (status: soakSessionStatus): string =>
  switch status {
  | SoakRunning => "Running"
  | SoakCompleted => "Completed"
  | SoakAborted(reason) => "Aborted: " ++ reason
  }

/// CSS colour class for session status.
let sessionStatusColor = (status: soakSessionStatus): string =>
  switch status {
  | SoakRunning => "text-green-400"
  | SoakCompleted => "text-blue-400"
  | SoakAborted(_) => "text-red-400"
  }

/// Format bytes as human-readable size string.
let formatBytes = (bytes: int): string => {
  let mb = Float.fromInt(bytes) /. 1048576.0
  if mb >= 1024.0 {
    Float.toFixed(mb /. 1024.0, ~digits=2) ++ " GB"
  } else if mb >= 1.0 {
    Float.toFixed(mb, ~digits=1) ++ " MB"
  } else {
    Float.toFixed(Float.fromInt(bytes) /. 1024.0, ~digits=1) ++ " KB"
  }
}

/// Current heap utilisation percentage from the latest trend point.
let heapUtilisation = (data: array<memoryTrendPoint>): float => {
  let count = data->Array.length
  if count == 0 {
    0.0
  } else {
    let latest = data->Array.getUnsafe(count - 1)
    if latest.heapTotalBytes == 0 {
      0.0
    } else {
      Float.fromInt(latest.heapUsedBytes) /. Float.fromInt(latest.heapTotalBytes) *. 100.0
    }
  }
}

/// Count high-confidence leak suspects (confidence >= 0.7).
let highConfidenceLeaks = (suspects: array<leakSuspect>): int =>
  suspects->Array.filter(s => s.confidence >= 0.7)->Array.length
