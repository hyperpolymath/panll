// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Panel Registry — canonical registry of all panel modules.
///
/// Central source of truth for panel metadata. The panel bar component
/// reads this to render icons and labels. New panels are added here
/// first, then wired into Model/Msg/Update/View.

open PanelSwitcherModel

/// All registered panels with their metadata. Order determines
/// default panel bar layout.
let allPanels: array<panelMeta> = [
  {
    id: PanelCloudGuard,
    name: "CloudGuard",
    shortName: "CG",
    description: "Cloudflare domain security management",
    icon: "shield",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("cloudguard"),
  },
  {
    id: PanelVab,
    name: "VAB",
    shortName: "VAB",
    description: "Verified Assembly Building — server component composer",
    icon: "rocket",
    connectionStatus: ServiceConnected, // VAB is local catalog, always "connected"
    hasBackend: false,
    cladeId: Some("vab"),
  },
  {
    id: PanelFarm,
    name: "Farm",
    shortName: "Farm",
    description: "Repository admin registry and maintenance hub",
    icon: "barn",
    connectionStatus: ServiceDisconnected,
    hasBackend: false, // Reads local JSON, no HTTP service
    cladeId: Some("farm"),
  },
  {
    id: PanelFleet,
    name: "Fleet",
    shortName: "Fleet",
    description: "Gitbot fleet orchestration and dispatch",
    icon: "bots",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("fleet"),
  },
  {
    id: PanelHypatia,
    name: "Hypatia",
    shortName: "Hyp",
    description: "Neurosymbolic CI/CD intelligence",
    icon: "brain",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("hypatia"),
  },
  {
    id: PanelReposystem,
    name: "Reposystem",
    shortName: "RSR",
    description: "RSR compliance and template management",
    icon: "layers",
    connectionStatus: ServiceDisconnected,
    hasBackend: false, // Filesystem scanning
    cladeId: Some("reposystem"),
  },
  {
    id: PanelDatabases,
    name: "Databases",
    shortName: "DB",
    description: "VeriSimDB, QuandleDB, LithoGlyph management",
    icon: "database",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("databases"),
  },
  {
    id: PanelAerie,
    name: "Aerie",
    shortName: "Net",
    description: "Network diagnostics and BGP forensics",
    icon: "network",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("aerie"),
  },
  {
    id: PanelInterfaces,
    name: "Interfaces",
    shortName: "FFI",
    description: "Language bridges, ABI/FFI inventory",
    icon: "bridge",
    connectionStatus: ServiceDisconnected,
    hasBackend: false, // Filesystem scanning
    cladeId: Some("interfaces"),
  },
  {
    id: PanelPlaygrounds,
    name: "Playgrounds",
    shortName: "Play",
    description: "Code sandbox, NQC console, tutorials",
    icon: "terminal",
    connectionStatus: ServiceDisconnected,
    hasBackend: true, // NQC proxy + database connections
    cladeId: Some("playgrounds"),
  },
  {
    id: PanelPlaza,
    name: "Palimpsest Plaza",
    shortName: "PMPL",
    description: "PMPL license adoption, compliance, and governance hub",
    icon: "scroll",
    connectionStatus: ServiceConnected, // Local scanning, always available
    hasBackend: false, // Filesystem scanning + CLI tools
    cladeId: Some("plaza"),
  },
  {
    id: PanelMinter,
    name: "Minter",
    shortName: "Mint",
    description: "Panel creation wizard — generate accessible panel modules from templates",
    icon: "wand",
    connectionStatus: ServiceConnected, // Local generation, always available
    hasBackend: true, // Tauri backend generates files and patches wiring
    cladeId: Some("minter"),
  },
  {
    id: PanelProvisioner,
    name: "Provisioner",
    shortName: "Prov",
    description: "Portfolio bundles, panel configuration, and isolation tier management",
    icon: "package",
    connectionStatus: ServiceConnected, // Local state management, always available
    hasBackend: false, // Configuration is local; container ops handled by Stapeln/Podman
    cladeId: Some("provisioner"),
  },
  {
    id: PanelVoiceTag,
    name: "Code MRI",
    shortName: "MRI",
    description: "Voice-activated code annotation — tags stored as portable .mri.json sidecars",
    icon: "mic",
    connectionStatus: ServiceConnected, // Local filesystem I/O, always available
    hasBackend: false, // Reads/writes .mri.json sidecar files, no HTTP service
    cladeId: Some("voicetag"),
  },
  {
    id: PanelAi,
    name: "AI",
    shortName: "AI",
    description: "Multi-provider AI neural interface — Claude, Gemini, Mistral, GPT, local models",
    icon: "brain-circuit",
    connectionStatus: ServiceDisconnected, // Connects to external AI providers
    hasBackend: true, // HTTP calls to AI provider APIs
    cladeId: Some("ai"),
  },
  {
    id: PanelRepoLoader,
    name: "Repo Loader",
    shortName: "Repo",
    description: "Repository scanner and panel configuration — load a repo, configure panels",
    icon: "folder-open",
    connectionStatus: ServiceConnected, // Local filesystem scanning, always available
    hasBackend: true, // Scans filesystem and reads manifests via Tauri
    cladeId: Some("repoloader"),
  },
  {
    id: PanelWorkspace,
    name: "Workspace",
    shortName: "WS",
    description: "Panel arrangements, groups, sessions, modes, and configurator",
    icon: "layout",
    connectionStatus: ServiceConnected, // Local state management, always available
    hasBackend: true, // System info queries via Tauri
    cladeId: Some("workspace"),
  },
  {
    id: PanelCapture,
    name: "Capture",
    shortName: "Cap",
    description: "Screenshots, recordings, demos, panel cloning, and comparison views",
    icon: "camera",
    connectionStatus: ServiceConnected, // Local file I/O, always available
    hasBackend: true, // File saving via Tauri
    cladeId: Some("capture"),
  },
  {
    id: PanelSecurity,
    name: "Security",
    shortName: "Sec",
    description: "Secrets redaction, vault, 2FA, Trustfile enforcement, shoulder-safe mode",
    icon: "lock",
    connectionStatus: ServiceConnected, // Local + vault CLI, always available
    hasBackend: true, // Redaction regex + vault I/O via Tauri
    cladeId: Some("security"),
  },
  {
    id: PanelMigration,
    name: "Migration",
    shortName: "Mig",
    description: "ReScript Migration Observatory — health tracking, sessions, submissions, merge resolver",
    icon: "migration",
    connectionStatus: ServiceDisconnected, // Connects to feedback-o-tron MCP + panic-attack
    hasBackend: true, // panic-attack CLI + feedback-o-tron MCP server
    cladeId: Some("migration"),
  },
  {
    id: PanelPanicAttack,
    name: "panic-attack",
    shortName: "PA",
    description: "Stress testing and logic-based bug signature detection — 47 languages, 20 categories",
    icon: "zap",
    connectionStatus: ServiceDisconnected, // Probes for local panic-attack binary
    hasBackend: true, // Invokes panic-attack CLI via Tauri
    cladeId: Some("panic-attack"),
  },
  {
    id: PanelMassPanic,
    name: "Mass Panic",
    shortName: "MP",
    description: "Organisation-scale batch scanning — assemblyline + BLAKE3 + verisimdb + delta",
    icon: "zap-off",
    connectionStatus: ServiceDisconnected, // Probes for panic-attack binary
    hasBackend: true, // Invokes panic-attack assemblyline via Tauri
    cladeId: Some("mass-panic"),
  },
  {
    id: PanelTsdm,
    name: "TSDM",
    shortName: "TSD",
    description: "Triaxial Software Development Methodology — directive panel for priority ordering across all panels",
    icon: "compass",
    connectionStatus: ServiceConnected, // Pure client-side state, always available
    hasBackend: false, // Directive state is local; optional verisimdb persistence
    cladeId: Some("tsdm"),
  },
  {
    id: PanelValenceShell,
    name: "Valence Shell",
    shortName: "VS",
    description: "Embedded terminal with Claude Code, session recording, reversible ops, and collaborative approval gate",
    icon: "terminal-square",
    connectionStatus: ServiceDisconnected, // Probes for Valence shell binary + PTY allocation
    hasBackend: true, // PTY via Tauri shell plugin + Valence binary
    cladeId: Some("valence-shell"),
  },
  {
    id: PanelGamePreview,
    name: "Game Preview",
    shortName: "Game",
    description: "Live IDApTIK game preview with hot-reload, frame stepping, overlays, and gameplay recording",
    icon: "gamepad-2",
    connectionStatus: ServiceDisconnected, // Probes for Vite dev server on :8080
    hasBackend: true, // Embedded iframe/webview + Tauri game control bridge
    cladeId: Some("game-preview"),
  },
  {
    id: PanelVmInspector,
    name: "VM Inspector",
    shortName: "VM",
    description: "Reversible VM visual debugger — stack, memory, instructions, step forward and backward",
    icon: "cpu",
    connectionStatus: ServiceDisconnected, // Connects to running VM via inter-webview or file
    hasBackend: true, // Tauri inter-webview messaging or file I/O
    cladeId: Some("vm-inspector"),
  },
  {
    id: PanelNetworkTopology,
    name: "Network Topology",
    shortName: "Topo",
    description: "Force-directed graph of IDApTIK in-game network — devices, zones, security levels, packet flow",
    icon: "network",
    connectionStatus: ServiceDisconnected, // Reads from running game via inter-webview
    hasBackend: true, // Inter-webview messaging to game instance
    cladeId: Some("network-topology"),
  },
  {
    id: PanelLevelArchitect,
    name: "Level Architect",
    shortName: "Lvl",
    description: "Visual level design — device placement, guard patrols, defence flags, validation, LevelConfig export",
    icon: "map",
    connectionStatus: ServiceDisconnected, // File I/O for level data
    hasBackend: true, // Tauri file I/O + validation
    cladeId: Some("level-architect"),
  },
  {
    id: PanelCoprocessors,
    name: "Coprocessors",
    shortName: "CoPr",
    description: "Monitor IDApTIK's 10 coprocessor backends — call log, heatmap, performance, health",
    icon: "chip",
    connectionStatus: ServiceDisconnected, // Reads from running game
    hasBackend: true, // Inter-webview messaging to game instance
    cladeId: Some("coprocessors"),
  },
  {
    id: PanelMultiplayerMonitor,
    name: "Multiplayer Monitor",
    shortName: "MP",
    description: "Monitor Elixir/Phoenix sync server — WebSocket, channels, player state, Lamport clocks, latency",
    icon: "users",
    connectionStatus: ServiceDisconnected, // WebSocket to Phoenix server
    hasBackend: true, // Phoenix WebSocket on :4000
    cladeId: Some("multiplayer-monitor"),
  },
  {
    id: PanelDlcWorkshop,
    name: "DLC Workshop",
    shortName: "DLC",
    description: "Create, test, and package DLC puzzle packs — VM composer, solution testing, asset bundling",
    icon: "puzzle",
    connectionStatus: ServiceDisconnected, // File I/O for DLC data
    hasBackend: true, // Tauri file I/O + test runner
    cladeId: Some("dlc-workshop"),
  },
  {
    id: PanelEditorBridge,
    name: "Editor Bridge",
    shortName: "EB",
    description: "Federate with external code editors — LSP diagnostics, symbols, open files, jump-to-line",
    icon: "file-code",
    connectionStatus: ServiceDisconnected, // LSP connection to external editor
    hasBackend: true, // LSP protocol via Tauri
    cladeId: Some("editor-bridge"),
  },
  {
    id: PanelBuildDashboard,
    name: "Build Dashboard",
    shortName: "Bld",
    description: "Monitor builds, tests, errors, and compilation status across IDApTIK sub-projects",
    icon: "hammer",
    connectionStatus: ServiceDisconnected, // Build process monitoring
    hasBackend: true, // Tauri build process invocation
    cladeId: Some("build-dashboard"),
  },
  {
    id: PanelReleaseManager,
    name: "Release Manager",
    shortName: "Rel",
    description: "Versioning, changelog, artifact building, signing, and distribution of IDApTIK builds",
    icon: "package-check",
    connectionStatus: ServiceDisconnected, // Release pipeline
    hasBackend: true, // Tauri release process invocation
    cladeId: Some("release-manager"),
  },
  {
    id: PanelAutomationRouter,
    name: "Automation Router",
    shortName: "Auto",
    description: "Hybrid cross-panel workflow orchestration — event-driven rules with approval gates",
    icon: "route",
    connectionStatus: ServiceConnected, // Local rule engine, always available
    hasBackend: true, // Tauri rule execution + .machine_readable/ENSAID_CONFIG.a2ml reading
    cladeId: Some("automation-router"),
  },
  {
    id: PanelScriptGist,
    name: "Script Gist",
    shortName: "Gist",
    description: "Portable computation gists — Minskian diachronic scripts (time) and synchronic schemata (space) as cardfiles, LLM-callable via MCP",
    icon: "file-code",
    connectionStatus: ServiceConnected, // Local gist engine, always available
    hasBackend: false, // Pure TEA state + optional Tauri persistence
    cladeId: Some("script-gist"),
  },
  {
    id: PanelBoj,
    name: "BoJ",
    shortName: "BoJ",
    description: "Bundle of Joy — unified cartridge server with 17 domains (incl. LSP/DAP/BSP), 3-layer ABI/FFI/Adapter, Umoja federation",
    icon: "box",
    connectionStatus: ServiceDisconnected, // Probes BoJ server at :7700
    hasBackend: true, // HTTP proxy to BoJ server via Tauri
    cladeId: Some("boj"),
  },
  {
    id: PanelCladeBrowser,
    name: "Clade Browser",
    shortName: "Clade",
    description: "Explore and customise panel clades — taxonomy, traits, kind filtering, panel-to-clade mapping",
    icon: "dna",
    connectionStatus: ServiceConnected, // Local taxonomy data, always available
    hasBackend: false, // Reads clade .a2ml files from filesystem
    cladeId: Some("clade-browser"),
  },
  {
    id: PanelTentacles,
    name: "7-Tentacles",
    shortName: "Tentacles",
    description: "Compiler agent orchestra — 7 colour-coded agents with OODA reasoning, progressive cephalopod staging, and ECHIDNA FFI bridge",
    icon: "cpu",
    connectionStatus: ServiceDisconnected, // FFI bridge checked on demand
    hasBackend: true, // ECHIDNA V-lang REST adapters
    cladeId: Some("tentacles"),
  },
  {
    id: PanelProtocolSquisher,
    name: "Protocol-Squisher",
    shortName: "Squisher",
    description: "13-format schema analysis — transport class classification, compatibility comparison, adapter cost estimation",
    icon: "layers",
    connectionStatus: ServiceDisconnected, // CLI checked on demand
    hasBackend: true, // Invokes protocol-squisher CLI
    cladeId: Some("protocol-squisher"),
  },
  {
    id: PanelMyLang,
    name: "My-Lang",
    shortName: "My-Lang",
    description: "AI-native language workbench — 4 dialects (Solo, Duet, Ensemble, Me), REPL, compiler, and LSP integration",
    icon: "code",
    connectionStatus: ServiceDisconnected, // CLI checked on demand
    hasBackend: true, // Invokes my-lang CLI
    cladeId: Some("my-lang"),
  },
  {
    id: PanelTypeLL,
    name: "TypeLL",
    shortName: "TypeLL",
    description: "Verification kernel — dependent, linear, affine, session, and refinement types with progressive disclosure and cross-panel type intelligence",
    icon: "shield",
    connectionStatus: ServiceDisconnected, // Server checked on demand
    hasBackend: true, // TypeLL server at TYPELL_URL
    cladeId: Some("typell"),
  },
  {
    id: PanelEvangeliser,
    name: "Evangeliser",
    shortName: "Evan",
    description: "ReScript Evangeliser — JS-to-ReScript transformation teaching with 52 patterns, Makaton glyphs, and celebrate/minimize/better narratives",
    icon: "sparkles",
    connectionStatus: ServiceConnected, // Pure local logic, always available
    hasBackend: false, // All pattern matching runs client-side
    cladeId: Some("evangeliser"),
  },
  {
    id: PanelHelp,
    name: "Help",
    shortName: "Help",
    description: "In-application help — searchable guides, neurosymbolic glossary, keyboard shortcuts, onboarding walkthrough",
    icon: "help-circle",
    connectionStatus: ServiceConnected, // Local content, always available
    hasBackend: false, // All content is static, no backend service
    cladeId: Some("help"),
  },
  {
    id: PanelEchidna,
    name: "ECHIDNA",
    shortName: "ECH",
    description: "Multi-solver theorem prover — proof dispatch, tactic suggestions, enterprise model checking",
    icon: "shield-check",
    connectionStatus: ServiceDisconnected, // Connects to ECHIDNA service
    hasBackend: true, // ECHIDNA V-lang REST adapters
    cladeId: Some("echidna"),
  },
  {
    id: PanelObservatory,
    name: "Observatory",
    shortName: "Obs",
    description: "Integrative dashboard — cross-panel health, service status, resource usage, ambient metrics",
    icon: "activity",
    connectionStatus: ServiceConnected, // Aggregates local state, always available
    hasBackend: true, // Queries Tauri for system info + panel health
    cladeId: Some("observatory"),
  },
  {
    id: PanelAmbientOps,
    name: "AmbientOps",
    shortName: "Ops",
    description: "Hospital-model sysadmin — clinician, network ambulance, hardware crash team, emergency room",
    icon: "stethoscope",
    connectionStatus: ServiceDisconnected, // Probes for ambientops services
    hasBackend: true, // Invokes clinician/network-repair CLIs via Tauri
    cladeId: Some("ambientops"),
  },
  {
    id: PanelLanguageForge,
    name: "Language Forge",
    shortName: "Forge",
    description: "Monitor and develop the 14 nextgen-languages portfolio — scores, phases, WASM readiness",
    icon: "hammer",
    connectionStatus: ServiceConnected, // Hardcoded data, always available
    hasBackend: false, // Pure client-side data, no HTTP service
    cladeId: Some("language-forge"),
  },
  {
    id: PanelTangleViz,
    name: "Tangle Viz",
    shortName: "Tangle",
    description: "Topological programming visualizer — braid diagrams, knot invariants, Tangle source parsing",
    icon: "knot",
    connectionStatus: ServiceConnected, // Pure client-side, always available
    hasBackend: false, // All computation runs client-side
    cladeId: Some("tangle-viz"),
  },
  {
    id: PanelSpecBrowser,
    name: "Spec Browser",
    shortName: "Spec",
    description: "Browse all 16 language specs, grammars, typing rules — side-by-side comparison and taxonomy completeness",
    icon: "book-open",
    connectionStatus: ServiceConnected, // Hardcoded data + filesystem reads, always available
    hasBackend: false, // Pure client-side data, no HTTP service
    cladeId: Some("spec-browser"),
  },
  {
    id: PanelVerificationDashboard,
    name: "Verification Dashboard",
    shortName: "Verify",
    description: "Proof/test/benchmark/fuzzing status across all nextgen-languages repos",
    icon: "check-circle",
    connectionStatus: ServiceConnected, // Hardcoded audit data, always available
    hasBackend: false, // Pure client-side data, no HTTP service
    cladeId: Some("verification-dashboard"),
  },
  {
    id: PanelUms,
    name: "Universal Modding Studio",
    shortName: "UMS",
    description: "Unified hub for IDApTIK game content creation — project management, ABI validation, asset pipeline, mod distribution",
    icon: "wrench",
    connectionStatus: ServiceDisconnected, // File I/O + ABI validation
    hasBackend: true, // Tauri file I/O + validation engine
    cladeId: Some("ums"),
  },
  // ── Game Testing panels ───────────────────────────────────────────────
  {
    id: PanelUnitTestRunner,
    name: "Unit Test Runner",
    shortName: "UTR",
    description: "ReScript test execution, coverage heatmap, diff-aware testing",
    icon: "test-tube",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("unit-test-runner"),
  },
  {
    id: PanelFunctionalTester,
    name: "Functional Tester",
    shortName: "FT",
    description: "End-to-end game workflow simulation and assertion checking",
    icon: "list-checks",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("functional-tester"),
  },
  {
    id: PanelRegressionGuard,
    name: "Regression Guard",
    shortName: "RG",
    description: "Snapshot comparison and golden-file testing for regressions",
    icon: "shield-alert",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("regression-guard"),
  },
  {
    id: PanelPerformanceProfiler,
    name: "Performance Profiler",
    shortName: "Perf",
    description: "Frame budget, GC pressure, memory flamegraphs, bottleneck detection",
    icon: "flame",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("performance-profiler"),
  },
  {
    id: PanelLoadTester,
    name: "Load Tester",
    shortName: "Load",
    description: "Phoenix channel stress testing, concurrent player simulation",
    icon: "gauge",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("load-tester"),
  },
  {
    id: PanelSoakMonitor,
    name: "Soak Monitor",
    shortName: "Soak",
    description: "Long-running session memory trend analysis and leak detection",
    icon: "droplets",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("soak-monitor"),
  },
  {
    id: PanelCompatibilityMatrix,
    name: "Compatibility Matrix",
    shortName: "Compat",
    description: "Browser, device, and resolution test matrix management",
    icon: "grid-3x3",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("compatibility-matrix"),
  },
  {
    id: PanelExploratoryWorkbench,
    name: "Exploratory Workbench",
    shortName: "Explore",
    description: "Freeform play session recording and anomaly detection",
    icon: "search",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("exploratory-workbench"),
  },
  {
    id: PanelBetaFeedbackHub,
    name: "Beta Feedback Hub",
    shortName: "Beta",
    description: "Feedback-o-tron integration, sentiment analysis, triage queue",
    icon: "message-circle",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("beta-feedback-hub"),
  },
  {
    id: PanelBalanceAnalyser,
    name: "Balance Analyser",
    shortName: "Bal",
    description: "Game balance stats, Monte Carlo simulation, difficulty curves",
    icon: "scale",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("balance-analyser"),
  },
  // ── Bridge panels ─────────────────────────────────────────────────────
  {
    id: PanelTypingBridge,
    name: "Typing Bridge",
    shortName: "TyB",
    description: "TypeLL type constraints for game state — cross-panel type intelligence bridge",
    icon: "type",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("typing-bridge"),
  },
  {
    id: PanelNeurosymBridge,
    name: "Neurosymbolic Bridge",
    shortName: "NsB",
    description: "Guard AI behaviour reasoning via ECHIDNA neurosymbolic integration",
    icon: "brain",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("neurosym-bridge"),
  },
  {
    id: PanelAgenticBridge,
    name: "Agentic Bridge",
    shortName: "AgB",
    description: "Automated playtesting agents with OODA loop reasoning",
    icon: "bot",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("agentic-bridge"),
  },
  {
    id: PanelAutomationBridge,
    name: "Automation Bridge",
    shortName: "AuB",
    description: "CI/CD pipeline orchestration for game builds and deployment",
    icon: "workflow",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("automation-bridge"),
  },
  {
    id: PanelDatabaseBridge,
    name: "Database Bridge",
    shortName: "DbB",
    description: "VeriSimDB game state persistence and query bridge",
    icon: "database",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("database-bridge"),
  },
  {
    id: PanelProtocolBridge,
    name: "Protocol Bridge",
    shortName: "PrB",
    description: "Multiplayer sync protocol analysis and debugging",
    icon: "arrow-left-right",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("protocol-bridge"),
  },
  {
    id: PanelProofsBridge,
    name: "Proofs Bridge",
    shortName: "PfB",
    description: "Proven repo formal verification integration bridge",
    icon: "check-check",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("proofs-bridge"),
  },
  {
    id: PanelScriptingBridge,
    name: "Scripting Bridge",
    shortName: "ScB",
    description: "VM instruction scripting REPL for game logic development",
    icon: "terminal",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("scripting-bridge"),
  },
  // ── Game-specific panels ──────────────────────────────────────────────
  {
    id: PanelGeneratorMode,
    name: "Generator Mode",
    shortName: "Gen",
    description: "Parametric procedural world builder with constraint-based generation",
    icon: "wand",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("generator-mode"),
  },
  {
    id: PanelArchitectMode,
    name: "Architect Mode",
    shortName: "Arch",
    description: "PixiJS fine-grained level editor with L/N/W pane integration",
    icon: "ruler",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("architect-mode"),
  },
  {
    id: PanelGuardAiTuner,
    name: "Guard AI Tuner",
    shortName: "GAI",
    description: "Guard patrol paths, alert thresholds, spawn rate tuning",
    icon: "shield",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("guard-ai-tuner"),
  },
  {
    id: PanelDeviceNetworkDesigner,
    name: "Device Network Designer",
    shortName: "DND",
    description: "Wire devices together, configure security levels and zones",
    icon: "circuit-board",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("device-network-designer"),
  },
  {
    id: PanelAssetManager,
    name: "Asset Manager",
    shortName: "Asset",
    description: "PixiJS sprites, sounds, level templates, and asset pipeline",
    icon: "image",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("asset-manager"),
  },
  {
    id: PanelPlaytestRecorder,
    name: "Playtest Recorder",
    shortName: "Play",
    description: "Record and replay game sessions, annotate key moments",
    icon: "video",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("playtest-recorder"),
  },
  // ── Team / collaboration panels ─────────────────────────────────────────
  {
    id: PanelCodeReview,
    name: "Code Review",
    shortName: "CR",
    description: "Pull request review, inline comments, file changes, and approval gates",
    icon: "eye",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("code-review"),
  },
  {
    id: PanelMergeCoordinator,
    name: "Merge Coordinator",
    shortName: "Merge",
    description: "Branch management, conflict resolution, merge queue, and history",
    icon: "git-merge",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("merge-coordinator"),
  },
  {
    id: PanelTeamDashboard,
    name: "Team Dashboard",
    shortName: "Team",
    description: "Team presence, activity feed, progress tracking, and schedule",
    icon: "users",
    connectionStatus: ServiceConnected,
    hasBackend: false,
    cladeId: Some("team-dashboard"),
  },
  {
    id: PanelDebuggingWorkbench,
    name: "Debugging Workbench",
    shortName: "Debug",
    description: "Time-travel debugging, state tree inspection, watch expressions, and console",
    icon: "bug",
    connectionStatus: ServiceConnected,
    hasBackend: false,
    cladeId: Some("debugging-workbench"),
  },
  // ── Infrastructure panels ───────────────────────────────────────────
  {
    id: PanelWiringInspector,
    name: "Wiring Inspector",
    shortName: "Wiring",
    description: "Constraint-aware panel wiring verification and bottleneck analysis",
    icon: "plug-zap",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
    cladeId: Some("wiring-inspector"),
  },
  {
    id: PanelK9Manager,
    name: "K9 Manager",
    shortName: "K9",
    description: "Self-validating K9 contractile file management — Kennel/Yard/Hunt security levels",
    icon: "dog",
    connectionStatus: ServiceConnected, // Local file I/O, always available
    hasBackend: true, // Tauri file I/O for loading .k9.ncl files
    cladeId: Some("k9-manager"),
  },
  {
    id: PanelContractileManager,
    name: "Contractile Manager",
    shortName: "Ctrl",
    description: "Cognitive governance dashboard — 11 contractiles with elastic enforcement and vexation tracking",
    icon: "shield-check",
    connectionStatus: ServiceConnected, // Pure client-side state, always available
    hasBackend: false, // All contractile evaluation runs client-side
    cladeId: Some("contractile-manager"),
  },
  // ── Floor Raise campaign panels ─────────────────────────────────────────
  {
    id: PanelFloorRaise,
    name: "Floor Raise",
    shortName: "FR",
    description: "Floor Raise campaign — foundational tool adoption dashboard",
    icon: "trending-up",
    connectionStatus: ServiceDisconnected, // Reads verisimdb data
    hasBackend: true, // VeriSimDB queries for adoption metrics
    cladeId: Some("floor-raise"),
  },
  {
    id: PanelProvenAdoption,
    name: "Proven Adoption",
    shortName: "PrA",
    description: "Proven library adoption — which repos use formally verified safety primitives",
    icon: "check-circle",
    connectionStatus: ServiceConnected, // Filesystem scanning, always available
    hasBackend: false, // Pure filesystem scanning
    cladeId: Some("proven-adoption"),
  },
  {
    id: PanelContractileCompleteness,
    name: "Contractile Completeness",
    shortName: "CC",
    description: "Contractile completeness — Mustfile/Trustfile/Dustfile/K9 coverage",
    icon: "file-check",
    connectionStatus: ServiceConnected, // Filesystem scanning, always available
    hasBackend: false, // Pure filesystem scanning
    cladeId: Some("contractile-completeness"),
  },
  {
    id: PanelManifestCoverage,
    name: "Manifest Coverage",
    shortName: "MC",
    description: "AI manifest coverage — 0-AI-MANIFEST.a2ml presence across all repos",
    icon: "clipboard-check",
    connectionStatus: ServiceConnected, // Filesystem scanning, always available
    hasBackend: false, // Pure filesystem scanning
    cladeId: Some("manifest-coverage"),
  },
  {
    id: PanelVerisimdbFeeds,
    name: "VeriSimDB Feeds",
    shortName: "VF",
    description: "VeriSimDB data feeds — cross-repo analytics health and flow",
    icon: "activity",
    connectionStatus: ServiceDisconnected, // Connects to VeriSimDB
    hasBackend: true, // VeriSimDB queries
    cladeId: Some("verisimdb-feeds"),
  },
  {
    id: PanelFeedbackRouting,
    name: "Feedback Routing",
    shortName: "FBR",
    description: "Feedback-o-Tron routing — upstream bug report status and integration map",
    icon: "message-circle",
    connectionStatus: ServiceDisconnected, // Connects to feedback-o-tron
    hasBackend: true, // HTTP calls to feedback platforms
    cladeId: Some("feedback-routing"),
  },
  {
    id: PanelVexometerFriction,
    name: "Vexometer Friction",
    shortName: "VxF",
    description: "Vexometer friction — irritation surface measurements across tools",
    icon: "gauge",
    connectionStatus: ServiceDisconnected, // Connects to vexometer backend
    hasBackend: true, // Vexometer measurement queries
    cladeId: Some("vexometer-friction"),
  },
]

/// Look up panel metadata by ID.
let findPanel = (id: panelId): option<panelMeta> => {
  allPanels->Array.find(p => p.id === id)
}

/// Get the display name for a panel ID.
let panelName = (id: panelId): string => {
  switch findPanel(id) {
  | Some(p) => p.name
  | None => "Unknown"
  }
}

/// Default panel order (all panels).
let defaultOrder: array<panelId> = allPanels->Array.map(p => p.id)

// ════════════════════════════════════════════════════════════════════════
// Clade-aware capability queries
// ════════════════════════════════════════════════════════════════════════

/// Get the clade ID for a panel.
let panelCladeId = (id: panelId): option<string> => {
  switch findPanel(id) {
  | Some(p) => p.cladeId
  | None => None
  }
}

/// Get the effective traits for a panel by resolving clade inheritance.
/// Returns None if the panel has no clade or the clade isn't found.
let panelTraits = (id: panelId, clades: array<CladeBrowserModel.cladeEntry>): option<CladeBrowserModel.cladeTraits> => {
  switch panelCladeId(id) {
  | None => None
  | Some(cid) => CladeBrowserEngine.resolveTraits(clades, cid)
  }
}

/// Check if a panel has a specific trait (via clade inheritance).
let panelHasTrait = (
  id: panelId,
  clades: array<CladeBrowserModel.cladeEntry>,
  getter: CladeBrowserModel.cladeTraits => bool,
): bool => {
  switch panelTraits(id, clades) {
  | None => false
  | Some(traits) => getter(traits)
  }
}

/// Get all panels that have a specific trait (via clade inheritance).
let panelsWithTrait = (
  clades: array<CladeBrowserModel.cladeEntry>,
  getter: CladeBrowserModel.cladeTraits => bool,
): array<panelMeta> => {
  allPanels->Array.filter(p => panelHasTrait(p.id, clades, getter))
}

/// Get all panels that belong to a specific clade.
let panelsInClade = (cladeId: string): array<panelMeta> => {
  allPanels->Array.filter(p => p.cladeId == Some(cladeId))
}

/// Initial panel switcher state.
let init: panelSwitcherState = {
  activePanel: None,
  panelOrder: defaultOrder,
  panels: allPanels,
  expandedGroup: None,
}
