// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Debugging Workbench Engine — pure computation and helpers for the
/// Debugging Workbench panel. Provides default state, time-travel navigation,
/// snapshot management, watch expression helpers, and console formatting.

open DebuggingWorkbenchModel

/// Default initial state for the Debugging Workbench panel.
/// Starts on the Time Travel tab with empty snapshot and watch lists.
let defaultState: debuggingWorkbenchState = {
  activeTab: TabTimeTravel,
  timeTravel: {
    currentIndex: 0,
    snapshots: [],
    isTimeTravelling: false,
  },
  watches: [],
  consoleLog: [],
  consoleEntries: [],
  selectedSnapshot: None,
  error: None,
}

/// Human-readable label for each tab in the Debugging Workbench panel.
let tabLabel = (tab: debuggingWorkbenchTab): string =>
  switch tab {
  | TabTimeTravel => "Time Travel"
  | TabStateInspector => "State Inspector"
  | TabWatchExpressions => "Watch Expressions"
  | TabConsole => "Console"
  }

/// All tabs in display order.
let allTabs: array<debuggingWorkbenchTab> = [
  TabTimeTravel,
  TabStateInspector,
  TabWatchExpressions,
  TabConsole,
]

/// Number of captured snapshots.
let snapshotCount = (tt: timeTravelState): int => Array.length(tt.snapshots)

/// Whether the time-travel slider can move backward.
let canGoBack = (tt: timeTravelState): bool => tt.currentIndex > 0

/// Whether the time-travel slider can move forward.
let canGoForward = (tt: timeTravelState): bool => tt.currentIndex < Array.length(tt.snapshots) - 1

/// Get the current snapshot (at the current index).
let currentSnapshot = (tt: timeTravelState): option<debugSnapshot> => {
  let count = Array.length(tt.snapshots)
  if count == 0 || tt.currentIndex >= count {
    None
  } else {
    Some(tt.snapshots->Array.getUnsafe(tt.currentIndex))
  }
}

/// Progress through the snapshot timeline as a percentage (0.0 to 100.0).
let timelineProgress = (tt: timeTravelState): float => {
  let count = Array.length(tt.snapshots)
  if count <= 1 {
    100.0
  } else {
    Float.fromInt(tt.currentIndex) /. Float.fromInt(count - 1) *. 100.0
  }
}

/// Duration between first and last snapshot in seconds.
let timelineDuration = (tt: timeTravelState): float => {
  let count = Array.length(tt.snapshots)
  if count < 2 {
    0.0
  } else {
    let first = tt.snapshots->Array.getUnsafe(0)
    let last = tt.snapshots->Array.getUnsafe(count - 1)
    (last.timestamp -. first.timestamp) /. 1000.0
  }
}

/// Number of watch expressions defined.
let watchCount = (watches: array<watchExpression>): int => Array.length(watches)

/// Console log entry count (legacy string-based).
let consoleLineCount = (log: array<string>): int => Array.length(log)

/// Count console entries by level.
let countConsoleByLevel = (entries: array<consoleEntry>, level: string): int =>
  entries->Array.filter(e => e.level == level)->Array.length

/// CSS colour class for console entry level.
let consoleLevelColor = (level: string): string =>
  switch level {
  | "error" => "text-red-400"
  | "warn" => "text-yellow-400"
  | "info" => "text-blue-400"
  | _ => "text-gray-300"
  }

/// Format a timestamp as a relative time label (e.g., "2.3s ago").
let formatRelativeTime = (timestamp: float, now: float): string => {
  let diffMs = now -. timestamp
  let seconds = diffMs /. 1000.0
  if seconds < 60.0 {
    Float.toFixed(seconds, ~digits=1) ++ "s ago"
  } else {
    let minutes = seconds /. 60.0
    Float.toFixed(minutes, ~digits=1) ++ "m ago"
  }
}
