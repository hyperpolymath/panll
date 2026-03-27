// SPDX-License-Identifier: PMPL-1.0-or-later

/// Sub-updater for Keybindings — recording, rebinding, reset.

open Model
open Msg

let updateKeybindings = (model: model, msg: keybindingsMsg): model => {
  let kb = model.keybindings
  switch msg {
  | StartRecording(action) => {
      ...model,
      keybindings: {...kb, recording: true, recordingAction: Some(action)},
    }
  | RecordKey(chord) =>
    switch kb.recordingAction {
    | Some(action) => {
        let newBindings = KeybindingsEngine.rebind(kb.bindings, action, chord)
        let conflicts = KeybindingsEngine.detectConflicts(newBindings)
        {
          ...model,
          keybindings: {
            bindings: newBindings,
            recording: false,
            recordingAction: None,
            conflicts,
          },
        }
      }
    | None => {...model, keybindings: {...kb, recording: false, recordingAction: None}}
    }
  | CancelRecording => {...model, keybindings: {...kb, recording: false, recordingAction: None}}
  | ResetBinding(action) => {
      let newBindings = KeybindingsEngine.resetBinding(kb.bindings, action)
      let conflicts = KeybindingsEngine.detectConflicts(newBindings)
      {...model, keybindings: {...kb, bindings: newBindings, conflicts}}
    }
  | ResetAllBindings => {
      let newBindings = KeybindingsEngine.resetAll()
      {
        ...model,
        keybindings: {
          bindings: newBindings,
          recording: false,
          recordingAction: None,
          conflicts: [],
        },
      }
    }
  }
}
