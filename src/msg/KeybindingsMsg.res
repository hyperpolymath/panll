// SPDX-License-Identifier: MPL-2.0

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
