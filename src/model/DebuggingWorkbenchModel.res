// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Debugging Workbench Model — time-travel debugging, state inspection, and
/// watch expressions for the TEA model.
/// Inspector clade. This module has NO dependencies on other PanLL modules.

/// A snapshot of model state captured at a point in time.
type debugSnapshot = {
  id: string,
  modelJson: string,
  timestamp: float,
  label: string,
}

/// Time-travel navigation state.
type timeTravelState = {
  currentIndex: int,
  snapshots: array<debugSnapshot>,
  isTimeTravelling: bool,
}

/// A watched expression with its current evaluated value.
type watchExpression = {
  id: string,
  expression: string,
  currentValue: string,
  lastUpdated: float,
}

/// Active tab within the Debugging Workbench panel.
type debuggingWorkbenchTab =
  | TabTimeTravel
  | TabStateInspector
  | TabWatchExpressions
  | TabConsole

/// Debugging Workbench panel state.
type debuggingWorkbenchState = {
  activeTab: debuggingWorkbenchTab,
  timeTravel: timeTravelState,
  watches: array<watchExpression>,
  consoleLog: array<string>,
  selectedSnapshot: option<string>,
  error: option<string>,
}
