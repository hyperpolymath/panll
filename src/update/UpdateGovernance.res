// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updaters for Cognitive Governance.
/// Contains: updateVexometer, updateOrbital, updateView, updateFeedback,
/// updateAntiCrash, and applyContractiles (the post-processing pass that
/// runs after every state-modifying update).

open Model
open Msg

// ===========================================================================
// Cognitive Governance Sub-Updaters
// ===========================================================================

/// STATE TRANSITION: Vexometer
/// Tracks operator vexation signals (cancellations, corrections) and manages
/// the anti-inflammatory feedback system. Backend events are recorded via
/// Tauri commands so the Rust VexationTracker can compute the composite index.
let updateVexometer = (model: model, msg: vexometerMsg): (model, Tea_Cmd.t<msg>) => {
  let vex = model.vexometer
  switch msg {
  | RecordCancellation => (
      {...model, vexometer: {...vex, recentCancellations: vex.recentCancellations + 1}},
      GossamerCmd.recordVexationEvent("cancellation", _result => NoOp),
    )
  | RecordCorrection => (
      {...model, vexometer: {...vex, recentCorrections: vex.recentCorrections + 1}},
      GossamerCmd.recordVexationEvent("correction", _result => NoOp),
    )
  | RecordVqlQuery => (
      // VQL queries contribute to cognitive load — tracked as a lighter-weight event.
      model,
      GossamerCmd.recordVexationEvent("vql_query", _result => NoOp),
    )
  | RequestVexationIndex => (
      model,
      GossamerCmd.getVexationIndex(index => Vexometer(UpdateVexationIndex(index))),
    )
  | UpdateVexationIndex(index) => ({...model, vexometer: {...vex, index}}, Tea_Cmd.none)
  | ToggleAntiInflammatory(active) => (
      {...model, vexometer: {...vex, antiInflammatoryActive: active}},
      Tea_Cmd.none,
    )
  | SetInertiaDetected(detected) => (
      {...model, vexometer: {...vex, inertiaDetected: detected}},
      Tea_Cmd.none,
    )
  | ResetVexometer => (
      {
        ...model,
        vexometer: {
          index: 0.0,
          recentCancellations: 0,
          recentCorrections: 0,
          antiInflammatoryActive: false,
          inertiaDetected: false,
        },
      },
      GossamerCmd.recordVexationEvent("reset", _result => NoOp),
    )
  }
}

/// STATE TRANSITION: Orbital Stability
/// Manages the Binary Star co-orbit stability metrics and drift aura.
/// The aura colour reflects orbit health: "indigo" (stable) or "amber" (decaying).
let updateOrbital = (model: model, msg: orbitalMsg): (model, Tea_Cmd.t<msg>) => {
  let orbital = model.orbital
  switch msg {
  | UpdateStability(value) => {
      // Recalculate drift aura colour when stability changes.
      let colour = if value >= 0.7 {
        "indigo"
      } else {
        "amber"
      }
      ({...model, orbital: {...orbital, stability: value, driftAuraColour: colour}}, Tea_Cmd.none)
    }
  | UpdateDivergence(value) => (
      {...model, orbital: {...orbital, divergenceLevel: value}},
      Tea_Cmd.none,
    )
  | SetDriftAura(colour) => (
      {...model, orbital: {...orbital, driftAuraColour: colour}},
      Tea_Cmd.none,
    )
  }
}

// ===========================================================================
// View & Feedback Sub-Updaters
// ===========================================================================

/// STATE TRANSITION: View Controls
/// Manages pane visibility, view mode, and information humidity level.
/// ParallaxAlign is a compound action that resets to the canonical three-pane layout.
let updateView = (model: model, msg: viewMsg): (model, Tea_Cmd.t<msg>) => {
  switch msg {
  | TogglePaneL => ({...model, paneLVisible: !model.paneLVisible}, Tea_Cmd.none)
  | TogglePaneN => ({...model, paneNVisible: !model.paneNVisible}, Tea_Cmd.none)
  | TogglePaneW => ({...model, paneWVisible: !model.paneWVisible}, Tea_Cmd.none)
  | ToggleProtocolAnalysis => (
      {...model, protocolAnalysisVisible: !model.protocolAnalysisVisible},
      Tea_Cmd.none,
    )
  | SetViewMode(mode) => ({...model, viewMode: mode}, Tea_Cmd.none)
  | SetHumidity(level) => ({...model, humidity: level}, Tea_Cmd.none)
  | ParallaxAlign => (
      // Synchronous horizontal tiling: show all panes in Standard mode.
      {...model, paneLVisible: true, paneNVisible: true, paneWVisible: true, viewMode: Standard},
      Tea_Cmd.none,
    )
  | TogglePanelBar => ({...model, panelBarVisible: !model.panelBarVisible}, Tea_Cmd.none)
  | ToggleFullscreen => (
      // When entering fullscreen, hide the panel bar. When exiting, restore it.
      {
        ...model,
        fullscreenActive: !model.fullscreenActive,
        panelBarVisible: model.fullscreenActive,
      },
      Tea_Cmd.none,
    )
  }
}

/// STATE TRANSITION: Feedback-O-Tron
/// Manages the feedback lifecycle: open dialog, submit to backend, cancel,
/// and handle the asynchronous submission result.
let updateFeedback = (model: model, msg: feedbackMsg): (model, Tea_Cmd.t<msg>) => {
  switch msg {
  | OpenFeedback => ({...model, feedbackPending: Some("")}, Tea_Cmd.none)
  | SubmitFeedback(text) => {
      let reportType = switch model.feedbackReportType {
      | Some(t) => t
      | None => "General"
      }
      (
        model,
        GossamerCmd.submitFeedback(
          text,
          model.paneN.monologue,
          model.paneW.content,
          reportType,
          result => Feedback(FeedbackSubmissionResult(result)),
        ),
      )
    }
  | CancelFeedback => ({...model, feedbackPending: None}, Tea_Cmd.none)
  | SetReportType(t) => ({...model, feedbackReportType: Some(t)}, Tea_Cmd.none)
  | FeedbackSubmitted => {
      // Build a JSON report from current feedback state and submit to Rust backend.
      let reportType = switch model.feedbackReportType {
      | Some(t) => t
      | None => "General"
      }
      let feedbackText = switch model.feedbackPending {
      | Some(text) => text
      | None => ""
      }
      let reportJson = `{"type":"${reportType}","text":"${feedbackText}","timestamp":"${Date.make()->Date.toISOString}"}`
      let cmd = FeedbackCmd.saveReport(reportJson, r => Feedback(FeedbackSubmissionResult(r)))
      ({...model, feedbackPending: None, feedbackError: None}, cmd)
    }
  | FeedbackSubmissionResult(result) =>
    switch result {
    | Ok(_) => ({...model, feedbackPending: None, feedbackError: None}, Tea_Cmd.none)
    | Error(err) => ({...model, feedbackError: Some(err)}, Tea_Cmd.none)
    }
  }
}

// ===========================================================================
// Anti-Crash Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Anti-Crash Validation
/// Routes neural tokens through the symbolic validation pipeline (the Circuit
/// Breaker) before they can reach the Task Barycentre. Halts inference when
/// a strict violation is detected, requiring operator intervention to resume.
let updateAntiCrash = (model: model, msg: antiCrashMsg): (model, Tea_Cmd.t<msg>) => {
  switch msg {
  | ValidateToken(token) => {
      // Run the token through the full Anti-Crash pipeline.
      let (newAntiCrash, validatedToken) = AntiCrash.processToken(
        token,
        model.paneL.constraints,
        model.antiCrash,
      )
      // If the token passed validation, add it to the neural stream.
      let newPaneN = switch validatedToken {
      | Some(vt) => {
          ...model.paneN,
          tokens: Array.concat(model.paneN.tokens, [vt]),
          nextTokenId: model.paneN.nextTokenId + 1,
          activeCausalChain: [vt.id],
        }
      | None => model.paneN
      }
      // M4: Anti-Crash → Governance feedback. When a token is rejected,
      // record a correction in the Vexometer so the governance engine
      // can adjust contractile elasticity on the next pass.
      let newVexometer = switch validatedToken {
      | None => {...model.vexometer, recentCorrections: model.vexometer.recentCorrections + 1}
      | Some(_) => model.vexometer
      }
      // Fire TypeLL type-level validation asynchronously for the token content.
      let constraintExprs = Array.map(Array.filter(model.paneL.constraints, c => c.active), c =>
        c.expression
      )
      let typellCmd = if Array.length(constraintExprs) > 0 {
        TypeLLService.validateToken(token.content, constraintExprs, result => AntiCrash(
          TokenTypeCheckResult(result),
        ))
      } else {
        Tea_Cmd.none
      }
      ({...model, antiCrash: newAntiCrash, paneN: newPaneN, vexometer: newVexometer}, typellCmd)
    }
  | ValidationPassed(token) => {
      // Token has already been validated externally — mark as validated and add.
      let validatedToken = {...token, validated: true}
      let newPaneN = {
        ...model.paneN,
        tokens: Array.concat(model.paneN.tokens, [validatedToken]),
        nextTokenId: model.paneN.nextTokenId + 1,
        activeCausalChain: [validatedToken.id],
      }
      ({...model, paneN: newPaneN}, Tea_Cmd.none)
    }
  | ValidationFailed(_token, reason) => {
      // Record the violation and potentially halt inference.
      let violation = LogicContradiction(reason)
      let newAntiCrash = {
        ...model.antiCrash,
        violations: Array.concat(model.antiCrash.violations, [violation]),
        halted: model.antiCrash.strictMode,
      }
      ({...model, antiCrash: newAntiCrash}, Tea_Cmd.none)
    }
  | RequestOperatorIntervention(_reason) => {
      // Halt the system and wait for operator to review.
      let newAntiCrash = {
        ...model.antiCrash,
        halted: true,
      }
      ({...model, antiCrash: newAntiCrash}, Tea_Cmd.none)
    }
  | TokenTypeCheckResult(Ok(_json)) => {
      // TypeLL confirmed type safety — increment service counter.
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TokenTypeCheckResult(Error(reason)) => {
      // TypeLL found a type violation — record it as a type-level constraint failure.
      let violation = LogicContradiction("TypeLL: " ++ reason)
      let newAntiCrash = {
        ...model.antiCrash,
        violations: Array.concat(model.antiCrash.violations, [violation]),
      }
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, antiCrash: newAntiCrash, typell: newTypell}, Tea_Cmd.none)
    }
  }
}

// ===========================================================================
// Contractiles Post-Processing (Cognitive Governance)
// ===========================================================================

/// Evaluate all contractiles against the current model state and update their
/// statuses. If any Strict contractile is Violated, halt neural inference as
/// a safety measure. This is called after every state-modifying update in the
/// main orchestrator.
let applyContractiles = (model: model, cmd: Tea_Cmd.t<msg>): (model, Tea_Cmd.t<msg>) => {
  // --- Phase 1: Evaluate contractiles ---

  let results = Contractiles.evaluateAll(model, model.contractiles)

  // Update each contractile's status based on evaluation results.
  let updatedContractiles = Array.map(model.contractiles, c => {
    let result = Array.find(results, r => r.contractId === c.id)
    switch result {
    | Some(r) => {...c, status: r.status}
    | None => c
    }
  })

  // Check for any Strict contractile violation — these require halting.
  let hasStrictViolation = Array.some(results, r => {
    let contractile = Array.find(model.contractiles, c => c.id === r.contractId)
    switch contractile {
    | Some(c) =>
      switch (c.enforcement, r.status) {
      | (Strict, Violated(_)) => true
      | _ => false
      }
    | None => false
    }
  })

  let newModel = {...model, contractiles: updatedContractiles}

  // Auto-activate anti-inflammatory when vexation index exceeds threshold (0.7).
  let antiInflammatoryActive = newModel.vexometer.index > 0.7
  let newModel = {
    ...newModel,
    vexometer: {...newModel.vexometer, antiInflammatoryActive},
  }

  // If a Strict contractile is violated, halt neural inference.
  let newModel = if hasStrictViolation {
    {...newModel, paneN: {...newModel.paneN, inferenceActive: false}}
  } else {
    newModel
  }

  // --- Phase 2: OrbitalSync — detect L↔N↔W divergence (M2) ---

  let (newSyncState, newOrbital) = OrbitalSync.sync(newModel, newModel.syncState)
  let newModel = {...newModel, syncState: newSyncState, orbital: newOrbital}

  // --- Phase 3: Consume pendingSync events (M2) ---
  // Cross-panel sync events feed back into the orbital metrics and
  // are cleared after processing. In future, these will trigger
  // Panel Bus events for inter-module communication.

  let syncEventCount = Array.length(newModel.syncState.pendingSync)
  let newModel = if syncEventCount > 0 {
    // Sync latency increases with event volume (simple heuristic).
    let latencyAdjust = Int.toFloat(syncEventCount) *. 5.0
    let newSync = {
      ...newModel.syncState,
      pendingSync: [], // Consumed — clear the queue
      syncLatency: Math.min(500.0, newModel.syncState.syncLatency +. latencyAdjust),
    }
    {...newModel, syncState: newSync}
  } else {
    // No events — latency decays toward zero.
    let newSync = {
      ...newModel.syncState,
      syncLatency: Math.max(0.0, newModel.syncState.syncLatency -. 2.0),
    }
    {...newModel, syncState: newSync}
  }

  // --- Phase 4: GovernanceEngine — close all feedback loops (M1, M3, M4) ---
  // Anti-Crash violations → Governance → Contractile elasticity
  // Vexometer frustration → Governance → Anti-Crash strictness
  // Orbital divergence → Governance → inference halting / humidity

  let (newModel, governanceCmd) = GovernanceEngine.governWithCmd(
    newModel,
    r => GovernanceNesyResult(r),
  )

  // --- Phase 5: Panel Bus event emission (M5) ---
  // Emit cross-panel events based on state transitions detected by
  // OrbitalSync and GovernanceEngine. Events are wrapped in envelopes
  // with metadata and routed through the subscriber registry.

  let busEvents: array<PanelBus.panelEvent> = []

  // Emit confidence update if orbital stability changed significantly.
  let stabilityDiff = newModel.orbital.stability -. model.orbital.stability
  let busEvents = if stabilityDiff > 0.05 || stabilityDiff < -0.05 {
    Array.concat(busEvents, [PanelBus.RepoHealthChanged("panll-orbit", newModel.orbital.stability)])
  } else {
    busEvents
  }

  // Emit database connection change if VeriSimDB state changed.
  let busEvents = if newModel.verisimdb.connected !== model.verisimdb.connected {
    Array.concat(
      busEvents,
      [PanelBus.DatabaseConnectionChanged("verisimdb", newModel.verisimdb.connected)],
    )
  } else {
    busEvents
  }

  // Emit inference activity change if Hypatia confidence shifted.
  let busEvents = if newModel.paneN.inferenceActive !== model.paneN.inferenceActive {
    Array.concat(
      busEvents,
      [
        PanelBus.HypatiaConfidenceUpdated(
          "paneN-inference",
          newModel.paneN.inferenceActive ? 1.0 : 0.0,
        ),
      ],
    )
  } else {
    busEvents
  }

  // Emit ECHIDNA proof dispatch if a proof result just arrived.
  let busEvents = if newModel.echidna.lastProofResult !== model.echidna.lastProofResult {
    switch newModel.echidna.lastProofResult {
    | Some(_result) =>
      Array.concat(busEvents, [PanelBus.HypatiaConfidenceUpdated("echidna-proof", 0.95)])
    | None => busEvents
    }
  } else {
    busEvents
  }

  // Emit fleet dispatch when fleet findings change.
  let busEvents = if Array.length(newModel.fleet.findings) !== Array.length(model.fleet.findings) {
    Array.concat(busEvents, [PanelBus.FarmRepoListUpdated(Array.length(newModel.fleet.findings))])
  } else {
    busEvents
  }

  // Emit compliance change if contractile statuses changed.
  let violatedCount = Array.filter(newModel.contractiles, c => {
    switch c.status {
    | Violated(_) => true
    | _ => false
    }
  })->Array.length
  let prevViolatedCount = Array.filter(model.contractiles, c => {
    switch c.status {
    | Violated(_) => true
    | _ => false
    }
  })->Array.length
  let busEvents = if violatedCount !== prevViolatedCount {
    let complianceScore = if Array.length(newModel.contractiles) > 0 {
      1.0 -. Int.toFloat(violatedCount) /. Int.toFloat(Array.length(newModel.contractiles))
    } else {
      1.0
    }
    Array.concat(busEvents, [PanelBus.RsrComplianceChanged("contractiles", complianceScore)])
  } else {
    busEvents
  }

  // Wrap events in envelopes and record in the registry ring buffer.
  let nowMs = Date.now()
  let busRegistry = Array.reduce(busEvents, newModel.busRegistry, (reg, evt) => {
    let (_envelope, updatedReg) = PanelBus.wrapEvent(reg, "governance", evt, nowMs)
    updatedReg
  })
  let newModel = {...newModel, busRegistry}

  // Dispatch follow-up messages for bus events. Each bus event maps to a
  // message that the consuming panel handles. This closes the cross-panel
  // intelligence loop: governance changes propagate to dependent panels.
  let busCmd = if Array.length(busEvents) > 0 {
    let followUps = Array.filterMap(busEvents, evt => {
      switch evt {
      | PanelBus.HypatiaConfidenceUpdated(_repo, _conf) => None // Hypatia consumes internally
      | PanelBus.RepoHealthChanged(_source, _score) => None // Orbital metric, no panel dispatch needed
      | PanelBus.DatabaseConnectionChanged(_db, connected) =>
        // When VeriSimDB connection changes, trigger a health check.
        connected ? Some(VeriSimDB(CheckHealth)) : None
      | PanelBus.RsrComplianceChanged(_source, _score) => None // Reposystem tracks internally
      | PanelBus.FarmRepoListUpdated(_count) => None // Farm refresh handled by Farm panel
      | PanelBus.FleetFixDispatched(_repo, _recipe) => None // Fleet tracks internally
      | PanelBus.HypatiaFindingsRouted(_json) =>
        // When Hypatia routes findings, tell Fleet to reload.
        Some(Fleet(LoadFleet))
      | _ => None // Unhandled bus events are no-ops
      }
    })
    if Array.length(followUps) > 0 {
      Tea_Cmd.batch(List.fromArray(Array.map(followUps, m => Tea_Cmd.msg(m))))
    } else {
      Tea_Cmd.none
    }
  } else {
    Tea_Cmd.none
  }

  // Merge bus commands and governance commands with the original command.
  let finalCmd = Tea_Cmd.batch(list{cmd, busCmd, governanceCmd})

  (newModel, finalCmd)
}
