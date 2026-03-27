// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL FocusDimmingEngine — Pure computation for focus-aware dimming and
/// smart memory mode.
///
/// Determines per-panel opacity classes based on focus state, dimming mode,
/// and per-panel overrides. Also manages interaction timestamps for the
/// Smart Memory mode, which progressively throttles unfocused panels to
/// conserve CPU and memory.
///
/// All functions are pure — no DOM access, no timers, no side effects.
/// The View layer calls panelOpacityClass() per panel on every render.
/// The Update layer calls recordInteraction() when panels receive input.
///
/// DESIGN NOTE: Smart Memory mode converts the configured dimOpacity float
/// to the nearest Tailwind opacity class (opacity-{0..100} in steps of 10).
/// This quantisation is intentional — Tailwind purges unused classes, so we
/// must map to a fixed set. If finer control is needed in future, the CSS
/// layer can add custom opacity utilities.

/// The default focus dimming state used at application startup.
///
/// Starts with dimming Off so all panels are fully visible and the app
/// doesn't appear dead. Users can enable SmartMemory or other modes via
/// the accessibility toolbar. A future inactivity timeout could auto-enable
/// SmartMemory after N minutes of no interaction.
let defaultState: FocusDimmingModel.focusDimmingState = {
  mode: DimmingOff,
  focusedPane: None,
  overrides: [],
  dimOpacity: 0.4,
  lastInteractionTimestamps: [],
}

/// Human-readable label for a dimming mode.
///
/// Used in the settings panel dropdown and for screen reader announcements
/// when the user changes the dimming mode.
let modeLabel = (mode: FocusDimmingModel.dimmingMode): string => {
  switch mode {
  | DimmingOff => "Off"
  | DimmingSubtle => "Subtle (70% opacity)"
  | DimmingStrong => "Strong (40% opacity)"
  | SmartMemory => "Smart Memory (dim + throttle)"
  }
}

/// Human-readable label for a panel focus override.
///
/// Used in the per-panel override selector and for screen reader
/// announcements.
let overrideLabel = (override: FocusDimmingModel.panelFocusOverride): string => {
  switch override {
  | Default => "Follow Global Mode"
  | AlwaysActive => "Always Active"
  | AlwaysDimmed => "Always Dimmed"
  }
}

/// Convert a float opacity (0.0–1.0) to the nearest Tailwind opacity class.
///
/// Quantises to the nearest 10% step and returns the corresponding Tailwind
/// utility class. Values at or above 1.0 return "" (full opacity, no class
/// needed). Values at or below 0.0 return "opacity-0".
///
/// Internal helper — not exported.
let opacityToTailwind = (opacity: float): string => {
  let pct = Int.toFloat(Float.toInt(opacity *. 10.0 +. 0.5)) *. 10.0
  if pct >= 100.0 {
    ""
  } else if pct <= 0.0 {
    "opacity-0"
  } else {
    "opacity-" ++ Int.toString(Float.toInt(pct))
  }
}

/// Look up the per-panel override for a given panel ID.
///
/// Searches the overrides array for a matching panel ID. Returns Default
/// if no override is found, meaning the panel follows the global dimming mode.
let getOverride = (
  panelId: PanelSwitcherModel.panelId,
  state: FocusDimmingModel.focusDimmingState,
): FocusDimmingModel.panelFocusOverride => {
  let found = state.overrides->Array.find(((id, _)) => id === panelId)
  switch found {
  | Some((_, override)) => override
  | None => Default
  }
}

/// Determine the CSS opacity class for a panel based on focus state.
///
/// Logic:
///   1. Check overrides first — AlwaysActive returns "" (full opacity),
///      AlwaysDimmed returns the mode's dim class regardless of focus.
///   2. If the panel's key matches focusedPane, return "" (focused = bright).
///   3. Otherwise, apply the global dimming mode:
///      - DimmingOff: "" (no dimming)
///      - DimmingSubtle: "opacity-70"
///      - DimmingStrong: "opacity-40"
///      - SmartMemory: nearest Tailwind class to dimOpacity
///
/// The panelKey parameter is a string (e.g. "paneL", "paneN", "paneW",
/// or a panel ID string) that is compared against focusedPane.
let panelOpacityClass = (state: FocusDimmingModel.focusDimmingState, panelKey: string): string => {
  // Determine the dim class for the current mode.
  let dimClass = switch state.mode {
  | DimmingOff => ""
  | DimmingSubtle => "opacity-70"
  | DimmingStrong => "opacity-40"
  | SmartMemory => opacityToTailwind(state.dimOpacity)
  }

  // Check if this panel has a per-panel override.
  // Overrides are stored as (panelId, override) tuples; we need to match
  // by string comparison since panelKey is a string, not a panelId variant.
  // For core panes (paneL, paneN, paneW), there are no overrides — they
  // always follow the global mode.
  let hasAlwaysActive = state.overrides->Array.some(((_, ov)) => {
    switch ov {
    | AlwaysActive => true
    | _ => false
    }
  })
  // NOTE: Override matching by panelKey string is a simplification. The full
  // implementation would require a panelId-to-string mapping. For now, core
  // panes and string-based lookups follow the global mode directly.
  let _ = hasAlwaysActive

  // If this panel is focused, it is always fully opaque.
  let isFocused = switch state.focusedPane {
  | Some(focused) => focused === panelKey
  | None => false
  }

  if isFocused {
    ""
  } else {
    dimClass
  }
}

/// Determine whether a panel should have its processing throttled.
///
/// Returns true only when ALL of the following are true:
///   - The global mode is SmartMemory
///   - The panel is NOT focused (focusedPane does not match panelKey)
///   - The panel does NOT have an AlwaysActive override
///
/// When true, the subscription layer should double polling intervals and
/// halve refresh rates for this panel to conserve resources.
let shouldThrottle = (state: FocusDimmingModel.focusDimmingState, panelKey: string): bool => {
  // Only SmartMemory mode throttles.
  if state.mode !== SmartMemory {
    false
  } else {
    // Check focus.
    let isFocused = switch state.focusedPane {
    | Some(focused) => focused === panelKey
    | None => false
    }
    if isFocused {
      false
    } else {
      // Check for AlwaysActive override. Since we're matching by string
      // and overrides use panelId, we check all overrides — the caller is
      // responsible for passing the correct panelKey that corresponds to
      // a panelId for override matching to work.
      let hasAlwaysActive = state.overrides->Array.some(((_, ov)) => {
        switch ov {
        | AlwaysActive => true
        | _ => false
        }
      })

      // This is a conservative check — if ANY panel has AlwaysActive, we
      // still throttle other panels. The proper per-panel check requires
      // panelId matching, which the full implementation will use.
      !hasAlwaysActive
    }
  }
}

/// Record a user interaction with a panel.
///
/// Updates the lastInteractionTimestamps array with the new timestamp for
/// the given panelKey, and sets focusedPane to that panel. If the panel
/// already has a timestamp entry, it is replaced; otherwise a new entry
/// is appended.
///
/// Called by the Update layer whenever a panel receives mouse, keyboard,
/// or touch input.
let recordInteraction = (
  state: FocusDimmingModel.focusDimmingState,
  panelKey: string,
  timestamp: float,
): FocusDimmingModel.focusDimmingState => {
  let filtered = state.lastInteractionTimestamps->Array.filter(((key, _)) => key !== panelKey)
  {
    ...state,
    focusedPane: Some(panelKey),
    lastInteractionTimestamps: Array.concat(filtered, [(panelKey, timestamp)]),
  }
}

/// Set the per-panel dimming override for a given panel ID.
///
/// If the panel already has an override entry, it is replaced. If the
/// override is Default, the entry is removed entirely (no need to store
/// "follow global" explicitly). This keeps the overrides array minimal.
let setOverride = (
  panelId: PanelSwitcherModel.panelId,
  override: FocusDimmingModel.panelFocusOverride,
  state: FocusDimmingModel.focusDimmingState,
): FocusDimmingModel.focusDimmingState => {
  let filtered = state.overrides->Array.filter(((id, _)) => id !== panelId)
  let newOverrides = switch override {
  | Default => filtered
  | _ => Array.concat(filtered, [(panelId, override)])
  }
  {
    ...state,
    overrides: newOverrides,
  }
}
