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

/// Generate the PixiJS embed script tag content for the game preview iframe.
/// This produces a minimal bootstrap that loads the IDApTIK game engine
/// and connects the dev server hot-reload socket.
let pixiBootstrapScript = (devServerUrl: string): string => {
  "const app = new PIXI.Application();" ++
  "await app.init({ width: 800, height: 600, backgroundColor: 0x1a1a2e });" ++
  "document.getElementById('game-root').appendChild(app.canvas);" ++
  "const ws = new WebSocket('" ++ devServerUrl ++ "/ws');" ++
  "ws.onmessage = (e) => { if (e.data === 'reload') { location.reload(); } };" ++
  "app.ticker.add(() => { /* game loop placeholder */ });"
}

/// Generate a srcdoc HTML string for the game preview iframe.
/// Embeds PixiJS from CDN and runs the bootstrap script.
let iframeSrcDoc = (devServerUrl: string): string => {
  "<!DOCTYPE html>" ++
  "<html><head>" ++
  "<script src='https://cdn.jsdelivr.net/npm/pixi.js@8/dist/pixi.min.mjs' type='module'></script>" ++
  "<style>body{margin:0;overflow:hidden;background:#1a1a2e}</style>" ++
  "</head><body>" ++
  "<div id='game-root'></div>" ++
  "<script type='module'>" ++ pixiBootstrapScript(devServerUrl) ++ "</script>" ++
  "</body></html>"
}

/// Default render stats for the performance tab.
let defaultRenderStats: renderStats = {
  fps: 60.0,
  drawCalls: 0,
  textureMemory: 0,
  spriteCount: 0,
}

/// Format render stats as a human-readable summary line.
let renderStatsLabel = (stats: renderStats): string => {
  Float.toFixed(stats.fps, ~digits=1) ++ " FPS | " ++
  Int.toString(stats.drawCalls) ++ " draws | " ++
  Int.toString(stats.spriteCount) ++ " sprites"
}
