// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Keybindings Model — types for customisable keyboard shortcuts.
///
/// Replaces the hardcoded Ctrl+Shift+L/N/B/W/V shortcuts in SubscriptionsFixed.res
/// with a configurable keybinding map. Users can remap shortcuts via the Workspace
/// panel's Keybindings configurator tab.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Modifier keys that can be combined with a key press.
type modifier =
  | Ctrl
  | Shift
  | Alt
  | Meta

/// A key chord: a combination of modifiers + a key character.
/// For example, Ctrl+Shift+Z would be { modifiers: [Ctrl, Shift], key: "Z" }.
type keyChord = {
  /// Set of modifier keys that must be held.
  modifiers: array<modifier>,
  /// The key character (e.g., "Z", "S", "Escape", "F11").
  key: string,
}

/// A named action that a keybinding can trigger.
/// These map 1:1 to msg constructors, but are stored as strings for
/// serialisation and conflict detection.
type keybindingAction =
  | ActionUndo
  | ActionRedo
  | ActionSave
  | ActionPrint
  | ActionResetPanel
  | ActionResetAll
  | ActionTogglePaneL
  | ActionTogglePaneN
  | ActionTogglePaneW
  | ActionToggleVab
  | ActionTogglePanelBar
  | ActionFullscreen
  | ActionCloseOverlay
  | ActionToggleCapture
  | ActionToggleWorkspace
  | ActionToggleSecurity
  | ActionCycleWorkspaceMode
  | ActionToggleDryRun

/// A single keybinding entry: maps a chord to an action.
type keybinding = {
  /// The key chord that triggers this action.
  chord: keyChord,
  /// The action to execute.
  action: keybindingAction,
  /// Whether this is a user-customised binding (vs default).
  custom: bool,
}

/// Root state for the keybindings system.
type keybindingsState = {
  /// All active keybindings (defaults + user overrides).
  bindings: array<keybinding>,
  /// Whether the keybinding editor is in "recording" mode (next keypress
  /// becomes the new chord for the selected action).
  recording: bool,
  /// The action currently being rebound (if recording).
  recordingAction: option<keybindingAction>,
  /// Detected conflicts (two bindings with the same chord).
  conflicts: array<(keybindingAction, keybindingAction)>,
}
