// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Messages - the communication protocol for TEA updates.
///
/// Every user action, backend response, and timer pulse is encoded here so
/// the Elm-style update loop can deterministically evolve the Binary Star
/// state machine. Each domain message type lives in its own module under
/// src/msg/ and is re-exported here via `include`. The unified `type msg`
/// at the bottom references all sub-types.
///
/// Dependency graph (no cycles):
///   src/msg/*Msg.res  <- Model (leaf types)
///   Msg.res           <- all msg modules (this file)

// -- Core pane messages --------------------------------------------------

/// Re-export Pane-L (Symbolic) messages.
include PaneLMsg

/// Re-export Pane-N (Neural) messages.
include PaneNMsg

/// Re-export Pane-W (World/Barycentre) messages.
include PaneWMsg

// -- Cognitive governance messages ---------------------------------------

/// Re-export Vexometer messages.
include VexometerMsg

/// Re-export Orbital stability messages.
include OrbitalMsg

/// Re-export View control messages.
include ViewMsg

/// Re-export Feedback-O-Tron messages.
include FeedbackMsg

/// Re-export Anti-Crash validation messages.
include AntiCrashMsg

// -- Backend service messages --------------------------------------------

/// Re-export VeriSimDB database messages.
include VeriSimDBMsg

/// Re-export ECHIDNA theorem prover messages.
include EchidnaMsg

/// Re-export VAB (Verified Assembly Building) messages.
include VabMsg

/// Re-export CloudGuard Cloudflare messages.
include CloudguardMsg

/// Re-export BoJ cartridge server messages.
include BojMsg

/// Re-export unified Databases panel messages.
include DatabasesMsg

// -- Tool and panel messages ---------------------------------------------

/// Re-export Git-Private-Farm messages.
include FarmMsg

/// Re-export Palimpsest Plaza messages.
include PlazaMsg

/// Re-export Hypatia neurosymbolic scanner messages.
include HypatiaMsg

/// Re-export Gitbot-Fleet messages.
include FleetMsg

/// Re-export Reposystem RSR compliance messages.
include ReposystemMsg

/// Re-export Aerie network diagnostics messages.
include AerieMsg

/// Re-export Interfaces ABI/FFI messages.
include InterfacesMsg

/// Re-export Playgrounds sandbox messages.
include PlaygroundsMsg

/// Re-export Panel Minter wizard messages.
include MinterMsg

/// Re-export Provisioner messages.
include ProvisionerMsg

/// Re-export Code MRI VoiceTag messages.
include VoiceTagMsg

/// Re-export Provenance Map messages.
include ProvenanceMsg

/// Re-export Watcher filesystem observation messages.
include WatcherMsg

/// Re-export AI panel messages.
include AiMsg

/// Re-export Repo Loader messages.
include RepoLoaderMsg

/// Re-export Panel Switcher messages.
include PanelSwitcherMsg

/// Re-export Workspace management messages.
include WorkspaceMsg

/// Re-export Capture messages.
include CaptureMsg

/// Re-export Security messages.
include SecurityMsg

/// Re-export Keybindings messages.
include KeybindingsMsg

/// Re-export Migration Observatory messages.
include MigrationMsg

/// Re-export panic-attack messages.
include PanicAttackMsg

/// Re-export Mass-panic batch scanning messages.
include MassPanicMsg

/// Re-export TSDM directive messages.
include TsdmMsg

/// Re-export Valence Shell terminal messages.
include ValenceShellMsg

/// Re-export Game Preview messages.
include GamePreviewMsg

/// Re-export VM Inspector messages.
include VmInspectorMsg

/// Re-export Network Topology messages.
include NetworkTopologyMsg

/// Re-export Level Architect messages.
include LevelArchitectMsg

/// Re-export Coprocessors messages.
include CoprocessorsMsg

/// Re-export Multiplayer Monitor messages.
include MultiplayerMonitorMsg

/// Re-export Universal Modding Studio messages.
include UmsMsg

/// Re-export DLC Workshop messages.
include DlcWorkshopMsg

/// Re-export Editor Bridge messages.
include EditorBridgeMsg

/// Re-export Build Dashboard messages.
include BuildDashboardMsg

/// Re-export Release Manager messages.
include ReleaseManagerMsg

/// Re-export Automation Router messages.
include AutomationRouterMsg

/// Re-export Script Gist messages.
include ScriptGistMsg

/// Re-export ENSAID_CONFIG messages.
include EnsaidConfigMsg

/// Re-export Code MRI Timeline messages.
include TimelineMsg

/// Re-export Code MRI Pattern Diagnostics messages (Layer 3).
include PatternDiagMsg

/// Re-export Code MRI Attribution-to-Licensing messages (Layer 4).
include AttributionLicenseMsg

/// Re-export Clade Browser messages.
include CladeBrowserMsg

/// Re-export Panel Bus messages.
include PanelBusMsg

/// Re-export 7-Tentacles compiler agent messages.
include TentaclesMsg

/// Re-export Protocol-Squisher messages.
include ProtocolSquisherMsg

/// Re-export My-Lang AI-native language messages.
include MyLangMsg

/// Re-export TypeLL verification kernel messages.
include TypellMsg

/// Re-export Observability messages.
include ObservabilityMsg

/// Re-export A2ML manifest messages.
include A2mlMsg

/// Re-export K9 contractile messages.
include K9Msg

/// Re-export Help system messages.
include HelpMsg

/// Re-export Accessibility toolbar messages.
include AccessibilityMsg

/// Re-export Tiling and multi-monitor messages.
include TilingMsg

/// Re-export Menu bar messages.
include MenuBarMsg

/// Re-export Focus dimming messages.
include FocusDimmingMsg

/// Re-export Stapeln container assembly messages.
include StapelnMsg

/// Re-export Evangeliser JS->ReScript messages.
include EvangeliserMsg

/// Re-export Language Forge messages.
include LanguageForgeMsg

/// Re-export TangleViz topological programming messages.
include TangleVizMsg

/// Re-export SpecBrowser language specification messages.
include SpecBrowserMsg

/// Re-export VerificationDashboard messages.
include VerificationDashboardMsg

/// Re-export Observatory integrative dashboard messages.
include ObservatoryMsg

/// Re-export AmbientOps hospital-model sysadmin messages.
include AmbientOpsMsg

// -- Game Testing panel messages -----------------------------------------

/// Re-export Unit Test Runner messages.
include UnitTestRunnerMsg

/// Re-export Functional Tester messages.
include FunctionalTesterMsg

/// Re-export Regression Guard messages.
include RegressionGuardMsg

/// Re-export Performance Profiler messages.
include PerformanceProfilerMsg

/// Re-export Load Tester messages.
include LoadTesterMsg

/// Re-export Soak Monitor messages.
include SoakMonitorMsg

/// Re-export Compatibility Matrix messages.
include CompatibilityMatrixMsg

/// Re-export Exploratory Workbench messages.
include ExploratoryWorkbenchMsg

/// Re-export Beta Feedback Hub messages.
include BetaFeedbackHubMsg

/// Re-export Balance Analyser messages.
include BalanceAnalyserMsg

// -- Bridge panel messages -----------------------------------------------

/// Re-export Typing Bridge messages.
include TypingBridgeMsg

/// Re-export Neurosymbolic Bridge messages.
include NeurosymBridgeMsg

/// Re-export Agentic Bridge messages.
include AgenticBridgeMsg

/// Re-export Automation Bridge messages.
include AutomationBridgeMsg

/// Re-export Database Bridge messages.
include DatabaseBridgeMsg

/// Re-export Protocol Bridge messages.
include ProtocolBridgeMsg

/// Re-export Proofs Bridge messages.
include ProofsBridgeMsg

/// Re-export Scripting Bridge messages.
include ScriptingBridgeMsg

// -- Game-specific panel messages ----------------------------------------

/// Re-export Generator Mode messages.
include GeneratorModeMsg

/// Re-export Architect Mode messages.
include ArchitectModeMsg

/// Re-export Guard AI Tuner messages.
include GuardAiTunerMsg

/// Re-export Device Network Designer messages.
include DeviceNetworkDesignerMsg

/// Re-export Asset Manager messages.
include AssetManagerMsg

/// Re-export Playtest Recorder messages.
include PlaytestRecorderMsg

// -- Team / collaboration panel messages ---------------------------------

/// Re-export Code Review messages.
include CodeReviewMsg

/// Re-export Merge Coordinator messages.
include MergeCoordinatorMsg

/// Re-export Team Dashboard messages.
include TeamDashboardMsg

/// Re-export Debugging Workbench messages.
include DebuggingWorkbenchMsg

// -- Infrastructure panel messages ---------------------------------------

/// Re-export Wiring Inspector messages.
include WiringInspectorMsg

// -- Floor Raise campaign messages ---------------------------------------

/// Re-export Floor Raise campaign dashboard messages.
include FloorRaiseMsg

/// Re-export Proven Adoption scanner messages.
include ProvenAdoptionMsg

/// Re-export Contractile Completeness scanner messages.
include ContractileCompletenessMsg

/// Re-export Manifest Coverage scanner messages.
include ManifestCoverageMsg

/// Re-export VeriSimDB Feeds viewer messages.
include VerisimdbFeedsMsg

/// Re-export Feedback Routing viewer messages.
include FeedbackRoutingMsg

/// Re-export Vexometer Friction viewer messages.
include VexometerFrictionMsg

// -- 007 Toolchain and VideoCoordination ---------------------------------

/// Re-export 007 Toolchain messages.
include Oo7Msg

/// Re-export VideoCoordination messages.
include VideoCoordinationMsg

// -- The unified message type --------------------------------------------

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
  | VoiceTag(voiceTagMsg) // Code MRI Layer 0 -- voice-activated annotation
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
  | Tsdm(tsdmMsg) // TSDM directive -- triaxial priority ordering
  | ValenceShell(valenceShellMsg) // Embedded terminal with Claude Code
  | GamePreview(gamePreviewMsg) // Live IDApTIK game preview
  | VmInspector(vmInspectorMsg) // Reversible VM visual debugger
  | NetworkTopology(networkTopologyMsg) // IDApTIK in-game network graph
  | LevelArchitect(levelArchitectMsg) // Visual level design tool
  | Coprocessors(coprocessorsMsg) // Coprocessor backend monitoring
  | MultiplayerMonitor(multiplayerMonitorMsg) // Phoenix sync server inspector
  | DlcWorkshop(dlcWorkshopMsg) // DLC puzzle pack creation and testing
  | Ums(umsMsg) // Universal Modding Studio -- unified game content creation hub
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
  | Timeline(timelineMsg) // Code MRI Layer 2 -- VeriSimDB development timeline
  | PatternDiag(patternDiagMsg) // Code MRI Layer 3 -- pattern diagnostics + gamification
  | AttrLicense(attributionLicenseMsg) // Code MRI Layer 4 -- attribution-to-licensing
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
  | Evangeliser(evangeliserMsg) // ReScript Evangeliser -- JS->ReScript teaching
  | LanguageForge(languageForgeMsg) // Language Forge -- nextgen-languages portfolio
  | TangleViz(tangleVizMsg) // Topological programming visualizer (braids, knots, invariants)
  | SpecBrowser(specBrowserMsg) // Language specification browser -- grammars, typing rules, taxonomy
  | VerificationDashboard(verificationDashboardMsg) // Proof/test/benchmark/fuzzing status
  | Observatory(observatoryMsg) // Integrative dashboard -- cross-panel health and resources
  | AmbientOps(ambientOpsMsg) // Hospital-model sysadmin -- clinician, network, hardware
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
  // Floor Raise panels -- foundational tool adoption campaign
  | FloorRaise(floorRaiseMsg) // Floor Raise campaign dashboard
  | ProvenAdoption(provenAdoptionMsg) // Proven library adoption scanner
  | ContractileCompleteness(contractileCompletenessMsg) // Contractile coverage scanner
  | ManifestCoverage(manifestCoverageMsg) // AI manifest coverage scanner
  | VerisimdbFeeds(verisimdbFeedsMsg) // VeriSimDB data feed viewer
  | FeedbackRouting(feedbackRoutingMsg) // Feedback-o-Tron routing viewer
  | VexometerFriction(vexometerFrictionMsg) // Vexometer friction viewer
  | SystemUpdate(SystemUpdateMsg.systemUpdateMsg) // System component update management
  | Burble(BurbleModel.burbleMsg) // Burble voice huddle (groove-aware)
  | Undo // Undo last significant action
  | Redo // Redo last undone action
  | SaveState // Persist current state to storage
  | NoOp
