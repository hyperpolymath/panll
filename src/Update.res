// SPDX-License-Identifier: AGPL-3.0-or-later

/// PanLL Update - The state transition logic.
///
/// This module implements the TEA update function, managing all
/// state transitions with deterministic, side-effect-free logic.

open Model
open Msg
open Tea.Cmd

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

/// Update Pane-W state
let updatePaneW = (model: model, msg: paneWMsg): model => {
  let paneW = model.paneW
  let newPaneW = switch msg {
  | UpdateContent(content) => {...paneW, content}
  | ToggleTopologyView => {...paneW, topologyView: !paneW.topologyView}
  | SetValidatedOutput(output) => {...paneW, lastValidatedOutput: output}
  }
  {...model, paneW: newPaneW}
}

/// Update Vexometer state
let updateVexometer = (model: model, msg: vexometerMsg): model => {
  let vex = model.vexometer
  let newVex = switch msg {
  | RecordCancellation => {...vex, recentCancellations: vex.recentCancellations + 1}
  | RecordCorrection => {...vex, recentCorrections: vex.recentCorrections + 1}
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
  | OpenFeedback => {...model, feedbackPending: Some("")}
  | SubmitFeedback(report) => {...model, feedbackPending: Some(report)}
  | CancelFeedback => {...model, feedbackPending: None}
  | FeedbackSubmitted => {...model, feedbackPending: None}
  }
}

/// Main update function
let update = (model: model, msg: msg): (model, cmd<msg>) => {
  let newModel = switch msg {
  | PaneL(m) => updatePaneL(model, m)
  | PaneN(m) => updatePaneN(model, m)
  | PaneW(m) => updatePaneW(model, m)
  | Vexometer(m) => updateVexometer(model, m)
  | Orbital(m) => updateOrbital(model, m)
  | View(m) => updateView(model, m)
  | Feedback(m) => updateFeedback(model, m)
  | AntiCrash(_) => model // Handled by AntiCrash module
  | NoOp => model
  }

  // Check for anti-inflammatory triggers
  let finalModel = if newModel.vexometer.index > 0.7 {
    {...newModel, vexometer: {...newModel.vexometer, antiInflammatoryActive: true}}
  } else {
    newModel
  }

  (finalModel, none)
}
