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
  | FetchOrchStatus
  | OrchStatusLoaded(result<string, string>)

/// ECHIDNA theorem prover backend messages — connection lifecycle, prover
/// catalog browsing, proof submission/verification, interactive sessions
/// (Phase 2 stub), tactic suggestions (Phase 2 stub), theorem search,
/// and UI state toggles.
type echidnaMsg =
  // Connection lifecycle
  | CheckHealth
  | HealthOk(string)
  | HealthError(string)
  // Prover catalog
  | ListProvers
  | ProversLoaded(result<string, string>)
  // Proof submission and verification
  | SubmitProof
  | ProofResult(result<string, string>)
  | SubmitVerify
  | VerifyResult(result<string, string>)
  // Theorem search
  | SearchTheorems(string)
  | SearchResult(result<string, string>)
  // Interactive sessions
  | CreateSession
  | SessionCreated(result<string, string>)
  | ApplyTactic(string, array<string>)
  | TacticApplied(result<string, string>)
  | GetSessionState
  | SessionStateLoaded(result<string, string>)
  | CancelSession
  | UpdateTacticInput(string)
  // Tactic suggestions
  | RequestTacticSuggestions
  | TacticSuggestionsLoaded(result<string, string>)
  // UI state
  | ToggleMenu
  | UpdateProofInput(string)
  | SelectProver(option<string>)
  | ClearProofResult

/// VAB (Verified Assembly Building) messages — server component assembly,
/// category navigation, dependency-driven recomputation, and assembly management.
type vabMsg =
  | ToggleVab
  | SelectCategory(vabCategory)
  | AddComponent(string)
  | RemoveComponent(string)
  | RenameServer(string)
  | ClearAssembly
  | SetFilterText(string)
  | SetSortBy(vabSortBy)
  | HoverComponent(option<string>)

/// CloudGuard Cloudflare domain security management messages — connection
/// lifecycle, zone listing, settings read/write, DNS records, DNSSEC,
/// hardening operations, audit, and UI state toggling.
type cloudguardMsg =
  // Connection lifecycle
  | VerifyToken
  | TokenVerified(result<string, string>)
  // Zone listing
  | FetchZones
  | ZonesLoaded(result<string, string>)
  // Zone selection (multi-select domain ribbon)
  | ToggleZoneSelection(string)
  | SelectAllZones
  | DeselectAllZones
  // Settings read/write
  | FetchSettings(string)
  | SettingsLoaded(result<string, string>)
  | ToggleSetting(string)
  | UpdateSettingValue(string, string)
  | PushChanges
  | ChangesPushed(result<string, string>)
  // DNS records
  | FetchDnsRecords(string)
  | DnsRecordsLoaded(result<string, string>)
  | CreateDnsRecord(string, string, string, string, int, option<bool>, option<int>) // zoneId, type, name, content, ttl, proxied, priority
  | DnsRecordCreated(result<string, string>)
  | DeleteDnsRecord(string, string)
  | DnsRecordDeleted(result<string, string>)
  | StartEditingDnsRecord(string) // record ID to edit
  | CancelEditingDnsRecord
  | ApplySecurityTemplate(string) // template name: "spf", "dmarc", "dkim_revoke", "caa", "tlsrpt"
  // DNSSEC
  | FetchDnssec(string)
  | DnssecLoaded(result<string, string>)
  | EnableDnssec(string)
  | DnssecEnabled(result<string, string>)
  // Hardening
  | HardenSelected
  | HardenZone(string)
  | ZoneHardened(result<string, string>)
  // Audit
  | RunAudit
  | AuditComplete(result<string, string>)
  // Offline config
  | DownloadConfig
  | ConfigDownloaded(result<string, string>)
  // Per-domain exceptions
  | AddException(string, string, settingValue, string) // domain, settingId, overrideValue, reason
  | RemoveException(string, string) // domain, settingId
  // UI state
  | ToggleCloudGuard
  | SetCategory(settingCategory)
  | SetFilterText(string)
  | SetSettingFilter(string)
  | ToggleAuditPanel
  | ToggleDiffPanel

/// Git-Private-Farm panel messages — repo inventory loading, filtering,
/// and category navigation. The farm backend reads local JSON, no HTTP.
type farmMsg =
  /// Trigger loading the repo inventory from farm-manifest.json.
  | LoadRepos
  /// Repo inventory loaded (or failed).
  | ReposLoaded(result<string, string>)
  /// Change the active category tab.
  | SetFarmCategory(farmCategory)
  /// Update the text filter for repo search.
  | SetFarmFilter(string)
  /// Change the sort order.
  | SetFarmSort(farmSortBy)

/// Palimpsest Plaza panel messages — PMPL licensing adoption, compliance
/// scanning, and governance. The plaza backend scans local filesystem.
type plazaMsg =
  /// Load adoption statistics across the ecosystem.
  | LoadAdoptionStats
  /// Adoption stats loaded (or failed).
  | AdoptionStatsLoaded(result<string, string>)
  /// Scan a specific repo for compliance.
  | ScanRepo(string)
  /// Repo scan result.
  | RepoScanned(result<string, string>)
  /// Change the active category tab.
  | SetPlazaCategory(plazaCategory)
  /// Update the text filter.
  | SetPlazaFilter(string)

/// Panel switcher messages — unified panel navigation replacing ad-hoc
/// `visible: bool` toggles on individual overlays. The panel bar dispatches
/// these when the operator clicks an icon.
type panelSwitcherMsg =
  /// Toggle a panel: opens it if closed, closes if already active.
  | TogglePanel(panelId)
  /// Close whatever panel is currently active (Escape key handler).
  | ClosePanels
  /// Health check result for a panel's backend service.
  | HealthCheckResult(panelId, result<string, string>)

/// The unified message type
type msg =
  | PaneL(paneLMsg)
  | PaneN(paneNMsg)
  | PaneW(paneWMsg)
  | VeriSimDB(verisimdbMsg)
  | Echidna(echidnaMsg)
  | Vexometer(vexometerMsg)
  | Orbital(orbitalMsg)
  | View(viewMsg)
  | Feedback(feedbackMsg)
  | AntiCrash(antiCrashMsg)
  | Vab(vabMsg)
  | CloudGuard(cloudguardMsg) // Cloudflare domain security management
  | Farm(farmMsg) // Git-Private-Farm repo inventory
  | Plaza(plazaMsg) // Palimpsest Plaza PMPL licensing
  | PanelSwitcher(panelSwitcherMsg) // Panel navigation and health checks
  | SaveState // Persist current state to storage
  | NoOp
