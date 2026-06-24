// SPDX-License-Identifier: MPL-2.0

/// PanLL Debugging Workbench Model — time-travel debugging, state inspection,
/// watch expressions, and console output for the TEA model.
///
/// Captures model snapshots at each TEA update cycle, enabling forward/backward
/// stepping through state history. Provides watch expressions that evaluate
/// against the model at each snapshot, and a console log for debug output.
///
/// Clade: Inspector. This module has NO dependencies on other PanLL modules.

// ============================================================================
// State Snapshots
// ============================================================================

/// A snapshot of model state captured at a point in time during execution.
/// Snapshots are the foundation of time-travel debugging — each one
/// represents a complete, frozen model state that can be inspected.
type debugSnapshot = {
  /// Unique snapshot identifier (monotonically increasing).
  id: string,
  /// Serialised model state as JSON.
  modelJson: string,
  /// Epoch timestamp in milliseconds when this snapshot was captured.
  timestamp: float,
  /// Human-readable label (auto-generated from the triggering message).
  label: string,
}

// ============================================================================
// Time Travel State
// ============================================================================

/// Navigation state for the time-travel debugger.
type timeTravelState = {
  /// Current position in the snapshot timeline (0-based index).
  currentIndex: int,
  /// All captured snapshots in chronological order.
  snapshots: array<debugSnapshot>,
  /// Whether time-travel mode is active (model frozen at a historical state).
  isTimeTravelling: bool,
}

// ============================================================================
// Watch Expressions
// ============================================================================

/// A watched expression that is re-evaluated whenever the active snapshot changes.
/// Expressions are JSON path queries into the serialised model state.
type watchExpression = {
  /// Unique watch identifier.
  id: string,
  /// The JSON path expression (e.g., "fleet.bots[0].status").
  expression: string,
  /// Current evaluated value (serialised as string).
  currentValue: string,
  /// Epoch timestamp of the last successful evaluation.
  lastUpdated: float,
}

/// Console output entry in the debug console.
type consoleEntry = {
  /// Console message text.
  message: string,
  /// Log level ("log", "warn", "error", "info").
  level: string,
  /// Epoch timestamp of this entry.
  timestamp: float,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Debugging Workbench panel.
type debuggingWorkbenchTab =
  /// Time Travel — snapshot timeline slider with step forward/backward.
  | TabTimeTravel
  /// State Inspector — JSON tree view of the model at the current snapshot.
  | TabStateInspector
  /// Watch Expressions — user-defined expressions evaluated at each snapshot.
  | TabWatchExpressions
  /// Console — debug output log with level filtering.
  | TabConsole

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Debugging Workbench panel.
type debuggingWorkbenchState = {
  /// Active tab within the panel.
  activeTab: debuggingWorkbenchTab,
  /// Time-travel navigation state.
  timeTravel: timeTravelState,
  /// User-defined watch expressions.
  watches: array<watchExpression>,
  /// Console output log.
  consoleLog: array<string>,
  /// Structured console entries (richer than plain strings).
  consoleEntries: array<consoleEntry>,
  /// Currently selected snapshot ID for detail view.
  selectedSnapshot: option<string>,
  /// Error from the last operation.
  error: option<string>,
}
