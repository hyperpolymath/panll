// SPDX-License-Identifier: MPL-2.0

/// PanLL Workspace Model — types for panel groups, arrangements, sessions,
/// workspace modes, session protection, simulation, and poly integration.
///
/// This is the backbone of PanLL's workspace management layer (DD-022 through DD-027).
/// It covers everything from how panels are grouped and arranged to how sessions
/// are protected against accidental (or intentional) mutations.
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Workspace Modes
// ============================================================================

/// Workspace personality modes — each hides/shows different subsets of panels
/// and metadata depending on the user's current focus. These are menu-selectable
/// and persist across sessions.
///
/// - Rhodium: full RSR standard compliance view (SCM files, contractiles, AI manifests,
///   directory structure, all governance panels visible)
/// - Everything: every panel, every tool, every metadata viewer enabled
/// - Code: pure development experience — hides RSR/compliance/governance panels,
///   shows only panels directly relevant to writing code
/// - Bespoke: per-repo customisation of which panels and metadata are visible,
///   saved in the repo's PANELS.a2ml manifest
type workspaceMode =
  | RhodiumMode
  | EverythingMode
  | CodeMode
  | BespokeMode

// ============================================================================
// Session Protection
// ============================================================================

/// Session protection levels control what operations are permitted within a
/// session. These form a lattice from fully open to fully locked:
///
/// - Open: normal operation, no restrictions
/// - ReadOnly: browse everything, edit nothing
/// - Sandboxed: all changes reset when the session ends
/// - LanguageLocked: specific languages are immutable (e.g., Idris files cannot
///   be edited, everything else is open)
/// - TranspilationGuarded: saves require equivalence proof — the new version must
///   produce the same output as the old before the save is committed
/// - ProductionGated: changes are staged and require explicit sign-off before
///   taking effect, like a release gate
type sessionProtection =
  | Open
  | ReadOnly
  | Sandboxed
  | LanguageLocked(array<string>)
  | TranspilationGuarded
  | ProductionGated

/// Execution modes for testing changes safely before committing them.
///
/// - Live: real execution against real data (normal operation)
/// - DryRun: preview changes without applying — shows diffs, no mutations
/// - Simulation: run scenarios in a simulated environment with mock data
/// - Emulation: full emulation of the target environment locally
type executionMode =
  | Live
  | DryRun
  | Simulation
  | Emulation

// ============================================================================
// Panel Groups
// ============================================================================

/// A group of panels that move, resize, show, and hide together.
/// Groups are the primary unit of panel organisation beyond individual panels.
type panelGroup = {
  /// Unique identifier for this group.
  id: string,
  /// Human-readable name (user-assigned).
  name: string,
  /// Panel IDs belonging to this group.
  panelIds: array<string>,
  /// Whether the group's arrangement is locked (prevents accidental rearrangement).
  locked: bool,
  /// Whether the group is currently visible.
  visible: bool,
  /// Z-order index (higher = closer to front).
  zIndex: int,
  /// User IDs this group is shared with (for collaboration).
  sharedWith: array<string>,
}

// ============================================================================
// Panel Arrangements (Named Layout Presets)
// ============================================================================

/// Position and size of a single panel within an arrangement.
type panelPosition = {
  /// Panel identifier (as string for flexibility with custom panels).
  panelId: string,
  /// Horizontal position (percentage of viewport, 0.0–100.0).
  x: float,
  /// Vertical position (percentage of viewport, 0.0–100.0).
  y: float,
  /// Width (percentage of viewport).
  width: float,
  /// Height (percentage of viewport).
  height: float,
  /// Z-order within the arrangement.
  zIndex: int,
  /// Whether this panel is visible in this arrangement.
  visible: bool,
}

/// A named arrangement captures the complete layout state of all panels,
/// their positions, sizes, groups, and visibility. Arrangements can be
/// saved, loaded, and shared.
type arrangement = {
  /// Unique identifier.
  id: string,
  /// Human-readable name ("Default 3-Panel", "AI Focus", "Debug Layout", etc.).
  name: string,
  /// Panel positions within this arrangement.
  positions: array<panelPosition>,
  /// Group definitions active in this arrangement.
  groups: array<panelGroup>,
  /// Whether this is a built-in preset (cannot be deleted, but can be overridden).
  builtIn: bool,
  /// Timestamp when this arrangement was last saved.
  lastSaved: float,
}

// ============================================================================
// Sessions & Checkpoints
// ============================================================================

/// A checkpoint is a named snapshot of the entire workspace state at a point in
/// time. Used for reset-to-checkpoint, undo-beyond-buffer, and session branching.
type checkpoint = {
  /// Unique identifier.
  id: string,
  /// Human-readable label.
  label: string,
  /// Timestamp when the checkpoint was created.
  timestamp: float,
  /// Whether this was an automatic checkpoint (periodic) or manual.
  automatic: bool,
}

/// A session represents a complete working context: which repo is loaded,
/// which arrangement is active, what protection level applies, etc.
/// Sessions can be saved, loaded, and forked (creating independent copies).
type session = {
  /// Unique identifier.
  id: string,
  /// Human-readable name.
  name: string,
  /// The repo path this session was created for (if any).
  repoPath: option<string>,
  /// Active arrangement ID.
  arrangementId: option<string>,
  /// Protection level for this session.
  protection: sessionProtection,
  /// Execution mode (live, dry-run, simulation, emulation).
  executionMode: executionMode,
  /// Active workspace mode.
  workspaceMode: workspaceMode,
  /// Checkpoints within this session.
  checkpoints: array<checkpoint>,
  /// Timestamp when this session was created.
  created: float,
  /// Timestamp of last activity.
  lastActive: float,
  /// Parent session ID if this was forked.
  forkedFrom: option<string>,
}

// ============================================================================
// Poly Integration
// ============================================================================

/// Categories of external tools available via polystack integration.
/// These represent the families of tools the AI panel can call into.
type polyToolCategory =
  | PolyMcp
  | PolySecrets
  | PolyKubernetes
  | PolyDatabases
  | PolyContainers
  | PolyNetworking
  | PolyMonitoring
  | PolyCustom(string)

/// A registered poly tool that can be invoked from the workspace.
type polyTool = {
  /// Unique identifier.
  id: string,
  /// Display name.
  name: string,
  /// Category this tool belongs to.
  category: polyToolCategory,
  /// Brief description of what this tool does.
  description: string,
  /// Whether this tool is currently available (service running, auth valid, etc.).
  available: bool,
  /// The command or endpoint to invoke this tool.
  endpoint: string,
}

// ============================================================================
// Repo Metadata Menu Items
// ============================================================================

/// Items viewable from the workspace menu — SCM files, contractiles, AI manifests,
/// and directory structure. These are the "bones" that RSR repos expose.
type repoMetadataItem =
  | MetaStateSCM
  | MetaEcosystemSCM
  | MetaMetaSCM
  | MetaAgenticSCM
  | MetaNeurosymSCM
  | MetaPlaybookSCM
  | MetaLanguagesSCM
  | MetaContractiles
  | MetaAIManifest
  | MetaTrustfile
  | MetaDirectoryTree
  | MetaTopology

// ============================================================================
// Configurator Tabs
// ============================================================================

/// Tabs within the workspace configurator panel.
type configuratorTab =
  | TabArrangements
  | TabGroups
  | TabSessions
  | TabKeybindings
  | TabModes
  | TabProtection
  | TabPolyTools

// ============================================================================
// Workspace State
// ============================================================================

/// Root state for the workspace management system.
type workspaceState = {
  /// Currently active workspace mode.
  mode: workspaceMode,
  /// Current session protection level.
  protection: sessionProtection,
  /// Current execution mode.
  executionMode: executionMode,
  /// All panel groups.
  groups: array<panelGroup>,
  /// All saved arrangements.
  arrangements: array<arrangement>,
  /// Currently active arrangement ID.
  activeArrangementId: option<string>,
  /// All saved sessions.
  sessions: array<session>,
  /// Currently active session ID.
  activeSessionId: option<string>,
  /// All registered poly tools.
  polyTools: array<polyTool>,
  /// Whether the workspace configurator is open.
  configuratorOpen: bool,
  /// Active configurator tab.
  configuratorTab: configuratorTab,
  /// Currently viewed repo metadata item (for the menu viewer).
  viewingMetadata: option<repoMetadataItem>,
  /// Content of the currently viewed metadata item.
  metadataContent: option<string>,
}
