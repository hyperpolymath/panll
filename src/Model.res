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

/// Re-export Help types (helpCategory, helpEntry, glossaryTerm, onboardingStep,
/// onboardingState, helpState) for the in-application help system with
/// context-sensitive guides, neurosymbolic glossary, and onboarding walkthrough.
include HelpModel

/// Re-export Accessibility types (fontSizePreset, animationPreference,
/// focusIndicatorStyle, accessibilityState) for the centralised accessibility
/// toolbar controlling colour palettes, animation, font size, and focus indicators.
include AccessibilityModel

/// Re-export Tiling types (snapZone, tilingPreset, detachedPanel, tilingState)
/// for multi-monitor panel detachment, Aero-style snap zones, and tiling presets.
include TilingModel

/// Re-export Focus Dimming types (dimmingMode, panelFocusOverride,
/// focusDimmingState) for focus-aware panel dimming and Smart Memory Mode
/// that throttles unfocused panel processing.
include FocusDimmingModel
include MenuBarModel

/// Re-export ScriptGist types (gistLanguage, gistParam, gistSchema, gistTarget,
/// gistVisibility, gistResult, scriptGist, gistTemplate, gistCategory, gistSortBy,
/// scriptGistState) for the portable computation gist system — saveable, shareable,
/// LLM-callable as MCP tools, user-runnable standalone.
include ScriptGistModel

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
  barycentreTour: tourState,
  menuBar: menuBarState,

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

  // A2ML — last loaded/validated manifest state
  lastA2mlManifest: option<A2mlEngine.a2mlManifest>,
  lastA2mlValidation: option<A2mlEngine.a2mlValidationResult>,
  a2mlManifestPaths: array<string>,

  // K9 — last loaded/validated contractile state
  lastK9Contractile: option<K9Engine.k9Contractile>,
  lastK9Layout: option<K9Engine.k9Layout>,
  k9KennelSchema: option<string>,
  k9YardContract: option<string>,

  // Compliance seams — exception register and audit state
  seamRegister: SeamEngine.seamRegister,
  lastSeamAudit: option<SeamEngine.seamAuditResult>,

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

  // Help — in-app help system with context-sensitive guides and glossary
  help: helpState,

  // Accessibility — centralised a11y preferences (palette, animation, font, focus)
  accessibility: accessibilityState,

  // Tiling — multi-monitor panel detachment and snap zone management
  tiling: tilingState,

  // Focus Dimming — focus-aware panel dimming and Smart Memory Mode
  focusDimming: focusDimmingState,

  // Script Gist — portable computation gists (saveable, LLM-callable, user-runnable)
  scriptGist: scriptGistState,
}

/// Initial model state - "Dark Start" mode
let init = (): model => {
  paneL: {
    constraints: [
      {
        id: "orbital-stability-inv",
        expression: "forall t : Time, stability(t) >= 0.3 -> co_orbit_maintained(t)",
        active: true,
        pinned: true,
      },
      {
        id: "divergence-bound",
        expression: "divergence(symbolic, neural) <= 0.7 // Jaccard distance ceiling",
        active: true,
        pinned: true,
      },
      {
        id: "autonomy-ceiling",
        expression: "agency.autonomyLevel <= 0.8 // Human-in-the-loop bound",
        active: true,
        pinned: false,
      },
      {
        id: "trust-propagation",
        expression: "forall a b : Artifact, depends(a, b) -> trust(a) <= trust(b)",
        active: true,
        pinned: false,
      },
      {
        id: "vexation-anti-inflammatory",
        expression: "vexometer.index > 0.6 -> enable_anti_inflammatory()",
        active: true,
        pinned: false,
      },
      {
        id: "type-safety-invariant",
        expression: "forall expr : Expr, type_check(expr) = Ok(t) -> eval(expr) : t",
        active: false,
        pinned: false,
      },
      {
        id: "sync-latency-bound",
        expression: "sync_latency(L, N, W) <= 2000ms // Cross-pane coherence",
        active: true,
        pinned: false,
      },
    ],
    activeConstraintId: None,
    editorContent: "// Symbolic Mass — Tractatus Editor\n// Define constraints that govern the Binary Star co-orbit.\n//\n// Active constraints feed into the barycentre position\n// and inform ECHIDNA's proof obligations.\n\ntype orbital_invariant =\n  | StabilityBound(float)    // Minimum stability threshold\n  | DivergenceLimit(float)   // Maximum symbolic-neural drift\n  | AutonomyCeiling(float)   // Human-in-the-loop guarantee\n  | TrustPropagation         // Provenance chain integrity\n\nlet verify_co_orbit : orbital_invariant -> result<proof, counterexample> =\n  fun inv -> match inv with\n  | StabilityBound(min) ->\n      if orbital.stability >= min then Ok(QED)\n      else Error(DriftDetected(orbital.stability, min))\n  | DivergenceLimit(max) ->\n      let d = jaccard_distance(paneL.tokens, paneN.tokens) in\n      if d <= max then Ok(WithinBound(d))\n      else Error(Diverged(d, max))\n  | AutonomyCeiling(cap) ->\n      assert(agency.autonomyLevel <= cap);\n      Ok(HumanInLoop)\n  | TrustPropagation ->\n      forall_chain(provenance.artifacts, fun a b ->\n        trust(a) <= trust(b))\n",
    lastInferredType: None,
  },
  paneN: {
    tokens: [
      {id: "t-0", content: "Initialising formal verification context...", timestamp: 0.0, confidence: 0.95, validated: true, source: NeuralInference, category: Observation, emittedDuring: Observe, causedBy: [], proofHash: None},
      {id: "t-1", content: "Loading Coq prover backend", timestamp: 0.1, confidence: 0.88, validated: true, source: EchidnaProver, category: Observation, emittedDuring: Observe, causedBy: ["t-0"], proofHash: None},
      {id: "t-2", content: "forall n : nat, n + 0 = n", timestamp: 0.2, confidence: 0.92, validated: true, source: EchidnaProver, category: Hypothesis, emittedDuring: Orient, causedBy: ["t-1"], proofHash: None},
      {id: "t-3", content: "Tactic suggestion: induction on n", timestamp: 0.3, confidence: 0.78, validated: false, source: EchidnaProver, category: Abduction, emittedDuring: Orient, causedBy: ["t-2"], proofHash: None},
      {id: "t-4", content: "Proof obligation discharged", timestamp: 0.4, confidence: 0.97, validated: true, source: EchidnaProver, category: ProofStep, emittedDuring: Decide, causedBy: ["t-2", "t-3"], proofHash: Some("sha256:a1b2c3...")},
      {id: "t-5", content: "Checking orbital stability invariant...", timestamp: 0.5, confidence: 0.91, validated: true, source: TypeLLKernel, category: Observation, emittedDuring: Observe, causedBy: [], proofHash: None},
      {id: "t-6", content: "Divergence bound verified: 0.23 <= 0.7", timestamp: 0.6, confidence: 0.94, validated: true, source: TypeLLKernel, category: ProofStep, emittedDuring: Decide, causedBy: ["t-5"], proofHash: Some("sha256:d4e5f6...")},
      {id: "t-7", content: "Trust propagation: 4 artifacts in chain", timestamp: 0.7, confidence: 0.86, validated: true, source: NeuralInference, category: Deduction, emittedDuring: Orient, causedBy: ["t-4", "t-6"], proofHash: None},
      {id: "t-8", content: "Autonomy ceiling: 0.0 <= 0.8 (human in loop)", timestamp: 0.8, confidence: 0.99, validated: true, source: AntiCrashGate, category: Observation, emittedDuring: Act, causedBy: [], proofHash: None},
      {id: "t-9", content: "7 constraints active, 6 satisfied, 1 pending", timestamp: 0.9, confidence: 0.93, validated: true, source: NeuralInference, category: Synthesis, emittedDuring: Act, causedBy: ["t-7", "t-8"], proofHash: None},
    ],
    inferenceActive: true,
    nextTokenId: 10,
    activeCausalChain: ["t-9"],
    monologue: "ECHIDNA neural advisor active. Processing 7 symbolic constraints from Panel-L.\n\n[OBSERVE] Scanning constraint set: orbital-stability-inv, divergence-bound, autonomy-ceiling, trust-propagation, vexation-anti-inflammatory, type-safety-invariant (disabled), sync-latency-bound.\n\n[ORIENT] Symbolic mass density: moderate (editor content ~180 tokens). Barycentre currently balanced — both stars contributing mass. Divergence level low: symbolic and neural streams share vocabulary overlap.\n\n[DECIDE] Recommend verifying trust-propagation constraint against current provenance chain. The forall quantifier over artifact dependencies requires inductive proof — dispatching to Coq backend.\n\n[ACT] Dispatched proof obligation: trust_propagation_inductive to Coq. Estimated completion: <200ms. Monitoring sync latency for cross-pane coherence bound (2000ms ceiling).\n\nContractile status: orbital-stability STRICT (elasticity 0.2), vexation-ceiling ADAPTIVE (elasticity 0.5), divergence-limit WARN (elasticity 0.3), autonomy-bound STRICT (elasticity 0.4). All within elastic bounds.\n\nNext: Awaiting Coq discharge for trust propagation. Will update inference manifold on completion.",
    agency: {
      phase: Orient,
      autonomyLevel: 0.15,
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
    symbolicMass: 0.0,
    neuralStream: 0.0,
    barycentrePosition: 0.0,
    syncHealth: 1.0,
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
    connected: true,
    endpoint: ServiceEndpoints.verisimdb,
    lastQuery: "SELECT * FROM entities WHERE modality = 'graph' LIMIT 10",
    queryResult: None,
    queryError: None,
    entities: [
      "orbital-stability-proof",
      "trust-chain-artifact-001",
      "divergence-metric-snapshot",
      "provenance-graph-root",
      "temporal-drift-log",
    ],
    selectedEntity: None,
    driftStatus: Some("Nominal — all 8 modalities within tolerance"),
    driftScores: Some({
      graph: 0.03,
      vector: 0.07,
      tensor: 0.02,
      semantic: 0.11,
      document: 0.04,
      temporal: 0.06,
      provenance: 0.01,
      spatial: 0.05,
    }),
    proofObligations: [
      {
        proofType: "invariant",
        contractName: "orbital-stability",
        status: "verified",
        proofHash: "a1b2c3d4e5f6",
      },
      {
        proofType: "temporal",
        contractName: "drift-bound",
        status: "pending",
        proofHash: "f6e5d4c3b2a1",
      },
    ],
    dbMenuExpanded: false,
    normalisingEntity: None,
    entityDetail: None,
    telemetry: None,
    telemetryVisible: false,
    orchStatus: Some("Orchestrator online — 5 entities indexed"),
    lastTypeCheck: None,
    proofDisplayActive: false,
    inferenceStream: [],
    antiCrashValidation: true,
    queryCount: 0,
    bojRouting: false,
  },
  echidna: {
    connected: true,
    endpoint: ServiceEndpoints.echidna,
    version: Some("0.4.1-neurosym"),
    provers: [
      {name: "Coq", tier: "ITP", complexity: "CoC"},
      {name: "Lean 4", tier: "ITP", complexity: "DTT"},
      {name: "Z3", tier: "SMT", complexity: "QF_LIA"},
      {name: "Isabelle/HOL", tier: "ITP", complexity: "HOL"},
      {name: "CVC5", tier: "SMT", complexity: "QF_UFLIA"},
    ],
    lastProofResult: None,
    proofError: None,
    proofLoading: false,
    session: None,
    tacticSuggestions: [
      {
        tactic: "induction",
        args: ["n"],
        confidence: 0.92,
        aspectTags: ["structural", "recursive"],
        description: "Structural induction on the natural number argument",
      },
      {
        tactic: "apply",
        args: ["trust_transitive"],
        confidence: 0.85,
        aspectTags: ["rewriting", "chain"],
        description: "Apply trust transitivity lemma to close provenance chain goal",
      },
      {
        tactic: "simpl",
        args: [],
        confidence: 0.78,
        aspectTags: ["simplification"],
        description: "Simplify the current goal using reduction rules",
      },
    ],
    selectedProver: Some("Coq"),
    proofInput: "",
    menuExpanded: false,
    activeTab: EchidnaProofTab,
    tacticInput: "",
    sessionLoading: false,
    lastProofObligations: None,
    bojRouting: false,
    enterpriseModel: {
      elements: [],
      constraints: [],
      checkResults: [],
      checking: false,
      activeMetamodel: None,
      activeLayer: None,
      lastXmiImport: None,
    },
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
  aerie: {
    loaded: true,
    loading: false,
    error: None,
    probes: [
      {
        endpoint: "1.1.1.1",
        label: "Cloudflare DNS",
        protocol: "ICMP",
        active: true,
      },
      {
        endpoint: "8.8.8.8",
        label: "Google DNS",
        protocol: "ICMP",
        active: true,
      },
      {
        endpoint: "api.github.com",
        label: "GitHub API",
        protocol: "HTTPS",
        active: true,
      },
    ],
    latencyResults: [
      {
        endpoint: "1.1.1.1",
        rttMs: 4.2,
        jitterMs: 0.8,
        packetLoss: 0.0,
        timestamp: "2026-03-09T10:30:00Z",
      },
      {
        endpoint: "8.8.8.8",
        rttMs: 12.7,
        jitterMs: 1.3,
        packetLoss: 0.0,
        timestamp: "2026-03-09T10:30:00Z",
      },
      {
        endpoint: "api.github.com",
        rttMs: 28.4,
        jitterMs: 3.1,
        packetLoss: 0.0,
        timestamp: "2026-03-09T10:30:00Z",
      },
    ],
    speedTests: [],
    bgpRoutes: [],
    activeCategory: AerieDashboard,
    bgpAnomalyCount: 0,
    bojRouting: false,
  },
  interfaces: InterfacesEngine.defaultState,
  playgrounds: PlaygroundsEngine.defaultState,
  hypatia: HypatiaEngine.defaultState,
  fleet: {
    loaded: true,
    loading: false,
    error: None,
    bots: [
      {
        id: Rhodibot,
        status: BotActive,
        queuedFindings: 3,
        processedFindings: 47,
        confidenceThreshold: 0.85,
        lastActivity: "2026-03-09T10:30:00Z",
      },
      {
        id: Echidnabot,
        status: BotActive,
        queuedFindings: 7,
        processedFindings: 112,
        confidenceThreshold: 0.90,
        lastActivity: "2026-03-09T10:28:00Z",
      },
      {
        id: Sustainabot,
        status: BotIdle,
        queuedFindings: 0,
        processedFindings: 23,
        confidenceThreshold: 0.80,
        lastActivity: "2026-03-09T09:45:00Z",
      },
      {
        id: Glambot,
        status: BotActive,
        queuedFindings: 2,
        processedFindings: 31,
        confidenceThreshold: 0.75,
        lastActivity: "2026-03-09T10:25:00Z",
      },
      {
        id: Seambot,
        status: BotIdle,
        queuedFindings: 0,
        processedFindings: 18,
        confidenceThreshold: 0.82,
        lastActivity: "2026-03-09T08:50:00Z",
      },
      {
        id: Finishbot,
        status: BotActive,
        queuedFindings: 1,
        processedFindings: 9,
        confidenceThreshold: 0.88,
        lastActivity: "2026-03-09T10:15:00Z",
      },
    ],
    findings: [
      {
        id: "HYP-2026-0142",
        repoName: "proven",
        summary: "4,566 believe_me instances — formal verification undermined",
        tier: Eliminate,
        confidence: 0.97,
        assignedBot: Some(Echidnabot),
        resolved: false,
      },
      {
        id: "HYP-2026-0143",
        repoName: "boj-server",
        summary: "Missing SPDX headers in 3 cartridge source files",
        tier: Control,
        confidence: 0.91,
        assignedBot: Some(Rhodibot),
        resolved: false,
      },
      {
        id: "HYP-2026-0144",
        repoName: "panll",
        summary: "Documentation coverage below 60% threshold",
        tier: Substitute,
        confidence: 0.84,
        assignedBot: Some(Glambot),
        resolved: false,
      },
    ],
    health: Some({
      activeBots: 4,
      totalQueued: 13,
      totalProcessed: 240,
      avgConfidence: 0.88,
      triangleCounts: (1, 1, 1),
    }),
    activeCategory: FleetDashboard,
    filterText: "",
  },
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
  boj: {
    serverUrl: ServiceEndpoints.bojServer,
    connected: true,
    lastHealthCheck: 1709942400.0,
    cartridges: [
      {
        name: "database-mcp",
        displayName: "Database MCP",
        description: "VeriSimDB query routing and schema introspection",
        grade: GradeD,
        loaded: true,
        protocols: [ProtoMCP, ProtoREST, ProtoGRPC, ProtoGraphQL],
        layers: {abiReady: true, ffiReady: true, adapterReady: true, sharedLibReady: true},
        soHash: "sha256:a1b2c3d4",
        restPort: 7701,
        grpcPort: 7702,
        graphqlPort: 7703,
      },
      {
        name: "proof-mcp",
        displayName: "Proof MCP",
        description: "ECHIDNA proof dispatch and tactic suggestions",
        grade: GradeD,
        loaded: true,
        protocols: [ProtoMCP, ProtoNeSy],
        layers: {abiReady: true, ffiReady: true, adapterReady: true, sharedLibReady: true},
        soHash: "sha256:e5f6a7b8",
        restPort: 7711,
        grpcPort: 7712,
        graphqlPort: 7713,
      },
      {
        name: "observe-mcp",
        displayName: "Observe MCP",
        description: "Network telemetry and Aerie probe routing",
        grade: GradeD,
        loaded: true,
        protocols: [ProtoMCP, ProtoREST],
        layers: {abiReady: true, ffiReady: true, adapterReady: false, sharedLibReady: true},
        soHash: "sha256:c9d0e1f2",
        restPort: 7721,
        grpcPort: 0,
        graphqlPort: 0,
      },
      {
        name: "fleet-mcp",
        displayName: "Fleet MCP",
        description: "Gitbot-fleet orchestration and dispatch",
        grade: GradeD,
        loaded: true,
        protocols: [ProtoMCP, ProtoFleet, ProtoAgentic],
        layers: {abiReady: true, ffiReady: true, adapterReady: true, sharedLibReady: true},
        soHash: "sha256:34567890",
        restPort: 7731,
        grpcPort: 7732,
        graphqlPort: 7733,
      },
      {
        name: "security-mcp",
        displayName: "Security MCP",
        description: "Panic-attack fuzzing and vulnerability scanning",
        grade: GradeD,
        loaded: false,
        protocols: [ProtoMCP, ProtoREST],
        layers: {abiReady: true, ffiReady: true, adapterReady: false, sharedLibReady: true},
        soHash: "sha256:abcdef01",
        restPort: 0,
        grpcPort: 0,
        graphqlPort: 0,
      },
    ],
    selectedCartridge: None,
    umoja: {
      active: true,
      localNodeId: "panll-primary-001",
      peers: [
        {
          nodeId: "boj-worker-002",
          address: "127.0.0.1:7750",
          state: PeerVerified,
          gossipRound: 12,
          catalogueDigest: "sha256:fedcba98",
          lastSeen: 1709942380.0,
        },
      ],
      currentRound: 12,
    },
    activeCategory: Dashboard,
    invokeCartridge: "",
    invokeTool: "",
    invokeArgs: [],
    invokeResult: None,
    loading: false,
    error: None,
    filterText: "",
    lastTypeCheck: None,
    latencyLog: [],
    umojaAddPeerInput: "",
  },
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
  lastA2mlManifest: None,
  lastA2mlValidation: None,
  a2mlManifestPaths: [],
  lastK9Contractile: None,
  lastK9Layout: None,
  k9KennelSchema: None,
  k9YardContract: None,
  seamRegister: SeamEngine.defaultRegister,
  lastSeamAudit: None,
  ensaidConfigPreview: None,
  ensaidConfigError: None,
  undoStack: [],
  redoStack: [],
  humidity: Medium,
  barycentreTour: {
    active: false,
    currentStep: TourIntro,
    completed: false,
  },
  menuBar: {
    activeMenu: None,
  },
  viewMode: Standard,
  paneLVisible: true,
  paneNVisible: true,
  paneWVisible: true,
  protocolAnalysisVisible: false,
  panelBarVisible: true,
  fullscreenActive: false,
  feedbackPending: None,
  feedbackError: None,
  feedbackReportType: Some("FeatureRequest"),
  help: HelpEngine.defaultState,
  accessibility: AccessibilityEngine.defaultState,
  tiling: TilingEngine.defaultState,
  focusDimming: FocusDimmingEngine.defaultState,
  scriptGist: ScriptGistEngine.defaultState,
}
