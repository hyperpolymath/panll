// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL TilingEngine — Pure computation for multi-monitor and window management.
///
/// Manages detached panel state (panels popped into separate browser windows),
/// snap zone positioning, and tiling preset labels. All functions are pure —
/// actual window operations are performed by WindowBridge via commands dispatched
/// from the Update layer.
///
/// DESIGN NOTE: Detached panels are tracked by windowName (a unique string set
/// as window.name on the child window). This serves as both the BroadcastChannel
/// target and the lookup key for lifecycle management. When a detached window
/// closes or becomes unresponsive, it is marked "dead" (alive: false) but kept
/// in the array until explicitly removed, allowing the UI to show a
/// "reconnect or discard" prompt.

/// The default tiling state used at application startup.
///
/// Tiling is disabled by default — users opt in via the toolbar or keyboard
/// shortcuts. No panels are detached, no preset is active, and the snap
/// preview is hidden.
let defaultState: TilingModel.tilingState = {
  detachedPanels: [],
  activePreset: None,
  snapPreview: None,
  tilingEnabled: false,
  controlsVisible: false,
}

/// Human-readable label for a snap zone.
///
/// Used in the tiling controls UI, tooltips, and screen reader announcements
/// when the user drags a panel near a screen edge and the snap preview appears.
let snapZoneLabel = (zone: TilingModel.snapZone): string => {
  switch zone {
  | SnapLeft => "Left Half"
  | SnapRight => "Right Half"
  | SnapTopLeft => "Top Left Quarter"
  | SnapTopRight => "Top Right Quarter"
  | SnapBottomLeft => "Bottom Left Quarter"
  | SnapBottomRight => "Bottom Right Quarter"
  | SnapFull => "Full Screen"
  | SnapCentre => "Centre Floating"
  }
}

/// CSS positioning classes for a snap zone.
///
/// Returns Tailwind utility classes that position and size a panel within
/// the snap zone. These are applied to the panel container element when a
/// tiling preset is active or when the user snaps a panel to an edge.
///
/// Uses fractional widths (w-1/2, w-1/4) and absolute positioning (left-0,
/// top-0, right-0, bottom-0) so panels tile correctly without overlapping.
/// SnapCentre uses a centred fixed-size layout for floating panels.
let snapZoneCss = (zone: TilingModel.snapZone): string => {
  switch zone {
  | SnapLeft => "left-0 top-0 w-1/2 h-full"
  | SnapRight => "right-0 top-0 w-1/2 h-full"
  | SnapTopLeft => "left-0 top-0 w-1/2 h-1/2"
  | SnapTopRight => "right-0 top-0 w-1/2 h-1/2"
  | SnapBottomLeft => "left-0 bottom-0 w-1/2 h-1/2"
  | SnapBottomRight => "right-0 bottom-0 w-1/2 h-1/2"
  | SnapFull => "left-0 top-0 w-full h-full"
  | SnapCentre => "left-1/4 top-1/4 w-1/2 h-1/2"
  }
}

/// Human-readable label for a tiling preset.
///
/// Used in the preset selector dropdown and keyboard shortcut hints.
/// Custom presets show the number of panel-to-zone mappings they contain.
let presetLabel = (preset: TilingModel.tilingPreset): string => {
  switch preset {
  | SideBySide => "Side by Side (50/50)"
  | TripleColumn => "Triple Column (33/33/33)"
  | QuadGrid => "Quad Grid (2x2)"
  | FocusAndSidebar => "Focus + Sidebar (75/25)"
  | Custom(mappings) =>
    "Custom (" ++ Int.toString(Array.length(mappings)) ++ " panels)"
  }
}

/// Check whether a given panel is currently detached into its own window.
///
/// Looks up the panel ID in the detachedPanels array. A panel is considered
/// detached even if its window is marked dead (alive: false) — the entry
/// persists until explicitly removed.
let isDetached = (
  panelId: PanelSwitcherModel.panelId,
  state: TilingModel.tilingState,
): bool => {
  state.detachedPanels->Array.some(dp => dp.panelId === panelId)
}

/// Add a panel to the detached panels array.
///
/// Creates a new detachedPanel entry with the given panel ID and window name,
/// initial position and size unknown (None), and alive: true. If the panel
/// is already detached, the existing entry is replaced (the old window is
/// assumed to have been closed by the caller).
let addDetachedPanel = (
  panelId: PanelSwitcherModel.panelId,
  windowName: string,
  state: TilingModel.tilingState,
): TilingModel.tilingState => {
  let filtered = state.detachedPanels->Array.filter(dp => dp.panelId !== panelId)
  let newEntry: TilingModel.detachedPanel = {
    panelId,
    windowName,
    position: None,
    size: None,
    alive: true,
  }
  {
    ...state,
    detachedPanels: Array.concat(filtered, [newEntry]),
  }
}

/// Remove a detached panel by its window name.
///
/// Filters the panel out of the detachedPanels array entirely. Use this
/// when the user explicitly re-docks a panel or discards a dead window.
/// After removal, the panel reverts to rendering inline in the main window.
let removeDetachedPanel = (
  windowName: string,
  state: TilingModel.tilingState,
): TilingModel.tilingState => {
  {
    ...state,
    detachedPanels: state.detachedPanels->Array.filter(dp => dp.windowName !== windowName),
  }
}

/// Mark a detached panel's window as dead (no longer responsive).
///
/// Sets alive: false for the panel identified by windowName. The entry
/// remains in the array so the UI can show a "window lost — reconnect
/// or discard?" prompt. This is called when the BroadcastChannel heartbeat
/// times out or the window sends a beforeunload message.
let markDetachedDead = (
  windowName: string,
  state: TilingModel.tilingState,
): TilingModel.tilingState => {
  {
    ...state,
    detachedPanels: state.detachedPanels->Array.map(dp =>
      if dp.windowName === windowName {
        {...dp, alive: false}
      } else {
        dp
      }
    ),
  }
}
