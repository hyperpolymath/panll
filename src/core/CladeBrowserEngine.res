// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Clade Browser Engine — pure helpers for clade display and filtering.
///
/// All functions are pure (no side effects). View and Update modules call
/// these to transform and query clade data.

open CladeBrowserModel

/// Human-readable label for a clade kind.
let kindLabel = (k: cladeKind): string => {
  switch k {
  | KindAi => "AI"
  | KindBridge => "Bridge"
  | KindBuilder => "Builder"
  | KindDatabase => "Database"
  | KindDirective => "Directive"
  | KindLoader => "Loader"
  | KindMeta => "Meta"
  | KindNetwork => "Network"
  | KindScanner => "Scanner"
  | KindTerminal => "Terminal"
  | KindViewer => "Viewer"
  | KindAll => "All"
  }
}

/// CSS-friendly colour for each kind.
let kindColour = (k: cladeKind): string => {
  switch k {
  | KindAi => "#a78bfa"
  | KindBridge => "#60a5fa"
  | KindBuilder => "#f59e0b"
  | KindDatabase => "#34d399"
  | KindDirective => "#f87171"
  | KindLoader => "#818cf8"
  | KindMeta => "#9ca3af"
  | KindNetwork => "#2dd4bf"
  | KindScanner => "#fb923c"
  | KindTerminal => "#a3e635"
  | KindViewer => "#c084fc"
  | KindAll => "#e5e7eb"
  }
}

/// Parse a kind string from a clade file.
let parseKind = (s: string): cladeKind => {
  switch s {
  | "ai" => KindAi
  | "bridge" => KindBridge
  | "builder" => KindBuilder
  | "database" => KindDatabase
  | "directive" => KindDirective
  | "loader" => KindLoader
  | "meta" => KindMeta
  | "network" => KindNetwork
  | "scanner" => KindScanner
  | "terminal" => KindTerminal
  | "viewer" => KindViewer
  | _ => KindMeta
  }
}

/// All kind values (for the filter dropdown).
let allKinds: array<cladeKind> = [
  KindAll, KindAi, KindBridge, KindBuilder, KindDatabase,
  KindDirective, KindLoader, KindMeta, KindNetwork,
  KindScanner, KindTerminal, KindViewer,
]

/// Filter clades by kind.
let filterByKind = (clades: array<cladeEntry>, kind: cladeKind): array<cladeEntry> => {
  switch kind {
  | KindAll => clades
  | k => {
      let kindStr = kindLabel(k)->String.toLowerCase
      clades->Array.filter(c => c.kind == kindStr)
    }
  }
}

/// Filter clades by search query (matches id, name, summary).
let filterBySearch = (clades: array<cladeEntry>, query: string): array<cladeEntry> => {
  if query == "" {
    clades
  } else {
    let q = query->String.toLowerCase
    clades->Array.filter(c =>
      c.id->String.toLowerCase->String.includes(q) ||
      c.name->String.toLowerCase->String.includes(q) ||
      c.summary->String.toLowerCase->String.includes(q)
    )
  }
}

/// Combined filter (kind + search).
let filterClades = (clades: array<cladeEntry>, kind: cladeKind, query: string): array<cladeEntry> => {
  clades->filterByKind(kind)->filterBySearch(query)
}

/// Count clades per kind.
let countByKind = (clades: array<cladeEntry>, kind: cladeKind): int => {
  filterByKind(clades, kind)->Array.length
}

/// Count traits across all clades.
let countWithTrait = (clades: array<cladeEntry>, getter: cladeTraits => bool): int => {
  clades->Array.filter(c => getter(c.traits))->Array.length
}

/// Category label for tab display.
let categoryLabel = (cat: cladeBrowserCategory): string => {
  switch cat {
  | CategoryOverview => "Overview"
  | CategoryByKind => "By Kind"
  | CategoryTraits => "Traits"
  | CategoryPanelMap => "Panel Map"
  }
}

/// All categories for tab rendering.
let allCategories: array<cladeBrowserCategory> = [
  CategoryOverview, CategoryByKind, CategoryTraits, CategoryPanelMap,
]

/// Extend a base clade entry with Tier 1 fields.
/// Clades start with empty protocols/capabilities/requires/enhances and
/// IsolationSoft. The enrichment pass below overrides specific clades.
let withDefaults = (
  ~protocols: array<cladeProtocol>=[],
  ~capabilities: array<cladeCapability>=[],
  ~requires: array<cladeDependency>=[],
  ~enhances: array<string>=[],
  ~isolation: cladeIsolation=IsolationSoft,
  ~signing: cladeSigningStatus=SigningNone,
  ~sbom: option<cladeSbom>=None,
  ~sandbox: option<cladeSandboxPolicy>=None,
  entry: cladeEntry,
): cladeEntry => {
  {
    ...entry,
    protocols,
    capabilities,
    requires,
    enhances,
    isolation,
    signing,
    sbom,
    sandbox,
  }
}

/// Built-in clade data (loaded from panel-clades/ at compile time).
/// In a full implementation, this would be loaded via Tauri from the
/// filesystem. For now, we embed the 36 known clades.
let builtinCladesBase: array<cladeEntry> = [
  { id: "aerie", name: "Aerie", kind: "network", version: "1.0.0",
    summary: "Network diagnostics, BGP forensics, IPv6 tools",
    longDescription: "Network analysis and simulation panel for BGP, DNS, and IPv6 diagnostics.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelAerie"], consumedBy: [], supersedes: [], parentCladeId: Some("network"), protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["cloudguard", "network-topology"] },
  { id: "ai", name: "AI", kind: "ai", version: "1.0.0",
    summary: "Multi-provider neural interface — Claude, Gemini, Mistral, GPT, local",
    longDescription: "Neural inference gateway supporting multiple AI providers with unified API.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelAi"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "automation-router", name: "Automation Router", kind: "bridge", version: "1.0.0",
    summary: "Hybrid cross-panel workflow orchestration",
    longDescription: "Event-driven rule engine for automating workflows across panels with approval gates.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelAutomationRouter"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "script-gist", name: "Script Gist", kind: "tool", version: "1.0.0",
    summary: "Portable computation gists — Minskian diachronic/synchronic cardfiles",
    longDescription: "Saveable, shareable script and schema drafting board. Gists are LLM-callable as MCP tools, runnable standalone, composable into cardfiles. Diachronic (time/scripts) and synchronic (space/schemata) state documents with rollback.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelScriptGist"], consumedBy: ["automation-router", "boj"], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: ["automation-router", "playgrounds"], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["playgrounds", "automation-router"] },
  { id: "boj", name: "BoJ — Bundle of Joy", kind: "bridge", version: "1.0.0",
    summary: "Unified cartridge server — 17 domains, Umoja federation",
    longDescription: "Protocol backbone bridging all domains through Idris2 ABI, Zig FFI, V-lang adapter.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelBoj"], consumedBy: ["aerie", "ai", "databases"], supersedes: ["polystack"], parentCladeId: Some("bridge"), protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["ai", "databases", "network-topology"] },
  { id: "build-dashboard", name: "Build Dashboard", kind: "builder", version: "1.0.0",
    summary: "Multi-project build, test, and compilation monitor",
    longDescription: "Tracks build status, errors, and test results across sub-projects.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelBuildDashboard"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "capture", name: "Capture", kind: "viewer", version: "1.0.0",
    summary: "Screenshots, recordings, demos, panel comparison views",
    longDescription: "Screen capture and recording with panel-aware cropping and export.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelCapture"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "cloudguard", name: "CloudGuard", kind: "network", version: "1.0.0",
    summary: "Cloudflare domain security management",
    longDescription: "DNS, WAF, and domain configuration management via Cloudflare API.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelCloudGuard"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "coprocessors", name: "Coprocessors", kind: "viewer", version: "1.0.0",
    summary: "IDApTIK coprocessor backend monitor — 10 backends",
    longDescription: "Monitors coprocessor call logs, heatmaps, and performance for IDApTIK.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelCoprocessors"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "databases", name: "Databases", kind: "database", version: "1.0.0",
    summary: "VeriSimDB, QuandleDB, LithoGlyph management",
    longDescription: "Formally verified database inspection, query execution, and schema management.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelDatabases"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "dlc-workshop", name: "DLC Workshop", kind: "builder", version: "1.0.0",
    summary: "Create, test, and package DLC puzzle packs",
    longDescription: "VM composer, solution testing, and asset bundling for IDApTIK DLC.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelDlcWorkshop"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "ums", name: "Universal Modding Studio", kind: "builder", version: "1.0.0",
    summary: "Unified IDApTIK game content creation — projects, ABI validation, assets, distribution",
    longDescription: "Hub panel orchestrating Level Architect, DLC Workshop, Game Preview, and VM Inspector. Manages mod projects, validates level data against Idris2 ABI proofs, runs asset pipelines, and handles mod distribution.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelUms"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: ["level-architect", "dlc-workshop", "game-preview", "vm-inspector"], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["level-architect", "dlc-workshop"] },
  { id: "editor-bridge", name: "Editor Bridge", kind: "bridge", version: "1.0.0",
    summary: "Federate with external code editors — LSP, diagnostics, symbols",
    longDescription: "Connects to VSCodium, JetBrains, Notepad++, Brackets via LSP for cross-editor integration.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelEditorBridge"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "farm", name: "Farm", kind: "loader", version: "1.0.0",
    summary: "Repository admin registry and maintenance hub",
    longDescription: "Git-Private-Farm repo inventory, health checks, and admin operations.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelFarm"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "fleet", name: "Fleet", kind: "scanner", version: "1.0.0",
    summary: "Gitbot fleet orchestration and dispatch",
    longDescription: "Manages 6-bot fleet: rhodibot, echidnabot, sustainabot, glambot, seambot, finishbot.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: true, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelFleet"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "game-preview", name: "Game Preview", kind: "viewer", version: "1.0.0",
    summary: "Live IDApTIK game preview with hot-reload",
    longDescription: "Embedded game preview with frame stepping, overlays, and gameplay recording.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelGamePreview"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "hypatia", name: "Hypatia", kind: "ai", version: "1.0.0",
    summary: "Neurosymbolic CI/CD intelligence",
    longDescription: "Hypatia scanning integration for neurosymbolic security analysis.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelHypatia"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "interfaces", name: "Interfaces", kind: "bridge", version: "1.0.0",
    summary: "Language bridges, ABI/FFI inventory",
    longDescription: "Filesystem scanning of ABI/FFI bindings across the ecosystem.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelInterfaces"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "level-architect", name: "Level Architect", kind: "builder", version: "1.0.0",
    summary: "Visual level design for IDApTIK",
    longDescription: "Device placement, guard patrols, defence flags, validation, LevelConfig export.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelLevelArchitect"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "mass-panic", name: "Mass Panic", kind: "scanner", version: "1.0.0",
    summary: "Organisation-scale batch scanning",
    longDescription: "Assemblyline + BLAKE3 + VeriSimDB + delta scanning across entire orgs.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelMassPanic"], consumedBy: [], supersedes: [], parentCladeId: Some("scanner"), protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["panic-attack"] },
  { id: "migration", name: "Migration", kind: "meta", version: "1.0.0",
    summary: "ReScript Migration Observatory",
    longDescription: "Health tracking, sessions, submissions, merge resolution for ReScript migration.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelMigration"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "minter", name: "Minter", kind: "builder", version: "1.0.0",
    summary: "Panel creation wizard — generate panel modules from templates",
    longDescription: "Scaffolds new panel modules with TEA wiring, clade assignment, and accessibility.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelMinter"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "multiplayer-monitor", name: "Multiplayer Monitor", kind: "network", version: "1.0.0",
    summary: "Elixir/Phoenix sync server monitor",
    longDescription: "WebSocket channels, player state, Lamport clocks, latency monitoring.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelMultiplayerMonitor"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "network-topology", name: "Network Topology", kind: "network", version: "1.0.0",
    summary: "Force-directed graph of IDApTIK in-game network",
    longDescription: "Devices, zones, security levels, packet flow visualisation.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelNetworkTopology"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "panic-attack", name: "panic-attack", kind: "scanner", version: "1.0.0",
    summary: "Stress testing and logic-based bug signature detection",
    longDescription: "47 languages, 20 categories, assault reports, ambush mode.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelPanicAttack"], consumedBy: [], supersedes: [], parentCladeId: Some("scanner"), protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["mass-panic"] },
  { id: "playgrounds", name: "Playgrounds", kind: "terminal", version: "1.0.0",
    summary: "Code sandbox, NQC console, tutorials",
    longDescription: "Interactive code playground with NQC database console integration.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelPlaygrounds"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "plaza", name: "Palimpsest Plaza", kind: "meta", version: "1.0.0",
    summary: "PMPL license adoption, compliance, and governance",
    longDescription: "License scanning, compliance checking, and PMPL governance hub.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelPlaza"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "provisioner", name: "Provisioner", kind: "loader", version: "1.0.0",
    summary: "Portfolio bundles, panel configuration, isolation tiers",
    longDescription: "Manages panel portfolios, configuration, and container isolation.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelProvisioner"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "release-manager", name: "Release Manager", kind: "builder", version: "1.0.0",
    summary: "Versioning, changelog, signing, distribution",
    longDescription: "Release pipeline with artifact building, signing, and distribution.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelReleaseManager"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "repoloader", name: "Repo Loader", kind: "loader", version: "1.0.0",
    summary: "Repository scanner and panel configuration",
    longDescription: "Scans repos, reads manifests, configures panels for loaded projects.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelRepoLoader"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "reposystem", name: "Reposystem", kind: "meta", version: "1.0.0",
    summary: "RSR compliance and template management",
    longDescription: "Rhodium Standard Repository compliance checking and template scaffolding.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelReposystem"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "security", name: "Security", kind: "scanner", version: "1.0.0",
    summary: "Secrets redaction, vault, 2FA, Trustfile enforcement",
    longDescription: "Security panel with shoulder-safe mode, secrets vault, and Trustfile enforcement.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: true },
    panelIds: ["PanelSecurity"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "tsdm", name: "TSDM", kind: "directive", version: "1.0.0",
    summary: "Triaxial Software Development Methodology",
    longDescription: "Priority ordering directive panel across all panels using triaxial methodology.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: true },
    panelIds: ["PanelTsdm"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "vab", name: "VAB", kind: "builder", version: "1.0.0",
    summary: "Verified Assembly Building — server component composer",
    longDescription: "Compose and verify server components with formal validation.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelVab"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "valence-shell", name: "Valence Shell", kind: "terminal", version: "1.0.0",
    summary: "Embedded terminal with Claude Code, session recording, reversible ops",
    longDescription: "Full terminal with PTY, Claude Code integration, collaborative approval gate.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelValenceShell"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "vm-inspector", name: "VM Inspector", kind: "viewer", version: "1.0.0",
    summary: "Reversible VM visual debugger",
    longDescription: "Stack, memory, instructions with step-forward and step-backward capability.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelVmInspector"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "voicetag", name: "Code MRI", kind: "viewer", version: "1.0.0",
    summary: "Voice-activated code annotation — .mri.json sidecars",
    longDescription: "Tag code with voice annotations stored as portable JSON sidecar files.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelVoiceTag"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "workspace", name: "Workspace", kind: "meta", version: "1.0.0",
    summary: "Panel arrangements, groups, sessions, modes, configurator",
    longDescription: "Manages panel layouts, session persistence, and workspace configuration.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelWorkspace"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "protocol-squisher", name: "Protocol-Squisher", kind: "scanner", version: "1.0.0",
    summary: "13-format schema analysis — transport class classification and compatibility",
    longDescription: "Analyses serialisation schemas across Protobuf, Avro, FlatBuffers, Cap'n Proto, Thrift, MessagePack, Bebop, JSON Schema, GraphQL, TOML, Rust, ReScript, Python. Classifies transport classes (Concorde/Business/Economy/Wheelbarrow) and compares compatibility.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelProtocolSquisher"], consumedBy: ["boj"], supersedes: [], parentCladeId: Some("scanner"), protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["aerie", "interfaces"] },
  { id: "my-lang", name: "My-Lang", kind: "builder", version: "1.0.0",
    summary: "AI-native language workbench — 4 dialects, REPL, compiler",
    longDescription: "Development environment for my-lang with Solo (systems), Duet (AI-assisted), Ensemble (AI-native), Me (personal agent) dialects. Includes code editor, REPL, and compilation output.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelMyLang"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["build-dashboard", "editor-bridge"] },
  { id: "typell", name: "TypeLL — Verification Kernel", kind: "ai", version: "1.0.0",
    summary: "Cross-panel type intelligence — dependent, linear, affine, session, refinement types",
    longDescription: "PanLL's verification backbone. Provides type checking, inference, refinement, and proof obligation generation to every panel. Progressive disclosure (RAW/FOLDED/GLYPHED/WYSIWYG) from rescript-evangeliser makes advanced type systems accessible.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: true },
    panelIds: ["PanelTypeLL"], consumedBy: ["databases", "protocol-squisher", "my-lang", "boj", "playgrounds"], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["ai", "clade-tentacles"] },
  { id: "echidna", name: "ECHIDNA", kind: "ai", version: "1.0.0",
    summary: "ECHIDNA multi-solver theorem prover — proof dispatch, tactic suggestions, enterprise model checking",
    longDescription: "Multi-solver theorem prover integrating proof dispatch, automated tactic suggestions, and enterprise-grade model checking across multiple backends.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelEchidna"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["typell", "ai"] },
  { id: "help", name: "Help", kind: "meta", version: "1.0.0",
    summary: "In-application help system with context-sensitive guides, glossary, and onboarding",
    longDescription: "Context-sensitive help overlay with searchable glossary, onboarding walkthroughs, and per-panel guidance.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelHelp"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "accessibility", name: "Accessibility", kind: "meta", version: "1.0.0",
    summary: "Centralised accessibility toolbar — colour palettes, font size, animation, focus indicators",
    longDescription: "Global accessibility controls including high-contrast colour palettes, font scaling, reduced motion, focus indicator customisation, and screen reader hints.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: true },
    panelIds: [], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["workspace"] },
  { id: "menu-bar", name: "Menu Bar", kind: "meta", version: "1.0.0",
    summary: "Standard application menu bar — File, Edit, View, Panel, Tools, Help",
    longDescription: "Top-level application menu with keyboard navigation, command palette integration, and dynamic menu items contributed by loaded panels.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: true },
    panelIds: [], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["workspace"] },
  { id: "status-bar", name: "Status Bar", kind: "meta", version: "1.0.0",
    summary: "VS Code-style status bar with configurable widgets",
    longDescription: "Bottom status bar with configurable widget slots for build status, git branch, language mode, encoding, notifications, and panel-contributed indicators.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: true },
    panelIds: [], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["workspace"] },
  { id: "vexometer", name: "Vexometer", kind: "viewer", version: "1.0.0",
    summary: "Cognitive load meter — Friction of Things index with anti-inflammatory mode",
    longDescription: "Ambient cognitive load gauge tracking Friction of Things index across all panels. Anti-inflammatory mode automatically reduces complexity when cognitive load exceeds thresholds.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: false, hasRealTime: true, isAmbient: true },
    panelIds: [], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["accessibility"] },
  { id: "provenance", name: "Provenance", kind: "scanner", version: "1.0.0",
    summary: "Qubes-style code trust surface — ambient provenance map",
    longDescription: "Ambient provenance overlay showing trust levels for code and dependencies using a Qubes-inspired colour-coded trust surface.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: true },
    panelIds: [], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["security", "panic-attack"] },
  { id: "feedback", name: "Feedback-O-Tron", kind: "meta", version: "1.0.0",
    summary: "Feedback-O-Tron — user feedback aggregation and sentiment analysis",
    longDescription: "Collects user feedback from in-app prompts and external channels, aggregates sentiment analysis, and surfaces actionable insights.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: [], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: [] },
  { id: "keybindings", name: "Keybindings", kind: "meta", version: "1.0.0",
    summary: "Customisable keyboard shortcuts system",
    longDescription: "Central keyboard shortcut registry with conflict detection, per-panel keymaps, vim/emacs presets, and exportable configuration.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: [], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["workspace", "accessibility"] },
  { id: "tiling", name: "Tiling", kind: "meta", version: "1.0.0",
    summary: "Multi-monitor panel detachment and Aero-style snap zones",
    longDescription: "Panel layout engine supporting multi-monitor detachment, snap zones, split views, and serialisable tiling configurations.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: [], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["workspace"] },
  { id: "focus-dimming", name: "Focus Dimming", kind: "meta", version: "1.0.0",
    summary: "Focus-aware panel dimming and Smart Memory Mode",
    longDescription: "Ambient focus system that dims inactive panels and activates Smart Memory Mode to reduce resource usage for off-screen or background panels.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: true },
    panelIds: [], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["workspace", "accessibility"] },
  { id: "clade-browser", name: "Clade Browser", kind: "meta", version: "1.0.0",
    summary: "Panel taxonomy explorer — clades, traits, kind filtering, panel mapping",
    longDescription: "Explore and customise the PanLL clade taxonomy, inspect trait inheritance chains, filter by kind, and see panel-to-clade assignments.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelCladeBrowser"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [], capabilities: [], requires: [], enhances: [], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["workspace", "minter"] },
  { id: "observatory", name: "Observatory", kind: "viewer", version: "1.0.0",
    summary: "Integrative dashboard — cross-panel health, service status, resource usage",
    longDescription: "Unified operational dashboard aggregating health, connection status, resource usage, and ambient metrics across all panels. Shows service connectivity, memory/CPU budgets, and panel activity.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: true },
    panelIds: ["PanelObservatory"], consumedBy: [], supersedes: [], parentCladeId: None, protocols: [ProtoTauriIPC], capabilities: [CapVisualisation, CapStreaming], requires: [], enhances: ["workspace", "provisioner", "focus-dimming"], isolation: IsolationSoft, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["build-dashboard", "workspace"] },
  { id: "ambientops", name: "AmbientOps", kind: "network", version: "1.0.0",
    summary: "Hospital-model sysadmin — clinician, network ambulance, hardware crash team",
    longDescription: "Integrates the AmbientOps hospital-model operations framework: AI-assisted clinician (Rust), network ambulance (Ada/SPARK + bash), hardware crash team (Rust), emergency room (V), observatory (Elixir). Evidence Envelope pipeline for diagnostics and repairs.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelAmbientOps"], consumedBy: [], supersedes: [], parentCladeId: Some("network"), protocols: [ProtoTauriIPC, ProtoREST], capabilities: [CapProcessSpawn, CapFilesystem, CapNetwork], requires: [], enhances: ["aerie", "security", "observatory"], isolation: IsolationProcess, signing: SigningNone, sbom: None, sandbox: None, siblingClades: ["aerie", "cloudguard"] },
]

// ════════════════════════════════════════════════════════════════════════
// Clade Inheritance Engine
// ════════════════════════════════════════════════════════════════════════
//
// Resolves trait inheritance: a child clade inherits all traits from its
// parent clade, then applies its own overrides. The merge rule is:
//   inherited_trait = parent_trait OR child_trait
// (a clade gains capabilities from its parent, never loses them).

/// Find a clade by ID in the registry.
let findClade = (clades: array<cladeEntry>, id: string): option<cladeEntry> => {
  clades->Array.find(c => c.id == id)
}

/// Merge two trait sets. OR semantics: a trait is true if either parent or child has it.
let mergeTraits = (parent: cladeTraits, child: cladeTraits): cladeTraits => {
  {
    hasPersistence: parent.hasPersistence || child.hasPersistence,
    hasBackend: parent.hasBackend || child.hasBackend,
    hasWorkItems: parent.hasWorkItems || child.hasWorkItems,
    hasRealTime: parent.hasRealTime || child.hasRealTime,
    isAmbient: parent.isAmbient || child.isAmbient,
  }
}

/// Resolve the effective traits for a clade, walking the parent chain.
/// Uses a visited set (as array of IDs) to prevent cycles.
let rec resolveTraitsRec = (
  clades: array<cladeEntry>,
  clade: cladeEntry,
  visited: array<string>,
): cladeTraits => {
  // Cycle detection.
  if visited->Array.some(v => v == clade.id) {
    clade.traits
  } else {
    switch clade.parentCladeId {
    | None => clade.traits
    | Some(parentId) =>
      switch findClade(clades, parentId) {
      | None => clade.traits
      | Some(parent) =>
        let parentTraits = resolveTraitsRec(clades, parent, Array.concat(visited, [clade.id]))
        mergeTraits(parentTraits, clade.traits)
      }
    }
  }
}

/// Public API: resolve the effective traits for a clade by ID.
let resolveTraits = (clades: array<cladeEntry>, cladeId: string): option<cladeTraits> => {
  switch findClade(clades, cladeId) {
  | None => None
  | Some(clade) => Some(resolveTraitsRec(clades, clade, []))
  }
}

/// Get the inheritance chain for a clade (child → parent → grandparent → ...).
let rec inheritanceChain = (clades: array<cladeEntry>, cladeId: string, visited: array<string>): array<string> => {
  if visited->Array.some(v => v == cladeId) {
    [] // cycle
  } else {
    switch findClade(clades, cladeId) {
    | None => []
    | Some(clade) =>
      switch clade.parentCladeId {
      | None => [cladeId]
      | Some(parentId) =>
        Array.concat([cladeId], inheritanceChain(clades, parentId, Array.concat(visited, [cladeId])))
      }
    }
  }
}

/// Get the inheritance chain as a display string (e.g. "boj → bridge").
let inheritanceLabel = (clades: array<cladeEntry>, cladeId: string): string => {
  let chain = inheritanceChain(clades, cladeId, [])
  chain->Array.join(" -> ")
}

/// Check if one clade is an ancestor of another.
let isAncestor = (clades: array<cladeEntry>, ancestorId: string, descendantId: string): bool => {
  let chain = inheritanceChain(clades, descendantId, [])
  chain->Array.some(id => id == ancestorId) && ancestorId != descendantId
}

/// Count clades that have a parent (i.e., participate in inheritance).
let countWithParent = (clades: array<cladeEntry>): int => {
  clades->Array.filter(c => c.parentCladeId != None)->Array.length
}

/// Get all root clades (no parent).
let rootClades = (clades: array<cladeEntry>): array<cladeEntry> => {
  clades->Array.filter(c => c.parentCladeId == None)
}

/// Get all children of a given clade.
let childrenOf = (clades: array<cladeEntry>, parentId: string): array<cladeEntry> => {
  clades->Array.filter(c => c.parentCladeId == Some(parentId))
}

// ════════════════════════════════════════════════════════════════════════
// Clade Permission System
// ════════════════════════════════════════════════════════════════════════
//
// Determines whether one clade may cross-reference another. Used by the
// Panel Bus and GovernanceEngine to gate cross-panel event delivery.

/// Look up the permission rule for a target clade.
let findPermissionRule = (
  rules: array<cladePermissionRule>,
  targetCladeId: string,
): option<cladePermissionRule> => {
  rules->Array.find(r => r.targetCladeId == targetCladeId)
}

/// Check if a source clade is allowed to reference a target clade.
/// Default (no rule): PermitAll — open by default.
let canReference = (
  rules: array<cladePermissionRule>,
  sourceCladeId: string,
  targetCladeId: string,
): bool => {
  // A clade can always reference itself.
  if sourceCladeId == targetCladeId {
    true
  } else {
    switch findPermissionRule(rules, targetCladeId) {
    | None => true // No rule = open access
    | Some({permission: PermitAll}) => true
    | Some({permission: PermitNone}) => false
    | Some({permission: PermitOnly(allowed)}) =>
      allowed->Array.some(id => id == sourceCladeId)
    }
  }
}

/// Check if a source panel (by panelId string) can reference a target
/// panel, resolving both to their clade IDs first.
let canPanelReference = (
  clades: array<cladeEntry>,
  rules: array<cladePermissionRule>,
  sourcePanelId: string,
  targetPanelId: string,
): bool => {
  // Find the clade for each panel.
  let sourceCladeId = clades->Array.find(c =>
    c.panelIds->Array.some(p => p == sourcePanelId)
  )->Option.map(c => c.id)
  let targetCladeId = clades->Array.find(c =>
    c.panelIds->Array.some(p => p == targetPanelId)
  )->Option.map(c => c.id)

  switch (sourceCladeId, targetCladeId) {
  | (Some(src), Some(tgt)) => canReference(rules, src, tgt)
  | _ => true // Unknown panels default to open
  }
}

/// Add or update a permission rule for a target clade.
let setPermission = (
  rules: array<cladePermissionRule>,
  targetCladeId: string,
  permission: cladePermission,
): array<cladePermissionRule> => {
  let exists = rules->Array.some(r => r.targetCladeId == targetCladeId)
  if exists {
    rules->Array.map(r =>
      if r.targetCladeId == targetCladeId {
        {...r, permission}
      } else {
        r
      }
    )
  } else {
    Array.concat(rules, [{targetCladeId, permission}])
  }
}

/// Remove a permission rule (reverts to default PermitAll behaviour).
let removePermission = (
  rules: array<cladePermissionRule>,
  targetCladeId: string,
): array<cladePermissionRule> => {
  rules->Array.filter(r => r.targetCladeId != targetCladeId)
}

/// Default permission rules. Security-sensitive clades are restricted.
let defaultPermissionRules: array<cladePermissionRule> = [
  // Security panel: only scanners, meta, and ai clades may reference it.
  {
    targetCladeId: "security",
    permission: PermitOnly(["panic-attack", "mass-panic", "fleet", "hypatia", "workspace", "ai", "typell"]),
  },
  // Valence Shell: restricted to avoid accidental terminal access.
  {
    targetCladeId: "valence-shell",
    permission: PermitOnly(["workspace", "automation-router", "editor-bridge", "ai"]),
  },
]

// ════════════════════════════════════════════════════════════════════════
// Tier 1 Enrichment — assign real protocols, capabilities, dependencies,
// and isolation levels to specific clades.
// ════════════════════════════════════════════════════════════════════════

/// Enrich a base clade with its real Tier 1 metadata.
let enrichClade = (entry: cladeEntry): cladeEntry =>
  switch entry.id {
  | "boj" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoGRPC, ProtoGraphQL, ProtoMCP, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapProcessSpawn, CapStreaming],
      ~enhances=["aerie", "ai", "databases"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "typell" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoStdio],
      ~capabilities=[CapTypeChecking, CapProofProduction, CapProofConsumption, CapStreaming],
      ~enhances=["databases", "protocol-squisher", "my-lang", "playgrounds"],
      entry,
    )
  | "editor-bridge" =>
    withDefaults(
      ~protocols=[ProtoLSP, ProtoDAP, ProtoStdio],
      ~capabilities=[CapNetwork, CapProcessSpawn],
      ~enhances=["my-lang", "playgrounds"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "ai" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoSSE, ProtoWebSocket, ProtoMCP],
      ~capabilities=[CapNetwork, CapStreaming],
      ~isolation=IsolationProcess,
      entry,
    )
  | "hypatia" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoSSE],
      ~capabilities=[CapNetwork, CapSecurityScan, CapProofProduction],
      ~enhances=["fleet", "farm"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "valence-shell" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoStdio],
      ~capabilities=[CapShell, CapProcessSpawn, CapFilesystem, CapClipboard, CapSessionRecording],
      ~isolation=IsolationContainer,
      ~sandbox=Some({
        allowedCapabilities: [CapShell, CapProcessSpawn, CapFilesystem, CapClipboard, CapSessionRecording],
        networkRateLimit: None,
        fsAllowedPaths: ["$HOME", "/tmp"],
        processApprovalRequired: true,
      }),
      entry,
    )
  | "databases" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoGraphQL, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapFilesystem, CapStreaming],
      ~isolation=IsolationProcess,
      entry,
    )
  | "protocol-squisher" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoStdio],
      ~capabilities=[CapTypeChecking, CapSecurityScan],
      ~enhances=["boj", "interfaces"],
      entry,
    )
  | "my-lang" =>
    withDefaults(
      ~protocols=[ProtoLSP, ProtoTauriIPC, ProtoStdio],
      ~capabilities=[CapFilesystem, CapProcessSpawn, CapTypeChecking],
      ~isolation=IsolationProcess,
      entry,
    )
  | "panic-attack" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoStdio],
      ~capabilities=[CapFilesystem, CapProcessSpawn, CapSecurityScan],
      ~enhances=["security"],
      ~isolation=IsolationContainer,
      ~sandbox=Some({
        allowedCapabilities: [CapFilesystem, CapProcessSpawn, CapSecurityScan],
        networkRateLimit: None,
        fsAllowedPaths: ["$PROJECT"],
        processApprovalRequired: false,
      }),
      entry,
    )
  | "mass-panic" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoTauriIPC],
      ~capabilities=[CapFilesystem, CapNetwork, CapProcessSpawn, CapSecurityScan, CapContainerised],
      ~requires=[{cladeId: "panic-attack", required: true, reason: "Core scanning engine"}],
      ~enhances=["security", "farm"],
      ~isolation=IsolationContainer,
      ~sandbox=Some({
        allowedCapabilities: [CapFilesystem, CapNetwork, CapProcessSpawn, CapSecurityScan, CapContainerised],
        networkRateLimit: Some(100),
        fsAllowedPaths: ["$PROJECT", "/tmp/panll/scans"],
        processApprovalRequired: false,
      }),
      entry,
    )
  | "security" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapSecretManagement, CapSecurityScan, CapClipboard],
      ~isolation=IsolationProcess,
      entry,
    )
  | "automation-router" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoWebSocket],
      ~capabilities=[CapStreaming],
      ~enhances=["workspace", "fleet"],
      entry,
    )
  | "aerie" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoWebSocket, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapVisualisation],
      ~enhances=["cloudguard", "network-topology"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "cloudguard" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapSecretManagement],
      ~enhances=["aerie"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "fleet" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoWebSocket, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapProcessSpawn],
      ~enhances=["farm", "hypatia"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "farm" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem],
      entry,
    )
  | "playgrounds" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoStdio],
      ~capabilities=[CapProcessSpawn, CapShell, CapStreaming],
      ~isolation=IsolationContainer,
      ~sandbox=Some({
        allowedCapabilities: [CapProcessSpawn, CapShell, CapStreaming],
        networkRateLimit: Some(50),
        fsAllowedPaths: ["/tmp/panll/playgrounds"],
        processApprovalRequired: false,
      }),
      entry,
    )
  | "workspace" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem, CapSessionRecording],
      entry,
    )
  | "capture" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem, CapClipboard, CapVisualisation, CapSessionRecording],
      ~enhances=["workspace"],
      entry,
    )
  | "game-preview" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoWebSocket],
      ~capabilities=[CapStreaming, CapVisualisation],
      ~enhances=["vm-inspector", "level-architect"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "vm-inspector" =>
    withDefaults(
      ~protocols=[ProtoDAP, ProtoTauriIPC],
      ~capabilities=[CapVisualisation, CapStreaming],
      ~enhances=["game-preview"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "level-architect" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem, CapVisualisation],
      ~enhances=["game-preview"],
      entry,
    )
  | "network-topology" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoWebSocket],
      ~capabilities=[CapVisualisation, CapStreaming],
      ~enhances=["game-preview"],
      entry,
    )
  | "multiplayer-monitor" =>
    withDefaults(
      ~protocols=[ProtoWebSocket, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapStreaming, CapVisualisation],
      ~isolation=IsolationProcess,
      entry,
    )
  | "build-dashboard" =>
    withDefaults(
      ~protocols=[ProtoBSP, ProtoTauriIPC],
      ~capabilities=[CapProcessSpawn, CapFilesystem],
      ~enhances=["my-lang", "release-manager"],
      entry,
    )
  | "release-manager" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoTauriIPC],
      ~capabilities=[CapFilesystem, CapNetwork, CapProcessSpawn],
      ~enhances=["build-dashboard"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "minter" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem],
      entry,
    )
  | "interfaces" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem],
      ~enhances=["boj", "protocol-squisher"],
      entry,
    )
  | "repoloader" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem],
      ~enhances=["farm"],
      entry,
    )
  | "tsdm" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      entry,
    )
  | "vab" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem, CapProcessSpawn],
      ~enhances=["build-dashboard"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "voicetag" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem],
      entry,
    )
  | "coprocessors" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoWebSocket],
      ~capabilities=[CapStreaming, CapVisualisation],
      ~enhances=["game-preview", "vm-inspector"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "dlc-workshop" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem, CapVisualisation],
      ~enhances=["game-preview", "level-architect"],
      entry,
    )
  | "ums" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoREST],
      ~capabilities=[CapFilesystem, CapVisualisation, CapProofProduction, CapTypeChecking],
      ~enhances=["level-architect", "dlc-workshop", "game-preview", "vm-inspector"],
      ~requires=[{cladeId: "level-architect", required: true, reason: "UMS validates levels via Level Architect's Idris2 ABI"}],
      entry,
    )
  | "plaza" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapFilesystem],
      ~enhances=["reposystem", "farm"],
      entry,
    )
  | "provisioner" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem],
      ~enhances=["minter", "workspace"],
      entry,
    )
  | "reposystem" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoREST],
      ~capabilities=[CapFilesystem, CapSecurityScan],
      ~enhances=["farm", "fleet"],
      entry,
    )
  | "migration" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoLSP],
      ~capabilities=[CapFilesystem, CapTypeChecking],
      ~enhances=["editor-bridge", "build-dashboard"],
      entry,
    )
  | "echidna" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoGRPC, ProtoTauriIPC, ProtoStdio],
      ~capabilities=[CapProofProduction, CapProofConsumption, CapTypeChecking, CapStreaming],
      ~isolation=IsolationProcess,
      ~requires=[{cladeId: "databases", required: false, reason: "VeriSimDB backing store for proof certificates"}],
      ~enhances=["typell", "databases"],
      entry,
    )
  | "help" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      entry,
    )
  | "accessibility" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~enhances=["workspace"],
      entry,
    )
  | "menu-bar" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~enhances=["workspace", "keybindings"],
      entry,
    )
  | "status-bar" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapStreaming],
      ~enhances=["workspace", "build-dashboard"],
      entry,
    )
  | "vexometer" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapStreaming, CapVisualisation],
      ~enhances=["accessibility", "workspace"],
      entry,
    )
  | "provenance" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoREST],
      ~capabilities=[CapSecurityScan, CapFilesystem],
      ~enhances=["security", "panic-attack"],
      entry,
    )
  | "feedback" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC, ProtoREST],
      ~capabilities=[CapFilesystem],
      entry,
    )
  | "keybindings" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~capabilities=[CapFilesystem],
      ~enhances=["workspace", "menu-bar"],
      entry,
    )
  | "tiling" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~enhances=["workspace"],
      entry,
    )
  | "focus-dimming" =>
    withDefaults(
      ~protocols=[ProtoTauriIPC],
      ~enhances=["workspace", "accessibility"],
      entry,
    )
  // Game Server Admin — universal game server probe + config management via Gossamer + VeriSimDB
  | "gsa" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoWebSocket, ProtoSSE, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapShell, CapProcessSpawn, CapContainerised, CapStreaming, CapSecretManagement, CapVisualisation, CapSessionRecording],
      ~enhances=["databases", "infrastructure"],
      ~isolation=IsolationProcess,
      entry,
    )
  | "gsa-browser" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoTauriIPC],
      ~capabilities=[CapNetwork],
      entry,
    )
  | "gsa-config" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapShell, CapSecretManagement],
      entry,
    )
  | "gsa-actions" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapShell, CapProcessSpawn, CapContainerised],
      entry,
    )
  | "gsa-logs" =>
    withDefaults(
      ~protocols=[ProtoWebSocket, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapStreaming],
      entry,
    )
  | "gsa-health" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoSSE, ProtoTauriIPC],
      ~capabilities=[CapNetwork],
      ~enhances=["databases"],
      entry,
    )
  | "gsa-history" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoTauriIPC],
      ~capabilities=[CapNetwork],
      ~enhances=["databases"],
      entry,
    )
  | "gsa-search" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoTauriIPC],
      ~capabilities=[CapNetwork],
      ~enhances=["databases"],
      entry,
    )
  | "gsa-game" =>
    withDefaults(
      ~protocols=[ProtoREST, ProtoTauriIPC],
      ~capabilities=[CapNetwork, CapShell, CapContainerised],
      entry,
    )
  | _ => entry
  }

/// The enriched built-in clades — base entries with real Tier 1 metadata.
let builtinClades: array<cladeEntry> = builtinCladesBase->Array.map(enrichClade)

// ════════════════════════════════════════════════════════════════════════
// Tier 1 Query Functions — protocol, capability, dependency queries
// ════════════════════════════════════════════════════════════════════════

/// Human-readable label for a protocol.
let protocolLabel = (p: cladeProtocol): string =>
  switch p {
  | ProtoLSP => "LSP"
  | ProtoDAP => "DAP"
  | ProtoBSP => "BSP"
  | ProtoMCP => "MCP"
  | ProtoREST => "REST"
  | ProtoGRPC => "gRPC"
  | ProtoGraphQL => "GraphQL"
  | ProtoWebSocket => "WebSocket"
  | ProtoSSE => "SSE"
  | ProtoTauriIPC => "Tauri IPC"
  | ProtoUnixSocket => "Unix Socket"
  | ProtoDBus => "D-Bus"
  | ProtoStdio => "Stdio"
  }

/// Human-readable label for a capability.
let capabilityLabel = (c: cladeCapability): string =>
  switch c {
  | CapFilesystem => "Filesystem"
  | CapNetwork => "Network"
  | CapClipboard => "Clipboard"
  | CapProcessSpawn => "Process Spawn"
  | CapShell => "Shell"
  | CapContainerised => "Containerised"
  | CapStreaming => "Streaming"
  | CapProofProduction => "Proof Production"
  | CapProofConsumption => "Proof Consumption"
  | CapTypeChecking => "Type Checking"
  | CapSecurityScan => "Security Scan"
  | CapSecretManagement => "Secret Management"
  | CapVisualisation => "Visualisation"
  | CapSessionRecording => "Session Recording"
  }

/// Human-readable label for an isolation level.
let isolationLabel = (i: cladeIsolation): string =>
  switch i {
  | IsolationNone => "None"
  | IsolationSoft => "Soft"
  | IsolationProcess => "Process"
  | IsolationContainer => "Container"
  }

/// CSS colour for an isolation level badge.
let isolationColour = (i: cladeIsolation): string =>
  switch i {
  | IsolationNone => "#f87171"
  | IsolationSoft => "#fbbf24"
  | IsolationProcess => "#60a5fa"
  | IsolationContainer => "#34d399"
  }

/// Check if a clade exposes a given protocol.
let cladeHasProtocol = (clade: cladeEntry, proto: cladeProtocol): bool =>
  clade.protocols->Array.some(p => p == proto)

/// Check if a clade provides a given capability.
let cladeHasCapability = (clade: cladeEntry, cap: cladeCapability): bool =>
  clade.capabilities->Array.some(c => c == cap)

/// Find all clades that expose a given protocol.
let cladesWithProtocol = (clades: array<cladeEntry>, proto: cladeProtocol): array<cladeEntry> =>
  clades->Array.filter(c => cladeHasProtocol(c, proto))

/// Find all clades that provide a given capability.
let cladesWithCapability = (clades: array<cladeEntry>, cap: cladeCapability): array<cladeEntry> =>
  clades->Array.filter(c => cladeHasCapability(c, cap))

/// Get the hard dependencies for a clade (required=true).
let cladeHardDeps = (clade: cladeEntry): array<cladeDependency> =>
  clade.requires->Array.filter(d => d.required)

/// Get the soft dependencies for a clade (required=false).
let cladeSoftDeps = (clade: cladeEntry): array<cladeDependency> =>
  clade.requires->Array.filter(d => !d.required)

/// Find all clades that require a given clade ID.
let cladesRequiring = (clades: array<cladeEntry>, depId: string): array<cladeEntry> =>
  clades->Array.filter(c => c.requires->Array.some(d => d.cladeId == depId))

/// Find all clades that enhance a given clade ID.
let cladesEnhancing = (clades: array<cladeEntry>, targetId: string): array<cladeEntry> =>
  clades->Array.filter(c => c.enhances->Array.some(e => e == targetId))

/// Count clades by isolation level.
let countByIsolation = (clades: array<cladeEntry>, level: cladeIsolation): int =>
  clades->Array.filter(c => c.isolation == level)->Array.length

/// Count clades that expose at least one protocol.
let countWithProtocols = (clades: array<cladeEntry>): int =>
  clades->Array.filter(c => c.protocols->Array.length > 0)->Array.length

/// Count clades that have at least one capability.
let countWithCapabilities = (clades: array<cladeEntry>): int =>
  clades->Array.filter(c => c.capabilities->Array.length > 0)->Array.length

// ════════════════════════════════════════════════════════════════════════
// Tier 4 Query Functions — signing, SBOM, sandbox queries
// ════════════════════════════════════════════════════════════════════════

/// Human-readable label for a signing status.
let signingLabel = (s: cladeSigningStatus): string =>
  switch s {
  | SigningNone => "Not Signed"
  | SigningPending => "Pending"
  | SigningVerified(signer) => "Verified (" ++ signer ++ ")"
  | SigningFailed(reason) => "Failed: " ++ reason
  }

/// Check if a clade is verified (signing passed).
let isVerified = (clade: cladeEntry): bool =>
  switch clade.signing {
  | SigningVerified(_) => true
  | _ => false
  }

/// Count signed/verified clades.
let countVerified = (clades: array<cladeEntry>): int =>
  clades->Array.filter(isVerified)->Array.length

/// Check if a clade has a sandbox policy.
let isSandboxed = (clade: cladeEntry): bool =>
  clade.sandbox !== None

/// Count sandboxed clades.
let countSandboxed = (clades: array<cladeEntry>): int =>
  clades->Array.filter(isSandboxed)->Array.length

/// Check if a clade has an SBOM.
let hasSbom = (clade: cladeEntry): bool =>
  clade.sbom !== None

/// Count clades with SBOMs.
let countWithSbom = (clades: array<cladeEntry>): int =>
  clades->Array.filter(hasSbom)->Array.length

/// Check if a capability is allowed by a sandbox policy.
let sandboxAllows = (sandbox: cladeSandboxPolicy, cap: cladeCapability): bool =>
  sandbox.allowedCapabilities->Array.some(c => c == cap)

/// Validate that a clade's active capabilities are within its sandbox.
/// Returns capabilities that are used but not allowed.
let sandboxViolations = (clade: cladeEntry): array<cladeCapability> =>
  switch clade.sandbox {
  | None => []
  | Some(sandbox) =>
    clade.capabilities->Array.filter(cap => !sandboxAllows(sandbox, cap))
  }
