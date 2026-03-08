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

/// Built-in clade data (loaded from panel-clades/ at compile time).
/// In a full implementation, this would be loaded via Tauri from the
/// filesystem. For now, we embed the 36 known clades.
let builtinClades: array<cladeEntry> = [
  { id: "aerie", name: "Aerie", kind: "network", version: "1.0.0",
    summary: "Network diagnostics, BGP forensics, IPv6 tools",
    longDescription: "Network analysis and simulation panel for BGP, DNS, and IPv6 diagnostics.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelAerie"], consumedBy: [], supersedes: [], parentCladeId: Some("network"), siblingClades: ["cloudguard", "network-topology"] },
  { id: "ai", name: "AI", kind: "ai", version: "1.0.0",
    summary: "Multi-provider neural interface — Claude, Gemini, Mistral, GPT, local",
    longDescription: "Neural inference gateway supporting multiple AI providers with unified API.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelAi"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "automation-router", name: "Automation Router", kind: "bridge", version: "1.0.0",
    summary: "Hybrid cross-panel workflow orchestration",
    longDescription: "Event-driven rule engine for automating workflows across panels with approval gates.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelAutomationRouter"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "boj", name: "BoJ — Bundle of Joy", kind: "bridge", version: "1.0.0",
    summary: "Unified cartridge server — 17 domains, Umoja federation",
    longDescription: "Protocol backbone bridging all domains through Idris2 ABI, Zig FFI, V-lang adapter.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelBoj"], consumedBy: ["aerie", "ai", "databases"], supersedes: ["polystack"], parentCladeId: Some("bridge"), siblingClades: ["ai", "databases", "network-topology"] },
  { id: "build-dashboard", name: "Build Dashboard", kind: "builder", version: "1.0.0",
    summary: "Multi-project build, test, and compilation monitor",
    longDescription: "Tracks build status, errors, and test results across sub-projects.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelBuildDashboard"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "capture", name: "Capture", kind: "viewer", version: "1.0.0",
    summary: "Screenshots, recordings, demos, panel comparison views",
    longDescription: "Screen capture and recording with panel-aware cropping and export.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelCapture"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "cloudguard", name: "CloudGuard", kind: "network", version: "1.0.0",
    summary: "Cloudflare domain security management",
    longDescription: "DNS, WAF, and domain configuration management via Cloudflare API.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelCloudGuard"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "coprocessors", name: "Coprocessors", kind: "viewer", version: "1.0.0",
    summary: "IDApTIK coprocessor backend monitor — 10 backends",
    longDescription: "Monitors coprocessor call logs, heatmaps, and performance for IDApTIK.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelCoprocessors"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "databases", name: "Databases", kind: "database", version: "1.0.0",
    summary: "VeriSimDB, QuandleDB, LithoGlyph management",
    longDescription: "Formally verified database inspection, query execution, and schema management.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelDatabases"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "dlc-workshop", name: "DLC Workshop", kind: "builder", version: "1.0.0",
    summary: "Create, test, and package DLC puzzle packs",
    longDescription: "VM composer, solution testing, and asset bundling for IDApTIK DLC.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelDlcWorkshop"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "editor-bridge", name: "Editor Bridge", kind: "bridge", version: "1.0.0",
    summary: "Federate with external code editors — LSP, diagnostics, symbols",
    longDescription: "Connects to VSCodium, JetBrains, Notepad++, Brackets via LSP for cross-editor integration.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelEditorBridge"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "farm", name: "Farm", kind: "loader", version: "1.0.0",
    summary: "Repository admin registry and maintenance hub",
    longDescription: "Git-Private-Farm repo inventory, health checks, and admin operations.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelFarm"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "fleet", name: "Fleet", kind: "scanner", version: "1.0.0",
    summary: "Gitbot fleet orchestration and dispatch",
    longDescription: "Manages 6-bot fleet: rhodibot, echidnabot, sustainabot, glambot, seambot, finishbot.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: true, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelFleet"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "game-preview", name: "Game Preview", kind: "viewer", version: "1.0.0",
    summary: "Live IDApTIK game preview with hot-reload",
    longDescription: "Embedded game preview with frame stepping, overlays, and gameplay recording.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelGamePreview"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "hypatia", name: "Hypatia", kind: "ai", version: "1.0.0",
    summary: "Neurosymbolic CI/CD intelligence",
    longDescription: "Hypatia scanning integration for neurosymbolic security analysis.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelHypatia"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "interfaces", name: "Interfaces", kind: "bridge", version: "1.0.0",
    summary: "Language bridges, ABI/FFI inventory",
    longDescription: "Filesystem scanning of ABI/FFI bindings across the ecosystem.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelInterfaces"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "level-architect", name: "Level Architect", kind: "builder", version: "1.0.0",
    summary: "Visual level design for IDApTIK",
    longDescription: "Device placement, guard patrols, defence flags, validation, LevelConfig export.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelLevelArchitect"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "mass-panic", name: "Mass Panic", kind: "scanner", version: "1.0.0",
    summary: "Organisation-scale batch scanning",
    longDescription: "Assemblyline + BLAKE3 + VeriSimDB + delta scanning across entire orgs.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelMassPanic"], consumedBy: [], supersedes: [], parentCladeId: Some("scanner"), siblingClades: ["panic-attack"] },
  { id: "migration", name: "Migration", kind: "meta", version: "1.0.0",
    summary: "ReScript Migration Observatory",
    longDescription: "Health tracking, sessions, submissions, merge resolution for ReScript migration.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelMigration"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "minter", name: "Minter", kind: "builder", version: "1.0.0",
    summary: "Panel creation wizard — generate panel modules from templates",
    longDescription: "Scaffolds new panel modules with TEA wiring, clade assignment, and accessibility.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelMinter"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "multiplayer-monitor", name: "Multiplayer Monitor", kind: "network", version: "1.0.0",
    summary: "Elixir/Phoenix sync server monitor",
    longDescription: "WebSocket channels, player state, Lamport clocks, latency monitoring.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelMultiplayerMonitor"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "network-topology", name: "Network Topology", kind: "network", version: "1.0.0",
    summary: "Force-directed graph of IDApTIK in-game network",
    longDescription: "Devices, zones, security levels, packet flow visualisation.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelNetworkTopology"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "panic-attack", name: "panic-attack", kind: "scanner", version: "1.0.0",
    summary: "Stress testing and logic-based bug signature detection",
    longDescription: "47 languages, 20 categories, assault reports, ambush mode.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelPanicAttack"], consumedBy: [], supersedes: [], parentCladeId: Some("scanner"), siblingClades: ["mass-panic"] },
  { id: "playgrounds", name: "Playgrounds", kind: "terminal", version: "1.0.0",
    summary: "Code sandbox, NQC console, tutorials",
    longDescription: "Interactive code playground with NQC database console integration.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelPlaygrounds"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "plaza", name: "Palimpsest Plaza", kind: "meta", version: "1.0.0",
    summary: "PMPL license adoption, compliance, and governance",
    longDescription: "License scanning, compliance checking, and PMPL governance hub.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelPlaza"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "provisioner", name: "Provisioner", kind: "loader", version: "1.0.0",
    summary: "Portfolio bundles, panel configuration, isolation tiers",
    longDescription: "Manages panel portfolios, configuration, and container isolation.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelProvisioner"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "release-manager", name: "Release Manager", kind: "builder", version: "1.0.0",
    summary: "Versioning, changelog, signing, distribution",
    longDescription: "Release pipeline with artifact building, signing, and distribution.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelReleaseManager"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "repoloader", name: "Repo Loader", kind: "loader", version: "1.0.0",
    summary: "Repository scanner and panel configuration",
    longDescription: "Scans repos, reads manifests, configures panels for loaded projects.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelRepoLoader"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "reposystem", name: "Reposystem", kind: "meta", version: "1.0.0",
    summary: "RSR compliance and template management",
    longDescription: "Rhodium Standard Repository compliance checking and template scaffolding.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelReposystem"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "security", name: "Security", kind: "scanner", version: "1.0.0",
    summary: "Secrets redaction, vault, 2FA, Trustfile enforcement",
    longDescription: "Security panel with shoulder-safe mode, secrets vault, and Trustfile enforcement.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: true },
    panelIds: ["PanelSecurity"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "tsdm", name: "TSDM", kind: "directive", version: "1.0.0",
    summary: "Triaxial Software Development Methodology",
    longDescription: "Priority ordering directive panel across all panels using triaxial methodology.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: true },
    panelIds: ["PanelTsdm"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "vab", name: "VAB", kind: "builder", version: "1.0.0",
    summary: "Verified Assembly Building — server component composer",
    longDescription: "Compose and verify server components with formal validation.",
    traits: { hasPersistence: false, hasBackend: false, hasWorkItems: true, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelVab"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "valence-shell", name: "Valence Shell", kind: "terminal", version: "1.0.0",
    summary: "Embedded terminal with Claude Code, session recording, reversible ops",
    longDescription: "Full terminal with PTY, Claude Code integration, collaborative approval gate.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelValenceShell"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "vm-inspector", name: "VM Inspector", kind: "viewer", version: "1.0.0",
    summary: "Reversible VM visual debugger",
    longDescription: "Stack, memory, instructions with step-forward and step-backward capability.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: false },
    panelIds: ["PanelVmInspector"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "voicetag", name: "Code MRI", kind: "viewer", version: "1.0.0",
    summary: "Voice-activated code annotation — .mri.json sidecars",
    longDescription: "Tag code with voice annotations stored as portable JSON sidecar files.",
    traits: { hasPersistence: true, hasBackend: false, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelVoiceTag"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "workspace", name: "Workspace", kind: "meta", version: "1.0.0",
    summary: "Panel arrangements, groups, sessions, modes, configurator",
    longDescription: "Manages panel layouts, session persistence, and workspace configuration.",
    traits: { hasPersistence: true, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelWorkspace"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: [] },
  { id: "protocol-squisher", name: "Protocol-Squisher", kind: "scanner", version: "1.0.0",
    summary: "13-format schema analysis — transport class classification and compatibility",
    longDescription: "Analyses serialisation schemas across Protobuf, Avro, FlatBuffers, Cap'n Proto, Thrift, MessagePack, Bebop, JSON Schema, GraphQL, TOML, Rust, ReScript, Python. Classifies transport classes (Concorde/Business/Economy/Wheelbarrow) and compares compatibility.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelProtocolSquisher"], consumedBy: ["boj"], supersedes: [], parentCladeId: Some("scanner"), siblingClades: ["aerie", "interfaces"] },
  { id: "my-lang", name: "My-Lang", kind: "builder", version: "1.0.0",
    summary: "AI-native language workbench — 4 dialects, REPL, compiler",
    longDescription: "Development environment for my-lang with Solo (systems), Duet (AI-assisted), Ensemble (AI-native), Me (personal agent) dialects. Includes code editor, REPL, and compilation output.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: false, isAmbient: false },
    panelIds: ["PanelMyLang"], consumedBy: [], supersedes: [], parentCladeId: None, siblingClades: ["build-dashboard", "editor-bridge"] },
  { id: "typell", name: "TypeLL — Verification Kernel", kind: "ai", version: "1.0.0",
    summary: "Cross-panel type intelligence — dependent, linear, affine, session, refinement types",
    longDescription: "PanLL's verification backbone. Provides type checking, inference, refinement, and proof obligation generation to every panel. Progressive disclosure (RAW/FOLDED/GLYPHED/WYSIWYG) from rescript-evangeliser makes advanced type systems accessible.",
    traits: { hasPersistence: false, hasBackend: true, hasWorkItems: false, hasRealTime: true, isAmbient: true },
    panelIds: ["PanelTypeLL"], consumedBy: ["databases", "protocol-squisher", "my-lang", "boj", "playgrounds"], supersedes: [], parentCladeId: None, siblingClades: ["ai", "clade-tentacles"] },
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
