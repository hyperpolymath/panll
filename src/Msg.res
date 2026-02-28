// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Messages - the communication protocol for TEA updates.
///
/// Every user action, backend response, and timer pulse is encoded here so
/// the Elm-style update loop can deterministically evolve the Binary Star
/// state machine. Annotating as we grow ensures we keep control of the message
/// surface as new features arrive.

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

/// Messages for Pane-W (World/Barycentre) – the security and event chain pane that
/// aggregates panic-attacker data and renders the central canvas.
type paneWMsg =
  | UpdateContent(string)
  | ToggleTopologyView
  | SetValidatedOutput(string)
  | UpdateEventChainInput(string)
  | ImportEventChain
  | ImportEventChainFile
  | ImportPanicAttackerReportFile
  | ImportLatestPanicAttacker
  | CheckPanicAttackerCapability
  | EventChainFileLoaded(result<string, string>)
  | PanicAttackerReportPathLoaded(result<string, string>)
  | PanicAttackerImportLoaded(result<string, string>)
  | PanicAttackerCapabilityLoaded(result<string, string>)
  /// Security menu interactions and panic-attacker command lifecycle
  | ToggleSecurityTools
  | OpenSecurityDialog(string)
  | CloseSecurityDialog
  | ToggleSecurityStudyView
  | SetSecurityTarget(string)
  | SetSecurityTimeline(string)
  | SetSecurityAxes(string)
  | SetSecurityIntensity(string)
  | SetSecurityDuration(string)
  | LoadSecurityTimelineFile
  | SecurityTimelineFileLoaded(result<string, string>)
  | LaunchSecurityAmbush
  | SecurityAmbushResult(result<string, string>)
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

/// VeriSimDB database backend messages — connection lifecycle, VQL query
/// execution, entity browsing, drift status retrieval, normalisation,
/// entity detail loading, and opt-in telemetry retrieval for product
/// development insights.
type verisimdbMsg =
  | CheckHealth
  | HealthResult(result<string, string>)
  | SubmitQuery(string)
  | UpdateQueryInput(string)
  | QueryResult(result<string, string>)
  | ListEntities
  | EntitiesLoaded(result<string, string>)
  | SelectEntity(string)
  | DriftLoaded(result<string, string>)
  | ToggleDbMenu
  | ClearQueryResult
  | TriggerNormalise(string)
  | NormaliseResult(result<string, string>)
  | LoadEntityDetail(string)
  | EntityDetailLoaded(result<string, string>)
  | FetchTelemetry
  | TelemetryLoaded(result<string, string>)
  | ToggleTelemetryPanel

/// The unified message type
type msg =
  | PaneL(paneLMsg)
  | PaneN(paneNMsg)
  | PaneW(paneWMsg)
  | VeriSimDB(verisimdbMsg)
  | Vexometer(vexometerMsg)
  | Orbital(orbitalMsg)
  | View(viewMsg)
  | Feedback(feedbackMsg)
  | AntiCrash(antiCrashMsg)
  | SaveState // Persist current state to storage
  | NoOp
