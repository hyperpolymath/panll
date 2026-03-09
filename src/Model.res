// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Model — Composition root for the eNSAID environment state.
///
/// This module re-exports all domain types from the four sub-modules
/// (PaneModel, EchidnaModel, VeriSimModel, GovernanceModel) and defines
/// the unified `model` record and its initial state.
///
/// Downstream code using `open Model` or `Model.typeName` continues to
/// work unchanged — `include` re-exports types AND variant constructors.
///
/// Dependency graph (no cycles):
///   PaneModel       ← no deps (leaf)
///   EchidnaModel    ← no deps (leaf)
///   VeriSimModel    ← no deps (leaf)
///   GovernanceModel ← PaneModel (for neuralToken in antiCrashState)
///   Model           ← all four (this file)
///
/// NOTE ON TYPE COMPOSITION: This `model` record contains 18 domain slices,
/// each with its own variant types and records. ReScript's `include` mechanism
/// re-exports all constructors — so `Installed`, `Native`, `Verified` etc. are
/// usable without qualification throughout the codebase. In TypeScript, this
/// would require either string literal unions (no exhaustiveness checking beyond
/// what the IDE approximates) or a maze of discriminated unions with manual type
/// guards. Here, the compiler enforces exhaustive matching on every `switch` —
/// add a new variant to any model and the compiler tells you every place in
/// 26,000+ lines that needs updating. That's not "nice to have" type safety;
/// it's the difference between refactoring with confidence and refactoring with
/// prayer. See https://rescript-lang.org/docs/manual/latest/variant

/// Re-export Pane-L, Pane-N, Pane-W state types and their supporting types
/// (symbolicConstraint, neuralToken, oodaPhase, agencyState, eventChain*).
include PaneModel

/// Re-export ECHIDNA theorem prover types (trust levels, axiom danger,
/// portfolio confidence, provers, sessions, dispatch results, tactic suggestions).
include EchidnaModel

/// Re-export VeriSimDB types (proof obligations, drift scores, telemetry,
/// database backend state).
include VeriSimModel

/// Re-export cognitive governance types (violationType, antiCrashState,
/// vexometer, orbital, humidity, viewMode, sync, contractiles).
include GovernanceModel

/// Re-export VAB (Verified Assembly Building) types (categories, components,
/// warnings, capabilities, assembly state) for the server composer panel.
include VabModel

/// Re-export CloudGuard types (zones, settings, DNS records, audit findings,
/// plan tiers, policy constraints, diff entries) for the Cloudflare domain
/// security management panel.
include CloudGuardModel

/// Re-export Farm types (farmRepo, farmPriority, farmCategory, farmSortBy,
/// farmState) for the Git-Private-Farm panel — repo inventory and health.
include FarmModel

/// Re-export Plaza types (complianceLevel, complianceAudit, adoptionStats,
/// plazaCategory, plazaState) for the Palimpsest Plaza licensing panel.
include PlazaModel

/// Re-export Reposystem types for RSR compliance auditing.
include ReposystemModel

/// Re-export Aerie types for network diagnostics and BGP forensics.
include AerieModel

/// Re-export Interfaces types for ABI/FFI inventory.
include InterfacesModel

/// Re-export Playgrounds types for code sandbox and NQC console.
include PlaygroundsModel

/// Re-export Hypatia types (neuralNetId, neuralNetStatus, neuralNetState,
/// scanResult, pipelineStage, learningCycle, hypatiaCategory, hypatiaState)
/// for the neurosymbolic CI/CD intelligence panel.
include HypatiaModel

/// Re-export Fleet types (botId, botStatus, botState, safetyTier, fleetFinding,
/// fleetHealth, fleetCategory, fleetState) for the Gitbot-Fleet panel.
include FleetModel

/// Re-export Minter types (panelBackendKind, accessibilityLevel, minterCapability,
/// nameValidation, minterForm, mintResult, minterState) for the Panel Minter
/// wizard that generates new panel modules with accessibility baked in.
include MinterModel

/// Re-export Provisioner types (panelIsolation, panelInstallStatus, panelConfig,
/// portfolio, portfolioInstallProgress, provisionerCategory, provisionerState)
/// for the portfolio bundling, panel configuration, and installation system.
include ProvisionerModel

/// Re-export VoiceTag types (mriTagType, mriInputMethod, mriAttribution,
/// mriCodeAuthor, mriTag, mriFileSummary, mriFile, voiceState, voiceTagState)
/// for the Code MRI Layer 0 annotation system. Tags are stored as portable
/// `.mri.json` sidecars — standalone-first, no PanLL dependency required.
include VoiceTagModel

/// Re-export Provenance types (trustLevel, provenanceRegion, provenanceSummary,
/// fileProvenance, accessibilityPalette, provenanceState) for the Qubes-style
/// code trust surface that is always visible as an ambient layer.
include ProvenanceModel

/// Re-export AI types (aiProviderId, aiProviderConfig, aiProviderStatus,
/// aiMessage, aiCategory, aiState) for the multi-provider AI neural interface
/// panel that speaks to Anthropic, Google, Mistral, OpenAI, and local models.
include AiModel

/// Re-export Repo Loader types (repoInfo, panelSuggestion, repoLoaderCategory,
/// repoLoaderState) for the repository scanning and panel configuration panel.
include RepoLoaderModel

/// Re-export Watcher types (watchEventKind, watchEvent, watcherState) for
/// the filesystem observation infrastructure that feeds events into the TEA
/// loop. Every panel can react to relevant file changes.
include WatcherModel

/// Re-export Panel Switcher types (panelId, connectionStatus, panelMeta,
/// panelSwitcherState) for the unified panel navigation system that replaces
/// ad-hoc `visible: bool` toggles on individual overlays.
include PanelSwitcherModel

/// Re-export Workspace types (workspaceMode, sessionProtection, executionMode,
/// panelGroup, arrangement, session, checkpoint, polyTool, configuratorTab,
/// workspaceState) for the workspace management layer (DD-022–DD-027).
include WorkspaceModel

/// Re-export Keybindings types (modifier, keyChord, keybindingAction, keybinding,
/// keybindingsState) for the customisable keyboard shortcut system.
include KeybindingsModel

/// Re-export Migration types (migrationVersionBracket, migrationConfigFormat,
/// migrationRepoSummary, migrationSession, migrationSubmission, migrationConstraint,
/// migrationObligation, mergeResolution, migrationCategory, migrationState) for the
/// ReScript Migration Observatory panel — health tracking, session observation,
/// submission queue, and merge conflict resolution timeline.
include MigrationModel

/// Re-export PanicAttack types (weakPointSeverity, weakPointCategory, weakPoint,
/// scanSummary, scanReport, panicCategory, panicAttackState) for the stress
/// testing and logic-based bug signature detection panel.
include PanicAttackModel

/// Re-export MassPanic types (repoScanStatus, repoResult, assemblylineSummary,
/// deltaEntry, repoSortMode, repoFilterMode, storageTarget, massPanicState) for
/// the organisation-scale batch scanning panel (assemblyline + BLAKE3 + verisimdb).
include MassPanicModel

/// Re-export TSDM types (scopeTier, maintenanceTier, auditTier, cleanupStep,
/// dialogueTopic, axisId, tsdmWorkItem, auditTooling, tsdmState) for the
/// Triaxial Software Development Methodology directive panel.
include TsdmModel

/// Re-export Capture types (captureFormat, captureEntry, recordingState, demoStep,
/// demoPackage, comparisonMode, panelClone, captureCategory, captureState) for
/// the panel capture, recording, and demo/teaching system (DD-022).
include CaptureModel

/// Re-export Status Bar types (widgetPosition, widgetKind, statusWidget, systemInfo,
/// statusBarState) for the configurable status bar widget system (DD-025).
include StatusBarModel

/// Re-export Security types (redactionMode, redactionPattern, detectedSecret,
/// vaultStatus, vaultKey, twoFactorStatus, securityLevel, trustfilePolicy,
/// securityCategory, securityState) for secrets, vault, 2FA, Trustfile (DD-026/027).
include SecurityModel

/// Re-export Valence Shell types (shellBackend, recordingState, terminalRecording,
/// approvalGateMode, pendingCommand, valenceCheckpoint, valenceShellCategory,
/// terminalLine, valenceShellState) for the embedded terminal panel with Claude
/// Code integration, session recording, and collaborative approval gate.
include ValenceShellModel

/// Re-export Game Preview types (gameOverlay, gameExecutionState,
/// gameRecordingState, deviceInteraction, gameplayClip, renderStats,
/// gamePreviewCategory, gamePreviewState) for the live IDApTIK game
/// preview panel with hot-reload, overlays, and gameplay recording.
include GamePreviewModel

/// Re-export VM Inspector types (vmInstructionTier, vmInstruction,
/// vmMemoryCell, vmPortEntry, vmSnapshot, vmBreakpoint, vmConnectionMode,
/// vmInspectorCategory, vmInspectorState) for the reversible VM visual
/// debugger with step forward/backward and execution timeline.
include VmInspectorModel

/// Re-export Network Topology types (networkZone, connectionProtocol,
/// networkDevice, networkConnection, dnsEntry, packetFlowEvent,
/// networkTopologyCategory, networkTopologyState) for the IDApTIK
/// in-game network topology viewer.
include NetworkTopologyModel

/// Re-export Level Architect types (levelEntityKind, levelEntity,
/// guardPatrol, defenceFlag, validationIssue, levelAsset, editorTool,
/// levelArchitectCategory, levelArchitectState) for the visual level
/// design tool with grid editor and LevelConfig export.
include LevelArchitectModel

/// Re-export Coprocessors types (coprocessorBackend, coprocHealth,
/// coprocCallEntry, coprocMetrics, heatmapCell, coprocessorsCategory,
/// coprocessorsState) for the IDApTIK coprocessor monitoring dashboard.
include CoprocessorsModel

/// Re-export Multiplayer Monitor types (wsConnectionState, connectedPlayer,
/// channelSubscription, stateDiffEntry, deviceLock, latencySample,
/// etsCacheEntry, multiplayerCategory, multiplayerMonitorState) for the
/// IDApTIK Phoenix sync server monitoring panel.
include MultiplayerMonitorModel

/// Re-export DLC Workshop types (puzzleDifficulty, testRunStatus,
/// puzzleInstruction, dlcPuzzle, puzzleChain, dlcAsset, dlcPackMeta,
/// dlcWorkshopCategory, dlcWorkshopState) for the DLC puzzle pack
/// creation, testing, and packaging panel.
include DlcWorkshopModel

/// Re-export Editor Bridge types (editorKind, editorConnectionState,
/// openFileEntry, lspDiagnostic, workspaceSymbol, bridgeActivity,
/// editorBridgeCategory, editorBridgeState) for the external code
/// editor federation panel (LSP diagnostics, symbols, jump-to-line).
include EditorBridgeModel

/// Re-export Build Dashboard types (buildTarget, buildStatus,
/// buildMessage, testResult, buildHistoryEntry, buildDashboardCategory,
/// buildDashboardState) for the IDApTIK build monitoring panel.
include BuildDashboardModel

/// Re-export Release Manager types (releaseChannel, platformTarget,
/// releaseStatus, releaseArtifact, changelogEntry, releaseRecord,
/// releaseManagerCategory, releaseManagerState) for the versioning,
/// changelog, and distribution panel.
include ReleaseManagerModel

/// Re-export Automation Router types (triggerEvent, ruleCondition, ruleAction,
/// approvalMode, automationRule, pendingAction, executionLogEntry,
/// automationRouterCategory, automationRouterState) for the hybrid cross-panel
/// workflow orchestration panel with event-driven rules and approval gates.
include AutomationRouterModel

/// Opens BojModel into this scope, contributing BoJ types
/// (bojCartridge, bojCategory, bojState, etc.) for the Bundle of Joy panel.
include BojModel
include CladeBrowserModel

/// Re-export Tentacles types (tentacleId, tentacleStage, oodaPhase,
/// tentacleConstraint, reasoningEntry, validatedResult, tentaclePersonality,
/// tentacleNames, agentBroadcastPayload, tentacleAgentState, tentaclesCategory,
/// tentaclesState) for the 7-Tentacles compiler agent panel — seven colour-coded
/// agents representing compiler subsystems with progressive cephalopod staging.
include TentaclesModel
include ProtocolSquisherModel
include MyLangModel
include TypeLLModel

/// The complete Model — composes all domain slices into a single record.
/// This is the "Gravitational Centre" of the Binary Star system.
type model = {
  // Core panes
  paneL: paneLState,
  paneN: paneNState,
  paneW: paneWState,

  // Cognitive governance
  antiCrash: antiCrashState,
  vexometer: vexometerState,
  orbital: orbitalState,
  syncState: syncState,
  contractiles: array<contractile>,
  humidity: humidityLevel,

  // View state
  viewMode: viewMode,
  paneLVisible: bool,
  paneNVisible: bool,
  paneWVisible: bool,
  protocolAnalysisVisible: bool,
  panelBarVisible: bool,
  fullscreenActive: bool,

  // Database backends
  verisimdb: verisimdbState,

  // Theorem prover backend
  echidna: echidnaState,

  // VAB (Verified Assembly Building)
  vab: vabState,

  // CloudGuard (Cloudflare domain security management)
  cloudguard: cloudguardState,

  // Git-Private-Farm — repo inventory and health dashboard
  farm: farmState,

  // Palimpsest Plaza — PMPL licensing adoption and governance
  plaza: plazaState,

  // Reposystem — RSR compliance across 265+ repos
  reposystem: reposystemState,

  // Aerie — network diagnostics, speed tests, BGP forensics
  aerie: aerieState,

  // Interfaces — Idris2 ABI + Zig FFI inventory + binding coverage
  interfaces: interfacesState,

  // Playgrounds — code sandbox + NQC console + tutorials
  playgrounds: playgroundsState,

  // Hypatia — neurosymbolic CI/CD intelligence (5 neural networks, 298+ repos)
  hypatia: hypatiaState,

  // Gitbot-Fleet — 6-bot orchestration and dispatch dashboard
  fleet: fleetState,

  // Panel Minter — create new panel modules with accessibility by default
  minter: minterState,

  // Provisioner — portfolio bundles, panel config, isolation tiers
  provisioner: provisionerState,

  // Code MRI VoiceTag — voice-activated annotation system (Layer 0)
  voiceTag: voiceTagState,

  // Provenance Map — Qubes-style code trust surface (always visible, ambient)
  provenance: provenanceState,

  // Watcher — filesystem observation infrastructure (feeds all panels)
  watcher: watcherState,

  // AI — multi-provider neural interface (Claude, Gemini, Mistral, GPT, local)
  ai: aiState,

  // Repo Loader — repository scanner and panel configuration wizard
  repoLoader: repoLoaderState,

  // Panel Switcher — unified panel navigation (replaces ad-hoc visible toggles)
  panelSwitcher: panelSwitcherState,

  // Workspace — panel arrangements, groups, sessions, modes (DD-022–DD-027)
  workspace: workspaceState,

  // Keybindings — customisable keyboard shortcuts
  keybindings: keybindingsState,

  // Capture — screenshots, recordings, demos, cloning (DD-022)
  capture: captureState,

  // Status Bar — configurable bottom bar with system info widgets (DD-025)
  statusBar: statusBarState,

  // Security — redaction, vault, 2FA, Trustfile enforcement (DD-026/027)
  security: securityState,

  // Migration Observatory — ReScript migration health, sessions, submissions
  migration: migrationState,

  // panic-attack — stress testing and weak point analysis
  panicAttack: panicAttackState,

  // mass-panic — organisation-scale batch scanning (assemblyline + BLAKE3 + verisimdb)
  massPanic: massPanicState,

  // TSDM — triaxial software development methodology directive
  tsdm: tsdmState,

  // Valence Shell — embedded terminal with Claude Code and reversible ops
  valenceShell: valenceShellState,

  // Game Preview — live IDApTIK game preview with hot-reload and overlays
  gamePreview: gamePreviewState,

  // VM Inspector — reversible VM visual debugger (step forward/backward)
  vmInspector: vmInspectorState,

  // Network Topology — IDApTIK in-game network graph viewer
  networkTopology: networkTopologyState,

  // Level Architect — visual level design tool
  levelArchitect: levelArchitectState,

  // Coprocessors — coprocessor backend monitoring dashboard
  coprocessors: coprocessorsState,

  // Multiplayer Monitor — Phoenix sync server inspector
  multiplayerMonitor: multiplayerMonitorState,

  // DLC Workshop — puzzle pack creation, testing, packaging
  dlcWorkshop: dlcWorkshopState,

  // Editor Bridge — federate with external code editors (VSCodium, Zed, etc.)
  editorBridge: editorBridgeState,

  // Build Dashboard — build/test/error monitoring for IDApTIK sub-projects
  buildDashboard: buildDashboardState,

  // Release Manager — versioning, changelog, artifacts, distribution
  releaseManager: releaseManagerState,

  // Automation Router — hybrid cross-panel workflow orchestration
  automationRouter: automationRouterState,

  // BoJ — Bundle of Joy cartridge server
  boj: bojState,

  // Clade Browser — panel taxonomy explorer
  cladeBrowser: cladeBrowserState,

  // Tentacles — 7-Tentacles compiler agent panel (within/without ECHIDNA)
  tentacles: tentaclesState,

  // Protocol-Squisher — 13-format schema analysis and compatibility
  protocolSquisher: protocolSquisherState,

  // My-Lang — AI-native language workbench (Solo/Duet/Ensemble/Me dialects)
  myLang: myLangState,

  // TypeLL — Verification kernel (cross-panel type intelligence)
  typell: typellState,

  // Panel Bus — pub/sub subscriber registry and event history
  busRegistry: PanelBus.subscriberRegistry,

  // ENSAID_CONFIG — cross-panel config generation state
  ensaidConfigPreview: option<string>,
  ensaidConfigError: option<string>,

  // Undo/Redo — ring buffer of model snapshots
  undoStack: array<string>,
  redoStack: array<string>,

  // Feedback-O-Tron
  feedbackPending: option<string>,
  feedbackError: option<string>,
  feedbackReportType: option<string>,
}

/// Initial model state - "Dark Start" mode
let init = (): model => {
  paneL: {
    constraints: [],
    activeConstraintId: None,
    editorContent: "",
    lastInferredType: None,
  },
  paneN: {
    tokens: [
      {content: "Initialising formal verification context...", timestamp: 0.0, confidence: 0.95, validated: true},
      {content: "Loading Coq prover backend", timestamp: 0.1, confidence: 0.88, validated: true},
      {content: "forall n : nat, n + 0 = n", timestamp: 0.2, confidence: 0.92, validated: true},
      {content: "Tactic suggestion: induction on n", timestamp: 0.3, confidence: 0.78, validated: false},
      {content: "Proof obligation discharged", timestamp: 0.4, confidence: 0.97, validated: true},
    ],
    inferenceActive: false,
    monologue: "ECHIDNA neural advisor active. Awaiting proof session...",
    agency: {
      phase: Observe,
      autonomyLevel: 0.0,
      lastOperatorInput: 0.0,
    },
  },
  paneW: {
    content: "",
    topologyView: true, // Start with Binary Star diagram
    lastValidatedOutput: "",
    eventChain: [],
    eventChainSummary: None,
    eventChainTimeline: None,
    eventChainInput: "",
    eventChainError: None,
    panicAttackerMode: "unknown",
    panicAttackerBinary: None,
    panicAttackerStatusDetail: None,
    securityTarget: "",
    securityTimeline: "",
    securityAxes: "cpu,memory,concurrency",
    securityIntensity: "medium",
    securityDuration: "30",
    securityStatus: None,
    securityError: None,
    securityMenuExpanded: false,
    securityDialogOpen: false,
    securityDialogTool: None,
    securityViewActive: false,
  },
  antiCrash: {
    enabled: true,
    strictMode: true,
    violations: [],
    halted: false,
    pendingReview: None,
  },
  vexometer: {
    index: 0.0,
    recentCancellations: 0,
    recentCorrections: 0,
    antiInflammatoryActive: false,
    inertiaDetected: false,
  },
  orbital: {
    stability: 1.0,
    divergenceLevel: 0.0,
    driftAuraColour: "indigo",
  },
  syncState: {
    lastSymbolicHash: "",
    lastNeuralHash: "",
    lastWorldHash: "",
    pendingSync: [],
    syncLatency: 0.0,
  },
  contractiles: [
    {
      id: "orbital-stability",
      name: "Orbital Stability Bound",
      description: "Ensures the Binary Star co-orbit remains stable",
      enforcement: Strict,
      status: Pending,
      elasticity: 0.2,
      lastEvaluated: 0.0,
    },
    {
      id: "vexation-ceiling",
      name: "Vexation Ceiling",
      description: "Prevents operator friction from exceeding acceptable levels",
      enforcement: Adaptive,
      status: Pending,
      elasticity: 0.5,
      lastEvaluated: 0.0,
    },
    {
      id: "divergence-limit",
      name: "Divergence Limit",
      description: "Limits drift between symbolic and neural subsystems",
      enforcement: Warn,
      status: Pending,
      elasticity: 0.3,
      lastEvaluated: 0.0,
    },
    {
      id: "autonomy-bound",
      name: "Autonomy Bound",
      description: "Constrains the machine's autonomous action level",
      enforcement: Strict,
      status: Pending,
      elasticity: 0.4,
      lastEvaluated: 0.0,
    },
  ],
  verisimdb: {
    connected: false,
    endpoint: ServiceEndpoints.verisimdb,
    lastQuery: "",
    queryResult: None,
    queryError: None,
    entities: [],
    selectedEntity: None,
    driftStatus: None,
    driftScores: None,
    proofObligations: [],
    dbMenuExpanded: false,
    normalisingEntity: None,
    entityDetail: None,
    telemetry: None,
    telemetryVisible: false,
    orchStatus: None,
    lastTypeCheck: None,
    proofDisplayActive: false,
    inferenceStream: [],
    antiCrashValidation: true,
    queryCount: 0,
    bojRouting: false,
  },
  echidna: {
    connected: false,
    endpoint: ServiceEndpoints.echidna,
    version: None,
    provers: [],
    lastProofResult: None,
    proofError: None,
    proofLoading: false,
    session: None,
    tacticSuggestions: [],
    selectedProver: None,
    proofInput: "",
    menuExpanded: false,
    tacticInput: "",
    sessionLoading: false,
    lastProofObligations: None,
    bojRouting: false,
  },
  vab: {
    visible: false,
    catalog: VabCatalog.allComponents,
    selectedCategory: VabCore,
    sortBy: SortByName,
    filterText: "",
    server: {
      name: "Untitled Server",
      components: [],
    },
    warnings: [],
    capabilities: VabEngine.computeCapabilities([], VabCatalog.allComponents, []),
    hoveredComponent: None,
  },
  cloudguard: {
    connection: Disconnected,
    loading: false,
    error: None,
    zones: [],
    selectedZoneIds: [],
    settings: [],
    dnsRecords: [],
    pagesProjects: [],
    auditResult: None,
    constraints: [],
    exceptions: [],
    configDiff: None,
    bulkProgress: None,
    visible: false,
    activeCategory: SslTls,
    filterText: "",
    settingFilter: "",
    showDiff: false,
    showAudit: true,
    dnsEditingId: None,
  },
  farm: {
    loaded: false,
    loading: false,
    error: None,
    repos: [],
    selectedRepoNames: [],
    activeCategory: AllRepos,
    filterText: "",
    sortBy: SortByName,
    totalRepos: 0,
    unhealthyCount: 0,
  },
  plaza: {
    loaded: false,
    loading: false,
    error: None,
    stats: None,
    audits: [],
    signatures: [],
    compatibilityResults: [],
    activeCategory: Dashboard,
    filterText: "",
    selectedRepo: None,
  },
  reposystem: ReposystemEngine.defaultState,
  aerie: AerieEngine.defaultState,
  interfaces: InterfacesEngine.defaultState,
  playgrounds: PlaygroundsEngine.defaultState,
  hypatia: HypatiaEngine.defaultState,
  fleet: FleetEngine.defaultState,
  minter: MinterEngine.defaultState,
  provisioner: ProvisionerEngine.defaultState,
  voiceTag: VoiceTagEngine.defaultState,
  provenance: ProvenanceEngine.defaultState,
  watcher: {
    running: false,
    watchedPaths: [],
    eventCount: 0,
    recentEvents: [],
    error: None,
  },
  ai: AiEngine.defaultState,
  repoLoader: RepoLoaderEngine.defaultState,
  panelSwitcher: PanelRegistry.init,
  workspace: WorkspaceEngine.defaultState,
  keybindings: KeybindingsEngine.defaultState,
  capture: CaptureEngine.defaultState,
  statusBar: StatusBarEngine.defaultState,
  security: SecurityEngine.defaultState,
  migration: MigrationEngine.defaultState,
  panicAttack: PanicAttackModel.init,
  massPanic: MassPanicModel.init,
  tsdm: TsdmModel.init,
  valenceShell: ValenceShellEngine.defaultState,
  gamePreview: GamePreviewEngine.defaultState,
  vmInspector: VmInspectorEngine.defaultState,
  networkTopology: NetworkTopologyEngine.defaultState,
  levelArchitect: LevelArchitectEngine.defaultState,
  coprocessors: CoprocessorsEngine.defaultState,
  multiplayerMonitor: MultiplayerMonitorEngine.defaultState,
  dlcWorkshop: DlcWorkshopEngine.defaultState,
  editorBridge: EditorBridgeEngine.defaultState,
  buildDashboard: BuildDashboardEngine.defaultState,
  releaseManager: ReleaseManagerEngine.defaultState,
  automationRouter: AutomationRouterEngine.defaultState,
  boj: BojEngine.defaultState,
  cladeBrowser: {
    ...CladeBrowserModel.defaultState,
    clades: CladeBrowserEngine.builtinClades,
    permissionRules: CladeBrowserEngine.defaultPermissionRules,
  },
  tentacles: TentaclesEngine.init(),
  protocolSquisher: ProtocolSquisherEngine.defaultState,
  myLang: MyLangEngine.defaultState,
  typell: TypeLLEngine.defaultState,
  busRegistry: PanelBus.defaultRegistry,
  ensaidConfigPreview: None,
  ensaidConfigError: None,
  undoStack: [],
  redoStack: [],
  humidity: Medium,
  viewMode: DarkStart,
  paneLVisible: true,
  paneNVisible: true,
  paneWVisible: true,
  protocolAnalysisVisible: false,
  panelBarVisible: true,
  fullscreenActive: false,
  feedbackPending: None,
  feedbackError: None,
  feedbackReportType: Some("FeatureRequest"),
}
