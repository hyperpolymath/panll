// SPDX-License-Identifier: MPL-2.0

/// Game Preview messages -- dev server lifecycle, game loop control,
/// overlay management, gameplay recording, and render stats for the
/// live IDApTIK game preview panel.

open Model

type gamePreviewMsg =
  /// Switch the active category tab.
  | SetPreviewCategory(gamePreviewCategory)
  /// Check if the Vite dev server is running.
  | CheckDevServer
  /// Dev server check result.
  | DevServerResult(result<string, string>)
  /// Pause the game loop.
  | PauseGame
  /// Resume the game loop.
  | ResumeGame
  /// Step one frame forward (when paused).
  | StepFrame
  /// Game control result.
  | GameControlResult(result<string, string>)
  /// Toggle a game overlay on/off.
  | ToggleOverlay(gameOverlay)
  /// Start recording gameplay to WebM.
  | StartGameRecording
  /// Stop gameplay recording.
  | StopGameRecording
  /// Gameplay recording started (or failed).
  | GameRecordingStarted(result<string, string>)
  /// Gameplay recording stopped (or failed).
  | GameRecordingStopped(result<string, string>)
  /// Take a screenshot of the current game frame.
  | ScreenshotGame
  /// Game screenshot captured (or failed).
  | GameScreenshotCaptured(result<string, string>)
  /// Set the zoom level.
  | SetZoom(float)
  /// Toggle multiplayer/co-op view.
  | ToggleMultiplayerView
  /// Load saved gameplay clips.
  | LoadClips
  /// Clips loaded (or failed).
  | ClipsLoaded(result<string, string>)
  /// Delete a gameplay clip by ID.
  | DeleteClip(string)
  /// Clip deleted (or failed).
  | ClipDeleted(result<string, string>)
  /// Refresh render statistics.
  | RefreshStats
  /// Render stats received.
  | StatsReceived(result<string, string>)
  /// Clear the device interaction log.
  | ClearDeviceLog
  /// A device interaction event arrived from the game.
  | DeviceInteractionEvent(deviceInteraction)
  /// Dismiss the error banner.
  | DismissGameError
  /// TypeLL cross-panel type check result for game config types.
  | TypeCheckResult(result<string, string>)
