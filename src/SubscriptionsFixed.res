// SPDX-License-Identifier: MPL-2.0

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
  | ActionTogglePanelBar => View(TogglePanelBar)
  | ActionFullscreen => View(ToggleFullscreen)
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
          let mods = if evt.ctrlKey {
            Array.concat(mods, [KeybindingsModel.Ctrl])
          } else {
            mods
          }
          let mods = if evt.shiftKey {
            Array.concat(mods, [KeybindingsModel.Shift])
          } else {
            mods
          }
          let mods = if evt.altKey {
            Array.concat(mods, [KeybindingsModel.Alt])
          } else {
            mods
          }
          let mods = if evt.metaKey {
            Array.concat(mods, [KeybindingsModel.Meta])
          } else {
            mods
          }
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
    Tea_Sub.batch(list{Tea_Time.every(500.0, _time => Vexometer(RequestVexationIndex))})
  } else {
    Tea_Sub.none
  }
}

/// S2: Gossamer backend event subscriptions — real-time neurosymbolic streaming.
/// These fire when the Rust backend receives events from ECHIDNA, Tentacles,
/// VeriSimDB, or Hypatia. Only active when the relevant panel is connected.
let neurosymbolicSubscriptions = (_model: model): Tea_Sub.t<msg> => {
  Tea_Sub.batch(list{
    // ECHIDNA proof progress → feed into proof session state.
    GossamerEvents.onEchidnaProgress(payload => Echidna(ProofResult(Ok(payload)))),
    // ECHIDNA tactic suggestions → populate suggestion ribbon.
    GossamerEvents.onEchidnaTactics(payload => Echidna(TacticSuggestionsLoaded(Ok(payload)))),
    // Tentacles agent phase changes → advance OODA indicators.
    // Payload expected as "agentId:phaseId" string from FFI.
    GossamerEvents.onTentaclesPhaseChange(payload => {
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
    GossamerEvents.onTentaclesBroadcast(payload => Tentacles(
      BroadcastFromAgent(
        Red,
        ReasoningShare({
          agent: Red,
          phase: Observe,
          summary: payload,
          detail: None,
          timestamp: 0.0,
        }),
      ),
    )),
    // VeriSimDB drift alerts → refresh drift display.
    GossamerEvents.onVeriSimDBDrift(payload => VeriSimDB(DriftLoaded(Ok(payload)))),
    // Hypatia neural network status → refresh network grid.
    GossamerEvents.onHypatiaStatus(payload => Hypatia(ScansLoaded(Ok(payload)))),
    // Governance signals → Anti-Crash intervention request.
    GossamerEvents.onGovernanceSignal(payload => AntiCrash(RequestOperatorIntervention(payload))),
    // AI streaming chunks → feed into AI panel streaming state machine.
    GossamerEvents.onAiStreamChunk(payload => Ai(AiStreamChunkReceived(payload))),
  })
}

/// S3: Token drip-feed — synthetic token emission for neural stream animation.
/// When inference is active, emits a lightweight "heartbeat" token every 3 seconds
/// so the neural stream shows visible activity even between real inference bursts.
/// The token content cycles through OODA status lines to give contextual feedback.
let tokenDripFeed = (model: model): Tea_Sub.t<msg> => {
  if model.paneN.inferenceActive {
    Tea_Sub.batch(list{
      Tea_Time.every(3000.0, time => {
        let phaseLabel = switch model.paneN.agency.phase {
        | Observe => "OBSERVE"
        | Orient => "ORIENT"
        | Decide => "DECIDE"
        | Act => "ACT"
        }
        let tokenContent = "[" ++ phaseLabel ++ "] Heartbeat @ " ++ Float.toString(time)
        let tokenId = "t-" ++ Int.toString(model.paneN.nextTokenId)
        PaneN(
          ReceiveToken({
            id: tokenId,
            content: tokenContent,
            timestamp: time,
            confidence: 0.5,
            validated: false,
            source: NeuralInference,
            category: Observation,
            emittedDuring: model.paneN.agency.phase,
            causedBy: model.paneN.activeCausalChain,
            proofHash: None,
          }),
        )
      }),
    })
  } else {
    Tea_Sub.none
  }
}

/// S4: OODA phase cycling — automatic phase progression for the neural agent.
/// Cycles Observe → Orient → Decide → Act → Observe every 8 seconds when
/// inference is active. This gives the appearance of an active deliberation
/// loop and keeps the agency monitor visually responsive.
let oodaPhaseCycling = (model: model): Tea_Sub.t<msg> => {
  if model.paneN.inferenceActive {
    Tea_Sub.batch(list{
      Tea_Time.every(8000.0, _time => {
        let nextPhase = switch model.paneN.agency.phase {
        | Observe => Orient
        | Orient => Decide
        | Decide => Act
        | Act => Observe
        }
        PaneN(
          UpdateAgency({
            ...model.paneN.agency,
            phase: nextPhase,
          }),
        )
      }),
    })
  } else {
    Tea_Sub.none
  }
}

/// S5: Filesystem watcher subscriptions — relay watcher events into TEA loop.
/// The Rust watcher emits on `watcher://event` when files change on disk.
/// This parses the JSON payload into a typed watchEvent and dispatches it.
let watcherSubscriptions = (_model: model): Tea_Sub.t<msg> => {
  Tea_Sub.batch(list{
    // Filesystem events → Watcher panel + consuming panels (Farm, Hypatia, etc.)
    GossamerEvents.onWatcherEvent(payload => {
      switch WatcherCmd.parseEvent(payload) {
      | Some(evt) => Watcher(FileEvent(evt))
      | None => NoOp
      }
    }),
    // Watcher errors → Observatory activity log
    GossamerEvents.onWatcherError(payload => Watcher(WatcherResult(Error(payload)))),
  })
}

/// Combined subscriptions — all subscription layers merged.
let all = (model: model): Tea_Sub.t<msg> => {
  Tea_Sub.batch(list{
    subscriptions(model),
    inferenceSubscriptions(model),
    neurosymbolicSubscriptions(model),
    tokenDripFeed(model),
    oodaPhaseCycling(model),
    watcherSubscriptions(model),
  })
}
