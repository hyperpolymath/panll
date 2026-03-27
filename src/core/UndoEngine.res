// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Undo Engine — ring buffer of model snapshots for undo/redo.
///
/// TEA's immutable state makes snapshot-based undo cheap: we just keep
/// the last N model values. No command pattern needed — the model IS the
/// snapshot.
///
/// Design: NOT every message pushes to undo. Only "significant" changes
/// (user actions, not timer ticks or loading states) are captured. The
/// `isSignificant` predicate filters noise from the undo stack.
///
/// Ring buffer is capped at `maxHistory` to bound memory. When the cap
/// is exceeded, the oldest snapshot is discarded.

open Msg

/// Maximum number of undo snapshots to keep. 50 provides a generous
/// undo buffer without excessive memory use (each snapshot is ~10-50KB
/// depending on panel state).
let maxHistory = 50

/// Determine whether a message represents a "significant" state change
/// that should be captured in the undo history.
///
/// Significant: user-initiated actions that modify domain state.
/// NOT significant: timer ticks, loading states, NoOp, health checks,
/// vexation index polling, inference subscription events.
let isSignificant = (msg: msg): bool => {
  switch msg {
  // Timer/polling/loading — NOT significant
  | NoOp => false
  | SaveState => false
  | Vexometer(RequestVexationIndex) => false
  | Vexometer(UpdateVexationIndex(_)) => false
  | Vexometer(SetInertiaDetected(_)) => false

  // Health check results — NOT significant (background polling)
  | VeriSimDB(HealthResult(_)) => false
  | Echidna(HealthOk(_)) => false
  | Echidna(HealthError(_)) => false
  | PanelSwitcher(HealthCheckResult(_, _)) => false

  // Watcher filesystem events — NOT significant (high frequency)
  | Watcher(FileEvent(_)) => false
  | Watcher(StatusLoaded(_)) => false
  | Watcher(WatcherResult(_)) => false

  // AI message responses — NOT significant (async results)
  | Ai(MessageReceived(_)) => false
  | Ai(ProviderChecked(_, _)) => false
  | Ai(ModelSet(_)) => false
  | Ai(PrioritySet(_)) => false
  | Ai(ProviderToggled(_)) => false
  | Ai(HistoryCleared(_)) => false
  | Ai(ContextBuilt(_)) => false
  | Ai(ProviderStateLoaded(_)) => false

  // Orbital sync updates — NOT significant (computed from other state)
  | Orbital(_) => false

  // View toggles — borderline, but include for good UX
  | View(_) => true

  // Everything else: user actions → significant
  | _ => true
  }
}

/// Push a model snapshot onto the undo stack, clearing the redo stack.
/// If the undo stack exceeds `maxHistory`, the oldest entry is dropped.
let pushUndo = (undoStack: array<'a>, _redoStack: array<'a>, snapshot: 'a): (
  array<'a>,
  array<'a>,
) => {
  let newUndo = Array.concat(undoStack, [snapshot])
  // Trim to max history: keep only the most recent entries.
  let trimmed = if Array.length(newUndo) > maxHistory {
    Array.slice(newUndo, ~start=Array.length(newUndo) - maxHistory, ~end=Array.length(newUndo))
  } else {
    newUndo
  }
  // Redo stack is always cleared after a new action.
  (trimmed, [])
}

/// Pop the most recent snapshot from the undo stack. Returns the snapshot
/// to restore, the new undo stack, and the updated redo stack (which gets
/// the current state pushed onto it).
let undo = (undoStack: array<'a>, redoStack: array<'a>, currentState: 'a): option<(
  'a,
  array<'a>,
  array<'a>,
)> => {
  let len = Array.length(undoStack)
  if len === 0 {
    None
  } else {
    let snapshot = undoStack[len - 1]
    let newUndo = Array.slice(undoStack, ~start=0, ~end=len - 1)
    let newRedo = Array.concat(redoStack, [currentState])
    switch snapshot {
    | Some(s) => Some((s, newUndo, newRedo))
    | None => None
    }
  }
}

/// Pop the most recent snapshot from the redo stack. Returns the snapshot
/// to restore, the updated undo stack (which gets the current state pushed),
/// and the new redo stack.
let redo = (undoStack: array<'a>, redoStack: array<'a>, currentState: 'a): option<(
  'a,
  array<'a>,
  array<'a>,
)> => {
  let len = Array.length(redoStack)
  if len === 0 {
    None
  } else {
    let snapshot = redoStack[len - 1]
    let newRedo = Array.slice(redoStack, ~start=0, ~end=len - 1)
    let newUndo = Array.concat(undoStack, [currentState])
    switch snapshot {
    | Some(s) => Some((s, newUndo, newRedo))
    | None => None
    }
  }
}

/// Check if undo is available (stack is non-empty).
let canUndo = (undoStack: array<'a>): bool => Array.length(undoStack) > 0

/// Check if redo is available (stack is non-empty).
let canRedo = (redoStack: array<'a>): bool => Array.length(redoStack) > 0
