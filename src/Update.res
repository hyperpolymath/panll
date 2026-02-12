// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Update - The state transition logic.
///
/// This module implements the TEA update function, managing all
/// state transitions with deterministic, side-effect-free logic.

open Model
open Msg

/// Update Pane-L state
let updatePaneL = (model: model, msg: paneLMsg): model => {
  let paneL = model.paneL
  let newPaneL = switch msg {
  | AddConstraint(c) => {...paneL, constraints: Array.concat(paneL.constraints, [c])}
  | RemoveConstraint(id) => {
      ...paneL,
      constraints: Array.filter(paneL.constraints, c => c.id !== id),
    }
  | ToggleConstraint(id) => {
      ...paneL,
      constraints: Array.map(paneL.constraints, c =>
        c.id === id ? {...c, active: !c.active} : c
      ),
    }
  | PinConstraint(id) => {
      ...paneL,
      constraints: Array.map(paneL.constraints, c =>
        c.id === id ? {...c, pinned: !c.pinned} : c
      ),
    }
  | UpdateEditorContent(content) => {...paneL, editorContent: content}
  | SetActiveConstraint(id) => {...paneL, activeConstraintId: id}
  }
  {...model, paneL: newPaneL}
}

/// Update Pane-N state
let updatePaneN = (model: model, msg: paneNMsg): model => {
  let paneN = model.paneN
  let newPaneN = switch msg {
  | ReceiveToken(token) => {...paneN, tokens: Array.concat(paneN.tokens, [token])}
  | ClearTokens => {...paneN, tokens: []}
  | SetInferenceActive(active) => {...paneN, inferenceActive: active}
  | UpdateMonologue(text) => {...paneN, monologue: text}
  | UpdateAgency(agency) => {...paneN, agency}
  }
  {...model, paneN: newPaneN}
}

/// Apply panic-attacker/PanLL event-chain JSON into Pane-W state.
/// This coalesces the parsed payload with the event-chain view, summary, and
/// timeline metadata so the world pane can visualize time/space studies.
let applyEventChainContents = (paneW: paneWState, contents: string): paneWState => {
  let base = {
    ...paneW,
    eventChainInput: contents,
    eventChainError: None,
  }
  switch EventChain.parse(contents) {
  | Ok(payload) => {
      ...base,
      eventChain: payload.events,
      eventChainSummary: payload.summary,
      eventChainTimeline: payload.timeline,
      eventChainError: None,
    }
  | Error(err) => {...base, eventChainError: Some(err)}
  }
}

/// Update Pane-W state
let updatePaneW = (model: model, msg: paneWMsg): model => {
  let paneW = model.paneW
  let newPaneW = switch msg {
  | UpdateContent(content) => {...paneW, content}
  | ToggleTopologyView => {...paneW, topologyView: !paneW.topologyView}
  | SetValidatedOutput(output) => {...paneW, lastValidatedOutput: output}
  | UpdateEventChainInput(input) => {
      ...paneW,
      eventChainInput: input,
      eventChainError: None,
    }
  | SetSecurityTarget(target) => {...paneW, securityTarget: target}
  | SetSecurityTimeline(path) => {...paneW, securityTimeline: path}
  | SetSecurityAxes(axes) => {...paneW, securityAxes: axes}
  | SetSecurityIntensity(intensity) => {...paneW, securityIntensity: intensity}
  | SetSecurityDuration(duration) => {...paneW, securityDuration: duration}
  | ImportEventChain =>
    switch EventChain.parse(paneW.eventChainInput) {
    | Ok(payload) => {
        ...paneW,
        eventChain: payload.events,
        eventChainSummary: payload.summary,
        eventChainError: None,
      }
    | Error(err) => {...paneW, eventChainError: Some(err)}
    }
  | ImportEventChainFile => paneW
  | ImportPanicAttackerReportFile => paneW
  | ImportLatestPanicAttacker => paneW
  | CheckPanicAttackerCapability => paneW
  | ToggleSecurityTools => {...paneW, securityMenuExpanded: !paneW.securityMenuExpanded}
  | OpenSecurityDialog(tool) =>
    {...paneW, securityDialogOpen: true, securityDialogTool: Some(tool)}
  | CloseSecurityDialog => {...paneW, securityDialogOpen: false}
  | ToggleSecurityStudyView => {...paneW, securityViewActive: !paneW.securityViewActive}
  | PanicAttackerReportPathLoaded(_) => paneW
  | PanicAttackerCapabilityLoaded(result) =>
    switch result {
    | Ok(raw) =>
      switch PanicAttackerCapability.parse(raw) {
      | Ok(capability) => {
          ...paneW,
          panicAttackerMode: capability.mode,
          panicAttackerBinary: capability.binary,
          panicAttackerStatusDetail: capability.detail,
        }
      | Error(err) => {
          ...paneW,
          panicAttackerMode: "unavailable",
          panicAttackerBinary: None,
          panicAttackerStatusDetail: Some(err),
        }
      }
    | Error(err) => {
        ...paneW,
        panicAttackerMode: "unavailable",
        panicAttackerBinary: None,
        panicAttackerStatusDetail: Some(err),
      }
    }
  | EventChainFileLoaded(result) =>
    switch result {
    | Ok(contents) => applyEventChainContents(paneW, contents)
    | Error(err) => {...paneW, eventChainError: Some(err)}
    }
  | PanicAttackerImportLoaded(result) =>
    switch result {
    | Ok(contents) => applyEventChainContents(paneW, contents)
    | Error(err) => {...paneW, eventChainError: Some(err)}
    }
  | ClearEventChain => {
      ...paneW,
      eventChain: [],
      eventChainSummary: None,
      eventChainTimeline: None,
      eventChainError: None,
    }
  | _ => paneW
  }
  {...model, paneW: newPaneW}
}

/// Update Vexometer state
let updateVexometer = (model: model, msg: vexometerMsg): model => {
  let vex = model.vexometer
  let newVex = switch msg {
  | RecordCancellation => {...vex, recentCancellations: vex.recentCancellations + 1}
  | RecordCorrection => {...vex, recentCorrections: vex.recentCorrections + 1}
  | RequestVexationIndex => vex
  | UpdateVexationIndex(idx) => {...vex, index: idx}
  | ToggleAntiInflammatory(active) => {...vex, antiInflammatoryActive: active}
  | SetInertiaDetected(detected) => {...vex, inertiaDetected: detected}
  | ResetVexometer => {
      index: 0.0,
      recentCancellations: 0,
      recentCorrections: 0,
      antiInflammatoryActive: false,
      inertiaDetected: false,
    }
  }
  {...model, vexometer: newVex}
}

/// Update Orbital state
let updateOrbital = (model: model, msg: orbitalMsg): model => {
  let orbital = model.orbital
  let newOrbital = switch msg {
  | UpdateStability(sigma) => {...orbital, stability: sigma}
  | UpdateDivergence(level) => {...orbital, divergenceLevel: level}
  | SetDriftAura(colour) => {...orbital, driftAuraColour: colour}
  }
  {...model, orbital: newOrbital}
}

/// Update View state
let updateView = (model: model, msg: viewMsg): model => {
  switch msg {
  | TogglePaneL => {...model, paneLVisible: !model.paneLVisible}
  | TogglePaneN => {...model, paneNVisible: !model.paneNVisible}
  | TogglePaneW => {...model, paneWVisible: !model.paneWVisible}
  | ToggleProtocolAnalysis => {
      ...model,
      protocolAnalysisVisible: !model.protocolAnalysisVisible,
    }
  | SetViewMode(mode) => {...model, viewMode: mode}
  | SetHumidity(level) => {...model, humidity: level}
  | ParallaxAlign => {
      ...model,
      paneLVisible: true,
      paneNVisible: true,
      paneWVisible: true,
    }
  }
}

/// Update Feedback state
let updateFeedback = (model: model, msg: feedbackMsg): model => {
  switch msg {
  | OpenFeedback => {
      ...model,
      feedbackPending: Some(""),
      feedbackError: None,
      feedbackReportType: Some(Option.getOr(model.feedbackReportType, "FeatureRequest")),
    }
  | SubmitFeedback(report) => {...model, feedbackPending: Some(report)}
  | CancelFeedback => {...model, feedbackPending: None, feedbackError: None}
  | SetReportType(reportType) => {...model, feedbackReportType: Some(reportType)}
  | FeedbackSubmitted => {...model, feedbackError: None}
  | FeedbackSubmissionResult(result) =>
    switch result {
    | Ok(_) => {...model, feedbackPending: None, feedbackError: None}
    | Error(err) => {...model, feedbackError: Some(err)}
    }
  }
}

/// Determine if a message should trigger auto-save
let shouldAutoSave = (msg: msg): bool => {
  switch msg {
  | PaneL(AddConstraint(_))
  | PaneL(RemoveConstraint(_))
  | PaneL(ToggleConstraint(_))
  | PaneL(PinConstraint(_))
  | PaneL(UpdateEditorContent(_))
  | PaneN(ReceiveToken(_))
  | PaneN(ClearTokens)
  | PaneW(UpdateContent(_))
  | PaneW(ImportEventChain)
  | PaneW(EventChainFileLoaded(_))
  | PaneW(PanicAttackerImportLoaded(_))
  | PaneW(ClearEventChain)
  | View(SetViewMode(_))
  | View(SetHumidity(_))
  | View(TogglePaneL)
  | View(TogglePaneN)
  | View(TogglePaneW) => true
  | _ => false
  }
}

/// Main update function
let update = (model: model, msg: msg): (model, Tea_Cmd.t<msg>) => {
  let (newModel, command) = switch msg {
  | PaneL(m) => (updatePaneL(model, m), Tea_Cmd.none)
  | PaneN(ReceiveToken(token)) => {
      let (nextAntiCrash, maybeToken) =
        AntiCrash.processToken(token, model.paneL.constraints, model.antiCrash)
      let nextPaneN = switch maybeToken {
      | Some(approved) => {
          ...model.paneN,
          tokens: Array.concat(model.paneN.tokens, [approved]),
        }
      | None => model.paneN
      }
      let updatedModel = {...model, paneN: nextPaneN, antiCrash: nextAntiCrash}
      let command = switch maybeToken {
      | Some(approved) =>
        if model.antiCrash.enabled {
          let activeConstraints =
            model.paneL.constraints
            ->Array.filter(c => c.active)
            ->Array.map(c => c.expression)
          TauriCmd.validateInference(
            approved.content,
            activeConstraints,
            result =>
              switch result {
              | Ok(true) => AntiCrash(ValidationPassed(approved))
              | Ok(false) => AntiCrash(ValidationFailed(approved, "Backend validation failed"))
              | Error(err) => AntiCrash(ValidationFailed(approved, err))
              },
          )
        } else {
          Tea_Cmd.none
        }
      | None => Tea_Cmd.none
      }
      (updatedModel, command)
    }
  | PaneN(m) => (updatePaneN(model, m), Tea_Cmd.none)
  | PaneW(ImportEventChainFile) =>
    (model, TauriCmd.openEventChainFile(result => PaneW(EventChainFileLoaded(result))))
  | PaneW(ImportPanicAttackerReportFile) =>
    (
      model,
      TauriCmd.openPanicAttackerReportFile(result => PaneW(PanicAttackerReportPathLoaded(result))),
    )
  | PaneW(PanicAttackerReportPathLoaded(result)) =>
    switch result {
    | Ok(reportPath) =>
      (
        model,
        TauriCmd.importPanicAttackerReport(
          reportPath,
          importResult => PaneW(PanicAttackerImportLoaded(importResult)),
        ),
      )
    | Error(err) =>
      (
        {
          ...model,
          paneW: {...model.paneW, eventChainError: Some(err)},
        },
        Tea_Cmd.none,
      )
    }
  | PaneW(LoadSecurityTimelineFile) =>
    (
      model,
      TauriCmd.openSecurityTimelineFile(result => PaneW(SecurityTimelineFileLoaded(result))),
    )
  | PaneW(SecurityTimelineFileLoaded(result)) =>
    let updatedPaneW = switch result {
    | Ok(path) =>
      {...model.paneW, securityTimeline: path, securityError: None}
    | Error(err) =>
      {...model.paneW, securityError: Some(err)}
    };
    ({...model, paneW: updatedPaneW}, Tea_Cmd.none)
  | PaneW(LaunchSecurityAmbush) => {
    /* The security dialog runs `panic-attack ambush` through the Tauri backend.
       We validate the target path, timeline, axes, intensity, and duration before
       issuing the backend command so the UI remains in sync with the verified CLI. */
    let target = String.trim(model.paneW.securityTarget);
    if target === "" {
      (
        {
          ...model,
          paneW: {...model.paneW, securityStatus: None, securityError: Some("Program path is required")},
        },
        Tea_Cmd.none,
      )
    } else {
      let timeline =
        if model.paneW.securityTimeline === "" {
          None
        } else {
          Some(model.paneW.securityTimeline)
        };
      let axes =
        if model.paneW.securityAxes === "" {
          None
        } else {
          Some(model.paneW.securityAxes)
        };
      let durationSecs =
        switch Int.fromString(model.paneW.securityDuration) {
        | Some(value) => value
        | None => 30
        };
      (
        {
          ...model,
          paneW: {...model.paneW, securityStatus: Some("Launching ambush..."), securityError: None},
        },
        TauriCmd.runPanicAttackAmbush(
          target,
          timeline,
          axes,
          model.paneW.securityIntensity,
          durationSecs,
          result => PaneW(SecurityAmbushResult(result)),
        ),
      )
    }
  }
  | PaneW(SecurityAmbushResult(result)) =>
    /* Once the backend returns the Panic-Attack export (with fallback conversion),
       we feed the payload into `applyEventChainContents` so the Time/Space view
       and summary reflect the latest ambush run. */
    switch result {
    | Ok(contents) =>
      let imported =
        applyEventChainContents(
          {...model.paneW, securityStatus: Some("Ambush complete"), securityError: None},
          contents,
        );
      ({...model, paneW: imported}, Tea_Cmd.none)
    | Error(err) =>
      (
        {
          ...model,
          paneW: {...model.paneW, securityStatus: None, securityError: Some(err)},
        },
        Tea_Cmd.none,
      )
    }
  | PaneW(ImportLatestPanicAttacker) =>
    (
      model,
      TauriCmd.importLatestPanicAttackerReport(result => PaneW(PanicAttackerImportLoaded(result))),
    )
  | PaneW(CheckPanicAttackerCapability) =>
    (
      model,
      TauriCmd.getPanicAttackerCapability(result => PaneW(PanicAttackerCapabilityLoaded(result))),
    )
  | PaneW(m) => (updatePaneW(model, m), Tea_Cmd.none)
  | Vexometer(RequestVexationIndex) =>
    (model, TauriCmd.getVexationIndex(idx => Vexometer(UpdateVexationIndex(idx))))
  | Vexometer(m) => (updateVexometer(model, m), Tea_Cmd.none)
  | Orbital(m) => (updateOrbital(model, m), Tea_Cmd.none)
  | View(m) => (updateView(model, m), Tea_Cmd.none)
  | Feedback(FeedbackSubmitted) => {
      let reportType = Option.getOr(model.feedbackReportType, "General")
      let command =
        TauriCmd.submitFeedback(
          model.paneL.editorContent,
          model.paneN.monologue,
          model.paneW.content,
          reportType,
          result => Feedback(FeedbackSubmissionResult(result)),
        )
      ({...model, feedbackError: None}, command)
    }
  | Feedback(m) => (updateFeedback(model, m), Tea_Cmd.none)
  | AntiCrash(ValidationPassed(token)) => {
      let updatedTokens =
        model.paneN.tokens
        ->Array.map(t =>
            t.timestamp === token.timestamp && t.content === token.content
              ? {...t, validated: true}
              : t
          )
      let updatedPaneN = {...model.paneN, tokens: updatedTokens}
      ({...model, paneN: updatedPaneN}, Tea_Cmd.none)
    }
  | AntiCrash(ValidationFailed(token, reason)) => {
      let updatedTokens =
        model.paneN.tokens
        ->Array.map(t =>
            t.timestamp === token.timestamp && t.content === token.content
              ? {...t, validated: false}
              : t
          )
      let updatedPaneN = {...model.paneN, tokens: updatedTokens}
      let updatedAntiCrash = {
        ...model.antiCrash,
        violations: Array.concat(model.antiCrash.violations, [LogicContradiction(reason)]),
        halted: model.antiCrash.strictMode,
      }
      ({...model, paneN: updatedPaneN, antiCrash: updatedAntiCrash}, Tea_Cmd.none)
    }
  | AntiCrash(_) => (model, Tea_Cmd.none)
  | SaveState => {
      Storage.save(model)
      (model, Tea_Cmd.none)
    }
  | NoOp => (model, Tea_Cmd.none)
  }

  // Check for anti-inflammatory triggers
  let finalModel = if newModel.vexometer.index > 0.7 {
    {...newModel, vexometer: {...newModel.vexometer, antiInflammatoryActive: true}}
  } else {
    newModel
  }

  // Orbital synchronisation (skip for NoOp and SaveState)
  let syncedModel = switch msg {
  | NoOp | SaveState => finalModel
  | _ => {
      let (newSyncState, newOrbital) = OrbitalSync.sync(finalModel, finalModel.syncState)
      let newHumidity = OrbitalSync.getHumidityLevel(finalModel)
      {...finalModel, syncState: newSyncState, orbital: newOrbital, humidity: newHumidity}
    }
  }

  // Contractile evaluation and adaptation (skip for NoOp and SaveState)
  let contractedModel = switch msg {
  | NoOp | SaveState => syncedModel
  | _ => {
      let _evaluationResults = Contractiles.evaluateAll(syncedModel, syncedModel.contractiles)
      let adaptedContractiles = Array.map(syncedModel.contractiles, c => Contractiles.adaptContract(c, syncedModel))
      {...syncedModel, contractiles: adaptedContractiles}
    }
  }

  // Auto-save state after important changes
  if shouldAutoSave(msg) {
    Storage.save(contractedModel)
  }

  (contractedModel, command)
}
