// SPDX-License-Identifier: PMPL-1.0-or-later

/// Keybindings messages -- rebinding, recording, reset.

open Model

type keybindingsMsg =
  /// Start recording a new keybinding for an action.
  | StartRecording(keybindingAction)
  /// A key was pressed while recording.
  | RecordKey(keyChord)
  /// Cancel recording.
  | CancelRecording
  /// Reset a single binding to default.
  | ResetBinding(keybindingAction)
  /// Reset all bindings to defaults.
  | ResetAllBindings
