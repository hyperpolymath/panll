// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Game Preview Engine — pure computation and helpers for the
/// live IDApTIK game preview panel.

open GamePreviewModel

/// Human-readable labels for category tabs.
let categoryLabel = (cat: gamePreviewCategory): string =>
  switch cat {
  | PreviewLive => "Live Preview"
  | PreviewDeviceLog => "Device Log"
  | PreviewClips => "Clips"
  | PreviewPerformance => "Performance"
  }

/// Human-readable labels for game overlays.
let overlayLabel = (overlay: gameOverlay): string =>
  switch overlay {
  | OverlayCollision => "Collision Boxes"
  | OverlayNetworkTopology => "Network Topology"
  | OverlayGuardPatrols => "Guard Patrols"
  | OverlayDeviceZones => "Device Zones"
  | OverlaySpawnPoints => "Spawn Points"
  | OverlayRenderStats => "Render Stats"
  }

/// All available overlays for the toggle panel.
let allOverlays: array<gameOverlay> = [
  OverlayCollision,
  OverlayNetworkTopology,
  OverlayGuardPatrols,
  OverlayDeviceZones,
  OverlaySpawnPoints,
  OverlayRenderStats,
]

/// Check if a specific overlay is active.
let isOverlayActive = (overlays: array<gameOverlay>, target: gameOverlay): bool =>
  Array.some(overlays, o => o === target)

/// Toggle an overlay on or off.
let toggleOverlay = (overlays: array<gameOverlay>, target: gameOverlay): array<gameOverlay> =>
  if isOverlayActive(overlays, target) {
    Array.filter(overlays, o => o !== target)
  } else {
    Array.concat(overlays, [target])
  }

/// Human-readable execution state label.
let executionLabel = (exec: gameExecutionState): string =>
  switch exec {
  | GameRunning => "Running"
  | GamePaused => "Paused"
  | GameStepping => "Stepping"
  }

/// Default state for the Game Preview panel.
let defaultState: gamePreviewState = {
  devServerConnected: false,
  devServerUrl: ServiceEndpoints.gamePreviewDev,
  execution: GameRunning,
  activeCategory: PreviewLive,
  activeOverlays: [],
  gameRecording: GameRecordingIdle,
  clips: [],
  deviceLog: [],
  stats: None,
  zoomLevel: 1.0,
  multiplayerView: false,
  error: None,
  loading: false,
}
