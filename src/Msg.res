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
  /// TypeLL inferred type for the current editor expression.
  | ConstraintTypeInferred(result<string, string>)

/// Messages for Pane-N (Neural)
type paneNMsg =
  | ReceiveToken(neuralToken)
  | ClearTokens
  | SetInferenceActive(bool)
  | UpdateMonologue(string)
  | UpdateAgency(agencyState)
  /// Token stream filter controls.
  | ToggleSourceFilter(tokenSource)
  | ToggleCategoryFilter(tokenCategory)
  | TogglePhaseFilter(oodaPhase)
  | SetConfidenceThreshold(float)
  | ToggleValidatedOnly
  | ToggleProofOnly
  | ClearFilters

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
  /// Barycentre tour messages
  | StartTour
  | NextTourStep
  | PrevTourStep
  | CloseTour

/// Vexometer messages
type vexometerMsg =
  | RecordCancellation
  | RecordCorrection
  /// Record a VQL query execution for cognitive load tracking.
  | RecordVqlQuery
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
  | TogglePanelBar // Toggle panel switcher bar visibility
  | ToggleFullscreen // Toggle fullscreen (hide all chrome)

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
  /// TypeLL type-level validation result for a token.
  | TokenTypeCheckResult(result<string, string>)

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
  /// TypeLL cross-panel type check result for the last VQL query.
  | VqlTypeCheckResult(result<string, string>)
  /// Toggle VQL-UT proof obligation display in Panel-L.
  | ToggleProofDisplay
  /// Neural advisor suggestion for the current VQL query.
  | InferenceSuggestion(string)
  /// Clear inference suggestions.
  | ClearInferenceSuggestions
  /// Toggle Anti-Crash VQL validation.
  | ToggleAntiCrashValidation
  /// Toggle BoJ routing for VQL queries (database-mcp cartridge).
  | ToggleVeriSimBojRouting

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
  /// TypeLL-generated proof obligations for the current proof input.
  | ProofObligationsGenerated(result<string, string>)
  /// Toggle BoJ routing for proof operations (proof-mcp cartridge).
  | ToggleEchidnaBojRouting
  /// Switch ECHIDNA panel tab (Proof / Enterprise).
  | SelectEchidnaTab(echidnaTab)
  // Enterprise model checking (MOF/OCL)
  /// Import model elements from XMI file.
  | ImportXmiModel
  /// XMI model loaded and parsed.
  | XmiModelLoaded(result<string, string>)
  /// Add an OCL constraint to the enterprise model.
  | AddOclConstraint(string, string, string) // context, name, expression
  /// Remove an OCL constraint by index.
  | RemoveOclConstraint(int)
  /// Run batch OCL constraint checking against loaded model.
  | RunOclCheck
  /// OCL batch check completed.
  | OclCheckResult(result<string, string>)
  /// Filter by metamodel standard.
  | SetMetamodelFilter(option<metamodelStandard>)
  /// Filter by MOF layer.
  | SetMofLayerFilter(option<mofLayer>)
  /// Clear enterprise model state.
  | ClearEnterpriseModel

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
  /// TypeLL cross-panel type check result for assembly config types.
  | TypeCheckResult(result<string, string>)

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
  | HardenSetting(string) // Fix a single audit finding by settingId
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
  /// TypeLL cross-panel type check result for settings JSON types.
  | TypeCheckResult(result<string, string>)

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
  /// TypeLL cross-panel type check result for repo manifest types.
  | TypeCheckResult(result<string, string>)

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
  /// TypeLL cross-panel type check result for compliance spec types.
  | TypeCheckResult(result<string, string>)

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
  /// TypeLL cross-panel type check result for scan config types.
  | TypeCheckResult(result<string, string>)
  /// Select a recipe for detail drill-down (None to deselect).
  | SelectRecipe(option<string>)
  /// Update recipe filter text.
  | SetRecipeFilter(string)

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
  /// TypeLL cross-panel type check result for bot dispatch types.
  | TypeCheckResult(result<string, string>)

/// Reposystem RSR compliance messages.
type reposystemMsg =
  | ScanAll
  | ScanAllLoaded(result<string, string>)
  | SetRsrCategory(reposystemCategory)
  | SetRsrFilter(string)
  /// Select a requirement for drill-down (None to deselect).
  | SelectRequirement(option<rsrRequirement>)
  /// TypeLL cross-panel type check result for RSR compliance types.
  | TypeCheckResult(result<string, string>)

/// Aerie network diagnostics messages.
type aerieMsg =
  | LoadAerie
  | LatencyLoaded(result<string, string>)
  | SpeedTestLoaded(result<string, string>)
  | SetAerieCategory(aerieCategory)
  /// Toggle BoJ routing for overlay operations (observe-mcp cartridge).
  | ToggleAerieBojRouting
  /// Toggle a probe target on/off by endpoint.
  | ToggleProbe(string)
  /// TypeLL cross-panel type check result for network config types.
  | TypeCheckResult(result<string, string>)

/// Interfaces ABI/FFI inventory messages.
type interfacesMsg =
  | ScanInterfaces
  | InterfacesLoaded(result<string, string>)
  | SetIfaceCategory(interfacesCategory)
  /// TypeLL cross-panel type check result for ABI/FFI binding types.
  | TypeCheckResult(result<string, string>)

/// Playgrounds code sandbox messages.
type playgroundsMsg =
  | SetPlayCategory(playgroundsCategory)
  | SetLanguage(playgroundLanguage)
  | UpdateCode(string)
  | Execute
  | ExecuteResult(result<string, string>)
  | LoadSnippet(string)
  /// NQC console: update query input text.
  | SetNqcInput(string)
  /// NQC console: switch query language (VQL/KQL/GQL).
  | SetNqcLanguage(playgroundLanguage)
  /// NQC console: execute the current NQC query.
  | ExecuteNqc
  /// NQC console: query result received.
  | NqcResult(result<string, string>)
  /// NQC console: clear query history.
  | ClearNqcHistory
  /// TypeLL cross-panel type check result for sandbox code types.
  | TypeCheckResult(result<string, string>)

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
  /// Trigger the minting operation via Gossamer backend.
  | ExecuteMint
  /// Result of the minting operation (success or error).
  | MintResult(result<string, string>)
  /// Reset the minter to its initial state for another panel.
  | ResetMinter
  /// Export current minter config to ENSAID_CONFIG.a2ml (adds panel entry).
  | ExportToEnsaidConfig
  /// TypeLL cross-panel type check result for panel spec types.
  | TypeCheckResult(result<string, string>)

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
  /// Export panel configs and portfolios to ENSAID_CONFIG.a2ml.
  | ExportProvisionerConfig
  /// TypeLL cross-panel type check result for portfolio config types.
  | TypeCheckResult(result<string, string>)

/// Code MRI VoiceTag messages — tag CRUD, voice input lifecycle, file I/O,
/// and filter controls. VoiceTag is an ambient annotation system (Layer 0)
/// that stores tags as portable `.mri.json` sidecar files.
type voiceTagMsg =
  /// Load tags from the .mri.json sidecar for the current file.
  | LoadFileTags
  /// Tags loaded from disk (or error).
  | TagsLoaded(result<string, string>)
  /// Tags saved to disk (or error).
  | TagsSaved(result<string, string>)
  /// Sidecar deleted (or error).
  | SidecarDeleted(result<string, string>)
  /// Project scan result (list of all .mri.json files).
  | ProjectScanned(result<string, string>)
  /// Select a tag by ID (for voice reference or click).
  | SelectTag(option<int>)
  /// Delete a tag by ID.
  | DeleteTagById(int)
  /// Resolve a tag by ID.
  | ResolveTagById(int)
  /// Set the type filter.
  | SetFilterType(option<mriTagType>)
  /// Toggle showing resolved tags.
  | ToggleShowResolved
  /// Start voice recognition.
  | StartVoice
  /// Stop voice recognition.
  | StopVoice
  /// Voice transcript received from Web Speech API.
  | VoiceTranscript(string)
  /// Voice recognition error.
  | VoiceError(string)
  /// Set current file path (when user opens a file).
  | SetCurrentFile(string)
  /// TypeLL cross-panel type check result for tag schema types.
  | TypeCheckResult(result<string, string>)

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
  /// TypeLL cross-panel type check result for provenance types.
  | TypeCheckResult(result<string, string>)

/// Watcher messages — filesystem observation infrastructure.
/// The watcher runs in a Rust background thread and emits events via the
/// Gossamer event bus. These messages handle lifecycle (start/stop/status)
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

/// AI panel messages — multi-provider neural interface for sending messages,
/// managing providers, building context, and controlling the conversation.
type aiMsg =
  /// Send a message to the current provider (or broadcast to all enabled).
  | SendMessage
  /// Message response received from a provider.
  | MessageReceived(result<string, string>)
  /// Update the input text field.
  | SetAiInput(string)
  /// Switch the active category tab.
  | SetAiCategory(aiCategory)
  /// Toggle broadcast mode (send to multiple providers simultaneously).
  | ToggleBroadcast
  /// Check provider health/auth status.
  | CheckProvider(aiProviderId)
  /// Provider health check result.
  | ProviderChecked(aiProviderId, result<string, string>)
  /// Change the selected model for a provider.
  | SetAiModel(aiProviderId, string)
  /// Model change confirmed.
  | ModelSet(result<string, string>)
  /// Change a provider's precedence ranking.
  | SetAiPriority(aiProviderId, int)
  /// Priority change confirmed.
  | PrioritySet(result<string, string>)
  /// Enable or disable a provider (mute/unmute).
  | ToggleAiProvider(aiProviderId)
  /// Provider toggle confirmed.
  | ProviderToggled(result<string, string>)
  /// Clear the conversation history.
  | ClearAiHistory
  /// History cleared confirmed.
  | HistoryCleared(result<string, string>)
  /// Build context from a loaded repo.
  | BuildContext(string)
  /// Context built.
  | ContextBuilt(result<string, string>)
  /// Load provider state from disk.
  | LoadProviderState
  /// Provider state loaded.
  | ProviderStateLoaded(result<string, string>)
  /// Update the system prompt override.
  | SetSystemPrompt(string)
  /// Mark a provider as quota-exhausted (429 received).
  | MarkQuotaExhausted(aiProviderId)
  /// TypeLL cross-panel type check result for prompt types.
  | TypeCheckResult(result<string, string>)
  // ---------------------------------------------------------------------------
  // Streaming + tool_use messages (Claude Code integration)
  // ---------------------------------------------------------------------------
  /// A stream chunk arrived from the Gossamer `ai:stream-chunk` event.
  /// Payload is the raw JSON string from the StreamChunk enum.
  | AiStreamChunkReceived(string)
  /// Streaming session started (fire-and-forget acknowledgement).
  | StreamingStarted(result<string, string>)
  /// A tool call has been fully accumulated and needs execution via BoJ.
  /// Dispatched when a ToolUseEnd chunk completes a pending tool call.
  | AiToolCallRequested({id: string, name: string, input: string})
  /// A tool call result arrived from BoJ cartridge execution.
  | AiToolCallResult({toolUseId: string, result: result<string, string>})
  /// All pending tool calls are complete — continue the conversation
  /// by sending a new streaming request with the tool results.
  | AiContinueAfterToolUse

/// Repo Loader messages — repository scanning, panel configuration,
/// directory picking, and recent repo management.
type repoLoaderMsg =
  /// Open directory picker to select a repo.
  | PickRepoDirectory
  /// Directory picked (or cancelled).
  | DirectoryPicked(result<string, string>)
  /// Scan a repo by path.
  | ScanRepo(string)
  /// Scan result received.
  | ScanResult(result<string, string>)
  /// Toggle a panel suggestion's enabled state.
  | ToggleSuggestion(string)
  /// Save panel configuration to PANELS.a2ml.
  | SavePanels
  /// Panels saved.
  | PanelsSaved(result<string, string>)
  /// Load recent repos list.
  | LoadRecent
  /// Recent repos loaded.
  | RecentLoaded(result<string, string>)
  /// Search the git-private-farm.
  | SearchFarm(string)
  /// Farm search results.
  | FarmSearchResult(result<string, string>)
  /// Update the search text.
  | SetRepoSearchText(string)
  /// Switch category tab.
  | SetRepoCategory(repoLoaderCategory)
  /// TypeLL cross-panel type check result for repo config types.
  | TypeCheckResult(result<string, string>)

/// Panel switcher messages — unified panel navigation replacing ad-hoc
/// `visible: bool` toggles on individual overlays. The panel bar dispatches
/// these when the operator clicks an icon.
type panelSwitcherMsg =
  /// Toggle a panel: opens it if closed, closes if already active.
  | TogglePanel(panelId)
  /// Close whatever panel is currently active (Escape key handler).
  | ClosePanels
  /// Expand a group in the sidebar (by kind name, e.g. "ai", "bridge").
  /// Clicking the same group again collapses it.
  | ExpandGroup(string)
  /// Health check result for a panel's backend service.
  | HealthCheckResult(panelId, result<string, string>)

/// Workspace messages — panel groups, arrangements, sessions, modes,
/// protection levels, execution modes, checkpoints (DD-022–DD-027).
type workspaceMsg =
  /// Set the workspace mode (Rhodium, Everything, Code, Bespoke).
  | SetWorkspaceMode(workspaceMode)
  /// Cycle to the next workspace mode.
  | CycleWorkspaceMode
  /// Set session protection level.
  | SetProtection(sessionProtection)
  /// Set execution mode (Live, DryRun, Simulation, Emulation).
  | SetExecutionMode(executionMode)
  /// Toggle between Live and DryRun execution modes.
  | ToggleDryRun
  /// Create a panel group.
  | CreateGroup(string, string, array<string>)
  /// Disband a panel group.
  | DisbandGroup(string)
  /// Lock/unlock a group's arrangement.
  | ToggleGroupLock(string)
  /// Toggle group visibility.
  | ToggleGroupVisibility(string)
  /// Push a group to back.
  | PushToBack(string)
  /// Pull a group to front.
  | PullToFront(string)
  /// Save current layout as a named arrangement.
  | SaveArrangement(string, string)
  /// Load a saved arrangement by ID.
  | LoadArrangement(string)
  /// Delete a saved arrangement.
  | DeleteArrangement(string)
  /// Arrangements loaded from disk.
  | ArrangementsLoaded(result<string, string>)
  /// Create a new session.
  | CreateSession(string, string)
  /// Fork the current session.
  | ForkSession(string, string)
  /// Delete a session.
  | DeleteSession(string)
  /// Switch active session.
  | SwitchSession(string)
  /// Sessions loaded from disk.
  | SessionsLoaded(result<string, string>)
  /// Add a checkpoint to the current session.
  | AddCheckpoint(string, string)
  /// System info loaded (CPU, memory, disk).
  | SystemInfoLoaded(result<string, string>)
  /// Open/close the configurator.
  | ToggleConfigurator
  /// Switch configurator tab.
  | SetConfiguratorTab(configuratorTab)
  /// View repo metadata item.
  | ViewMetadata(repoMetadataItem)
  /// Close metadata viewer.
  | CloseMetadata
  /// Metadata content loaded.
  | MetadataLoaded(result<string, string>)
  /// Reset a single panel to its default state.
  | ResetPanel(string)
  /// Reset all panels to defaults.
  | ResetAllPanels
  /// Export workspace config (mode, protection, execution, arrangement) to ENSAID_CONFIG.a2ml.
  | ExportWorkspaceConfig
  /// TypeLL cross-panel type check result for arrangement types.
  | TypeCheckResult(result<string, string>)

/// Capture messages — screenshots, recordings, demos, cloning (DD-022).
type captureMsg =
  /// Take a screenshot of a panel.
  | CaptureScreenshot(string)
  /// Screenshot saved to disk.
  | ScreenshotSaved(result<string, string>)
  /// Start recording a panel.
  | StartRecording(string)
  /// Stop recording.
  | StopRecording
  /// Pause/resume recording.
  | TogglePauseRecording
  /// Print the active panel.
  | PrintPanel(string)
  /// Print result.
  | PrintResult(result<string, string>)
  /// Toggle capture selection for a panel (multi-panel capture).
  | ToggleCaptureSelection(string)
  /// Clear capture selection.
  | ClearCaptureSelection
  /// Capture all selected panels.
  | CaptureSelected
  /// Capture full environment.
  | CaptureFullEnvironment
  /// Toggle capture bar visibility.
  | ToggleCaptureBar
  /// Clone a panel's state.
  | ClonePanel(string)
  /// Remove a clone.
  | RemoveClone(string)
  /// Enter comparison mode.
  | SetComparison(comparisonMode)
  /// Exit comparison mode.
  | ExitComparison
  /// Start demo playback.
  | StartDemo(string)
  /// Stop demo playback.
  | StopDemo
  /// Next demo step.
  | NextDemoStep
  /// Previous demo step.
  | PrevDemoStep
  /// Save a demo package.
  | SaveDemo
  /// Demo saved to disk.
  | DemoSaved(result<string, string>)
  /// Load demos from disk.
  | LoadDemos
  /// Demos loaded.
  | DemosLoaded(result<string, string>)
  /// Set capture category tab.
  | SetCaptureCategory(captureCategory)
  /// Remove a capture entry.
  | RemoveCapture(string)
  /// TypeLL cross-panel type check result for capture config types.
  | TypeCheckResult(result<string, string>)

/// Security messages — redaction, vault, 2FA, Trustfile (DD-026/027).
type securityMsg =
  /// Toggle a redaction pattern's enabled state.
  | TogglePattern(string)
  /// Add a custom redaction pattern.
  | AddPattern(redactionPattern)
  /// Remove a custom pattern.
  | RemovePattern(string)
  /// Set the redaction mode.
  | SetRedactionMode(redactionMode)
  /// Request text redaction via backend.
  | RedactText(string, string)
  /// Redaction result from backend.
  | RedactionResult(result<string, string>)
  /// Store a secret in the vault.
  | VaultStore(string, string)
  /// Vault store result.
  | VaultStoreResult(result<string, string>)
  /// Retrieve a secret from the vault.
  | VaultRetrieve(string)
  /// Vault retrieve result.
  | VaultRetrieveResult(result<string, string>)
  /// List vault keys.
  | VaultList
  /// Vault list result.
  | VaultListResult(result<string, string>)
  /// Submit TOTP code for 2FA.
  | SubmitTotp(string)
  /// 2FA verification result.
  | TotpResult(result<string, string>)
  /// Update TOTP input field.
  | SetTotpInput(string)
  /// Load Trustfile from repo.
  | LoadTrustfile(string)
  /// Trustfile loaded.
  | TrustfileLoaded(result<string, string>)
  /// Toggle shoulder-safe mode.
  | ToggleShoulderSafe
  /// Set security category tab.
  | SetSecurityCategory(securityCategory)
  /// Update new pattern form: label field.
  | SetNewPatternLabel(string)
  /// Update new pattern form: regex field.
  | SetNewPatternRegex(string)
  /// Submit the new pattern form.
  | SubmitNewPattern
  /// TypeLL cross-panel type check result for trustfile types.
  | TypeCheckResult(result<string, string>)

/// Migration Observatory messages — migration health, sessions, submissions, merges.
type migrationMsg =
  /// Load migration data from panic-attack / feedback-o-tron.
  | LoadMigrationData
  /// Migration data loaded successfully.
  | MigrationDataLoaded(result<string, string>)
  /// Set migration category tab.
  | SetMigrationCategory(migrationCategory)
  /// Set report type selection.
  | SetMigrationReportType(migrationReportType)
  /// Filter repos by text.
  | SetMigrationFilter(string)
  /// Begin a new migration observation session.
  | BeginObservation(string, string)
  /// Observation session started.
  | ObservationStarted(result<string, string>)
  /// End current observation session.
  | EndObservation(string)
  /// Observation session ended.
  | ObservationEnded(result<string, string>)
  /// Approve a submission in the review queue.
  | ApproveSubmission(string)
  /// Reject a submission in the review queue.
  | RejectSubmission(string)
  /// Submit all approved submissions.
  | SubmitApproved
  /// Submissions sent.
  | SubmissionsResult(result<string, string>)
  /// Begin merge resolution.
  | BeginMergeResolution(string, string)
  /// Merge resolution started.
  | MergeResolutionStarted(result<string, string>)
  /// Rollback a merge session.
  | RollbackMerge(string)
  /// Accept a merge session.
  | AcceptMerge(string)
  /// Refresh migration health data.
  | RefreshMigrationHealth
  /// TypeLL cross-panel type check result for migration types.
  | TypeCheckResult(result<string, string>)

/// panic-attack panel messages — scanning, report management, filtering,
/// comparison, and capability probing for the stress testing panel.
type panicAttackMsg =
  /// Probe whether panic-attack binary is available.
  | CheckCapability
  /// Capability probe result.
  | CapabilityLoaded(result<string, string>)
  /// Set the target path for scanning.
  | SetTargetPath(string)
  /// Run a static analysis scan (assail).
  | RunAssail
  /// Assail scan result.
  | AssailResult(result<string, string>)
  /// Run a full assault (static + stress).
  | RunAssault
  /// Assault result.
  | AssaultResult(result<string, string>)
  /// Load saved reports list.
  | LoadReports
  /// Reports list loaded.
  | ReportsLoaded(result<string, string>)
  /// View a specific report.
  | ViewReport(string)
  /// Report loaded.
  | ReportLoaded(result<string, string>)
  /// Compare two reports.
  | CompareReports(string, string)
  /// Comparison result.
  | ComparisonLoaded(result<string, string>)
  /// Export report as SARIF.
  | ExportSarif(string)
  /// SARIF export result.
  | SarifExported(result<string, string>)
  /// Export report as PanLL event chain.
  | ExportEventChain(string)
  /// Event chain export result.
  | EventChainExported(result<string, string>)
  /// Set the active category filter.
  | SetPanicCategory(PanicAttackModel.panicCategory)
  /// Set the text filter.
  | SetPanicFilter(string)
  /// Toggle report diff view.
  | ToggleDiffView
  /// Dismiss error.
  | DismissError
  /// TypeLL cross-panel type check result for attack vector types.
  | TypeCheckResult(result<string, string>)

/// Mass-panic panel messages — assemblyline batch scanning, repo discovery,
/// incremental BLAKE3, verisimdb persistence, delta reporting, notifications.
type massPanicMsg =
  /// Set the repos directory path.
  | SetReposDirectory(string)
  /// Discover repos in the directory.
  | DiscoverRepos
  /// Repos discovered.
  | ReposDiscovered(result<string, string>)
  /// Run assemblyline on all repos.
  | RunAssemblyline
  /// Run assemblyline on selected repos only.
  | RunSelected
  /// Assemblyline scan result.
  | AssemblylineResult(result<string, string>)
  /// Poll scan progress.
  | PollProgress
  /// Progress update received.
  | ProgressUpdate(result<string, string>)
  /// Toggle incremental scanning (BLAKE3).
  | ToggleIncremental
  /// Toggle notification generation.
  | ToggleNotify
  /// Set filter mode.
  | SetFilterMode(MassPanicModel.repoFilterMode)
  /// Set sort mode.
  | SetSortMode(MassPanicModel.repoSortMode)
  /// Set search text.
  | SetSearchText(string)
  /// Toggle repo selection by index.
  | ToggleRepoSelection(int)
  /// Toggle select all.
  | ToggleSelectAll
  /// Toggle delta comparison view.
  | ToggleDelta
  /// Load delta comparison between latest two runs.
  | LoadDelta
  /// Delta loaded.
  | DeltaLoaded(result<string, string>)
  /// Generate notification summary.
  | GenerateNotification
  /// Notification generated.
  | NotificationGenerated(result<string, string>)
  /// Dismiss error.
  | DismissMassPanicError
  // -- Sub-view navigation --
  /// Switch active sub-view (scan / imaging / temporal).
  | SwitchView(MassPanicModel.massPanicView)
  // -- Imaging (fNIRS-style spatial health map) --
  /// Build system image from latest assemblyline results.
  | BuildImage
  /// System image built/loaded.
  | ImageLoaded(result<string, string>)
  /// Import a panll.system-image.v0 JSON file.
  | ImportImageFile
  /// Image file loaded.
  | ImageFileLoaded(result<string, string>)
  // -- Temporal navigation --
  /// List temporal snapshots.
  | ListSnapshots
  /// Snapshots listed.
  | SnapshotsLoaded(result<string, string>)
  /// Select a snapshot for comparison (slot 0 or 1).
  | SelectSnapshot(int, int)
  /// Diff selected snapshots.
  | DiffSnapshots
  /// Diff computed.
  | DiffLoaded(result<string, string>)
  /// Take a snapshot of the current image.
  | TakeSnapshot(string)
  /// Snapshot taken.
  | SnapshotTaken(result<string, string>)
  /// TypeLL cross-panel type check result for batch config types.
  | TypeCheckResult(result<string, string>)

/// TSDM directive panel messages — axis reordering, tier customisation,
/// cleanup configuration, work item aggregation, and directive persistence.
type tsdmMsg =
  /// Move an axis up in execution order.
  | MoveAxisUp(int)
  /// Move an axis down in execution order.
  | MoveAxisDown(int)
  /// Move a scope tier up in priority.
  | MoveScopeTierUp(int)
  /// Move a scope tier down in priority.
  | MoveScopeTierDown(int)
  /// Move a maintenance tier up in priority.
  | MoveMaintenanceTierUp(int)
  /// Move a maintenance tier down in priority.
  | MoveMaintenanceTierDown(int)
  /// Move an audit tier up in priority.
  | MoveAuditTierUp(int)
  /// Move an audit tier down in priority.
  | MoveAuditTierDown(int)
  /// Toggle a cleanup step on/off.
  | ToggleCleanupStep(TsdmModel.cleanupStep)
  /// Set axis filter for work items view.
  | SetAxisFilter(option<TsdmModel.axisId>)
  /// Set search text.
  | SetTsdmSearch(string)
  /// Toggle show completed items.
  | ToggleShowCompleted
  /// Lock/unlock the directive.
  | ToggleLock
  /// Reset all orderings to defaults.
  | ResetToDefaults
  /// Save directive to persistent storage.
  | SaveDirective
  /// Directive saved result.
  | DirectiveSaved(result<string, string>)
  /// Load directive from persistent storage.
  | LoadDirective
  /// Directive loaded result.
  | DirectiveLoaded(result<string, string>)
  /// Collect work items from consumer panels.
  | CollectWorkItems
  /// Work items collected result.
  | WorkItemsCollected(result<string, string>)
  /// Dismiss error.
  | DismissTsdmError
  /// TypeLL cross-panel type check result for directive types.
  | TypeCheckResult(result<string, string>)

/// Valence Shell messages — terminal PTY lifecycle, input handling,
/// session recording, checkpoint management, approval gate, and Claude
/// Code integration for the embedded terminal panel.
type valenceShellMsg =
  /// Switch the active category tab.
  | SetShellCategory(valenceShellCategory)
  /// Update the text input line.
  | UpdateInput(string)
  /// Submit the current input line (Enter key).
  | SubmitInput
  /// Select a completion from the popup.
  | SelectCompletion(string)
  /// Toggle the completions popup visibility.
  | ToggleCompletions
  /// PTY spawned (or failed).
  | PtySpawned(result<string, string>)
  /// Terminal output received from the PTY.
  | PtyOutput(string, bool)
  /// PTY exited.
  | PtyExited
  /// Check if Valence shell binary is available.
  | CheckValenceAvailability
  /// Valence availability result.
  | ValenceAvailabilityResult(result<string, string>)
  /// Launch Claude Code in the terminal.
  | LaunchClaudeCode
  /// Start recording a terminal session.
  | StartRecordingSession
  /// Stop the current recording.
  | StopRecordingSession
  /// Recording started (or failed).
  | RecordingStarted(result<string, string>)
  /// Recording stopped and saved (or failed).
  | RecordingStopped(result<string, string>)
  /// Load the list of saved recordings.
  | LoadRecordings
  /// Recordings loaded (or failed).
  | RecordingsLoaded(result<string, string>)
  /// Delete a recording by ID.
  | DeleteRecordingById(string)
  /// Recording deleted (or failed).
  | RecordingDeleted(result<string, string>)
  /// Export a recording in the given format (html, json, cast).
  | ExportRecordingAs(string, string)
  /// Recording exported (or failed).
  | RecordingExported(result<string, string>)
  /// Create a Valence filesystem checkpoint with the given label.
  | CreateCheckpointWithLabel(string)
  /// Checkpoint created (or failed).
  | CheckpointCreated(result<string, string>)
  /// Restore a checkpoint by ID.
  | RestoreCheckpointById(string)
  /// Checkpoint restored (or failed).
  | CheckpointRestored(result<string, string>)
  /// Load the list of checkpoints.
  | LoadCheckpoints
  /// Checkpoints loaded (or failed).
  | CheckpointsLoaded(result<string, string>)
  /// Take a screenshot of the terminal state.
  | ScreenshotTerminal
  /// Screenshot captured (or failed).
  | ScreenshotCaptured(result<string, string>)
  /// Set the approval gate mode.
  | SetApprovalGate(approvalGateMode)
  /// Approve a pending command by index.
  | ApproveCommand(int)
  /// Reject a pending command by index.
  | RejectCommand(int)
  /// Toggle split view mode.
  | ToggleSplitView
  /// Dismiss the error banner.
  | DismissError
  /// TypeLL cross-panel type check result for command types.
  | TypeCheckResult(result<string, string>)

/// Game Preview messages — dev server lifecycle, game loop control,
/// overlay management, gameplay recording, and render stats for the
/// live IDApTIK game preview panel.
type gamePreviewMsg =
  /// Switch the active category tab.
  | SetPreviewCategory(gamePreviewCategory)
  /// Check if the Vite dev server is running.
  | CheckDevServer
  /// Dev server check result.
  | DevServerResult(result<string, string>)
  /// Pause the game loop.
  | PauseGame
  /// Resume the game loop.
  | ResumeGame
  /// Step one frame forward (when paused).
  | StepFrame
  /// Game control result.
  | GameControlResult(result<string, string>)
  /// Toggle a game overlay on/off.
  | ToggleOverlay(gameOverlay)
  /// Start recording gameplay to WebM.
  | StartGameRecording
  /// Stop gameplay recording.
  | StopGameRecording
  /// Gameplay recording started (or failed).
  | GameRecordingStarted(result<string, string>)
  /// Gameplay recording stopped (or failed).
  | GameRecordingStopped(result<string, string>)
  /// Take a screenshot of the current game frame.
  | ScreenshotGame
  /// Game screenshot captured (or failed).
  | GameScreenshotCaptured(result<string, string>)
  /// Set the zoom level.
  | SetZoom(float)
  /// Toggle multiplayer/co-op view.
  | ToggleMultiplayerView
  /// Load saved gameplay clips.
  | LoadClips
  /// Clips loaded (or failed).
  | ClipsLoaded(result<string, string>)
  /// Delete a gameplay clip by ID.
  | DeleteClip(string)
  /// Clip deleted (or failed).
  | ClipDeleted(result<string, string>)
  /// Refresh render statistics.
  | RefreshStats
  /// Render stats received.
  | StatsReceived(result<string, string>)
  /// Clear the device interaction log.
  | ClearDeviceLog
  /// A device interaction event arrived from the game.
  | DeviceInteractionEvent(deviceInteraction)
  /// Dismiss the error banner.
  | DismissGameError
  /// TypeLL cross-panel type check result for game config types.
  | TypeCheckResult(result<string, string>)

/// VM Inspector messages — VM state reading, step execution, breakpoint
/// management, timeline navigation, and state export for the reversible
/// VM visual debugger panel.
type vmInspectorMsg =
  /// Switch the active category tab.
  | SetInspectorCategory(vmInspectorCategory)
  /// Read the current VM state from the running game.
  | ReadVmState
  /// VM state received.
  | VmStateReceived(result<string, string>)
  /// Step the VM forward by one instruction.
  | StepForward
  /// Step the VM backward by one instruction (reverse execution).
  | StepBackward
  /// Step result received.
  | StepResult(result<string, string>)
  /// Run the VM until the next breakpoint or end.
  | RunVm
  /// Pause the running VM.
  | PauseVm
  /// Run/pause result.
  | RunResult(result<string, string>)
  /// Reset the VM to initial state.
  | ResetVm
  /// Toggle a breakpoint at the given instruction index.
  | ToggleBreakpoint(int)
  /// Seek to a position in the execution timeline.
  | SeekTimeline(int)
  /// Export the current VM state as JSON.
  | ExportSnapshot
  /// Snapshot exported (or failed).
  | SnapshotExported(result<string, string>)
  /// Toggle multi-VM view (for multiplayer debugging).
  | ToggleMultiVm
  /// Dismiss the error banner.
  | DismissVmError
  /// Toggle BoJ routing for DAP operations (dap-mcp cartridge).
  | ToggleVmBojRouting
  /// TypeLL cross-panel type check result for VM state types.
  | TypeCheckResult(result<string, string>)

/// Network Topology messages — topology reading, device selection,
/// packet flow animation, DNS browsing, and display toggles for the
/// IDApTIK in-game network topology viewer.
type networkTopologyMsg =
  /// Switch the active category tab.
  | SetTopologyCategory(networkTopologyCategory)
  /// Read the network topology from the running game.
  | RefreshTopology
  /// Topology data received.
  | TopologyReceived(result<string, string>)
  /// Select a device by ID.
  | SelectDevice(string)
  /// Deselect the current device.
  | DeselectDevice
  /// Read DNS resolution table.
  | RefreshDns
  /// DNS data received.
  | DnsReceived(result<string, string>)
  /// Toggle packet flow animation.
  | TogglePacketAnimation
  /// Packet flow data received.
  | PacketFlowReceived(result<string, string>)
  /// Toggle device name labels.
  | ToggleLabels
  /// Toggle security level indicators.
  | ToggleSecurityLevels
  /// Export topology as SVG.
  | ExportTopologySvg
  /// SVG exported (or failed).
  | TopologySvgExported(result<string, string>)
  /// Dismiss the error banner.
  | DismissTopoError
  /// TypeLL cross-panel type check result for topology types.
  | TypeCheckResult(result<string, string>)

/// Level Architect messages — grid editing, entity placement, patrol
/// editing, defence flag toggling, asset browsing, validation, undo/redo,
/// and level file I/O for the IDApTIK visual level design tool.
type levelArchitectMsg =
  /// Switch the active category tab.
  | SetArchitectCategory(levelArchitectCategory)
  /// Click a grid cell (place/select/erase based on tool).
  | ClickGrid(int, int)
  /// Select an entity by ID.
  | SelectEntity(string)
  /// Deselect the current entity.
  | DeselectEntity
  /// Select an editor tool.
  | SelectTool(editorTool)
  /// Toggle a defence flag on/off.
  | ToggleDefenceFlag(defenceFlag)
  /// Set the alert threshold.
  | SetAlertThreshold(int)
  /// Browse game assets.
  | BrowseAssets
  /// Assets loaded.
  | AssetsLoaded(result<string, string>)
  /// Validate the current level.
  | ValidateLevel
  /// Validation result.
  | ValidationResult(result<string, string>)
  /// Load a level from file.
  | LoadLevel(string)
  /// Level loaded.
  | LevelLoaded(result<string, string>)
  /// Save the current level.
  | SaveLevel(string)
  /// Level saved.
  | LevelSaved(result<string, string>)
  /// Export as LevelConfig.res.
  | ExportLevelConfig
  /// LevelConfig exported.
  | LevelConfigExported(result<string, string>)
  /// Undo the last action.
  | UndoAction
  /// Redo the last undone action.
  | RedoAction
  /// Toggle grid line visibility.
  | ToggleGrid
  /// Toggle patrol path visibility.
  | TogglePatrolPaths
  /// Dismiss the error banner.
  | DismissArchitectError
  /// TypeLL cross-panel type check result for level data types.
  | TypeCheckResult(result<string, string>)
  /// Toggle BoJ routing for UMS validation.
  | ToggleLaBojRouting
  /// UMS ABI validation result from BoJ cartridge.
  | UmsValidationResult(result<string, string>)

/// Coprocessors messages — metrics refresh, call log, heatmap,
/// backend toggling, and filter controls for the IDApTIK coprocessor
/// monitoring dashboard.
type coprocessorsMsg =
  /// Switch the active category tab.
  | SetCoprocCategory(coprocessorsCategory)
  /// Refresh all metrics.
  | RefreshMetrics
  /// Metrics received.
  | MetricsReceived(result<string, string>)
  /// Refresh the call log.
  | RefreshCallLog
  /// Call log received.
  | CallLogReceived(result<string, string>)
  /// Refresh the heatmap.
  | RefreshHeatmap
  /// Heatmap received.
  | HeatmapReceived(result<string, string>)
  /// Toggle a coprocessor backend on/off.
  | ToggleCoprocBackend(coprocessorBackend)
  /// Backend toggle result.
  | BackendToggled(result<string, string>)
  /// Select a backend filter for the call log.
  | SelectBackendFilter(option<coprocessorBackend>)
  /// Toggle auto-refresh.
  | ToggleAutoRefresh
  /// Dismiss the error banner.
  | DismissCoprocError
  /// Query an external compute engine (Axiom.jl, BoJ cartridge).
  | QueryComputeEngine(string, string)
  /// Compute engine query result.
  | ComputeEngineResult(result<string, string>)
  /// Discover available compute devices.
  | DiscoverDevices
  /// Device discovery result.
  | DevicesDiscovered(result<string, string>)
  /// Toggle BoJ routing for compute operations (agent-mcp cartridge).
  | ToggleCoprocBojRouting
  /// Phase 2: Load the Zig FFI shared library for local GPU/CPU dispatch.
  | LoadLocalFfi
  /// Phase 2: FFI load result.
  | LocalFfiLoaded(result<string, string>)
  /// Phase 2: Dispatch a compute operation to local GPU/CPU via Zig FFI.
  | DispatchLocal(string, string)
  /// Phase 2: Local dispatch result.
  | LocalDispatchResult(result<string, string>)
  /// Phase 2: Query local system resources (CPU, GPU memory).
  | QueryLocalResources
  /// Phase 2: Local resources result.
  | LocalResourcesResult(result<string, string>)
  /// Phase 3: Set the routing strategy.
  | SetRoutingStrategy(routingStrategy)
  /// Phase 3: Smart route a compute operation (auto-selects local vs remote).
  | SmartDispatch(string, string)
  /// Phase 3: Smart routing result.
  | SmartDispatchResult(result<string, string>)
  /// TypeLL cross-panel type check result for compute types.
  | TypeCheckResult(result<string, string>)

/// Multiplayer Monitor messages — WebSocket lifecycle, player state,
/// channel subscriptions, state diffs, device locks, latency, and
/// reconnection testing for the IDApTIK Phoenix sync server.
type multiplayerMonitorMsg =
  /// Switch the active category tab.
  | SetMultiplayerCategory(multiplayerCategory)
  /// Connect to the Phoenix sync server.
  | ConnectServer
  /// Disconnect from the sync server.
  | DisconnectServer
  /// Connection result.
  | ConnectionResult(result<string, string>)
  /// Disconnection result.
  | DisconnectionResult(result<string, string>)
  /// Refresh the full multiplayer state.
  | RefreshState
  /// Multiplayer state received.
  | StateReceived(result<string, string>)
  /// Refresh state diffs.
  | RefreshDiffs
  /// State diffs received.
  | DiffsReceived(result<string, string>)
  /// Select a player by ID.
  | SelectPlayer(string)
  /// Deselect the current player.
  | DeselectPlayer
  /// Toggle spectator visibility.
  | ToggleSpectators
  /// Toggle auto-reconnect.
  | ToggleAutoReconnect
  /// Run a reconnection test.
  | ReconnectionTest
  /// Reconnection test result.
  | ReconnectionTestResult(result<string, string>)
  /// Dismiss the error banner.
  | DismissMultiplayerError
  /// TypeLL cross-panel type check result for Phoenix types.
  | TypeCheckResult(result<string, string>)

/// Universal Modding Studio messages — project CRUD, ABI validation,
/// template management, asset pipeline, mod distribution, and API reference
/// for the unified IDApTIK game content creation hub.
type umsMsg =
  /// Switch the active category tab.
  | SetUmsCategory(umsCategory)
  /// Load mod projects from disk.
  | LoadProjects
  /// Projects loaded result.
  | ProjectsLoaded(result<string, string>)
  /// Create a new mod project.
  | CreateProject(string)
  /// Project created result.
  | ProjectCreated(result<string, string>)
  /// Select a project by ID.
  | SelectProject(string)
  /// Deselect the current project.
  | DeselectProject
  /// Open an existing project.
  | OpenProject(string)
  /// Project opened result.
  | ProjectOpened(result<string, string>)
  /// Delete a project.
  | DeleteProject(string)
  /// Project deleted result.
  | ProjectDeleted(result<string, string>)
  /// Run ABI validation on all levels.
  | ValidateAll
  /// Run ABI validation on a level.
  | ValidateLevel(string)
  /// Validation result.
  | ValidationResult(result<string, string>)
  /// Load available templates.
  | LoadTemplates
  /// Templates loaded result.
  | TemplatesLoaded(result<string, string>)
  /// Instantiate a template to create a new project.
  | InstantiateTemplate(string)
  /// Template instantiated result.
  | TemplateInstantiated(result<string, string>)
  /// Load project assets.
  | LoadAssets
  /// Assets loaded result.
  | AssetsLoaded(result<string, string>)
  /// Import an asset file.
  | ImportAsset(string)
  /// Asset imported result.
  | AssetImported(result<string, string>)
  /// Publish mod to a distribution target.
  | PublishMod
  /// Publish result.
  | PublishResult(result<string, string>)
  /// Load modding API reference.
  | LoadApiReference
  /// API reference loaded result.
  | ApiReferenceLoaded(result<string, string>)
  /// Set filter text.
  | SetUmsFilter(string)
  /// Dismiss the error banner.
  | DismissUmsError
  /// Toggle BoJ routing for UMS commands.
  | ToggleUmsBojRouting
  /// TypeLL cross-panel type check result for ABI validation.
  | AbiTypeCheckResult(result<string, string>)
  /// Navigate to a related panel (Level Architect, DLC Workshop, etc.).
  | NavigateToPanel(panelId)

/// DLC Workshop messages — puzzle CRUD, composer, testing, asset browsing,
/// packaging, import/export for the IDApTIK DLC puzzle pack panel.
type dlcWorkshopMsg =
  /// Switch the active category tab.
  | SetWorkshopCategory(dlcWorkshopCategory)
  /// Load puzzles from the DLC directory.
  | LoadPuzzles
  /// Puzzles loaded.
  | PuzzlesLoaded(result<string, string>)
  /// Select a puzzle by ID.
  | SelectPuzzle(string)
  /// Deselect the current puzzle.
  | DeselectPuzzle
  /// Add an instruction to the composer.
  | AddInstruction
  /// Remove an instruction by index.
  | RemoveInstruction(int)
  /// Clear the composer.
  | ClearComposer
  /// Save the current puzzle.
  | SavePuzzle
  /// Puzzle saved.
  | PuzzleSaved(result<string, string>)
  /// Run tests for a specific puzzle.
  | RunPuzzleTest(string)
  /// Test result for a puzzle.
  | PuzzleTestResult(result<string, string>)
  /// Run all tests.
  | RunAllTests
  /// All tests result.
  | AllTestsResult(result<string, string>)
  /// Browse DLC assets.
  | BrowseDlcAssets
  /// Assets loaded.
  | DlcAssetsLoaded(result<string, string>)
  /// Package the DLC for distribution.
  | PackageDlc
  /// Package result.
  | PackageResult(result<string, string>)
  /// Import a puzzle from file.
  | ImportPuzzle
  /// Puzzle imported.
  | PuzzleImported(result<string, string>)
  /// Export the selected puzzle.
  | ExportPuzzle
  /// Puzzle exported.
  | PuzzleExported(result<string, string>)
  /// Set filter text.
  | SetDlcFilter(string)
  /// Set difficulty filter.
  | SetDifficultyFilter(option<puzzleDifficulty>)
  /// Dismiss the error banner.
  | DismissWorkshopError
  /// TypeLL cross-panel type check result for puzzle spec types.
  | TypeCheckResult(result<string, string>)

/// Editor Bridge messages — editor detection, LSP lifecycle, diagnostics,
/// symbols, open files, jump-to-line, and settings for the external code
/// editor federation panel.
type editorBridgeMsg =
  /// Switch the active category tab.
  | SetBridgeCategory(editorBridgeCategory)
  /// Detect which editor is running.
  | DetectEditor
  /// Editor detection result.
  | EditorDetected(result<string, string>)
  /// Connect to the editor's LSP server.
  | ConnectLsp
  /// LSP connection result.
  | LspConnected(result<string, string>)
  /// Refresh diagnostics from LSP.
  | RefreshDiagnostics
  /// Diagnostics received.
  | DiagnosticsReceived(result<string, string>)
  /// Refresh open files list.
  | RefreshOpenFiles
  /// Open files received.
  | OpenFilesReceived(result<string, string>)
  /// Refresh workspace symbols.
  | RefreshSymbols
  /// Symbols received.
  | SymbolsReceived(result<string, string>)
  /// Open a file at a specific line in the external editor.
  | OpenFileInEditor(string, int)
  /// File opened (or failed).
  | FileOpened(result<string, string>)
  /// Refresh the bridge status.
  | RefreshBridge
  /// Set the diagnostic filter text.
  | SetDiagnosticFilter(string)
  /// Toggle BoJ routing — route LSP through lsp-mcp cartridge.
  | ToggleBojRouting
  /// Toggle error visibility.
  | ToggleShowErrors
  /// Toggle warning visibility.
  | ToggleShowWarnings
  /// Toggle info visibility.
  | ToggleShowInfo
  /// Set the symbol search filter.
  | SetSymbolFilter(string)
  /// Set the preferred editor kind.
  | SetEditorKind(editorKind)
  /// Toggle auto-sync with the editor.
  | ToggleAutoSync
  /// Dismiss the error banner.
  | DismissBridgeError
  /// TypeLL cross-panel type check result for LSP diagnostics types.
  | TypeCheckResult(result<string, string>)

/// Build Dashboard messages — build triggering, status reading, test
/// running, error display, and history for the IDApTIK build monitoring panel.
type buildDashboardMsg =
  /// Switch the active category tab.
  | SetBuildCategory(buildDashboardCategory)
  /// Trigger a build for a specific target.
  | TriggerBuild(buildTarget)
  /// Build triggered (or failed).
  | BuildTriggered(result<string, string>)
  /// Refresh build status for all targets.
  | RefreshBuildStatus
  /// Build status received.
  | BuildStatusReceived(result<string, string>)
  /// Run tests for a specific target.
  | RunTests(buildTarget)
  /// Test results received.
  | TestsReceived(result<string, string>)
  /// Cancel a running build.
  | CancelBuild(buildTarget)
  /// Build cancelled (or failed).
  | BuildCancelled(result<string, string>)
  /// Refresh build history.
  | RefreshHistory
  /// History received.
  | HistoryReceived(result<string, string>)
  /// Toggle watch mode.
  | ToggleWatchMode
  /// Toggle auto-rebuild.
  | ToggleAutoRebuild
  /// Toggle show passed tests.
  | ToggleShowPassed
  /// Dismiss the error banner.
  | DismissBuildError
  /// Toggle BoJ routing for BSP operations (bsp-mcp cartridge).
  | ToggleBuildBojRouting
  /// TypeLL cross-panel type check result for build config types.
  | TypeCheckResult(result<string, string>)

/// Release Manager messages — version bumping, changelog generation,
/// artifact building, signing, publishing, and channel management for
/// the IDApTIK release distribution panel.
type releaseManagerMsg =
  /// Switch the active category tab.
  | SetReleaseCategory(releaseManagerCategory)
  /// Bump the version (patch, minor, major).
  | BumpVersion(string)
  /// Version bumped (or failed).
  | VersionBumped(result<string, string>)
  /// Select a release to view details.
  | SelectRelease(string)
  /// Generate changelog from git history.
  | GenerateChangelog
  /// Changelog generated (or failed).
  | ChangelogGenerated(result<string, string>)
  /// Toggle auto-changelog generation.
  | ToggleAutoChangelog
  /// Toggle a platform target for artifact building.
  | TogglePlatform(platformTarget)
  /// Build artifacts for enabled platforms.
  | BuildArtifacts
  /// Artifacts built (or failed).
  | ArtifactsBuilt(result<string, string>)
  /// Publish a release.
  | PublishRelease
  /// Release published (or failed).
  | ReleasePublished(result<string, string>)
  /// Set the release channel.
  | SetChannel(releaseChannel)
  /// Toggle artifact signing.
  | ToggleSignArtifacts
  /// Load release history.
  | LoadReleases
  /// Releases loaded (or failed).
  | ReleasesLoaded(result<string, string>)
  /// Dismiss the error banner.
  | DismissReleaseError
  /// TypeLL cross-panel type check result for release types.
  | TypeCheckResult(result<string, string>)

/// Automation Router messages — rule management, execution, approval gates,
/// history, and configuration for the hybrid cross-panel workflow orchestrator.
type automationRouterMsg =
  /// Switch the active category tab.
  | SetRouterCategory(automationRouterCategory)
  /// Toggle global automation on/off.
  | ToggleGlobalEnabled
  /// Toggle a specific rule on/off.
  | ToggleRule(string)
  /// Execute a rule manually.
  | ExecuteRule(string)
  /// Rule execution result.
  | ExecutionResult(string, result<string, string>)
  /// Approve a pending action by index.
  | ApproveAction(int)
  /// Reject a pending action by index.
  | RejectAction(int)
  /// Approve all pending actions.
  | ApproveAll
  /// Reject all pending actions.
  | RejectAll
  /// Load rules from storage or repo.
  | LoadRules
  /// Rules loaded.
  | RulesLoaded(result<string, string>)
  /// Save rules to local storage.
  | SaveRules
  /// Rules saved.
  | RulesSaved(result<string, string>)
  /// Load rules from repo's .machine_readable/ENSAID_CONFIG.a2ml.
  | LoadFromRepo
  /// Repo rules loaded.
  | RepoRulesLoaded(result<string, string>)
  /// Set filter text.
  | SetRouterFilter(string)
  /// Toggle show disabled rules.
  | ToggleShowDisabled
  /// Dismiss the error banner.
  | DismissRouterError
  /// Export automation rules to ENSAID_CONFIG.a2ml.
  | ExportAutomationConfig
  /// Toggle BoJ routing for automation operations (agent-mcp cartridge).
  | ToggleAutomationBojRouting
  /// TypeLL cross-panel type check result for rule types.
  | TypeCheckResult(result<string, string>)

/// BoJ messages — Bundle of Joy cartridge server interaction.
type bojMsg =
  /// Switch the active category tab.
  | SetBojCategory(bojCategory)
  /// Refresh BoJ server health check.
  | RefreshHealth
  /// Health check result.
  | HealthResult(result<string, string>)
  /// Refresh cartridge list.
  | RefreshCartridges
  /// Cartridge list result.
  | CartridgesResult(result<string, string>)
  /// Select a cartridge for detail view.
  | SelectCartridge(string)
  /// Load a cartridge into the runtime.
  | LoadCartridge(string)
  /// Unload a cartridge from the runtime.
  | UnloadCartridge(string)
  /// Load/unload result.
  | CartridgeActionResult(string, result<string, string>)
  /// Refresh topology data.
  | RefreshTopology
  /// Topology result.
  | TopologyResult(result<string, string>)
  /// Refresh Umoja federation status.
  | RefreshUmoja
  /// Umoja status result.
  | UmojaResult(result<string, string>)
  /// Disconnect a peer from the Umoja federation.
  | UmojaDisconnectPeer(string)
  /// Sync catalogue with a specific peer.
  | UmojaSyncCatalogue(string)
  /// View metrics for a specific peer.
  | UmojaPeerMetrics(string)
  /// Update the add-peer input field.
  | UmojaAddPeerInput(string)
  /// Add a new peer to the Umoja federation.
  | UmojaAddPeer(string)
  /// Trigger a manual gossip round.
  | UmojaTriggerGossip
  /// Result of adding a peer.
  | UmojaAddPeerResult(result<string, string>)
  /// Result of disconnecting a peer.
  | UmojaDisconnectPeerResult(result<string, string>)
  /// Result of triggering gossip round.
  | UmojaTriggerGossipResult(result<string, string>)
  /// Result of catalogue sync.
  | UmojaSyncCatalogueResult(result<string, string>)
  /// Result of peer metrics query.
  | UmojaPeerMetricsResult(result<string, string>)
  /// Set the cartridge for invocation.
  | SetInvokeCartridge(string)
  /// Set the tool name for invocation.
  | SetInvokeTool(string)
  /// Set the args JSON for invocation.
  | SetInvokeArgs(string)
  /// Execute the invocation.
  | ExecuteInvoke
  /// Invocation result.
  | InvokeResult(result<string, string>)
  /// Set filter text.
  | SetBojFilter(string)
  /// Dismiss the error banner.
  | DismissBojError
  /// TypeLL ABI type-check result for cartridge invocation.
  | AbiTypeCheckResult(result<string, string>)

/// Databases panel messages — unified VeriSimDB/QuandleDB/LithoGlyph management.
type databasesMsg =
  /// Switch the active category tab.
  | SetCategory(databasesCategory)
  /// Select a database module by ID.
  | SelectModule(string)
  /// Connect to all database backends.
  | ConnectAll
  /// Refresh health/connection status for all modules.
  | RefreshHealth
  /// Health check result for a module.
  | HealthResult(string, result<string, string>)
  /// Set the query input text.
  | SetQueryInput(string)
  /// Execute the current query against the selected module.
  | ExecuteQuery
  /// Query execution result.
  | QueryResult(result<string, string>)
  /// Clear the query input and result.
  | ClearQuery
  /// Load an example query into the editor.
  | LoadExampleQuery(string)
  /// Set the schema filter text.
  | SetFilter(string)
  /// Select a schema entity for detail view.
  | SelectEntity(string)
  /// Load entity detail JSON.
  | LoadEntityDetail(string)
  /// Entity detail result.
  | EntityDetailResult(result<string, string>)
  /// Refresh drift scores for the selected module.
  | RefreshDrift
  /// Drift scores result.
  | DriftResult(result<string, string>)
  /// Normalise all drifted modalities.
  | NormaliseAll
  /// Normalisation result.
  | NormaliseResult(result<string, string>)
  /// Load telemetry snapshot.
  | LoadTelemetry
  /// Telemetry snapshot result.
  | TelemetryResult(result<string, string>)
  /// Toggle BoJ cartridge routing.
  | ToggleBojRouting
  /// Dismiss error banner.
  | DismissError

/// Script Gist messages — portable computation gist lifecycle.
/// Covers gist CRUD, execution, template expansion, MCP tool registration,
/// and diachronic/synchronic state document management (Minskian cardfiles).
type scriptGistMsg =
  /// Switch the active category tab.
  | SetGistCategory(gistCategory)
  /// Select a gist for editing/viewing.
  | SelectGist(option<string>)
  /// Create a new empty gist.
  | CreateGist
  /// Create a gist from a template.
  | CreateFromTemplate(string) // template id
  /// Update the code of the currently selected gist.
  | UpdateGistCode(string)
  /// Update the title of the currently selected gist.
  | UpdateGistTitle(string)
  /// Update the language of the currently selected gist.
  | UpdateGistLanguage(gistLanguage)
  /// Update the target of the currently selected gist.
  | UpdateGistTarget(gistTarget)
  /// Update the visibility of the currently selected gist.
  | UpdateGistVisibility(gistVisibility)
  /// Toggle pinned status of a gist.
  | ToggleGistPin(string)
  /// Delete a gist by id.
  | DeleteGist(string)
  /// Save the current gist (persist to storage).
  | SaveGist
  /// Execute the currently selected gist.
  | ExecuteGist
  /// Execution result returned.
  | GistExecutionResult(result<gistResult, string>)
  /// Set filter/search text.
  | SetGistFilter(string)
  /// Set sort order.
  | SetGistSort(gistSortBy)
  /// Toggle the gist editor panel open/closed.
  | ToggleGistEditor
  /// Toggle MCP tool registration (advertise gists as tools).
  | ToggleMcpTools
  /// Dismiss error.
  | DismissGistError
  /// Update a schema parameter on the current gist.
  | UpdateGistSchemaName(string)
  /// Update schema summary.
  | UpdateGistSchemaSummary(string)
  /// Add a schema input parameter.
  | AddGistSchemaParam
  /// Remove a schema input parameter by index.
  | RemoveGistSchemaParam(int)
  /// Snapshot current gist state as a diachronic checkpoint (time-based rollback).
  | SnapshotDiachronic
  /// Restore a diachronic checkpoint by index.
  | RestoreDiachronic(int)
  /// Insert gist into a synchronic cardfile (space-based composition).
  | InsertIntoCardfile(string) // cardfile id
  /// Remove gist from a synchronic cardfile.
  | RemoveFromCardfile(string) // cardfile id

/// ENSAID_CONFIG messages — cross-panel config generation and I/O.
/// Any panel can trigger a full ENSAID_CONFIG export; the engine assembles
/// state from Provisioner, Workspace, and Automation Router into one file.
type ensaidConfigMsg =
  /// Generate and write ENSAID_CONFIG.a2ml to the current repo.
  | GenerateAndWrite
  /// Preview the generated content (no disk write).
  | PreviewConfig
  /// Config preview ready (content string).
  | PreviewReady(string)
  /// Config written successfully.
  | ConfigWritten(result<string, string>)
  /// Read existing config from repo.
  | ReadFromRepo
  /// Config read from repo.
  | ConfigRead(result<string, string>)
  /// Dismiss error.
  | DismissConfigError
  /// TypeLL cross-panel type check result for ENSAID config types.
  | TypeCheckResult(result<string, string>)

/// Code MRI Timeline messages (Layer 2) — VeriSimDB-backed development timeline.
/// Handles database connection, snapshot capture, history loading, scrubber
/// navigation, and export. The timeline is append-only and passive — it reads
/// metrics from other panels but never modifies the codebase.
type timelineMsg =
  /// Connect to the VeriSimDB timeline database for the loaded repo.
  | Connect
  /// Connection result (Ok = db path, Error = message).
  | Connected(result<string, string>)
  /// Capture a new snapshot of the current codebase state.
  | CaptureSnapshot
  /// Snapshot captured (Ok = snapshot JSON, Error = message).
  | SnapshotCaptured(result<string, string>)
  /// Load all historical snapshots from VeriSimDB.
  | LoadHistory
  /// History loaded (Ok = snapshots JSON array, Error = message).
  | HistoryLoaded(result<string, string>)
  /// Query snapshots within a date range (startDate, endDate in ISO 8601).
  | QueryRange(string, string)
  /// Range query result.
  | RangeLoaded(result<string, string>)
  /// Move the time-machine scrubber to a specific snapshot index.
  | SeekScrubber(option<int>)
  /// Toggle the dashboard panel expanded/collapsed.
  | ToggleDashboard
  /// Export timeline to a standalone JSON file.
  | ExportTimeline(string)
  /// Export result.
  | TimelineExported(result<string, string>)
  /// Dismiss a timeline error.
  | DismissError

/// Clade Browser messages — exploring and customising panel clades.
type cladeBrowserMsg =
  /// Switch the active category tab.
  | SetCladeCategory(cladeBrowserCategory)
  /// Select a clade for detail view.
  | SelectClade(option<string>)
  /// Set the kind filter.
  | SetKindFilter(cladeKind)
  /// Update search query.
  | UpdateCladeSearch(string)
  /// Load clades from filesystem (or use builtins).
  | LoadClades
  /// Clades loaded successfully.
  | CladesLoaded(array<cladeEntry>)
  /// Set the permission level for a target clade.
  | SetCladePermission(string, cladePermission)
  /// Remove a permission rule (revert to PermitAll).
  | RemoveCladePermission(string)
  /// TypeLL cross-panel type check result for clade spec types.
  | TypeCheckResult(result<string, string>)

/// Messages for the Panel Bus — subscriber management.
type panelBusMsg =
  /// Subscribe a clade to specific topics.
  | BusSubscribe(string, array<PanelBus.eventTopic>)
  /// Unsubscribe a clade from the bus.
  | BusUnsubscribe(string)
  /// Clear the event history ring buffer.
  | BusClearHistory

/// Messages for the 7-Tentacles compiler agent panel.
type tentaclesMsg =
  /// Switch the active category tab.
  | SetTentaclesCategory(tentaclesCategory)
  /// Select an agent for the AgentView tab.
  | SelectAgent(tentacleId)
  /// Change the global learner stage.
  | SetGlobalStage(tentacleStage)
  /// Toggle orchestra compact mode.
  | ToggleOrchestraCompact
  /// An agent broadcasts a message to the orchestra.
  | BroadcastFromAgent(tentacleId, agentBroadcastPayload)
  /// Deliver pending broadcasts to all agents.
  | DeliverBroadcasts
  /// Start a task on a specific agent.
  | StartAgentTask(tentacleId, string)
  /// An agent's OODA phase advanced.
  | AgentPhaseAdvanced(tentacleId, oodaPhase)
  /// An agent produced a constraint (Panel-L feed).
  | AgentConstraintAdded(tentacleId, tentacleConstraint)
  /// An agent produced a reasoning entry (Panel-N feed).
  | AgentReasoningAdded(tentacleId, reasoningEntry)
  /// An agent produced a validated result (Panel-W feed).
  | AgentResultAdded(tentacleId, validatedResult)
  /// An agent finished its current task.
  | AgentTaskCompleted(tentacleId)
  /// An agent encountered an error.
  | AgentError(tentacleId, string)
  /// Clear an agent's error state.
  | ClearAgentError(tentacleId)
  /// Check FFI bridge health (ECHIDNA "without" mode).
  | CheckFfiBridge
  /// FFI bridge health check result.
  | FfiBridgeResult(bool, option<string>)
  /// TypeLL cross-panel type check result for agent task types.
  | TypeCheckResult(result<string, string>)

/// Keybindings messages — rebinding, recording, reset.
type keybindingsMsg =
  /// Start recording a new keybinding for an action.
  | StartRecording(keybindingAction)
  /// A key was pressed while recording.
  | RecordKey(keyChord)
  /// Cancel recording.
  | CancelRecording
  /// Reset a single binding to default.
  | ResetBinding(keybindingAction)
  /// Reset all bindings to defaults.
  | ResetAllBindings

/// Protocol-Squisher format analysis messages.
type protocolSquisherMsg =
  /// Set the active category tab.
  | SetPsCategory(protocolSquisherCategory)
  /// Check whether CLI binary is available.
  | CheckPsCli
  /// CLI check result.
  | PsCliResult(result<string, string>)
  /// Update the analyse file path input.
  | SetAnalyseInput(string)
  /// Run analysis on the current input path.
  | RunAnalysis
  /// Analysis result from Gossamer backend.
  | AnalysisResult(result<string, string>)
  /// Update the left comparison input.
  | SetCompareLeft(string)
  /// Update the right comparison input.
  | SetCompareRight(string)
  /// Run comparison between left and right schemas.
  | RunComparison
  /// Comparison result from Gossamer backend.
  | ComparisonResult(result<string, string>)
  /// TypeLL cross-panel type check result for the last schema analysis.
  | SchemaTypeCheckResult(result<string, string>)
  /// Import IR analysis results as Panel-L constraints.
  | ImportIrConstraints
  /// Toggle transport compatibility display in Panel-W.
  | ToggleTransportDisplay

/// My-Lang AI-native language messages.
type myLangMsg =
  /// Set the active category tab.
  | SetMlCategory(myLangCategory)
  /// Switch the active dialect.
  | SetDialect(myLangDialect)
  /// Check whether CLI binary is available.
  | CheckMlCli
  /// CLI check result.
  | MlCliResult(result<string, string>)
  /// Update editor content.
  | UpdateEditor(string)
  /// Compile the current editor content.
  | Compile
  /// Compilation result from Gossamer backend.
  | CompileResult(result<string, string>)
  /// Update REPL input.
  | UpdateReplInput(string)
  /// Evaluate the current REPL input.
  | EvalRepl
  /// REPL evaluation result from Gossamer backend.
  | ReplResult(result<string, string>)
  /// TypeLL cross-panel type check result for the last compilation.
  | MlTypeCheckResult(result<string, string>)
  /// Connect to my-lang LSP server.
  | ConnectLsp
  /// LSP connection result.
  | LspConnected(result<string, string>)
  /// LSP diagnostics received for current editor content.
  | LspDiagnosticsReceived(array<string>)
  /// Request diagnostics from LSP.
  | RequestDiagnostics
  /// Toggle BoJ routing for My-Lang operations (lsp-mcp cartridge).
  | ToggleMyLangBojRouting

/// TypeLL verification kernel messages.
type typellMsg =
  /// Set the active category tab.
  | SetTlCategory(typellCategory)
  /// Set the view layer (progressive disclosure level).
  | SetViewLayer(viewLayer)
  /// Check TypeLL server health.
  | CheckTlHealth
  /// Health check result.
  | TlHealthResult(result<string, string>)
  /// Update checker input.
  | UpdateCheckerInput(string)
  /// Run type check on current input.
  | RunCheck
  /// Type check result.
  | CheckResult(result<string, string>)
  /// Run type inference on current input.
  | RunInfer
  /// Type inference result.
  | InferResult(result<string, string>)
  /// Load signatures from server.
  | LoadSignatures
  /// Signatures loaded.
  | SignaturesLoaded(result<string, string>)
  /// Load universe hierarchy.
  | LoadUniverses
  /// Universes loaded.
  | UniversesLoaded(result<string, string>)
  /// Set signature search filter.
  | SetSignatureFilter(string)
  /// Set tier filter.
  | SetTierFilter(option<typeTier>)
  /// Update refinement spec.
  | UpdateRefinementSpec(string)
  /// Update refinement constraints.
  | UpdateRefinementConstraints(string)
  /// Run refinement.
  | RunRefine
  /// Refinement result.
  | RefineResult(result<string, string>)
  /// Toggle BoJ routing for TypeLL operations (nesy-mcp cartridge).
  | ToggleTypellBojRouting
  /// Set the default type discipline for modules without a declaration.
  | SetDefaultDiscipline(typeDiscipline)
  /// Add or update a module-level discipline declaration.
  | SetModuleDiscipline(string, typeDiscipline) // (scope, discipline)
  /// Remove a module-level discipline declaration (revert to default).
  | RemoveModuleDiscipline(string) // scope

/// Observability messages — SARIF export and OpenTelemetry trace collection
/// via the observe-mcp BoJ cartridge.
type observabilityMsg =
  /// Export a panic-attack report as SARIF via observe-mcp.
  | ExportSarifViaObserveMcp(string)
  /// SARIF export result.
  | SarifExportResult(result<string, string>)
  /// Export BoJ latency entries as OpenTelemetry traces.
  | ExportOtelTraces
  /// OTEL trace export result.
  | OtelExportResult(result<string, string>)
  /// Fetch observability summary (active exporters, trace counts).
  | FetchObservabilitySummary
  /// Observability summary result.
  | ObservabilitySummaryResult(result<string, string>)
  /// TypeLL cross-panel type check result for observability types.
  | TypeCheckResult(result<string, string>)

/// A2ML manifest messages — loading, validation, and listing of AI manifests.
type a2mlMsg =
  /// Load a specific A2ML manifest file.
  | LoadManifest(string)
  /// Manifest loaded result.
  | ManifestLoaded(result<string, string>)
  /// Validate a manifest file.
  | ValidateManifest(string)
  /// Validation result.
  | ManifestValidated(result<string, string>)
  /// List all A2ML manifests in the repo.
  | ListManifests
  /// List result.
  | ManifestsListed(result<string, string>)
  /// TypeLL cross-panel type check result for A2ML manifest types.
  | TypeCheckResult(result<string, string>)

/// K9 contractile messages — loading, validation, and layout application.
type k9Msg =
  /// Load a K9 contractile file.
  | LoadContractile(string)
  /// Contractile loaded result.
  | ContractileLoaded(result<string, string>)
  /// Validate a contractile file.
  | ValidateContractile(string)
  /// Validation result.
  | ContractileValidated(result<string, string>)
  /// Apply a K9 layout by name.
  | ApplyLayout(string)
  /// Layout application result.
  | LayoutApplied(result<string, string>)
  /// TypeLL cross-panel type check result for K9 contractile types.
  | TypeCheckResult(result<string, string>)

/// Help system messages — search, navigation, onboarding, and context-sensitive help.
type helpMsg =
  /// Update the search query in the help search bar.
  | SetHelpSearch(string)
  /// Switch to a different help category tab.
  | SetHelpCategory(helpCategory)
  /// Select a specific help entry to display in full.
  | SelectEntry(string)
  /// Close the help panel.
  | CloseHelp
  /// Begin the onboarding walkthrough from the first step.
  | StartOnboarding
  /// Advance to the next onboarding step.
  | NextOnboardingStep
  /// Go back to the previous onboarding step.
  | PrevOnboardingStep
  /// Skip the rest of the onboarding walkthrough.
  | SkipOnboarding
  /// Mark the onboarding as completed.
  | CompleteOnboarding
  /// Open help pre-filtered to the specified panel's guide (F1 context-sensitive).
  | OpenContextHelp(option<panelId>)
  /// Search the glossary for a specific term.
  | SearchGlossary(string)

/// Accessibility toolbar messages — palette, animation, font size, focus indicators.
type accessibilityMsg =
  /// Switch the active colour palette (Standard, Deuteranopia, Protanopia, High Contrast).
  | SetAccessibilityPalette(accessibilityPalette)
  /// Set the theme mode (Dark, Light, System).
  | SetThemeMode(themeMode)
  /// OS colour scheme changed (dispatched by matchMedia listener when in System mode).
  | OsColorSchemeChanged(themeMode)
  /// Set the animation preference (On, Reduced, Off).
  | SetAnimations(animationPreference)
  /// Set the font size preset.
  | SetFontSize(fontSizePreset)
  /// Set the focus indicator style.
  | SetFocusStyle(focusIndicatorStyle)
  /// Toggle the accessibility toolbar expanded/collapsed state.
  | ToggleAccessibilityToolbar

/// Tiling and multi-monitor messages — detach panels, snap zones, presets.
type tilingMsg =
  /// Detach a panel into its own browser window.
  | DetachPanel(panelId)
  /// Reattach a previously detached panel back to the main window.
  | ReattachPanel(panelId)
  /// Snap a panel to a specific screen zone.
  | SetSnapZone(panelId, snapZone)
  /// Apply a predefined tiling preset layout.
  | ApplyTilingPreset(tilingPreset)
  /// Clear the active tiling preset and return to freeform.
  | ClearTilingPreset
  /// Show/hide the snap zone preview overlay while dragging.
  | SetSnapPreview(option<snapZone>)
  /// A detached panel window has been closed by the user.
  | DetachedPanelClosed(string)
  /// Sync model state to a detached window via BroadcastChannel.
  | SyncToDetached(string)
  /// Toggle the tiling controls UI visibility.
  | ToggleTilingControls
  /// Enable or disable the tiling system entirely.
  | SetTilingEnabled(bool)

/// Menu bar messages — standard application menu interactions.
type menuBarMsg =
  /// Open a specific top-level menu dropdown.
  | OpenMenu(openMenu)
  /// Close all menu dropdowns.
  | CloseMenus
  /// Menu item actions (dispatched from menu items, routed to appropriate sub-updaters).
  | MenuAction(string)

/// Focus dimming messages — dimming mode, per-panel overrides, interaction tracking.
type focusDimmingMsg =
  /// Set the global dimming mode (Off, Subtle, Strong, SmartMemory).
  | SetDimmingMode(dimmingMode)
  /// Set a per-panel override for dimming behaviour.
  | SetPanelFocusOverride(panelId, panelFocusOverride)
  /// Record a user interaction with a specific panel (updates timestamps and focus).
  | RecordInteraction(string)
  /// Set the custom dim opacity for Smart Memory Mode.
  | SetDimOpacity(float)

/// Stapeln messages — container assembly pipeline operations.
type stapelnMsg =
  /// Set the pipeline backend URL.
  | SetPipelineUrl(string)
  /// Initiate connection to the stapeln backend.
  | Connect
  /// Connection result (true = connected, false = failed).
  | Connected(bool)
  /// Update a constraint field by key and value.
  | UpdateConstraint(string, string)
  /// Request validation of the current assembly.
  | RequestValidation
  /// Validation results received from backend.
  | ValidationReceived(validationSummary)
  /// Request artifact generation in specified format.
  | RequestGenerate(string)
  /// Generated artifact content received from backend.
  | GenerateReceived(string)
  /// Refresh pipeline status from backend.
  | RefreshStatus
  /// Pipeline status received from backend.
  | StatusReceived(pipelineStatus)
  /// Switch the active tab ("constraints" | "reasoning" | "results").
  | SetActiveTab(string)
  /// Dismiss the error banner.
  | DismissError

/// Evangeliser messages — JS→ReScript pattern detection and teaching.
type evangeliserMsg =
  /// Set the JS code input for scanning.
  | SetJsInput(string)
  /// Run the pattern scanner on the current JS input.
  | RunScan
  /// Scan completed (or failed).
  | ScanComplete(result<evangeliserAnalysis, string>)
  /// Switch the active tab.
  | SetTab(evangeliserTab)
  /// Set the view layer (RAW, FOLDED, GLYPHED, WYSIWYG).
  | SetViewLayer(evangeliserViewLayer)
  /// Set the minimum confidence threshold.
  | SetMinConfidence(float)
  /// Set the difficulty filter.
  | SetDifficultyFilter(option<evangeliserDifficulty>)
  /// Toggle a category in the constraint filter.
  | ToggleCategory(evangeliserCategory)
  /// Select a match in the results view.
  | SelectMatch(option<int>)
  /// Set the pattern filter text.
  | SetFilterText(string)
  /// Dismiss error.
  | DismissError

/// Language Forge panel messages — nextgen-languages portfolio monitoring.
type languageForgeMsg =
  /// Load language data (re-initialise from hardcoded assessment).
  | LoadLanguages
  /// Change the active category tab.
  | SetForgeCategory(forgeCategory)
  /// Update the text filter for language search.
  | SetForgeFilter(string)
  /// Change the sort order.
  | SetForgeSort(forgeSortBy)
  /// Select a language for detail view (None to deselect).
  | SelectLanguage(option<string>)
  /// Toggle the MoSCoW breakdown in the detail view.
  | ToggleMoscow

/// Messages for TangleViz topological programming visualizer.
type tangleVizMsg =
  /// Switch view mode (braid diagram / knot diagram / algebraic).
  | SetViewMode(tangleViewMode)
  /// Update Tangle source code input text.
  | SetInputText(string)
  /// Parse the current input text into a braid word.
  | ParseInput
  /// Clear all input and state.
  | ClearAll
  /// Load an example braid word (array of generators).
  | LoadExample(array<braidGenerator>)
  /// Select a knot invariant for computation.
  | SelectInvariant(knotInvariant)
  /// Compute the currently selected invariant.
  | ComputeInvariant
  /// Dismiss the error banner.
  | DismissError

/// SpecBrowser messages — language specification browsing and comparison.
type specBrowserMsg =
  /// Set the active category tab.
  | SetSpecCategory(specBrowserCategory)
  /// Select a language for detail/grammar/typing views.
  | SelectSpecLanguage(option<string>)
  /// Set the comparison side language.
  | SetComparisonSide(comparisonSide, string)
  /// Update the text filter.
  | SetSpecFilter(string)
  /// Toggle showing only incomplete languages.
  | ToggleIncompleteOnly
  /// Dismiss error.
  | DismissSpecError

/// VerificationDashboard messages — proof/test/benchmark status.
type verificationDashboardMsg =
  /// Set the active category tab.
  | SetVdCategory(verificationDashboardCategory)
  /// Select a language for detail view.
  | SelectVdLanguage(option<string>)
  /// Update the text filter.
  | SetVdFilter(string)
  /// Set the sort criterion.
  | SetVdSort(verificationSortBy)
  /// Toggle showing only languages with admitted/sorry debt.
  | ToggleDebtOnly
  /// Dismiss error.
  | DismissVdError

/// Observatory messages — integrative dashboard health and resource monitoring.
type observatoryMsg =
  /// Switch the active tab.
  | SetObsTab(observatoryTab)
  /// Start a health check sweep across all panels.
  | RunHealthCheck
  /// Health check completed with resource snapshots.
  | HealthCheckComplete(result<array<resourceSnapshot>, string>)
  /// Dismiss error banner.
  | DismissObsError

/// AmbientOps messages — hospital-model sysadmin diagnostics and repair.
type ambientOpsMsg =
  /// Switch the active tab.
  | SetOpsTab(ambientOpsTab)
  /// Start a diagnostic sweep.
  | RunDiagnostics
  /// Diagnostic sweep completed with findings.
  | DiagnosticsComplete(result<array<diagnosticFinding>, string>)
  /// Dismiss error banner.
  | DismissOpsError

/// Unit Test Runner messages — test execution, coverage, diff-aware testing.
type unitTestRunnerMsg =
  | SetUtrTab(unitTestTab)
  | UtrStarted
  | UtrCompleted(result<string, string>)
  | DismissUtrError
  | RunAllTests
  | StopTests
  | ToggleDiffAware

/// Functional Tester messages — end-to-end game workflow simulation.
type functionalTesterMsg =
  | SetFtTab(functionalTestTab)
  | FtStarted
  | FtCompleted(result<string, string>)
  | DismissFtError
  | NewWorkflow
  | SelectWorkflow(string)
  | RunWorkflow(string)
  | LoadTemplate(string)

/// Regression Guard messages — snapshot comparison and golden-file testing.
type regressionGuardMsg =
  | SetRgTab(regressionTab)
  | RgStarted
  | RgCompleted(result<string, string>)
  | DismissRgError
  | CheckAll
  | UpdateAll
  | UpdateSnapshot(string)
  | ViewDiff(string)
  | ToggleAutoUpdate

/// Performance Profiler messages — frame budget, GC pressure, memory flamegraphs.
type performanceProfilerMsg =
  | SetPpTab(performanceTab)
  | PpStarted
  | PpCompleted(result<string, string>)
  | DismissPpError
  | StartProfiling
  | StopProfiling

/// Load Tester messages — Phoenix channel stress testing, concurrent simulation.
type loadTesterMsg =
  | SetLtTab(loadTestTab)
  | LtStarted
  | LtCompleted(result<string, string>)
  | DismissLtError
  | RunScenario(string)
  | RunSelectedScenario
  | SelectScenario(string)

/// Soak Monitor messages — long-running session memory trend and leak detection.
type soakMonitorMsg =
  | SetSmTab(soakTab)
  | SmStarted
  | SmCompleted(result<string, string>)
  | DismissSmError
  | StartMonitor
  | StopMonitor

/// Compatibility Matrix messages — browser/device/resolution test matrix.
type compatibilityMatrixMsg =
  | SetCmTab(compatibilityTab)
  | CmStarted
  | CmCompleted(result<string, string>)
  | DismissCmError
  | RunAll
  | SelectCell(string, string)

/// Exploratory Workbench messages — freeform play session recording, anomaly detection.
type exploratoryWorkbenchMsg =
  | SetEwTab(exploratoryTab)
  | EwStarted
  | EwCompleted(result<string, string>)
  | DismissEwError
  | StartRecording
  | StopRecording
  | QuickFlag(string)
  | ToggleAnomalyDetection
  | UpdateNotes(string)

/// Beta Feedback Hub messages — feedback-o-tron integration, sentiment, triage.
type betaFeedbackHubMsg =
  | SetBfhTab(betaFeedbackTab)
  | BfhStarted
  | BfhCompleted(result<string, string>)
  | DismissBfhError
  | SelectFeedback(string)
  | Upvote(string)
  | Downvote(string)
  | SubmitFeedback
  | UpdateSubmitTitle(string)
  | UpdateSubmitBody(string)
  | ToggleSortByVotes

/// Balance Analyser messages — game balance stats, Monte Carlo, difficulty curves.
type balanceAnalyserMsg =
  | SetBaTab(balanceTab)
  | BaStarted
  | BaCompleted(result<string, string>)
  | DismissBaError
  | RunSimulation
  | SelectLevel(string)
  | ApplyRecommendation(string, string, float)

/// Typing Bridge messages — TypeLL type constraints for game state.
type typingBridgeMsg =
  | SetTbTab(typingBridgeTab)
  | TbStarted
  | TbCompleted(result<string, string>)
  | DismissTbError

/// Neurosymbolic Bridge messages — guard AI behaviour reasoning via ECHIDNA.
type neurosymBridgeMsg =
  | SetNbTab(neurosymBridgeTab)
  | NbStarted
  | NbCompleted(result<string, string>)
  | DismissNbError

/// Agentic Bridge messages — automated playtesting agents with OODA loop.
type agenticBridgeMsg =
  | SetAbTab(agenticBridgeTab)
  | AbStarted
  | AbCompleted(result<string, string>)
  | DismissAbError

/// Automation Bridge messages — CI/CD pipeline orchestration for game builds.
type automationBridgeMsg =
  | SetAutoBTab(automationBridgeTab)
  | AutoBStarted
  | AutoBCompleted(result<string, string>)
  | DismissAutoBError

/// Database Bridge messages — VeriSimDB game state persistence.
type databaseBridgeMsg =
  | SetDbBTab(databaseBridgeTab)
  | DbBStarted
  | DbBCompleted(result<string, string>)
  | DismissDbBError

/// Protocol Bridge messages — multiplayer sync protocol analysis.
type protocolBridgeMsg =
  | SetPbTab(protocolBridgeTab)
  | PbStarted
  | PbCompleted(result<string, string>)
  | DismissPbError

/// Proofs Bridge messages — proven repo formal verification integration.
type proofsBridgeMsg =
  | SetPrBTab(proofsBridgeTab)
  | PrBStarted
  | PrBCompleted(result<string, string>)
  | DismissPrBError

/// Scripting Bridge messages — VM instruction scripting REPL.
type scriptingBridgeMsg =
  | SetScBTab(scriptingBridgeTab)
  | ScBStarted
  | ScBCompleted(result<string, string>)
  | DismissScBError

/// Generator Mode messages — parametric procedural world builder.
type generatorModeMsg =
  | SetGenCategory(generatorModeCategory)
  | GenStarted
  | GenCompleted(result<string, string>)
  | DismissGenError

/// Architect Mode messages — PixiJS fine-grained level editor with L/N/W.
type architectModeMsg =
  | SetArchModeCategory(architectModeCategory)
  | ArchModeStarted
  | ArchModeCompleted(result<string, string>)
  | DismissArchModeError

/// Guard AI Tuner messages — guard patrol, alert threshold, spawn rate tuning.
type guardAiTunerMsg =
  | SetGatCategory(guardAiTunerCategory)
  | GatStarted
  | GatCompleted(result<string, string>)
  | DismissGatError

/// Device Network Designer messages — wire devices, configure security levels.
type deviceNetworkDesignerMsg =
  | SetDndCategory(deviceNetworkDesignerCategory)
  | DndStarted
  | DndCompleted(result<string, string>)
  | DismissDndError

/// Asset Manager messages — PixiJS sprites, sounds, level templates.
type assetManagerMsg =
  | SetAmCategory(assetManagerCategory)
  | AmStarted
  | AmCompleted(result<string, string>)
  | DismissAmError

/// Playtest Recorder messages — record + replay sessions, annotate moments.
type playtestRecorderMsg =
  | SetPrCategory(playtestRecorderCategory)
  | PrStarted
  | PrCompleted(result<string, string>)
  | DismissPrError

/// Code Review messages — PR review, inline comments, approval gates.
type codeReviewMsg =
  | SetCrTab(codeReviewTab)
  | SetCrFilter(string)
  | SelectPr(string)
  | ApprovePr
  | DismissCrError

/// Merge Coordinator messages — branch management, conflict resolution, merge queue.
type mergeCoordinatorMsg =
  | SetMcTab(mergeCoordinatorTab)
  | SelectBranch(string)
  | ResolveConflict(string, string)
  | DismissMcError

/// Team Dashboard messages — team presence, activity feed, progress tracking.
type teamDashboardMsg =
  | SetTdTab(teamDashboardTab)
  | SetTdFilter(string)
  | DismissTdError

/// Debugging Workbench messages — time-travel debugging, state inspection, watches.
type debuggingWorkbenchMsg =
  | SetDwTab(debuggingWorkbenchTab)
  | DwStepBack
  | DwStepForward
  | DwGoToSnapshot(int)
  | DwCaptureSnapshot
  | DwAddWatch
  | DwRemoveWatch(string)
  | DwClearConsole
  | DismissDwError

/// Wiring Inspector messages — PCC verification lifecycle, audit tabs, and UI state.
type wiringInspectorMsg =
  | RunVerification
  | VerificationResult(result<string, string>)
  | RunSingleVerification(string)
  | SingleVerificationResult(result<string, string>)
  | SelectPanel(option<string>)
  | SetFilterStatus(option<string>)
  | SetAuditTab(WiringInspectorModel.auditTab)
  | SetSortBy(string)
  | ToggleStateSection(WiringInspectorModel.panelState)

// ── Floor Raise campaign message types ──────────────────────────────────

/// Messages for the Floor Raise campaign dashboard.
type floorRaiseMsg =
  | SetTab(FloorRaiseModel.floorRaiseTab)
  | ScanAdoption
  | AdoptionScanned(result<string, string>)
  | RunCampaign(string)
  | CampaignResult(result<string, string>)
  | ClearError

/// Messages for the Proven Adoption scanner panel.
type provenAdoptionMsg =
  | SetTab(ProvenAdoptionModel.provenAdoptionTab)
  | ScanRepos
  | ReposScanned(result<string, string>)
  | SelectRepo(string)
  | ClearError

/// Messages for the Contractile Completeness scanner panel.
type contractileCompletenessMsg =
  | SetTab(ContractileCompletenessModel.contractileCompletenessTab)
  | ScanRepos
  | ReposScanned(result<string, string>)
  | SelectRepo(string)
  | ClearError

/// Messages for the Manifest Coverage scanner panel.
type manifestCoverageMsg =
  | SetTab(ManifestCoverageModel.manifestCoverageTab)
  | ScanRepos
  | ReposScanned(result<string, string>)
  | SelectRepo(string)
  | ClearError

/// Messages for the VeriSimDB Feeds viewer panel.
type verisimdbFeedsMsg =
  | SetTab(VerisimdbFeedsModel.verisimdbFeedsTab)
  | CheckFeeds
  | FeedsChecked(result<string, string>)
  | SelectFeed(string)
  | ClearError

/// Messages for the Feedback Routing viewer panel.
type feedbackRoutingMsg =
  | SetTab(FeedbackRoutingModel.feedbackRoutingTab)
  | RefreshReports
  | ReportsRefreshed(result<string, string>)
  | SelectReport(string)
  | ClearError

/// Messages for the Vexometer Friction viewer panel.
type vexometerFrictionMsg =
  | SetTab(VexometerFrictionModel.vexometerFrictionTab)
  | MeasureAll
  | MeasureResult(result<string, string>)
  | SelectTool(string)
  | ClearError

/// Messages for the 007 Toolchain panel.
type oo7Msg =
  | SetCategory(Oo7ToolchainModel.oo7Category)
  | ConnectDaemon
  | DisconnectDaemon
  | SetPermissions(Oo7ToolchainModel.daemonPermission)
  | RunStage(Oo7ToolchainModel.oo7Stage)
  | StageResult(Oo7ToolchainModel.oo7Stage, result<string, string>)
  | UpdateSource(string)
  | LoadToolchain
  | ClearError

/// Messages for the VideoCoordination panel — Drive-to-Photos batch transfers.
type videoCoordinationMsg =
  | StartTransfer(string, string) // source, destination
  | PauseTransfer(string) // batchId
  | RefreshStatus
  | StatusResult(result<string, string>)
  | TransferResult(result<string, string>)
  | ClearError

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
  | Oo7Toolchain(oo7Msg) // Agentic compiler and high-rigor execution
  | VideoCoordination(videoCoordinationMsg) // Drive-to-Photos batch transfer dashboard
  | Interfaces(interfacesMsg) // ABI/FFI inventory
  | Playgrounds(playgroundsMsg) // Code sandbox
  | Minter(minterMsg) // Panel Minter wizard
  | Provisioner(provisionerMsg) // Portfolio bundles, config, isolation
  | VoiceTag(voiceTagMsg) // Code MRI Layer 0 — voice-activated annotation
  | Provenance(provenanceMsg) // Code trust surface (core infrastructure)
  | Watcher(watcherMsg) // Filesystem observation (core infrastructure)
  | Ai(aiMsg) // Multi-provider AI neural interface
  | RepoLoader(repoLoaderMsg) // Repository scanner and panel configuration
  | PanelSwitcher(panelSwitcherMsg) // Panel navigation and health checks
  | Workspace(workspaceMsg) // Workspace management layer (DD-022–DD-027)
  | Capture(captureMsg) // Screenshots, recordings, demos (DD-022)
  | Security(securityMsg) // Redaction, vault, 2FA, Trustfile (DD-026/027)
  | Keybindings(keybindingsMsg) // Keyboard shortcut management
  | Migration(migrationMsg) // ReScript Migration Observatory
  | PanicAttack(panicAttackMsg) // Stress testing and bug detection
  | MassPanic(massPanicMsg) // Organisation-scale batch scanning
  | Tsdm(tsdmMsg) // TSDM directive — triaxial priority ordering
  | ValenceShell(valenceShellMsg) // Embedded terminal with Claude Code
  | GamePreview(gamePreviewMsg) // Live IDApTIK game preview
  | VmInspector(vmInspectorMsg) // Reversible VM visual debugger
  | NetworkTopology(networkTopologyMsg) // IDApTIK in-game network graph
  | LevelArchitect(levelArchitectMsg) // Visual level design tool
  | Coprocessors(coprocessorsMsg) // Coprocessor backend monitoring
  | MultiplayerMonitor(multiplayerMonitorMsg) // Phoenix sync server inspector
  | DlcWorkshop(dlcWorkshopMsg) // DLC puzzle pack creation and testing
  | Ums(umsMsg) // Universal Modding Studio — unified game content creation hub
  | EditorBridge(editorBridgeMsg) // External code editor federation (LSP)
  | BuildDashboard(buildDashboardMsg) // Build/test/error monitoring
  | ReleaseManager(releaseManagerMsg) // Versioning, changelog, distribution
  | AutomationRouter(automationRouterMsg) // Hybrid cross-panel workflow orchestration
  | ScriptGist(scriptGistMsg) // Portable computation gists (Minskian cardfiles)
  | Databases(databasesMsg) // Unified database management (VeriSimDB/QuandleDB/LithoGlyph)
  | Boj(bojMsg) // Bundle of Joy cartridge server
  | CladeBrowser(cladeBrowserMsg) // Clade taxonomy browser
  | Tentacles(tentaclesMsg) // 7-Tentacles compiler agent orchestra
  | ProtocolSquisher(protocolSquisherMsg) // Format analysis and compatibility
  | MyLang(myLangMsg) // AI-native language workbench
  | TypeLL(typellMsg) // Verification kernel (cross-panel type intelligence)
  | EnsaidConfig(ensaidConfigMsg) // Cross-panel ENSAID_CONFIG generation and I/O
  | Timeline(timelineMsg) // Code MRI Layer 2 — VeriSimDB development timeline
  | Bus(panelBusMsg) // Panel Bus subscriber management
  | RecordBojLatency(string, string, float) // cartridge, tool, elapsed ms
  | GovernanceNesyResult(result<string, string>) // nesy-mcp governance query response
  | GovernanceNesyValidateResult(result<string, string>) // nesy-mcp adjustment validation
  | GovernanceNesyProbeResult(result<string, string>) // nesy-mcp stability probe
  | Observability(observabilityMsg) // SARIF export and OpenTelemetry via observe-mcp
  | A2ml(a2mlMsg) // AI manifest parsing and validation
  | K9(k9Msg) // K9 contractile configuration and layout
  | AuditSeams // Run compliance seam audit against exception register
  | SeamAuditResult(SeamEngine.seamAuditResult) // Result of seam audit
  | Help(helpMsg) // In-app help, glossary, onboarding
  | MenuBar(menuBarMsg) // Standard application menu bar
  | AccessibilityCtrl(accessibilityMsg) // Accessibility toolbar preferences
  | Tiling(tilingMsg) // Multi-monitor panel detachment and tiling
  | FocusDimming(focusDimmingMsg) // Focus-aware dimming and Smart Memory Mode
  | Stapeln(stapelnMsg) // Stapeln container assembly pipeline
  | Evangeliser(evangeliserMsg) // ReScript Evangeliser — JS→ReScript teaching
  | LanguageForge(languageForgeMsg) // Language Forge — nextgen-languages portfolio
  | TangleViz(tangleVizMsg) // Topological programming visualizer (braids, knots, invariants)
  | SpecBrowser(specBrowserMsg) // Language specification browser — grammars, typing rules, taxonomy
  | VerificationDashboard(verificationDashboardMsg) // Proof/test/benchmark/fuzzing status
  | Observatory(observatoryMsg) // Integrative dashboard — cross-panel health and resources
  | AmbientOps(ambientOpsMsg) // Hospital-model sysadmin — clinician, network, hardware
  // Game Testing panels
  | UnitTestRunner(unitTestRunnerMsg) // ReScript test execution, coverage heatmap
  | FunctionalTester(functionalTesterMsg) // End-to-end game workflow simulation
  | RegressionGuard(regressionGuardMsg) // Snapshot comparison and golden-file testing
  | PerformanceProfiler(performanceProfilerMsg) // Frame budget, GC pressure, flamegraphs
  | LoadTester(loadTesterMsg) // Phoenix channel stress testing
  | SoakMonitor(soakMonitorMsg) // Long-running session memory trend
  | CompatibilityMatrix(compatibilityMatrixMsg) // Browser/device/resolution test matrix
  | ExploratoryWorkbench(exploratoryWorkbenchMsg) // Freeform play session recording
  | BetaFeedbackHub(betaFeedbackHubMsg) // Feedback-o-tron integration, sentiment
  | BalanceAnalyser(balanceAnalyserMsg) // Game balance stats, Monte Carlo
  // Bridge panels
  | TypingBridge(typingBridgeMsg) // TypeLL type constraints for game state
  | NeurosymBridge(neurosymBridgeMsg) // Guard AI behaviour reasoning via ECHIDNA
  | AgenticBridge(agenticBridgeMsg) // Automated playtesting agents with OODA
  | AutomationBridge(automationBridgeMsg) // CI/CD pipeline orchestration
  | DatabaseBridge(databaseBridgeMsg) // VeriSimDB game state persistence
  | ProtocolBridge(protocolBridgeMsg) // Multiplayer sync protocol analysis
  | ProofsBridge(proofsBridgeMsg) // Proven repo formal verification
  | ScriptingBridge(scriptingBridgeMsg) // VM instruction scripting REPL
  // Game-specific panels
  | GeneratorMode(generatorModeMsg) // Parametric procedural world builder
  | ArchitectMode(architectModeMsg) // PixiJS fine-grained level editor
  | GuardAiTuner(guardAiTunerMsg) // Guard patrol, alert threshold tuning
  | DeviceNetworkDesigner(deviceNetworkDesignerMsg) // Wire devices, security levels
  | AssetManager(assetManagerMsg) // PixiJS sprites, sounds, templates
  | PlaytestRecorder(playtestRecorderMsg) // Record + replay sessions
  // Team / collaboration panels
  | CodeReview(codeReviewMsg) // PR review, inline comments, approval gates
  | MergeCoordinator(mergeCoordinatorMsg) // Branch management, conflict resolution
  | TeamDashboard(teamDashboardMsg) // Team presence, activity feed, progress
  | DebuggingWorkbench(debuggingWorkbenchMsg) // Time-travel debugging, state inspection
  // Infrastructure panels
  | WiringInspector(wiringInspectorMsg) // PCC constraint state and bottleneck analysis
  // Floor Raise panels — foundational tool adoption campaign
  | FloorRaise(floorRaiseMsg) // Floor Raise campaign dashboard
  | ProvenAdoption(provenAdoptionMsg) // Proven library adoption scanner
  | ContractileCompleteness(contractileCompletenessMsg) // Contractile coverage scanner
  | ManifestCoverage(manifestCoverageMsg) // AI manifest coverage scanner
  | VerisimdbFeeds(verisimdbFeedsMsg) // VeriSimDB data feed viewer
  | FeedbackRouting(feedbackRoutingMsg) // Feedback-o-Tron routing viewer
  | VexometerFriction(vexometerFrictionMsg) // Vexometer friction viewer
  | Burble(BurbleModel.burbleMsg) // Burble voice huddle (groove-aware)
  | Undo // Undo last significant action
  | Redo // Redo last undone action
  | SaveState // Persist current state to storage
  | NoOp
