// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Game Preview Model — types for the live IDApTIK game preview panel.
///
/// Embeds the Vite dev server output (port 8080) in a PanLL panel via Tauri
/// webview or iframe. Supports hot-reload, frame stepping, overlay toggles,
/// gameplay recording, and render statistics.
///
/// The preview connects to the running IDApTIK dev server and reflects
/// ReScript code changes in real time. Overlays can show collision boxes,
/// network topology, guard patrol paths, and device interaction logs.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Which overlays are currently enabled on top of the game preview.
type gameOverlay =
  /// Show collision bounding boxes for all entities.
  | OverlayCollision
  /// Show in-game network topology as a force-directed graph.
  | OverlayNetworkTopology
  /// Show guard patrol waypoint paths.
  | OverlayGuardPatrols
  /// Show device interaction zones (clickable areas).
  | OverlayDeviceZones
  /// Show spawn points for player, guards, companions.
  | OverlaySpawnPoints
  /// Show FPS counter and render statistics.
  | OverlayRenderStats

/// Game loop execution state — whether the game is running or paused.
type gameExecutionState =
  /// Game loop is running normally.
  | GameRunning
  /// Game loop is paused (frame-by-frame stepping available).
  | GamePaused
  /// Game loop is stepping one frame at a time.
  | GameStepping

/// Gameplay recording state — captures WebM video of the preview.
type gameRecordingState =
  /// Not recording gameplay.
  | GameRecordingIdle
  /// Actively recording gameplay to WebM.
  | GameRecordingActive(float)
  /// Recording paused.
  | GameRecordingPaused(float)

/// A device interaction log entry — records which devices the player touched.
type deviceInteraction = {
  /// Device type name (e.g., "DesktopDevice", "CameraDevice").
  deviceType: string,
  /// Device ID in the level.
  deviceId: string,
  /// Interaction type (e.g., "opened", "hacked", "scanned").
  interaction: string,
  /// Unix timestamp of the interaction.
  timestamp: float,
}

/// A saved gameplay clip.
type gameplayClip = {
  /// Unique identifier.
  id: string,
  /// Human-readable name.
  name: string,
  /// Absolute path to the WebM file.
  path: string,
  /// Duration in seconds.
  durationSecs: float,
  /// File size in bytes.
  sizeBytes: int,
  /// When the clip was recorded (Unix timestamp).
  createdAt: float,
}

/// Render statistics from the PixiJS engine.
type renderStats = {
  /// Frames per second.
  fps: float,
  /// Draw calls per frame.
  drawCalls: int,
  /// Texture memory usage in bytes.
  textureMemory: int,
  /// Number of active sprites.
  spriteCount: int,
}

/// Category tabs for the Game Preview panel.
type gamePreviewCategory =
  /// Main game preview with live iframe/webview.
  | PreviewLive
  /// Device interaction log.
  | PreviewDeviceLog
  /// Saved gameplay clips browser.
  | PreviewClips
  /// Render statistics and performance profiling.
  | PreviewPerformance

/// Root state for the Game Preview panel.
type gamePreviewState = {
  /// Whether the Vite dev server is detected and running.
  devServerConnected: bool,
  /// The URL of the dev server (default: http://localhost:8080).
  devServerUrl: string,
  /// Game loop execution state (running, paused, stepping).
  execution: gameExecutionState,
  /// Active category tab.
  activeCategory: gamePreviewCategory,
  /// Which overlays are currently enabled.
  activeOverlays: array<gameOverlay>,
  /// Gameplay recording state.
  gameRecording: gameRecordingState,
  /// Saved gameplay clips.
  clips: array<gameplayClip>,
  /// Device interaction log (ring buffer, last 200 entries).
  deviceLog: array<deviceInteraction>,
  /// Current render statistics.
  stats: option<renderStats>,
  /// Current zoom level (1.0 = normal, 0.5 = zoomed out, 2.0 = zoomed in).
  zoomLevel: float,
  /// Whether multiplayer view is active (shows both players).
  multiplayerView: bool,
  /// Error message (if any).
  error: option<string>,
  /// Loading state for async operations.
  loading: bool,
}
