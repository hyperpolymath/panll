// SPDX-License-Identifier: PMPL-1.0-or-later

/// Focus dimming messages -- dimming mode, per-panel overrides, interaction tracking.

open Model

type focusDimmingMsg =
  /// Set the global dimming mode (Off, Subtle, Strong, SmartMemory).
  | SetDimmingMode(dimmingMode)
  /// Set a per-panel override for dimming behaviour.
  | SetPanelFocusOverride(panelId, panelFocusOverride)
  /// Record a user interaction with a specific panel (updates timestamps and focus).
  | RecordInteraction(string)
  /// Set the custom dim opacity for Smart Memory Mode.
  | SetDimOpacity(float)
