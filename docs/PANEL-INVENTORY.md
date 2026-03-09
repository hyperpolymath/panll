<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- PANEL-INVENTORY.md — Complete catalog of all 41 PanLL panels -->
<!-- Last updated: 2026-03-09 -->

# Panel Inventory

PanLL has 41 panel entries across 6 categories. The three core panels (L, N, W)
are always visible; overlay panels appear one at a time on top of them.

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
| Databases | `PanelDatabases` | DB | — | main.rs (8 verisimdb + 10 echidna) | VeriSimDB, QuandleDB, LithoGlyph management |
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
