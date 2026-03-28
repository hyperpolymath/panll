// SPDX-License-Identifier: PMPL-1.0-or-later

/// Panel switcher messages -- unified panel navigation replacing ad-hoc
/// `visible: bool` toggles on individual overlays.

open Model

type panelSwitcherMsg =
  /// Toggle a panel: opens it if closed, closes if already active.
  | TogglePanel(panelId)
  /// Close whatever panel is currently active (Escape key handler).
  | ClosePanels
  /// Expand a group in the sidebar (by kind name, e.g. "ai", "bridge").
  /// Clicking the same group again collapses it.
  | ExpandGroup(string)
  /// Health check result for a panel's backend service.
  | HealthCheckResult(panelId, result<string, string>)
