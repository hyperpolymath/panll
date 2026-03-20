// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Panel Switcher Model — types for the unified panel navigation system.
///
/// Replaces the ad-hoc `visible: bool` pattern on individual overlays with
/// a single `activePanel` selector. At most one full-screen panel overlay
/// is active at a time. The three core panes (L, N, W) are always present
/// underneath.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Unique identifier for each panel module in PanLL.
/// Order here determines default panel bar ordering.
type panelId =
  | PanelCloudGuard
  | PanelVab
  | PanelFarm
  | PanelFleet
  | PanelHypatia
  | PanelReposystem
  | PanelDatabases
  | PanelAerie
  | PanelInterfaces
  | PanelPlaygrounds
  | PanelPlaza
  | PanelMinter
  | PanelProvisioner
  | PanelVoiceTag
  | PanelAi
  | PanelRepoLoader
  | PanelWorkspace
  | PanelCapture
  | PanelSecurity
  | PanelMigration
  | PanelPanicAttack
  | PanelMassPanic
  | PanelTsdm
  | PanelValenceShell
  | PanelGamePreview
  | PanelVmInspector
  | PanelNetworkTopology
  | PanelLevelArchitect
  | PanelCoprocessors
  | PanelMultiplayerMonitor
  | PanelDlcWorkshop
  | PanelEditorBridge
  | PanelBuildDashboard
  | PanelReleaseManager
  | PanelAutomationRouter
  | PanelScriptGist
  | PanelBoj
  | PanelCladeBrowser
  | PanelTentacles
  | PanelProtocolSquisher
  | PanelMyLang
  | PanelTypeLL
  /// ECHIDNA multi-solver theorem prover — proof dispatch, tactic suggestions.
  | PanelEchidna
  /// ReScript Evangeliser — JS→ReScript transformation teaching panel.
  | PanelEvangeliser
  /// In-application help system — searchable guides, glossary, onboarding.
  | PanelHelp
  /// Integrative dashboard — cross-panel health, resource usage, service status.
  | PanelObservatory
  /// AmbientOps — hospital-model sysadmin tools: clinician, network ambulance, hardware crash team.
  | PanelAmbientOps
  /// Language Forge — nextgen-languages portfolio monitoring and development dashboard.
  | PanelLanguageForge
  /// TangleViz — topological programming visualizer for braid/knot topology from the Tangle language.
  | PanelTangleViz
  /// SpecBrowser — browse all language specs, grammars, typing rules side-by-side.
  | PanelSpecBrowser
  /// VerificationDashboard — proof/test/benchmark/fuzzing status across all repos.
  | PanelVerificationDashboard
  /// Universal Modding Studio — unified hub for IDApTIK game content creation,
  /// ABI validation, asset pipeline, mod distribution, and cross-panel orchestration.
  | PanelUms
  /// Unit Test Runner — ReScript test execution, coverage heatmap, diff-aware.
  | PanelUnitTestRunner
  /// Functional Tester — end-to-end game workflow simulation.
  | PanelFunctionalTester
  /// Regression Guard — snapshot comparison and golden-file testing.
  | PanelRegressionGuard
  /// Performance Profiler — frame budget, GC pressure, memory flamegraphs.
  | PanelPerformanceProfiler
  /// Load Tester — Phoenix channel stress testing, concurrent simulation.
  | PanelLoadTester
  /// Soak Monitor — long-running session memory trend and leak detection.
  | PanelSoakMonitor
  /// Compatibility Matrix — browser/device/resolution test matrix.
  | PanelCompatibilityMatrix
  /// Exploratory Workbench — freeform play session recording, anomaly detection.
  | PanelExploratoryWorkbench
  /// Beta Feedback Hub — feedback-o-tron integration, sentiment, triage.
  | PanelBetaFeedbackHub
  /// Balance Analyser — game balance stats, Monte Carlo, difficulty curves.
  | PanelBalanceAnalyser
  /// Typing Bridge — TypeLL type constraints for game state.
  | PanelTypingBridge
  /// Neurosymbolic Bridge — guard AI behaviour reasoning via ECHIDNA.
  | PanelNeurosymBridge
  /// Agentic Bridge — automated playtesting agents with OODA loop.
  | PanelAgenticBridge
  /// Automation Bridge — CI/CD pipeline orchestration for game builds.
  | PanelAutomationBridge
  /// Database Bridge — VeriSimDB game state persistence.
  | PanelDatabaseBridge
  /// Protocol Bridge — multiplayer sync protocol analysis.
  | PanelProtocolBridge
  /// Proofs Bridge — proven repo formal verification integration.
  | PanelProofsBridge
  /// Scripting Bridge — VM instruction scripting REPL.
  | PanelScriptingBridge
  /// Generator Mode — parametric procedural world builder.
  | PanelGeneratorMode
  /// Architect Mode — PixiJS fine-grained level editor with L/N/W.
  | PanelArchitectMode
  /// Guard AI Tuner — guard patrol, alert threshold, spawn rate tuning.
  | PanelGuardAiTuner
  /// Device Network Designer — wire devices, configure security levels.
  | PanelDeviceNetworkDesigner
  /// Asset Manager — PixiJS sprites, sounds, level templates.
  | PanelAssetManager
  /// Playtest Recorder — record + replay sessions, annotate moments.
  | PanelPlaytestRecorder
  /// Code Review — PR review, inline comments, approval gates.
  | PanelCodeReview
  /// Merge Coordinator — branch management, conflict resolution.
  | PanelMergeCoordinator
  /// Team Dashboard — who's working on what, activity feed.
  | PanelTeamDashboard
  /// Debugging Workbench — Tea_Debug frontend, time-travel state inspection.
  | PanelDebuggingWorkbench
  /// Wiring Inspector — PCC constraint state, obligation graph, bottleneck analysis.
  | PanelWiringInspector
  /// K9 Manager — self-validating K9 contractile file management.
  | PanelK9Manager
  /// Contractile Manager — cognitive governance dashboard for the 11 built-in contractiles.
  | PanelContractileManager
  // Floor Raise panels — foundational tool adoption campaign
  /// Floor Raise campaign — foundational tool adoption dashboard.
  | PanelFloorRaise
  /// Proven adoption scanner — which repos use formally verified safety primitives.
  | PanelProvenAdoption
  /// Contractile completeness scanner — Mustfile/Trustfile/Dustfile/K9 coverage.
  | PanelContractileCompleteness
  /// AI manifest coverage scanner — 0-AI-MANIFEST.a2ml presence.
  | PanelManifestCoverage
  /// VeriSimDB data feeds viewer — cross-repo analytics health.
  | PanelVerisimdbFeeds
  /// Feedback-o-Tron routing viewer — upstream bug report status.
  | PanelFeedbackRouting
  /// Vexometer friction viewer — irritation surface measurements.
  | PanelVexometerFriction

/// Connection status for panels backed by external services.
type connectionStatus =
  | ServiceConnected
  | ServiceDisconnected
  | ServiceChecking
  | ServiceError(string)

/// Metadata for a registered panel — used by the panel bar to render
/// icons, labels, and connection indicators.
type panelMeta = {
  id: panelId,
  name: string,
  shortName: string,
  description: string,
  icon: string,
  connectionStatus: connectionStatus,
  /// Whether this panel has a backend service to connect to.
  hasBackend: bool,
  /// Clade ID this panel belongs to (for trait inheritance queries).
  cladeId: option<string>,
}

/// Root state for the panel switcher.
type panelSwitcherState = {
  /// Currently active full-screen overlay panel (None = show core panes).
  activePanel: option<panelId>,
  /// Ordered list of panel IDs for the panel bar.
  panelOrder: array<panelId>,
  /// Registry of panel metadata indexed by panel ID.
  /// Stored as array (not Map) for ReScript simplicity.
  panels: array<panelMeta>,
  /// Currently expanded group in the sidebar (kind name, e.g. "ai", "bridge").
  /// None means all groups are collapsed — only group headers visible.
  expandedGroup: option<string>,
}
