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

/// Hypatia neurosymbolic scanner messages — network status, scan results,
/// learning cycle, quarantine, and category navigation.
type hypatiaMsg =
  /// Load all Hypatia data (networks + scans).
  | LoadHypatia
  /// Neural network states loaded.
  | NetworksLoaded(result<string, string>)
  /// Scan results loaded.
  | ScansLoaded(result<string, string>)
  /// Change the active category tab.
  | SetHypatiaCategory(hypatiaCategory)
  /// Update the scan results text filter.
  | SetHypatiaFilter(string)

/// Gitbot-Fleet panel messages — bot status, findings queue, dispatch,
/// and safety triangle navigation.
type fleetMsg =
  /// Load all fleet data (bots + findings).
  | LoadFleet
  /// Bot status loaded from fleet API.
  | BotsLoaded(result<string, string>)
  /// Findings loaded from fleet API.
  | FindingsLoaded(result<string, string>)
  /// Change the active category tab.
  | SetFleetCategory(fleetCategory)
  /// Update the findings text filter.
  | SetFleetFilter(string)

/// Reposystem RSR compliance messages.
type reposystemMsg =
  | ScanAll
  | ScanAllLoaded(result<string, string>)
  | SetRsrCategory(reposystemCategory)
  | SetRsrFilter(string)

/// Aerie network diagnostics messages.
type aerieMsg =
  | LoadAerie
  | LatencyLoaded(result<string, string>)
  | SpeedTestLoaded(result<string, string>)
  | SetAerieCategory(aerieCategory)

/// Interfaces ABI/FFI inventory messages.
type interfacesMsg =
  | ScanInterfaces
  | InterfacesLoaded(result<string, string>)
  | SetIfaceCategory(interfacesCategory)

/// Playgrounds code sandbox messages.
type playgroundsMsg =
  | SetPlayCategory(playgroundsCategory)
  | SetLanguage(playgroundLanguage)
  | UpdateCode(string)
  | Execute
  | ExecuteResult(result<string, string>)
  | LoadSnippet(string)

/// Panel Minter messages — wizard state transitions for creating new panel
/// modules with accessibility and proof hooks baked in by default.
type minterMsg =
  /// Update the panel name (triggers live PascalCase validation).
  | SetPanelName(string)
  /// Update the short name (panel bar label, max ~8 chars).
  | SetShortName(string)
  /// Update the one-line description.
  | SetDescription(string)
  /// Update the icon identifier.
  | SetIcon(string)
  /// Select the backend kind (NoBackend, FilesystemBackend, HttpBackend, DatabaseBackend).
  | SetBackendKind(panelBackendKind)
  /// Select the accessibility level (Standard or Enhanced).
  | SetAccessibility(accessibilityLevel)
  /// Update the endpoint URL (relevant for HTTP/Database backends).
  | SetEndpoint(string)
  /// Add a new empty capability declaration.
  | AddCapability
  /// Remove a capability by index.
  | RemoveCapability(int)
  /// Advance to the next wizard step.
  | NextStep
  /// Go back to the previous wizard step.
  | PrevStep
  /// Trigger the minting operation via Tauri backend.
  | ExecuteMint
  /// Result of the minting operation (success or error).
  | MintResult(result<string, string>)
  /// Reset the minter to its initial state for another panel.
  | ResetMinter

/// Provisioner messages — portfolio bundling, panel configuration,
/// installation lifecycle, and isolation tier management.
type provisionerMsg =
  /// Switch category tab.
  | SetProvCategory(provisionerCategory)
  /// Update filter text.
  | SetProvFilter(string)
  /// Install all panels in a portfolio.
  | InstallPortfolio(string)
  /// Install a single panel.
  | InstallPanel(string)
  /// Remove a single panel (clean uninstall for pods).
  | RemovePanel(string)
  /// Installation result for a panel.
  | InstallResult(string, result<string, string>)
  /// Removal result for a panel.
  | RemoveResult(string, result<string, string>)
  /// Toggle a panel's enabled state.
  | TogglePanelEnabled(string)
  /// Set a panel's isolation tier.
  | SetPanelIsolation(string, panelIsolation)
  /// Update custom portfolio name.
  | SetCustomName(string)
  /// Toggle a panel in/out of the custom portfolio.
  | ToggleCustomPanel(string)
  /// Save the custom portfolio.
  | SaveCustomPortfolio

/// Provenance Map messages — code trust surface lifecycle.
/// The provenance map is ambient (always visible), not a panel overlay.
/// These messages handle file analysis, palette switching, and hostile UX.
type provenanceMsg =
  /// Analyse a file's provenance via git blame.
  | AnalyseFile(string, string) // repoPath, filePath
  /// Blame analysis result.
  | AnalysisResult(result<string, string>)
  /// Unsound marker scan result.
  | UnsoundScanResult(result<string, string>)
  /// Switch the accessibility palette.
  | SetPalette(accessibilityPalette)
  /// Toggle hostile UX suppression (the "pull the battery" action).
  | ToggleHostileUx
  /// Acknowledge a specific unreviewed AI region (dismiss its warning).
  | AcknowledgeRegion(string, int) // filePath, startLine
  /// Enable or disable the provenance overlay entirely.
  | SetEnabled(bool)

/// Watcher messages — filesystem observation infrastructure.
/// The watcher runs in a Rust background thread and emits events via the
/// Tauri event bus. These messages handle lifecycle (start/stop/status)
/// and incoming filesystem events that panels can react to.
type watcherMsg =
  /// Start watching the given paths.
  | StartWatcher(array<string>)
  /// Stop the filesystem watcher.
  | StopWatcher
  /// Request current watcher status.
  | RequestStatus
  /// Watcher lifecycle result (start/stop/add/remove responses).
  | WatcherResult(result<string, string>)
  /// Status response from the backend.
  | StatusLoaded(result<string, string>)
  /// A filesystem event arrived from the Rust watcher.
  | FileEvent(watchEvent)

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
  | Hypatia(hypatiaMsg) // Hypatia neurosymbolic scanner
  | Fleet(fleetMsg) // Gitbot-Fleet orchestration
  | Reposystem(reposystemMsg) // RSR compliance auditing
  | Aerie(aerieMsg) // Network diagnostics
  | Interfaces(interfacesMsg) // ABI/FFI inventory
  | Playgrounds(playgroundsMsg) // Code sandbox
  | Minter(minterMsg) // Panel Minter wizard
  | Provisioner(provisionerMsg) // Portfolio bundles, config, isolation
  | Provenance(provenanceMsg) // Code trust surface (core infrastructure)
  | Watcher(watcherMsg) // Filesystem observation (core infrastructure)
  | PanelSwitcher(panelSwitcherMsg) // Panel navigation and health checks
  | SaveState // Persist current state to storage
  | NoOp
