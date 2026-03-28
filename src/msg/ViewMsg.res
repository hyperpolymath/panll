// SPDX-License-Identifier: PMPL-1.0-or-later

/// View control messages -- pane toggles, mode switching, and layout controls.

open Model

type viewMsg =
  | TogglePaneL
  | TogglePaneN
  | TogglePaneW
  | ToggleProtocolAnalysis
  | SetViewMode(viewMode)
  | SetHumidity(humidityLevel)
  | ParallaxAlign // Synchronous horizontal tiling
  | TogglePanelBar // Toggle panel switcher bar visibility
  | ToggleFullscreen // Toggle fullscreen (hide all chrome)
