// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Keybindings Engine — default bindings, lookup, and conflict detection.
///
/// Pure functions for managing the keybinding map. No side effects — all keyboard
/// event handling happens in SubscriptionsFixed.res which calls these lookup
/// functions to determine which action a keypress should trigger.

open KeybindingsModel

/// Helper: create a chord with standard modifier combinations.
let chord = (modifiers: array<modifier>, key: string): keyChord => {
  modifiers,
  key,
}

/// Helper: create a keybinding with default (non-custom) flag.
let bind = (modifiers: array<modifier>, key: string, action: keybindingAction): keybinding => {
  chord: chord(modifiers, key),
  action,
  custom: false,
}

/// Default keybindings — the standard set that ships with PanLL.
/// Users can override any of these via the keybinding editor.
let defaults: array<keybinding> = [
  // Undo/Redo
  bind([Ctrl], "z", ActionUndo),
  bind([Ctrl, Shift], "Z", ActionRedo),

  // Save
  bind([Ctrl], "s", ActionSave),

  // Print active panel
  bind([Ctrl], "p", ActionPrint),

  // Reset
  bind([Ctrl, Shift], "R", ActionResetPanel),
  bind([Ctrl, Shift, Alt], "R", ActionResetAll),

  // Pane toggles (preserving existing Ctrl+Shift shortcuts)
  bind([Ctrl, Shift], "L", ActionTogglePaneL),
  bind([Ctrl, Shift], "N", ActionTogglePaneN),
  bind([Ctrl, Shift], "B", ActionTogglePaneW),
  bind([Ctrl, Shift], "W", ActionTogglePaneW),
  bind([Ctrl, Shift], "V", ActionToggleVab),

  // Panel bar
  bind([Ctrl], "`", ActionTogglePanelBar),

  // Fullscreen active panel
  bind([], "F11", ActionFullscreen),

  // Close overlay (Escape)
  bind([], "Escape", ActionCloseOverlay),

  // New panel shortcuts
  bind([Ctrl, Shift], "C", ActionToggleCapture),
  bind([Ctrl, Shift], "K", ActionToggleWorkspace),
  bind([Ctrl, Shift], "S", ActionToggleSecurity),

  // Workspace mode cycling
  bind([Ctrl, Shift], "M", ActionCycleWorkspaceMode),

  // Dry run toggle
  bind([Ctrl, Shift], "D", ActionToggleDryRun),
]

/// Look up which action (if any) a key event should trigger.
/// Returns None if no binding matches the event.
let lookup = (
  bindings: array<keybinding>,
  ctrlKey: bool,
  shiftKey: bool,
  altKey: bool,
  metaKey: bool,
  key: string,
): option<keybindingAction> => {
  // Build the set of active modifiers from the event.
  let activeModifiers = {
    let mods = []
    let mods = if ctrlKey { Array.concat(mods, [Ctrl]) } else { mods }
    let mods = if shiftKey { Array.concat(mods, [Shift]) } else { mods }
    let mods = if altKey { Array.concat(mods, [Alt]) } else { mods }
    let mods = if metaKey { Array.concat(mods, [Meta]) } else { mods }
    mods
  }

  // Find the first binding whose chord matches.
  let match_ = Array.find(bindings, binding => {
    let chordMods = binding.chord.modifiers
    // Exact modifier set match (same length + all present).
    let modsMatch =
      Array.length(chordMods) === Array.length(activeModifiers) &&
      Array.every(chordMods, m => Array.some(activeModifiers, am => am === m))
    // Key match (case-sensitive for shifted keys, case-insensitive for unshifted).
    let keyMatch = binding.chord.key === key
    modsMatch && keyMatch
  })

  switch match_ {
  | Some(b) => Some(b.action)
  | None => None
  }
}

/// Detect conflicts: two or more bindings with the same chord.
/// Returns pairs of conflicting actions.
let detectConflicts = (bindings: array<keybinding>): array<(keybindingAction, keybindingAction)> => {
  let conflicts = []
  let len = Array.length(bindings)
  let result = ref(conflicts)
  for i in 0 to len - 2 {
    for j in i + 1 to len - 1 {
      switch (bindings[i], bindings[j]) {
      | (Some(a), Some(b)) => {
          let sameModifiers =
            Array.length(a.chord.modifiers) === Array.length(b.chord.modifiers) &&
            Array.every(a.chord.modifiers, m => Array.some(b.chord.modifiers, bm => bm === m))
          let sameKey = a.chord.key === b.chord.key
          if sameModifiers && sameKey {
            result := Array.concat(result.contents, [(a.action, b.action)])
          }
        }
      | _ => ()
      }
    }
  }
  result.contents
}

/// Replace or add a keybinding for a given action. If the action already
/// has a binding, it is replaced. Otherwise, a new binding is appended.
let rebind = (
  bindings: array<keybinding>,
  action: keybindingAction,
  newChord: keyChord,
): array<keybinding> => {
  let exists = Array.some(bindings, b => b.action === action)
  if exists {
    Array.map(bindings, b =>
      if b.action === action {
        { chord: newChord, action, custom: true }
      } else {
        b
      }
    )
  } else {
    Array.concat(bindings, [{ chord: newChord, action, custom: true }])
  }
}

/// Reset a single action's binding back to its default.
let resetBinding = (bindings: array<keybinding>, action: keybindingAction): array<keybinding> => {
  let defaultBinding = Array.find(defaults, b => b.action === action)
  switch defaultBinding {
  | Some(db) =>
    Array.map(bindings, b =>
      if b.action === action { db } else { b }
    )
  | None => bindings
  }
}

/// Reset all bindings to defaults.
let resetAll = (): array<keybinding> => defaults

/// Initial keybindings state.
let defaultState: keybindingsState = {
  bindings: defaults,
  recording: false,
  recordingAction: None,
  conflicts: [],
}
