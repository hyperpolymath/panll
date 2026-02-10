// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Messages - The communication protocol for TEA updates.
///
/// All state changes flow through these messages, ensuring the
/// deterministic "Gravitational Synchronicity" of the Binary Star.

open Model

/// Messages for Pane-L (Symbolic)
type paneLMsg =
  | AddConstraint(symbolicConstraint)
  | RemoveConstraint(string)
  | ToggleConstraint(string)
  | PinConstraint(string)
  | UpdateEditorContent(string)
  | SetActiveConstraint(option<string>)

/// Messages for Pane-N (Neural)
type paneNMsg =
  | ReceiveToken(neuralToken)
  | ClearTokens
  | SetInferenceActive(bool)
  | UpdateMonologue(string)
  | UpdateAgency(agencyState)

/// Messages for Pane-W (World/Barycentre)
type paneWMsg =
  | UpdateContent(string)
  | ToggleTopologyView
  | SetValidatedOutput(string)
  | UpdateEventChainInput(string)
  | ImportEventChain
  | ImportEventChainFile
  | EventChainFileLoaded(result<string, string>)
  | ClearEventChain

/// Vexometer messages
type vexometerMsg =
  | RecordCancellation
  | RecordCorrection
  | RequestVexationIndex
  | UpdateVexationIndex(float)
  | ToggleAntiInflammatory(bool)
  | SetInertiaDetected(bool)
  | ResetVexometer

/// Orbital stability messages
type orbitalMsg =
  | UpdateStability(float)
  | UpdateDivergence(float)
  | SetDriftAura(string)

/// View control messages
type viewMsg =
  | TogglePaneL
  | TogglePaneN
  | TogglePaneW
  | ToggleProtocolAnalysis
  | SetViewMode(viewMode)
  | SetHumidity(humidityLevel)
  | ParallaxAlign // Synchronous horizontal tiling

/// Feedback-O-Tron messages
type feedbackMsg =
  | OpenFeedback
  | SubmitFeedback(string)
  | CancelFeedback
  | SetReportType(string)
  | FeedbackSubmitted
  | FeedbackSubmissionResult(result<string, string>)

/// Anti-Crash validation messages
type antiCrashMsg =
  | ValidateToken(neuralToken)
  | ValidationPassed(neuralToken)
  | ValidationFailed(neuralToken, string)
  | RequestOperatorIntervention(string)

/// The unified message type
type msg =
  | PaneL(paneLMsg)
  | PaneN(paneNMsg)
  | PaneW(paneWMsg)
  | Vexometer(vexometerMsg)
  | Orbital(orbitalMsg)
  | View(viewMsg)
  | Feedback(feedbackMsg)
  | AntiCrash(antiCrashMsg)
  | SaveState // Persist current state to storage
  | NoOp
