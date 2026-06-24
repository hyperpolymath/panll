// SPDX-License-Identifier: MPL-2.0

/// Capture messages -- screenshots, recordings, demos, cloning (DD-022).

open Model

type captureMsg =
  /// Take a screenshot of a panel.
  | CaptureScreenshot(string)
  /// Screenshot saved to disk.
  | ScreenshotSaved(result<string, string>)
  /// Start recording a panel.
  | StartRecording(string)
  /// Stop recording.
  | StopRecording
  /// Pause/resume recording.
  | TogglePauseRecording
  /// Print the active panel.
  | PrintPanel(string)
  /// Print result.
  | PrintResult(result<string, string>)
  /// Toggle capture selection for a panel (multi-panel capture).
  | ToggleCaptureSelection(string)
  /// Clear capture selection.
  | ClearCaptureSelection
  /// Capture all selected panels.
  | CaptureSelected
  /// Capture full environment.
  | CaptureFullEnvironment
  /// Toggle capture bar visibility.
  | ToggleCaptureBar
  /// Clone a panel's state.
  | ClonePanel(string)
  /// Remove a clone.
  | RemoveClone(string)
  /// Enter comparison mode.
  | SetComparison(comparisonMode)
  /// Exit comparison mode.
  | ExitComparison
  /// Start demo playback.
  | StartDemo(string)
  /// Stop demo playback.
  | StopDemo
  /// Next demo step.
  | NextDemoStep
  /// Previous demo step.
  | PrevDemoStep
  /// Save a demo package.
  | SaveDemo
  /// Demo saved to disk.
  | DemoSaved(result<string, string>)
  /// Load demos from disk.
  | LoadDemos
  /// Demos loaded.
  | DemosLoaded(result<string, string>)
  /// Set capture category tab.
  | SetCaptureCategory(captureCategory)
  /// Remove a capture entry.
  | RemoveCapture(string)
  /// TypeLL cross-panel type check result for capture config types.
  | TypeCheckResult(result<string, string>)
