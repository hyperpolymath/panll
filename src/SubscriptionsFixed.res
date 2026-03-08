// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Subscriptions — External event handling (Custom TEA version).
///
/// This module defines all subscriptions (external events) that the PanLL
/// environment listens to, following the TEA pattern.
///
/// Keyboard shortcuts now use KeybindingsEngine for lookup instead of
/// hardcoded switch arms. This makes shortcuts customisable via the
/// Workspace panel's Keybindings configurator tab.

open Model
open Msg

/// Map a keybinding action to its corresponding msg. This is the bridge
/// between the configurable keybinding map and the TEA message dispatch.
let actionToMsg = (action: KeybindingsModel.keybindingAction): msg => {
  switch action {
  | ActionUndo => Undo
  | ActionRedo => Redo
  | ActionSave => SaveState
  | ActionPrint => NoOp // Print needs the active panel ID — handled specially
  | ActionResetPanel => Workspace(ResetPanel("active"))
  | ActionResetAll => Workspace(ResetAllPanels)
  | ActionTogglePaneL => View(TogglePaneL)
  | ActionTogglePaneN => View(TogglePaneN)
  | ActionTogglePaneW => View(TogglePaneW)
  | ActionToggleVab => PanelSwitcher(TogglePanel(PanelVab))
  | ActionTogglePanelBar => NoOp // TODO: toggle panel bar visibility
  | ActionFullscreen => NoOp // TODO: fullscreen active panel
  | ActionCloseOverlay => PanelSwitcher(ClosePanels)
  | ActionToggleCapture => PanelSwitcher(TogglePanel(PanelCapture))
  | ActionToggleWorkspace => PanelSwitcher(TogglePanel(PanelWorkspace))
  | ActionToggleSecurity => PanelSwitcher(TogglePanel(PanelSecurity))
  | ActionCycleWorkspaceMode => Workspace(CycleWorkspaceMode)
  | ActionToggleDryRun => Workspace(ToggleDryRun)
  }
}

/// Main subscriptions function — keyboard shortcuts + polling.
let subscriptions = (model: model): Tea_Sub.t<msg> => {
  Tea_Sub.batch(list{
    // Keyboard shortcuts via configurable keybinding map.
    KeyboardFixed.onKeyDown(evt => {
      // If keybinding editor is in recording mode, capture the key for rebinding.
      if model.keybindings.recording {
        let modifiers = {
          let mods = []
          let mods = if evt.ctrlKey { Array.concat(mods, [KeybindingsModel.Ctrl]) } else { mods }
          let mods = if evt.shiftKey { Array.concat(mods, [KeybindingsModel.Shift]) } else { mods }
          let mods = if evt.altKey { Array.concat(mods, [KeybindingsModel.Alt]) } else { mods }
          let mods = if evt.metaKey { Array.concat(mods, [KeybindingsModel.Meta]) } else { mods }
          mods
        }
        Keybindings(RecordKey({modifiers, key: evt.key}))
      } else {
        // Look up the key event in the keybinding map.
        let action = KeybindingsEngine.lookup(
          model.keybindings.bindings,
          evt.ctrlKey,
          evt.shiftKey,
          evt.altKey,
          evt.metaKey,
          evt.key,
        )
        switch action {
        | Some(a) => actionToMsg(a)
        | None => NoOp
        }
      }
    }),

    // Update vexation index periodically (every 2 seconds).
    if model.paneN.inferenceActive {
      Tea_Time.every(2000.0, _time => {
        Vexometer(RequestVexationIndex)
      })
    } else {
      Tea_Sub.none
    },
  })
}

/// Subscription for when inference is active — more frequent vexation polling.
let inferenceSubscriptions = (model: model): Tea_Sub.t<msg> => {
  if model.paneN.inferenceActive {
    Tea_Sub.batch(list{
      Tea_Time.every(500.0, _time => Vexometer(RequestVexationIndex)),
    })
  } else {
    Tea_Sub.none
  }
}

/// S2: Tauri backend event subscriptions — real-time neurosymbolic streaming.
/// These fire when the Rust backend receives events from ECHIDNA, Tentacles,
/// VeriSimDB, or Hypatia. Only active when the relevant panel is connected.
let neurosymbolicSubscriptions = (_model: model): Tea_Sub.t<msg> => {
  Tea_Sub.batch(list{
    // ECHIDNA proof progress → feed into proof session state.
    TauriEvents.onEchidnaProgress(payload =>
      Echidna(ProofResult(Ok(payload)))
    ),
    // ECHIDNA tactic suggestions → populate suggestion ribbon.
    TauriEvents.onEchidnaTactics(payload =>
      Echidna(TacticSuggestionsLoaded(Ok(payload)))
    ),
    // Tentacles agent phase changes → advance OODA indicators.
    // Payload expected as "agentId:phaseId" string from FFI.
    TauriEvents.onTentaclesPhaseChange(payload => {
      // Parse "0:2" as agent Red, phase Decide — graceful fallback.
      let parts = String.split(payload, ":")
      let agentIdx = parts[0]->Option.getOr("0")->Int.fromString->Option.getOr(0)
      let agentId = switch agentIdx {
      | 0 => TentaclesModel.Red
      | 1 => TentaclesModel.Orange
      | 2 => TentaclesModel.Yellow
      | 3 => TentaclesModel.Green
      | 4 => TentaclesModel.Blue
      | 5 => TentaclesModel.Indigo
      | _ => TentaclesModel.Violet
      }
      let phaseIdx = parts[1]->Option.getOr("0")->Int.fromString->Option.getOr(0)
      let phase = switch phaseIdx {
      | 0 => PaneModel.Observe
      | 1 => PaneModel.Orient
      | 2 => PaneModel.Decide
      | _ => PaneModel.Act
      }
      Tentacles(AgentPhaseAdvanced(agentId, phase))
    }),
    // Tentacles agent broadcasts → deliver as reasoning share.
    TauriEvents.onTentaclesBroadcast(payload =>
      Tentacles(BroadcastFromAgent(Red, ReasoningShare({
        agent: Red,
        phase: Observe,
        summary: payload,
        detail: None,
        timestamp: 0.0,
      })))
    ),
    // VeriSimDB drift alerts → refresh drift display.
    TauriEvents.onVeriSimDBDrift(payload =>
      VeriSimDB(DriftLoaded(Ok(payload)))
    ),
    // Hypatia neural network status → refresh network grid.
    TauriEvents.onHypatiaStatus(payload =>
      Hypatia(ScansLoaded(Ok(payload)))
    ),
    // Governance signals → Anti-Crash intervention request.
    TauriEvents.onGovernanceSignal(payload =>
      AntiCrash(RequestOperatorIntervention(payload))
    ),
  })
}

/// Combined subscriptions.
let all = (model: model): Tea_Sub.t<msg> => {
  Tea_Sub.batch(list{
    subscriptions(model),
    inferenceSubscriptions(model),
    neurosymbolicSubscriptions(model),
  })
}
