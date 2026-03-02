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
  },
  {
    id: PanelVab,
    name: "VAB",
    shortName: "VAB",
    description: "Verified Assembly Building — server component composer",
    icon: "rocket",
    connectionStatus: ServiceConnected, // VAB is local catalog, always "connected"
    hasBackend: false,
  },
  {
    id: PanelFarm,
    name: "Farm",
    shortName: "Farm",
    description: "Repository admin registry and maintenance hub",
    icon: "barn",
    connectionStatus: ServiceDisconnected,
    hasBackend: false, // Reads local JSON, no HTTP service
  },
  {
    id: PanelFleet,
    name: "Fleet",
    shortName: "Fleet",
    description: "Gitbot fleet orchestration and dispatch",
    icon: "bots",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
  },
  {
    id: PanelHypatia,
    name: "Hypatia",
    shortName: "Hyp",
    description: "Neurosymbolic CI/CD intelligence",
    icon: "brain",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
  },
  {
    id: PanelReposystem,
    name: "Reposystem",
    shortName: "RSR",
    description: "RSR compliance and template management",
    icon: "layers",
    connectionStatus: ServiceDisconnected,
    hasBackend: false, // Filesystem scanning
  },
  {
    id: PanelDatabases,
    name: "Databases",
    shortName: "DB",
    description: "VeriSimDB, QuandleDB, LithoGlyph management",
    icon: "database",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
  },
  {
    id: PanelAerie,
    name: "Aerie",
    shortName: "Net",
    description: "Network diagnostics and BGP forensics",
    icon: "network",
    connectionStatus: ServiceDisconnected,
    hasBackend: true,
  },
  {
    id: PanelInterfaces,
    name: "Interfaces",
    shortName: "FFI",
    description: "Language bridges, ABI/FFI inventory",
    icon: "bridge",
    connectionStatus: ServiceDisconnected,
    hasBackend: false, // Filesystem scanning
  },
  {
    id: PanelPlaygrounds,
    name: "Playgrounds",
    shortName: "Play",
    description: "Code sandbox, NQC console, tutorials",
    icon: "terminal",
    connectionStatus: ServiceDisconnected,
    hasBackend: true, // NQC proxy + database connections
  },
  {
    id: PanelPlaza,
    name: "Palimpsest Plaza",
    shortName: "PMPL",
    description: "PMPL license adoption, compliance, and governance hub",
    icon: "scroll",
    connectionStatus: ServiceConnected, // Local scanning, always available
    hasBackend: false, // Filesystem scanning + CLI tools
  },
  {
    id: PanelMinter,
    name: "Minter",
    shortName: "Mint",
    description: "Panel creation wizard — generate accessible panel modules from templates",
    icon: "wand",
    connectionStatus: ServiceConnected, // Local generation, always available
    hasBackend: true, // Tauri backend generates files and patches wiring
  },
  {
    id: PanelProvisioner,
    name: "Provisioner",
    shortName: "Prov",
    description: "Portfolio bundles, panel configuration, and isolation tier management",
    icon: "package",
    connectionStatus: ServiceConnected, // Local state management, always available
    hasBackend: false, // Configuration is local; container ops handled by Stapeln/Podman
  },
  {
    id: PanelVoiceTag,
    name: "Code MRI",
    shortName: "MRI",
    description: "Voice-activated code annotation — tags stored as portable .mri.json sidecars",
    icon: "mic",
    connectionStatus: ServiceConnected, // Local filesystem I/O, always available
    hasBackend: false, // Reads/writes .mri.json sidecar files, no HTTP service
  },
  {
    id: PanelAi,
    name: "AI",
    shortName: "AI",
    description: "Multi-provider AI neural interface — Claude, Gemini, Mistral, GPT, local models",
    icon: "brain-circuit",
    connectionStatus: ServiceDisconnected, // Connects to external AI providers
    hasBackend: true, // HTTP calls to AI provider APIs
  },
  {
    id: PanelRepoLoader,
    name: "Repo Loader",
    shortName: "Repo",
    description: "Repository scanner and panel configuration — load a repo, configure panels",
    icon: "folder-open",
    connectionStatus: ServiceConnected, // Local filesystem scanning, always available
    hasBackend: true, // Scans filesystem and reads manifests via Tauri
  },
  {
    id: PanelWorkspace,
    name: "Workspace",
    shortName: "WS",
    description: "Panel arrangements, groups, sessions, modes, and configurator",
    icon: "layout",
    connectionStatus: ServiceConnected, // Local state management, always available
    hasBackend: true, // System info queries via Tauri
  },
  {
    id: PanelCapture,
    name: "Capture",
    shortName: "Cap",
    description: "Screenshots, recordings, demos, panel cloning, and comparison views",
    icon: "camera",
    connectionStatus: ServiceConnected, // Local file I/O, always available
    hasBackend: true, // File saving via Tauri
  },
  {
    id: PanelSecurity,
    name: "Security",
    shortName: "Sec",
    description: "Secrets redaction, vault, 2FA, Trustfile enforcement, shoulder-safe mode",
    icon: "lock",
    connectionStatus: ServiceConnected, // Local + vault CLI, always available
    hasBackend: true, // Redaction regex + vault I/O via Tauri
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

/// Initial panel switcher state.
let init: panelSwitcherState = {
  activePanel: None,
  panelOrder: defaultOrder,
  panels: allPanels,
}
