// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Tiling Model — types for multi-monitor and window management.
///
/// Supports panel detachment (pop panels into separate browser windows),
/// Aero-style snap zones for quick panel positioning, and tiling presets
/// for common multi-panel layouts.
///
/// Cross-window communication uses the BroadcastChannel API for message
/// passing between the main PanLL window and detached panel windows.
/// Each detached window runs a minimal PanLL shell rendering a single panel.
///
/// NOTE: Virtual desktop awareness is OS-level and not accessible from
/// browser APIs. The Gossamer backend could provide this via native window
/// management APIs in a future phase. For now, tiling operates within
/// the browser's own window management.
///
/// Dependency: imports PanelSwitcherModel for panelId type only.

/// Snap zones for Aero-style window positioning.
/// Each zone represents a screen region that a panel can snap to.
type snapZone =
  /// Left half of screen (Windows+Left equivalent).
  | SnapLeft
  /// Right half of screen (Windows+Right equivalent).
  | SnapRight
  /// Top-left quarter of screen.
  | SnapTopLeft
  /// Top-right quarter of screen.
  | SnapTopRight
  /// Bottom-left quarter of screen.
  | SnapBottomLeft
  /// Bottom-right quarter of screen.
  | SnapBottomRight
  /// Full screen / maximised.
  | SnapFull
  /// Centre floating — not snapped to any edge.
  | SnapCentre

/// Predefined tiling presets for common multi-panel layouts.
/// Users can apply a preset with one click or keyboard shortcut.
type tilingPreset =
  /// Two panels side by side (50/50 split).
  | SideBySide
  /// Three panels in equal columns (33/33/33 split).
  | TripleColumn
  /// Four panels in a 2x2 grid (each takes a quarter).
  | QuadGrid
  /// One large focus panel (75%) with a narrow sidebar panel (25%).
  | FocusAndSidebar
  /// Custom user-defined layout mapping panels to snap zones.
  | Custom(array<(PanelSwitcherModel.panelId, snapZone)>)

/// A panel that has been detached into its own browser window.
/// Tracks the window reference for communication and cleanup.
type detachedPanel = {
  /// Which panel is detached.
  panelId: PanelSwitcherModel.panelId,
  /// Browser window.name used to identify this detached window.
  /// Used as the BroadcastChannel message target.
  windowName: string,
  /// Last known window position (x, y in screen pixels).
  /// Updated when the detached window reports its position.
  position: option<(int, int)>,
  /// Last known window size (width, height in pixels).
  size: option<(int, int)>,
  /// Whether the detached window is still open and responsive.
  alive: bool,
}

/// Root state for the tiling and window management system.
type tilingState = {
  /// Panels currently detached into their own browser windows.
  detachedPanels: array<detachedPanel>,
  /// Currently active tiling preset (None = freeform layout).
  activePreset: option<tilingPreset>,
  /// Snap zone preview shown while dragging a panel near a screen edge.
  /// None when not actively dragging.
  snapPreview: option<snapZone>,
  /// Master toggle for the tiling system. When false, all tiling features
  /// are disabled and panels behave as standard overlays.
  tilingEnabled: bool,
  /// Whether the tiling controls UI is visible.
  controlsVisible: bool,
}
