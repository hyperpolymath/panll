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
