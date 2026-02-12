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
  | SecurityTimelineFileLoaded(result) =>
    switch result {
    | Ok(path) => {...paneW, securityTimeline: path}
    | Error(err) => {...paneW, securityError: Some(err)}
    }
  | SecurityAmbushResult(result) =>
    switch result {
    | Ok(contents) => applyEventChainContents(paneW, contents)
    | Error(err) => {...paneW, securityError: Some(err)}
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
  | PaneW(SecurityAmbushResult(_))
  | PaneW(SecurityTimelineFileLoaded(_))
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
  let newModel = switch msg {
  | PaneL(m) => updatePaneL(model, m)
  | PaneN(m) => updatePaneN(model, m)
  | PaneW(m) => updatePaneW(model, m)
  | Vexometer(m) => updateVexometer(model, m)
  | Orbital(m) => updateOrbital(model, m)
  | View(m) => updateView(model, m)
  | Feedback(m) => updateFeedback(model, m)
  | AntiCrash(m) =>
    switch m {
    | ValidateToken(_) => model // Command generated below
    | ValidationPassed(token) => {
        ...model,
        paneN: {
          ...model.paneN,
          tokens: Array.concat(model.paneN.tokens, [{...token, validated: true}]),
        },
        antiCrash: {...model.antiCrash, halted: false},
      }
    | ValidationFailed(_token, reason) => {
        ...model,
        antiCrash: {
          ...model.antiCrash,
          violations: Array.concat(model.antiCrash.violations, [LogicContradiction(reason)]),
          halted: model.antiCrash.strictMode,
        },
      }
    | RequestOperatorIntervention(_) => {
        ...model,
        antiCrash: {...model.antiCrash, halted: true},
      }
    }
  | SaveState => {
      // Save current state to storage
      Storage.save(model)
      model
    }
  | NoOp => model
  }

  // Check for anti-inflammatory triggers
  let withAntiInflammatory = if newModel.vexometer.index > 0.7 {
    {...newModel, vexometer: {...newModel.vexometer, antiInflammatoryActive: true}}
  } else {
    newModel
  }

  // Run OrbitalSync: detect pane changes, compute divergence and stability
  let (newSyncState, newOrbital) = OrbitalSync.sync(
    withAntiInflammatory,
    withAntiInflammatory.syncState,
  )
  let newHumidity = OrbitalSync.getHumidityLevel(withAntiInflammatory)

  // Evaluate Contractiles against current state
  let evaluationResults = Contractiles.evaluateAll(
    withAntiInflammatory,
    withAntiInflammatory.contractiles,
  )

  // Update contractile statuses from evaluation and adapt elasticity
  let updatedContractiles = Array.mapWithIndex(withAntiInflammatory.contractiles, (c, i) => {
    let evaluated = switch evaluationResults->Array.get(i) {
    | Some(result) => {...c, status: result.status}
    | None => c
    }
    Contractiles.adaptContract(evaluated, withAntiInflammatory)
  })

  let finalModel = {
    ...withAntiInflammatory,
    syncState: newSyncState,
    orbital: newOrbital,
    humidity: newHumidity,
    contractiles: updatedContractiles,
  }

  // Auto-save state after important changes
  if shouldAutoSave(msg) {
    Storage.save(finalModel)
  }

  // Generate commands for backend-tracked events
  let cmd = switch msg {
  // Anti-Crash: validate token via backend
  | AntiCrash(ValidateToken(token)) => {
      let constraintExprs = Array.map(
        Array.filter(finalModel.paneL.constraints, c => c.active),
        c => c.expression,
      )
      TauriCmd.validateInference(token.content, constraintExprs, result =>
        switch result {
        | Ok(valid) =>
          valid
            ? AntiCrash(ValidationPassed(token))
            : AntiCrash(ValidationFailed(token, "Backend validation rejected token"))
        | Error(err) => AntiCrash(ValidationFailed(token, err))
        }
      )
    }
  // Vexometer: record events and request index
  | Vexometer(RecordCancellation) =>
    TauriCmd.recordVexationEvent("cancellation", _result => NoOp)
  | Vexometer(RecordCorrection) =>
    TauriCmd.recordVexationEvent("correction", _result => NoOp)
  | Vexometer(RequestVexationIndex) =>
    TauriCmd.getVexationIndex(idx => Vexometer(UpdateVexationIndex(idx)))
  // Feedback: submit report to backend
  | Feedback(SubmitFeedback(_)) =>
    TauriCmd.submitFeedback(
      finalModel.paneL.editorContent,
      finalModel.paneN.monologue,
      finalModel.paneW.content,
      Option.getOr(finalModel.feedbackReportType, "FeatureRequest"),
      result => Feedback(FeedbackSubmissionResult(result)),
    )
  // PaneW: file import and panic-attacker integration
  | PaneW(ImportEventChainFile) =>
    TauriCmd.openEventChainFile(result => PaneW(EventChainFileLoaded(result)))
  | PaneW(ImportPanicAttackerReportFile) =>
    TauriCmd.openPanicAttackerReportFile(result => PaneW(PanicAttackerReportPathLoaded(result)))
  | PaneW(PanicAttackerReportPathLoaded(Ok(path))) =>
    TauriCmd.importPanicAttackerReport(path, result => PaneW(PanicAttackerImportLoaded(result)))
  | PaneW(ImportLatestPanicAttacker) =>
    TauriCmd.importLatestPanicAttackerReport(result => PaneW(PanicAttackerImportLoaded(result)))
  | PaneW(CheckPanicAttackerCapability) =>
    TauriCmd.getPanicAttackerCapability(result => PaneW(PanicAttackerCapabilityLoaded(result)))
  // PaneW: security tools
  | PaneW(LoadSecurityTimelineFile) =>
    TauriCmd.openSecurityTimelineFile(result => PaneW(SecurityTimelineFileLoaded(result)))
  | PaneW(LaunchSecurityAmbush) =>
    TauriCmd.runPanicAttackAmbush(
      finalModel.paneW.securityTarget,
      Some(finalModel.paneW.securityTimeline)->Option.flatMap(t => t === "" ? None : Some(t)),
      Some(finalModel.paneW.securityAxes)->Option.flatMap(a => a === "" ? None : Some(a)),
      finalModel.paneW.securityIntensity,
      switch Int.fromString(finalModel.paneW.securityDuration) {
      | Some(d) => d
      | None => 30
      },
      result => PaneW(SecurityAmbushResult(result)),
    )
  | _ => Tea_Cmd.none
  }

  (finalModel, cmd)
}
