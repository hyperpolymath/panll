<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- PANEL-INVENTORY.md — Complete catalog of all 79 PanLL panels -->
<!-- Last updated: 2026-03-15 -->

# Panel Inventory

PanLL has 79 panel entries across 11 categories. The three core panels (L, N, W)
are always visible; overlay panels appear one at a time on top of them.
The 28 game dev panels (added 2026-03-14) exist as clade definitions; ReScript
Model/Update/View/Cmd modules are pending implementation.
K9 Manager, Contractile Manager, and Wiring Inspector added 2026-03-15.

## Core Panels (3)

These panels form the permanent three-panel layout and are always rendered.

| Panel | Category | Description |
|-------|----------|-------------|
| Panel-L (Symbolic Mass) | Core | Constraints, formal specs, type rules, proofs |
| Panel-N (Neural Stream) | Core | AI reasoning, ECHIDNA confidence, OODA loop |
| Panel-W (World/Barycentre) | Core | Results, dashboards, VeriSimDB, live data |

## Overlay Panels (14)

Full-screen overlays activated via the panel bar. At most one is active at a time.

| Panel | panelId | Short | Source Files | Rust Backend | Description |
|-------|---------|-------|-------------|--------------|-------------|
| CloudGuard | `PanelCloudGuard` | CG | CloudGuardEngine, CloudGuardCmd, CloudGuardModel, CloudGuard | `cloudguard/` (14 commands) | Cloudflare domain security management |
| VAB | `PanelVab` | VAB | VabEngine, VabModel, Vab | None (local catalog) | Verified Assembly Building — server component composer |
| Farm | `PanelFarm` | Farm | FarmEngine, FarmModel, Farm | `farm/` (3 commands) | Repository admin registry and maintenance hub |
| Fleet | `PanelFleet` | Fleet | FleetEngine, FleetModel, Fleet | None (external Axum API) | Gitbot fleet orchestration and dispatch |
| Hypatia | `PanelHypatia` | Hyp | HypatiaEngine, HypatiaModel, Hypatia | None (external Elixir API) | Neurosymbolic CI/CD intelligence |
| Reposystem | `PanelReposystem` | RSR | ReposystemEngine, ReposystemModel, Reposystem | None (filesystem scanning) | RSR compliance and template management |
| Aerie | `PanelAerie` | Net | AerieEngine, AerieModel, Aerie | `overlay/` (21 commands) | Network diagnostics, BGP forensics, overlay networks |
| Interfaces | `PanelInterfaces` | FFI | InterfacesEngine, InterfacesModel, Interfaces | None (filesystem scanning) | Language bridges, ABI/FFI inventory |
| Playgrounds | `PanelPlaygrounds` | Play | PlaygroundsEngine, PlaygroundsModel, Playgrounds | None (NQC proxy) | Code sandbox, NQC console, tutorials |
| Palimpsest Plaza | `PanelPlaza` | PMPL | PlazaEngine, PlazaModel, Plaza | `plaza/` (3 commands) | PMPL license adoption, compliance, governance |
| Minter | `PanelMinter` | Mint | MinterEngine, MinterModel, Minter | `minter/` (2 commands) | Panel creation wizard — generate accessible panel modules |
| Protocol-Squisher | `PanelProtocolSquisher` | Squisher | ProtocolSquisherEngine, ProtocolSquisherModel, ProtocolSquisher | main.rs (3 commands) | 13-format schema analysis, compatibility comparison |
| My-Lang | `PanelMyLang` | My-Lang | MyLangEngine, MyLangModel, MyLang | main.rs (5 commands) | AI-native language workbench — 4 dialects, REPL, compiler |
| BoJ | `PanelBoj` | BoJ | BojEngine, BojModel, Boj | `boj/` (8 commands) | Bundle of Joy — 17-cartridge server, Umoja federation |

## IDApTIK eNSAID Panels (11)

Panels specific to the IDApTIK game engine development environment.

| Panel | panelId | Short | Source Files | Rust Backend | Description |
|-------|---------|-------|-------------|--------------|-------------|
| Valence Shell | `PanelValenceShell` | VS | ValenceShellEngine, ValenceShellModel, ValenceShell | `valence_shell/` (12 commands) | Embedded terminal, session recording, checkpoints |
| Game Preview | `PanelGamePreview` | Game | GamePreviewEngine, GamePreviewModel, GamePreview | `game_preview/` (8 commands) | Live IDApTIK preview, hot-reload, frame stepping |
| VM Inspector | `PanelVmInspector` | VM | VmInspectorEngine, VmInspectorModel, VmInspector | `vm_inspector/` (7 commands) | Reversible VM debugger — stack, memory, stepping |
| Network Topology | `PanelNetworkTopology` | Topo | NetworkTopologyEngine, NetworkTopologyModel, NetworkTopology | `network_topology/` (4 commands) | Force-directed graph of in-game network |
| Level Architect | `PanelLevelArchitect` | Lvl | LevelArchitectEngine, LevelArchitectModel, LevelArchitect | `level_architect/` (5 commands) | Visual level design, device placement, validation |
| Coprocessors | `PanelCoprocessors` | CoPr | CoprocessorsEngine, CoprocessorsModel, Coprocessors | `coprocessor/` (8 commands) | Monitor 10 coprocessor backends, heatmap, health |
| Multiplayer Monitor | `PanelMultiplayerMonitor` | MP | MultiplayerMonitorEngine, MultiplayerMonitorModel, MultiplayerMonitor | `multiplayer_monitor/` (6 commands) | Phoenix sync server — WebSocket, Lamport clocks |
| DLC Workshop | `PanelDlcWorkshop` | DLC | DlcWorkshopEngine, DlcWorkshopModel, DlcWorkshop | `dlc_workshop/` (8 commands) | Puzzle pack creation, VM composer, asset bundling |
| Editor Bridge | `PanelEditorBridge` | EB | EditorBridgeEngine, EditorBridgeModel, EditorBridge | None (LSP via BoJ) | Federate with external editors — LSP diagnostics |
| Build Dashboard | `PanelBuildDashboard` | Bld | BuildDashboardEngine, BuildDashboardModel, BuildDashboard | None (BSP via BoJ) | Monitor builds, tests, compilation status |
| Release Manager | `PanelReleaseManager` | Rel | ReleaseManagerEngine, ReleaseManagerModel, ReleaseManager | `release_manager/` (5 commands) | Versioning, changelog, artifact signing, distribution |

## Cross-Cutting Services (4)

These are not standalone panels but provide capabilities that span multiple panels.

| Panel | panelId | Short | Source Files | Rust Backend | Description |
|-------|---------|-------|-------------|--------------|-------------|
| TypeLL | `PanelTypeLL` | TypeLL | TypeLLEngine, TypeLLModel, TypeLL | `typell/` (7 commands) | Verification kernel — dependent, linear, session types |
| 7-Tentacles | `PanelTentacles` | Tentacles | TentaclesEngine, TentaclesModel, Tentacles | None (ECHIDNA FFI) | Multi-agent orchestration, OODA reasoning, cephalopod staging |
| A2ML/K9 | (via PanelCladeBrowser) | — | A2mlEngine, K9Engine | `a2ml/` (3) + `k9/` (3) | Manifest parsing, contractile validation, layout |
| Coprocessor Engine | `PanelCoprocessors` | CoPr | CoprocessorsEngine | `coprocessor/` (8 commands) | Control + data + smart routing (Phase 1-3) |

## Infrastructure (5)

Ambient infrastructure panels always present or accessed via the panel bar.

| Panel | panelId | Short | Source Files | Rust Backend | Description |
|-------|---------|-------|-------------|--------------|-------------|
| Panel Switcher | (built-in) | — | PanelSwitcherModel, PanelRegistry, PanelBar | None | Unified navigation bar |
| Provisioner | `PanelProvisioner` | Prov | ProvisionerEngine, ProvisionerModel, Provisioner | None (Stapeln/Podman) | Portfolios, configuration, isolation tiers |
| Code Provenance | `PanelVoiceTag` | MRI | VoiceTagEngine, VoiceTagModel, VoiceTag | `voicetag/` (4 commands) | Trust surface, 4 palettes, .mri.json sidecars |
| Filesystem Watcher | (built-in) | — | WatcherModel | `watcher/` (5 commands) | Rust notify + ReScript event stream |
| Clade Browser | `PanelCladeBrowser` | Clade | CladeBrowserEngine, CladeBrowserModel, CladeBrowser | `clade_scanner/` (1 command) | 41 clades, inheritance engine, taxonomy |

## Cognitive Governance (6)

Ambient cognitive ergonomics — always present, no dedicated panel IDs.

| Panel | panelId | Source Files | Rust Backend | Description |
|-------|---------|-------------|--------------|-------------|
| Vexometer | (built-in) | VexometerModel, Vexometer | main.rs (`record_vexation_event`, `get_vexation_index`) | Real-time friction monitoring |
| Anti-Crash Gate | (built-in) | AntiCrashModel | main.rs (`validate_inference`) | Neural token gating, circuit breaker |
| Orbital Drift Aura | (built-in) | OrbitalDriftModel | None | Ambient stability indicator |
| Feedback-O-Tron | (built-in) | FeedbackOTronModel | main.rs (`submit_feedback`) | Community-driven performance reporting |
| Information Humidity | (built-in) | HumidityModel | None | UI density adaptation (High/Medium/Low) |
| Dark Start | (built-in) | DarkStartModel | None | Architecture manifold entry point |

## Additional Utility Panels

| Panel | panelId | Short | Source Files | Rust Backend | Description |
|-------|---------|-------|-------------|--------------|-------------|
| Databases | `PanelDatabases` | DB | — | main.rs (8 verisim + 10 echidna) | VeriSimDB, QuandleDB, LithoGlyph management |
| AI | `PanelAi` | AI | AiEngine, AiModel | `ai/` (8 commands) | Multi-provider neural interface |
| Repo Loader | `PanelRepoLoader` | Repo | RepoLoaderEngine | `repoloader/` (4 commands) | Repository scanner and panel configuration |
| Workspace | `PanelWorkspace` | WS | WorkspaceEngine, WorkspaceModel | `workspace/` (7 commands) | Arrangements, groups, sessions, modes |
| Capture | `PanelCapture` | Cap | CaptureEngine, CaptureModel | `capture/` (5 commands) | Screenshots, recordings, demos |
| Security | `PanelSecurity` | Sec | SecurityEngine, SecurityModel | `security/` (5 commands) | Redaction, vault, 2FA, Trustfile enforcement |
| Migration | `PanelMigration` | Mig | MigrationEngine, MigrationModel | None (panic-attack CLI) | ReScript Migration Observatory |
| panic-attack | `PanelPanicAttack` | PA | PanicAttackModel | main.rs (4 commands) | Stress testing, bug signature detection |
| Mass Panic | `PanelMassPanic` | MP | MassPanicModel | main.rs (via panic-attack) | Batch scanning — assemblyline + BLAKE3 |
| TSDM | `PanelTsdm` | TSD | TsdmModel | None | Triaxial Software Development Methodology |
| Automation Router | `PanelAutomationRouter` | Auto | AutomationRouterEngine | None (ENSAID_CONFIG reading) | Cross-panel workflow orchestration |
| Observability | (via governance) | — | ObservabilityEngine | `observability/` (3 commands) | SARIF export, OpenTelemetry traces |
| Umoja | (via BoJ) | — | — | `umoja/` (5 commands) | Federation gossip protocol peer management |

## Game Dev — Testing (10)

Panels for test orchestration, profiling, compatibility, and balance analysis.
**Status:** Clade definitions only (a2ml manifests). ReScript implementation pending.

| Panel | panelId | Short | Kind | Description |
|-------|---------|-------|------|-------------|
| Unit Test Runner | `PanelUnitTestRunner` | UTR | Scanner | Execute unit test suites, pass/fail tree, coverage heatmap |
| Functional Tester | `PanelFunctionalTester` | FT | Scanner | Scenario-based functional test orchestration, screenshots |
| Regression Guard | `PanelRegressionGuard` | RG | Scanner | Baseline comparison, drift detection, blame analysis |
| Performance Profiler | `PanelPerformanceProfiler` | Perf | Inspector | CPU flame graphs, memory tracking, frame timing |
| Load Tester | `PanelLoadTester` | Load | Scanner | Synthetic load generation, latency percentiles, throughput |
| Soak Monitor | `PanelSoakMonitor` | Soak | Inspector | Long-running stability, memory leaks, resource trends |
| Compatibility Matrix | `PanelCompatibilityMatrix` | Compat | Viewer | Cross-platform/version test matrix, colour-coded grid |
| Exploratory Workbench | `PanelExploratoryWorkbench` | Explore | Builder | Free-form manual testing, session notes, bug tagging |
| Beta Feedback Hub | `PanelBetaFeedbackHub` | Beta | Viewer | Player/tester feedback collection, sentiment, triage |
| Balance Analyser | `PanelBalanceAnalyser` | Balance | Inspector | Difficulty curves, win/loss tracking, resource economy |

## Game Dev — Bridge (8)

Panels bridging PanLL to external systems, type systems, protocols, and runtimes.
**Status:** Clade definitions only (a2ml manifests). ReScript implementation pending.

| Panel | panelId | Short | Kind | Description |
|-------|---------|-------|------|-------------|
| Typing Bridge | `PanelTypingBridge` | TyBr | Bridge | Bridge TypeLL to Idris2, Rust, ReScript, Gleam type systems |
| Neurosym Bridge | `PanelNeurosymBridge` | NeSy | Bridge | Neural-symbolic translation, confidence gating, proof-guided inference |
| Agentic Bridge | `PanelAgenticBridge` | Agent | Bridge | External AI agent dispatch (MCP, Claude Code, ECHIDNA) |
| Automation Bridge | `PanelAutomationBridge` | CI | Bridge | CI/CD pipeline trigger, monitoring, artifact collection |
| Database Bridge | `PanelDatabaseBridge` | DBBr | Bridge | VeriSimDB/QuandleDB query proxy, schema inspection |
| Protocol Bridge | `PanelProtocolBridge` | Proto | Bridge | MCP/LSP/DAP/BSP/gRPC message translation and inspection |
| Proofs Bridge | `PanelProofsBridge` | Proof | Bridge | Formal verification (Idris2, ECHIDNA, Lean4) proof submission |
| Scripting Bridge | `PanelScriptingBridge` | Script | Bridge | Deno/Julia/Elixir/Lua snippet execution, sandbox management |

## Game Dev — Game-Specific (6)

Panels for IDApTIK game content creation, AI tuning, and playtesting.
**Status:** Clade definitions only (a2ml manifests). ReScript implementation pending.

| Panel | panelId | Short | Kind | Description |
|-------|---------|-------|------|-------------|
| Generator Mode | `PanelGeneratorMode` | Gen | Builder | Procedural level/puzzle/topology generation with constraint satisfaction |
| Architect Mode | `PanelArchitectMode` | Arch | Builder | High-level system design, dependency graphs, ADR management |
| Guard AI Tuner | `PanelGuardAiTuner` | GAI | Builder | Tune guard AI patrol patterns, detection, escalation, difficulty |
| Device Network Designer | `PanelDeviceNetworkDesigner` | NetDes | Builder | Visual in-game network designer, drag-and-drop, topology validation |
| Asset Manager | `PanelAssetManager` | Asset | Loader | Game asset inventory, import pipeline, unused detection |
| Playtest Recorder | `PanelPlaytestRecorder` | Play | Inspector | Record/replay play sessions, input capture, decision trees |

## Game Dev — Team (4)

Panels for collaborative development workflows.
**Status:** Clade definitions only (a2ml manifests). ReScript implementation pending.

| Panel | panelId | Short | Kind | Description |
|-------|---------|-------|------|-------------|
| Code Review | `PanelCodeReview` | Review | Viewer | In-panel diff views, inline comments, approval workflow |
| Merge Coordinator | `PanelMergeCoordinator` | Merge | Directive | Branch management, conflict resolution, merge queues |
| Team Dashboard | `PanelTeamDashboard` | Team | Viewer | Commit velocity, review throughput, build health overview |
| Debugging Workbench | `PanelDebuggingWorkbench` | Debug | Inspector | DAP-backed breakpoints, watch expressions, multi-runtime |

## Governance & Contracts (3)

Panels for contractile enforcement, K9 security validation, and wiring integrity.
**Status:** Implemented 2026-03-15 with full ReScript components.

| Panel | panelId | Short | Source Files | Rust Backend | Description |
|-------|---------|-------|-------------|--------------|-------------|
| K9 Manager | `PanelK9Manager` | K9 | K9Model, K9Manager | via `k9/` commands | Security level badges (Kennel/Yard/Hunt), file validation, Load/Validate/Apply |
| Contractile Manager | `PanelContractileManager` | CTR | ContractileManager | via contractiles | 11 built-in contractiles, colour-coded status, elasticity bars, vexation index |
| Wiring Inspector | `PanelWiringInspector` | Wire | WiringInspectorModel, WiringInspector | None | Phase 5 Constraint Audit Dashboard, 77 panel contracts, PCC verification |
