// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Debugging Workbench Engine — pure functions for time-travel debugging
/// and state inspection.

open DebuggingWorkbenchModel

/// Default initial state for the Debugging Workbench panel.
let defaultState: debuggingWorkbenchState = {
  activeTab: TabTimeTravel,
  timeTravel: {
    currentIndex: 0,
    snapshots: [],
    isTimeTravelling: false,
  },
  watches: [],
  consoleLog: [],
  selectedSnapshot: None,
  error: None,
}

/// Human-readable label for each tab.
let tabLabel = (tab: debuggingWorkbenchTab): string =>
  switch tab {
  | TabTimeTravel => "Time Travel"
  | TabStateInspector => "State Inspector"
  | TabWatchExpressions => "Watch Expressions"
  | TabConsole => "Console"
  }

/// All tabs in display order.
let allTabs: array<debuggingWorkbenchTab> = [TabTimeTravel, TabStateInspector, TabWatchExpressions, TabConsole]

/// Number of captured snapshots.
let snapshotCount = (tt: timeTravelState): int =>
  Array.length(tt.snapshots)

/// Whether the time-travel slider can move backward.
let canGoBack = (tt: timeTravelState): bool =>
  tt.currentIndex > 0

/// Whether the time-travel slider can move forward.
let canGoForward = (tt: timeTravelState): bool =>
  tt.currentIndex < Array.length(tt.snapshots) - 1
