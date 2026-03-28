// SPDX-License-Identifier: PMPL-1.0-or-later

/// Workspace messages -- panel groups, arrangements, sessions, modes,
/// protection levels, execution modes, checkpoints (DD-022-DD-027).

open Model

type workspaceMsg =
  /// Set the workspace mode (Rhodium, Everything, Code, Bespoke).
  | SetWorkspaceMode(workspaceMode)
  /// Cycle to the next workspace mode.
  | CycleWorkspaceMode
  /// Set session protection level.
  | SetProtection(sessionProtection)
  /// Set execution mode (Live, DryRun, Simulation, Emulation).
  | SetExecutionMode(executionMode)
  /// Toggle between Live and DryRun execution modes.
  | ToggleDryRun
  /// Create a panel group.
  | CreateGroup(string, string, array<string>)
  /// Disband a panel group.
  | DisbandGroup(string)
  /// Lock/unlock a group's arrangement.
  | ToggleGroupLock(string)
  /// Toggle group visibility.
  | ToggleGroupVisibility(string)
  /// Push a group to back.
  | PushToBack(string)
  /// Pull a group to front.
  | PullToFront(string)
  /// Save current layout as a named arrangement.
  | SaveArrangement(string, string)
  /// Load a saved arrangement by ID.
  | LoadArrangement(string)
  /// Delete a saved arrangement.
  | DeleteArrangement(string)
  /// Arrangements loaded from disk.
  | ArrangementsLoaded(result<string, string>)
  /// Create a new session.
  | CreateSession(string, string)
  /// Fork the current session.
  | ForkSession(string, string)
  /// Delete a session.
  | DeleteSession(string)
  /// Switch active session.
  | SwitchSession(string)
  /// Sessions loaded from disk.
  | SessionsLoaded(result<string, string>)
  /// Add a checkpoint to the current session.
  | AddCheckpoint(string, string)
  /// System info loaded (CPU, memory, disk).
  | SystemInfoLoaded(result<string, string>)
  /// Open/close the configurator.
  | ToggleConfigurator
  /// Switch configurator tab.
  | SetConfiguratorTab(configuratorTab)
  /// View repo metadata item.
  | ViewMetadata(repoMetadataItem)
  /// Close metadata viewer.
  | CloseMetadata
  /// Metadata content loaded.
  | MetadataLoaded(result<string, string>)
  /// Reset a single panel to its default state.
  | ResetPanel(string)
  /// Reset all panels to defaults.
  | ResetAllPanels
  /// Export workspace config (mode, protection, execution, arrangement) to ENSAID_CONFIG.a2ml.
  | ExportWorkspaceConfig
  /// TypeLL cross-panel type check result for arrangement types.
  | TypeCheckResult(result<string, string>)
