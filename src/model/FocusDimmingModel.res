// SPDX-License-Identifier: MPL-2.0

/// PanLL Focus Dimming Model — types for focus-aware dimming and smart memory mode.
///
/// When a pane or panel loses focus, it can optionally dim (reduce opacity)
/// and reduce processing to minimise distractions and save resources.
///
/// Modes:
///   - Off: all panels render at full opacity and full processing, always.
///   - Subtle: unfocused panels dim to 70% opacity, no processing change.
///   - Strong: unfocused panels dim to 40% opacity, no processing change.
///   - Smart Memory: unfocused panels dim AND have their subscriptions
///     throttled (polling intervals doubled, refresh rates reduced).
///     This is the "resource-conscious" mode for memory management.
///
/// Users can override the dimming behaviour per-panel: "Always Active"
/// forces a panel to stay fully bright and fully processing regardless
/// of focus, while "Always Dimmed" forces it to stay dim even when focused.
///
/// Dependency: imports PanelSwitcherModel for panelId type only.

/// Global dimming mode — controls how unfocused panels behave.
type dimmingMode =
  /// No dimming at all. All panels render identically regardless of focus.
  | DimmingOff
  /// Subtle dimming: unfocused panels at 70% opacity. Processing unchanged.
  /// Good for reducing visual clutter without affecting performance.
  | DimmingSubtle
  /// Strong dimming: unfocused panels at 40% opacity. Processing unchanged.
  /// Good for users who want to focus intensely on one panel at a time.
  | DimmingStrong
  /// Smart Memory Mode: unfocused panels dim (configurable opacity) AND
  /// have their subscriptions throttled to reduce CPU/memory usage.
  /// Subscription polling intervals are doubled, refresh rates halved.
  /// This is the default mode — balances focus with resource conservation.
  | SmartMemory

/// Per-panel override for dimming behaviour.
type panelFocusOverride =
  /// Follow the global dimming mode (no override).
  | Default
  /// Always render at full opacity and full processing, regardless of
  /// focus state or global dimming mode. Use for panels you need to
  /// actively monitor (e.g. build dashboard, multiplayer monitor).
  | AlwaysActive
  /// Always render dimmed, even when focused. Useful for panels that
  /// serve as background reference (e.g. documentation, topology view).
  | AlwaysDimmed

/// Root state for the focus dimming system.
type focusDimmingState = {
  /// Current global dimming mode. Default: SmartMemory.
  mode: dimmingMode,
  /// Which pane or panel currently has focus.
  /// Uses string identifiers: "paneL", "paneN", "paneW", or panel IDs.
  /// None when no specific panel has focus (e.g. interacting with toolbar).
  focusedPane: option<string>,
  /// Per-panel overrides for dimming behaviour.
  /// Panels not in this array follow the global mode.
  overrides: array<(PanelSwitcherModel.panelId, panelFocusOverride)>,
  /// Custom dim opacity (0.0 = invisible, 1.0 = fully opaque).
  /// Only used when mode is SmartMemory. Default: 0.4.
  dimOpacity: float,
  /// Timestamps of last user interaction per panel (panel ID string → epoch ms).
  /// Used by Smart Memory Mode to progressively dim panels that haven't
  /// been interacted with recently.
  lastInteractionTimestamps: array<(string, float)>,
}
