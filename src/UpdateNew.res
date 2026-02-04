// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Update - The state transition logic (rescript-tea version)
///
/// This module implements the TEA update function with proper command handling.

open Model
open Msg

/// Update Pane-L state
let updatePaneL = (model: model, msg: paneLMsg): (model, Tea_Cmd.t<msg>) => {
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
  ({...model, paneL: newPaneL}, Tea_Cmd.none)
}

/// Update Pane-N state
let updatePaneN = (model: model, msg: paneNMsg): (model, Tea_Cmd.t<msg>) => {
  let paneN = model.paneN
  let newPaneN = switch msg {
  | ReceiveToken(token) => {...paneN, tokens: Array.concat(paneN.tokens, [token])}
  | ClearTokens => {...paneN, tokens: []}
  | SetInferenceActive(active) => {...paneN, inferenceActive: active}
  | UpdateMonologue(text) => {...paneN, monologue: text}
  | UpdateAgency(agency) => {...paneN, agency}
  }
  ({...model, paneN: newPaneN}, Tea_Cmd.none)
}

/// Update Pane-W state
let updatePaneW = (model: model, msg: paneWMsg): (model, Tea_Cmd.t<msg>) => {
  let paneW = model.paneW
  let newPaneW = switch msg {
  | UpdateContent(content) => {...paneW, content}
  | ToggleTopologyView => {...paneW, topologyView: !paneW.topologyView}
  | SetValidatedOutput(output) => {...paneW, lastValidatedOutput: output}
  }
  ({...model, paneW: newPaneW}, Tea_Cmd.none)
}

/// Update Vexometer state
let updateVexometer = (model: model, msg: vexometerMsg): (model, Tea_Cmd.t<msg>) => {
  let vex = model.vexometer
  let (newVex, cmd) = switch msg {
  | RecordCancellation => ({...vex, recentCancellations: vex.recentCancellations + 1}, Tea_Cmd.none)
  | RecordCorrection => ({...vex, recentCorrections: vex.recentCorrections + 1}, Tea_Cmd.none)
  | UpdateVexationIndex(idx) => ({...vex, index: idx}, Tea_Cmd.none)
  | ToggleAntiInflammatory(active) => ({...vex, antiInflammatoryActive: active}, Tea_Cmd.none)
  | SetInertiaDetected(detected) => ({...vex, inertiaDetected: detected}, Tea_Cmd.none)
  | ResetVexometer => (
      {
        index: 0.0,
        recentCancellations: 0,
        recentCorrections: 0,
        antiInflammatoryActive: false,
        inertiaDetected: false,
      },
      Tea_Cmd.none,
    )
  }
  ({...model, vexometer: newVex}, cmd)
}

/// Update Orbital state
let updateOrbital = (model: model, msg: orbitalMsg): (model, Tea_Cmd.t<msg>) => {
  let orbital = model.orbital
  let newOrbital = switch msg {
  | UpdateStability(sigma) => {...orbital, stability: sigma}
  | UpdateDivergence(level) => {...orbital, divergenceLevel: level}
  | SetDriftAura(colour) => {...orbital, driftAuraColour: colour}
  }
  ({...model, orbital: newOrbital}, Tea_Cmd.none)
}

/// Update View state
let updateView = (model: model, msg: viewMsg): (model, Tea_Cmd.t<msg>) => {
  let newModel = switch msg {
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
  (newModel, Tea_Cmd.none)
}

/// Update Feedback state
let updateFeedback = (model: model, msg: feedbackMsg): (model, Tea_Cmd.t<msg>) => {
  let (newModel, cmd) = switch msg {
  | OpenFeedback => ({...model, feedbackPending: Some("")}, Tea_Cmd.none)
  | SubmitFeedback(report) => {
      // Submit feedback to backend
      let cmd = TauriCmd.submitFeedback(
        "paneL-state", // TODO: Serialize actual state
        "paneN-state",
        "paneW-state",
        report,
        result => {
          switch result {
          | Ok(_) => Feedback(FeedbackSubmitted)
          | Error(_) => Feedback(CancelFeedback)
          }
        },
      )
      ({...model, feedbackPending: Some(report)}, cmd)
    }
  | CancelFeedback => ({...model, feedbackPending: None}, Tea_Cmd.none)
  | FeedbackSubmitted => ({...model, feedbackPending: None}, Tea_Cmd.none)
  }
  (newModel, cmd)
}

/// Update AntiCrash state
let updateAntiCrash = (model: model, msg: antiCrashMsg): (model, Tea_Cmd.t<msg>) => {
  switch msg {
  | ValidateToken(token) => {
      // Send token to backend for validation
      let constraints = model.paneL.constraints
        ->Array.filter(c => c.active)
        ->Array.map(c => c.expression)

      let cmd = TauriCmd.validateInference(
        token.content,
        constraints,
        result => {
          switch result {
          | Ok(true) => AntiCrash(ValidationPassed(token))
          | Ok(false) => AntiCrash(ValidationFailed(token, "Constraint violation"))
          | Error(reason) => AntiCrash(ValidationFailed(token, reason))
          }
        },
      )
      (model, cmd)
    }

  | ValidationPassed(token) => {
      // Token passed validation - add to Pane-N and Pane-W
      let validatedToken = {...token, validated: true}
      let paneN = {...model.paneN, tokens: Array.concat(model.paneN.tokens, [validatedToken])}
      let paneW = {...model.paneW, lastValidatedOutput: token.content}
      ({...model, paneN, paneW}, Tea_Cmd.none)
    }

  | ValidationFailed(token, reason) => {
      // Token failed validation - record in vexometer and halt if strict mode
      let newIndex = model.vexometer.index +. 0.1
      let vexometer = {
        ...model.vexometer,
        recentCancellations: model.vexometer.recentCancellations + 1,
        index: newIndex > 1.0 ? 1.0 : newIndex,
      }
      ({...model, vexometer}, Tea_Cmd.none)
    }

  | RequestOperatorIntervention(reason) => {
      // Show modal or notification requesting operator input
      // For now, just update vexometer
      let vexometer = {...model.vexometer, inertiaDetected: true}
      ({...model, vexometer}, Tea_Cmd.none)
    }
  }
}

/// Main update function
let update = (model: model, msg: msg): (model, Tea_Cmd.t<msg>) => {
  let (newModel, cmd) = switch msg {
  | PaneL(m) => updatePaneL(model, m)
  | PaneN(m) => updatePaneN(model, m)
  | PaneW(m) => updatePaneW(model, m)
  | Vexometer(m) => updateVexometer(model, m)
  | Orbital(m) => updateOrbital(model, m)
  | View(m) => updateView(model, m)
  | Feedback(m) => updateFeedback(model, m)
  | AntiCrash(m) => updateAntiCrash(model, m)
  | NoOp => (model, Tea_Cmd.none)
  }

  // Check for anti-inflammatory triggers
  let finalModel = if newModel.vexometer.index > 0.7 {
    {...newModel, vexometer: {...newModel.vexometer, antiInflammatoryActive: true}}
  } else {
    newModel
  }

  // Trigger vexation index update from backend periodically
  let finalCmd = if finalModel.paneN.inferenceActive {
    Tea_Cmd.batch(list{
      cmd,
      TauriCmd.getVexationIndex(index => Vexometer(UpdateVexationIndex(index))),
    })
  } else {
    cmd
  }

  (finalModel, finalCmd)
}
