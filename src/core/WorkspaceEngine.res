// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Workspace Engine — pure functions for workspace management.
///
/// Handles panel groups, arrangements, sessions, checkpoints, workspace modes,
/// session protection, execution modes, and poly tool management.
///
/// All functions are pure: (state, action) -> state. Side effects (filesystem
/// save/load, Tauri IPC) happen elsewhere via Tea_Cmd.

open WorkspaceModel

// ============================================================================
// Group Operations
// ============================================================================

/// Create a new panel group from a set of panel IDs.
let createGroup = (
  groups: array<panelGroup>,
  id: string,
  name: string,
  panelIds: array<string>,
): array<panelGroup> => {
  Array.concat(groups, [{
    id,
    name,
    panelIds,
    locked: false,
    visible: true,
    zIndex: Array.length(groups) + 1,
    sharedWith: [],
  }])
}

/// Disband a group by ID (removes the group, panels remain independent).
let disbandGroup = (groups: array<panelGroup>, groupId: string): array<panelGroup> => {
  Array.filter(groups, g => g.id !== groupId)
}

/// Lock a group's arrangement (prevent rearrangement).
let lockGroup = (groups: array<panelGroup>, groupId: string): array<panelGroup> => {
  Array.map(groups, g =>
    if g.id === groupId { {...g, locked: true} } else { g }
  )
}

/// Unlock a group's arrangement.
let unlockGroup = (groups: array<panelGroup>, groupId: string): array<panelGroup> => {
  Array.map(groups, g =>
    if g.id === groupId { {...g, locked: false} } else { g }
  )
}

/// Toggle visibility for an entire group.
let toggleGroupVisibility = (groups: array<panelGroup>, groupId: string): array<panelGroup> => {
  Array.map(groups, g =>
    if g.id === groupId { {...g, visible: !g.visible} } else { g }
  )
}

/// Push a panel/group to back (lowest z-index).
let pushToBack = (groups: array<panelGroup>, groupId: string): array<panelGroup> => {
  Array.map(groups, g =>
    if g.id === groupId { {...g, zIndex: 0} }
    else { {...g, zIndex: g.zIndex + 1} }
  )
}

/// Pull a panel/group to front (highest z-index).
let pullToFront = (groups: array<panelGroup>, groupId: string): array<panelGroup> => {
  let maxZ = Array.reduce(groups, 0, (max, g) =>
    if g.zIndex > max { g.zIndex } else { max }
  )
  Array.map(groups, g =>
    if g.id === groupId { {...g, zIndex: maxZ + 1} } else { g }
  )
}

/// Add a panel to an existing group.
let addToGroup = (
  groups: array<panelGroup>,
  groupId: string,
  panelId: string,
): array<panelGroup> => {
  Array.map(groups, g =>
    if g.id === groupId {
      let alreadyIn = Array.some(g.panelIds, id => id === panelId)
      if alreadyIn { g }
      else { {...g, panelIds: Array.concat(g.panelIds, [panelId])} }
    } else { g }
  )
}

/// Remove a panel from a group.
let removeFromGroup = (
  groups: array<panelGroup>,
  groupId: string,
  panelId: string,
): array<panelGroup> => {
  Array.map(groups, g =>
    if g.id === groupId {
      {...g, panelIds: Array.filter(g.panelIds, id => id !== panelId)}
    } else { g }
  )
}

/// Share a group with a user.
let shareGroup = (
  groups: array<panelGroup>,
  groupId: string,
  userId: string,
): array<panelGroup> => {
  Array.map(groups, g =>
    if g.id === groupId {
      let alreadyShared = Array.some(g.sharedWith, id => id === userId)
      if alreadyShared { g }
      else { {...g, sharedWith: Array.concat(g.sharedWith, [userId])} }
    } else { g }
  )
}

// ============================================================================
// Arrangement Operations
// ============================================================================

/// Save the current panel positions as a named arrangement.
let saveArrangement = (
  arrangements: array<arrangement>,
  id: string,
  name: string,
  positions: array<panelPosition>,
  groups: array<panelGroup>,
  timestamp: float,
): array<arrangement> => {
  // If arrangement with this ID exists, update it. Otherwise, append.
  let exists = Array.some(arrangements, a => a.id === id)
  if exists {
    Array.map(arrangements, a =>
      if a.id === id {
        {...a, name, positions, groups, lastSaved: timestamp}
      } else { a }
    )
  } else {
    Array.concat(arrangements, [{
      id,
      name,
      positions,
      groups,
      builtIn: false,
      lastSaved: timestamp,
    }])
  }
}

/// Delete a non-built-in arrangement.
let deleteArrangement = (arrangements: array<arrangement>, id: string): array<arrangement> => {
  Array.filter(arrangements, a => a.id !== id || a.builtIn)
}

/// Built-in arrangement presets.
let builtInArrangements: array<arrangement> = [
  {
    id: "default-3-panel",
    name: "Default 3-Panel",
    positions: [
      { panelId: "paneL", x: 0.0, y: 0.0, width: 33.3, height: 100.0, zIndex: 1, visible: true },
      { panelId: "paneN", x: 33.3, y: 0.0, width: 33.3, height: 100.0, zIndex: 1, visible: true },
      { panelId: "paneW", x: 66.6, y: 0.0, width: 33.4, height: 100.0, zIndex: 1, visible: true },
    ],
    groups: [],
    builtIn: true,
    lastSaved: 0.0,
  },
  {
    id: "ai-focus",
    name: "AI Focus",
    positions: [
      { panelId: "paneL", x: 0.0, y: 0.0, width: 20.0, height: 100.0, zIndex: 1, visible: true },
      { panelId: "paneN", x: 20.0, y: 0.0, width: 60.0, height: 100.0, zIndex: 2, visible: true },
      { panelId: "paneW", x: 80.0, y: 0.0, width: 20.0, height: 100.0, zIndex: 1, visible: true },
    ],
    groups: [],
    builtIn: true,
    lastSaved: 0.0,
  },
  {
    id: "debug-layout",
    name: "Debug Layout",
    positions: [
      { panelId: "paneL", x: 0.0, y: 0.0, width: 50.0, height: 50.0, zIndex: 1, visible: true },
      { panelId: "paneN", x: 50.0, y: 0.0, width: 50.0, height: 50.0, zIndex: 1, visible: true },
      { panelId: "paneW", x: 0.0, y: 50.0, width: 100.0, height: 50.0, zIndex: 2, visible: true },
    ],
    groups: [],
    builtIn: true,
    lastSaved: 0.0,
  },
  {
    id: "teaching-mode",
    name: "Teaching Mode",
    positions: [
      { panelId: "paneL", x: 0.0, y: 0.0, width: 50.0, height: 100.0, zIndex: 1, visible: true },
      { panelId: "paneN", x: 50.0, y: 0.0, width: 50.0, height: 50.0, zIndex: 1, visible: true },
      { panelId: "paneW", x: 50.0, y: 50.0, width: 50.0, height: 50.0, zIndex: 1, visible: true },
    ],
    groups: [],
    builtIn: true,
    lastSaved: 0.0,
  },
]

// ============================================================================
// Session Operations
// ============================================================================

/// Create a new session.
let createSession = (
  sessions: array<session>,
  id: string,
  name: string,
  repoPath: option<string>,
  timestamp: float,
): array<session> => {
  Array.concat(sessions, [{
    id,
    name,
    repoPath,
    arrangementId: Some("default-3-panel"),
    protection: Open,
    executionMode: Live,
    workspaceMode: EverythingMode,
    checkpoints: [],
    created: timestamp,
    lastActive: timestamp,
    forkedFrom: None,
  }])
}

/// Fork a session — create an independent copy that starts from the current state.
let forkSession = (
  sessions: array<session>,
  sourceId: string,
  newId: string,
  newName: string,
  timestamp: float,
): array<session> => {
  let source = Array.find(sessions, s => s.id === sourceId)
  switch source {
  | Some(s) =>
    Array.concat(sessions, [{
      ...s,
      id: newId,
      name: newName,
      created: timestamp,
      lastActive: timestamp,
      forkedFrom: Some(sourceId),
    }])
  | None => sessions
  }
}

/// Add a checkpoint to a session.
let addCheckpoint = (
  sessions: array<session>,
  sessionId: string,
  checkpointId: string,
  label: string,
  timestamp: float,
  automatic: bool,
): array<session> => {
  Array.map(sessions, s =>
    if s.id === sessionId {
      {...s, checkpoints: Array.concat(s.checkpoints, [{
        id: checkpointId,
        label,
        timestamp,
        automatic,
      }])}
    } else { s }
  )
}

/// Delete a session.
let deleteSession = (sessions: array<session>, id: string): array<session> => {
  Array.filter(sessions, s => s.id !== id)
}

/// Update a session's protection level.
let setSessionProtection = (
  sessions: array<session>,
  sessionId: string,
  protection: sessionProtection,
): array<session> => {
  Array.map(sessions, s =>
    if s.id === sessionId { {...s, protection} } else { s }
  )
}

/// Update a session's execution mode.
let setExecutionMode = (
  sessions: array<session>,
  sessionId: string,
  mode: executionMode,
): array<session> => {
  Array.map(sessions, s =>
    if s.id === sessionId { {...s, executionMode: mode} } else { s }
  )
}

// ============================================================================
// Workspace Mode Cycling
// ============================================================================

/// Cycle to the next workspace mode in order:
/// Rhodium → Everything → Code → Bespoke → Rhodium.
let cycleMode = (current: workspaceMode): workspaceMode => {
  switch current {
  | RhodiumMode => EverythingMode
  | EverythingMode => CodeMode
  | CodeMode => BespokeMode
  | BespokeMode => RhodiumMode
  }
}

/// Determine which panel IDs should be visible for a given workspace mode.
/// Returns an array of panel ID strings. In Code mode, RSR-specific panels
/// are hidden. In Rhodium mode, everything is shown. Bespoke delegates to
/// a per-repo manifest.
let visiblePanelsForMode = (mode: workspaceMode): option<array<string>> => {
  switch mode {
  | EverythingMode => None // None means "show all"
  | RhodiumMode => None // Also show all (RSR is the full standard)
  | CodeMode =>
    // Code mode: hide RSR governance panels, keep dev-focused panels
    Some([
      "PanelVab",
      "PanelDatabases",
      "PanelPlaygrounds",
      "PanelAi",
      "PanelRepoLoader",
      "PanelAerie",
      "PanelInterfaces",
      "PanelCapture",
      "PanelWorkspace",
    ])
  | BespokeMode => None // Bespoke: loaded from PANELS.a2ml (handled elsewhere)
  }
}

// ============================================================================
// Protection Enforcement
// ============================================================================

/// Check whether a mutation is allowed under the current session protection.
/// Returns true if the action should be blocked.
let isMutationBlocked = (protection: sessionProtection): bool => {
  switch protection {
  | Open => false
  | ReadOnly => true
  | Sandboxed => false // Allowed, but will be rolled back
  | LanguageLocked(_) => false // Checked per-file, not globally
  | TranspilationGuarded => false // Allowed, but save requires proof
  | ProductionGated => false // Allowed, but commit requires sign-off
  }
}

/// Check whether a file mutation is allowed for a specific file path
/// under LanguageLocked protection.
let isFileBlocked = (protection: sessionProtection, filePath: string): bool => {
  switch protection {
  | LanguageLocked(extensions) =>
    Array.some(extensions, ext => {
      // Check if the file path ends with the locked extension
      let extLen = String.length(ext)
      let pathLen = String.length(filePath)
      if pathLen >= extLen {
        String.sliceToEnd(filePath, ~start=pathLen - extLen) === ext
      } else {
        false
      }
    })
  | _ => false
  }
}

// ============================================================================
// Default State
// ============================================================================

/// Initial workspace state.
let defaultState: workspaceState = {
  mode: EverythingMode,
  protection: Open,
  executionMode: Live,
  groups: [],
  arrangements: builtInArrangements,
  activeArrangementId: Some("default-3-panel"),
  sessions: [],
  activeSessionId: None,
  polyTools: [],
  configuratorOpen: false,
  configuratorTab: TabArrangements,
  viewingMetadata: None,
  metadataContent: None,
}
