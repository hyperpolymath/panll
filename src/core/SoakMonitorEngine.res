// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Soak Monitor Engine — pure functions for long-running session tracking.

open SoakMonitorModel

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

let tabLabel = (tab: soakTab): string =>
  switch tab {
  | TabLiveMonitor => "Live Monitor"
  | TabTrends => "Trends"
  | TabLeakDetection => "Leak Detection"
  | TabHistory => "History"
  }

let allTabs: array<soakTab> = [TabLiveMonitor, TabTrends, TabLeakDetection, TabHistory]

/// Calculate memory growth rate (bytes per hour) from trend data.
let memoryGrowthRate = (data: array<memoryTrendPoint>): float => {
  let count = data->Array.length
  if count < 2 { 0.0 }
  else {
    let first = data->Array.getUnsafe(0)
    let last = data->Array.getUnsafe(count - 1)
    let timeDeltaHours = (last.timestamp -. first.timestamp) /. 3600000.0
    if timeDeltaHours <= 0.0 { 0.0 }
    else { Float.fromInt(last.heapUsedBytes - first.heapUsedBytes) /. timeDeltaHours }
  }
}

/// Session duration as human-readable string.
let sessionDuration = (session: soakSession): string => {
  let mins = session.durationMinutes
  if mins < 60.0 { Float.toFixed(mins, ~digits=0) ++ "m" }
  else { Float.toFixed(mins /. 60.0, ~digits=1) ++ "h" }
}

/// Status label.
let sessionStatusLabel = (status: soakSessionStatus): string =>
  switch status {
  | SoakRunning => "Running"
  | SoakCompleted => "Completed"
  | SoakAborted(reason) => "Aborted: " ++ reason
  }
