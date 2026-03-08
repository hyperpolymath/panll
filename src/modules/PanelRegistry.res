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
    cladeId: None,
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
    cladeId: None,
  },
  {
    id: PanelTentacles,
    name: "7-Tentacles",
    shortName: "Tentacles",
    description: "Compiler agent orchestra — 7 colour-coded agents with OODA reasoning, progressive cephalopod staging, and ECHIDNA FFI bridge",
    icon: "cpu",
    connectionStatus: ServiceDisconnected, // FFI bridge checked on demand
    hasBackend: true, // ECHIDNA V-lang REST adapters
    cladeId: Some("clade-tentacles"),
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
}
