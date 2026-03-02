// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Capture Model — types for panel screenshots, recordings, demos,
/// panel cloning, and comparison views (DD-022).
///
/// The capture system provides per-panel screenshots and recordings, a demo/teaching
/// environment with golden output comparison, and panel cloning for before/after
/// analysis.
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Capture Types
// ============================================================================

/// Format for captured images.
type captureFormat =
  | Png
  | Pdf
  | Svg

/// A single captured screenshot or recording.
type captureEntry = {
  /// Unique identifier.
  id: string,
  /// Which panel was captured (as string for flexibility).
  panelId: string,
  /// Human-readable label (auto-generated or user-assigned).
  label: string,
  /// File path where the capture is stored.
  filePath: string,
  /// Capture format.
  format: captureFormat,
  /// Timestamp when the capture was taken.
  timestamp: float,
  /// Width in pixels (for images).
  width: int,
  /// Height in pixels (for images).
  height: int,
  /// Whether this is a recording (vs a static screenshot).
  isRecording: bool,
  /// Duration in seconds (for recordings, 0 for screenshots).
  durationSeconds: float,
}

/// State of an ongoing recording.
type recordingState =
  | NotRecording
  | Recording(string, float)  // panelId, startTime
  | Paused(string, float)     // panelId, elapsedTime

// ============================================================================
// Demo/Teaching Types
// ============================================================================

/// A single step in a demo sequence — captures the panel state at one point.
type demoStep = {
  /// Step number (1-indexed).
  stepNumber: int,
  /// Description of what this step demonstrates.
  description: string,
  /// Capture entry for this step's visual output.
  captureId: string,
  /// Serialised panel state at this step (JSON string).
  stateSnapshot: string,
  /// Timestamp within the demo.
  timestamp: float,
}

/// A complete demo package that can be saved, loaded, and replayed.
type demoPackage = {
  /// Unique identifier.
  id: string,
  /// Title of the demo.
  title: string,
  /// Author name.
  author: string,
  /// Description of the demo's purpose.
  description: string,
  /// The panel this demo was recorded from.
  panelId: string,
  /// Ordered sequence of demo steps.
  steps: array<demoStep>,
  /// Timestamp when the demo was created.
  created: float,
  /// File path of the .panll-demo package (ZIP).
  filePath: option<string>,
}

/// Comparison mode for side-by-side panel views.
type comparisonMode =
  | NoComparison
  | SideBySide(string, string)       // leftPanelId, rightPanelId
  | DemoComparison(string, string)   // studentPanelId, demoStepCaptureId
  | BeforeAfter(string, string)      // beforeCaptureId, afterCaptureId

// ============================================================================
// Panel Cloning
// ============================================================================

/// A cloned panel instance: independent copy of another panel's state.
type panelClone = {
  /// Unique identifier for this clone.
  id: string,
  /// The original panel this was cloned from.
  sourcePanelId: string,
  /// Label for the clone (e.g., "PaneL (Clone 1)").
  label: string,
  /// Serialised state snapshot at the time of cloning.
  stateSnapshot: string,
  /// Timestamp when the clone was created.
  created: float,
}

// ============================================================================
// Capture State
// ============================================================================

/// Active category tab in the Capture panel.
type captureCategory =
  | CaptureGallery
  | CaptureRecordings
  | CaptureDemos
  | CaptureClones
  | CaptureComparison

/// Root state for the capture system.
type captureState = {
  /// All captured screenshots and recordings.
  captures: array<captureEntry>,
  /// Current recording state.
  recording: recordingState,
  /// Panels selected for multi-panel capture.
  selectedForCapture: array<string>,
  /// All loaded demo packages.
  demos: array<demoPackage>,
  /// Currently active demo (for playback).
  activeDemo: option<string>,
  /// Current step index in the active demo.
  activeDemoStep: int,
  /// Comparison mode state.
  comparison: comparisonMode,
  /// Panel clones.
  clones: array<panelClone>,
  /// Active category tab.
  activeCategory: captureCategory,
  /// Whether the capture bar is visible on panels.
  captureBarVisible: bool,
  /// Whether capturing full environment (all panels + chrome).
  fullEnvironmentCapture: bool,
}
