// SPDX-License-Identifier: PMPL-1.0-or-later

/// Code MRI — Timeline Model (Layer 2)
///
/// State types for the VeriSimDB-backed development timeline. The timeline
/// captures point-in-time snapshots of codebase health metrics and stores
/// them as an append-only log in VeriSimDB.
///
/// The timeline state lives in the main PanLL model and is updated by
/// TimelineCmd (Tauri invoke wrappers) and TimelineEngine (pure computation).
///
/// DESIGN: The timeline is a passive observer — it reads data from git,
/// panic-attack, the Vexometer, and Code MRI tags to assemble snapshots.
/// It never modifies the codebase. The "time machine" scrubber shows
/// historical states but does not perform rollbacks (that's a git operation
/// triggered by the user, not the timeline).

/// The state of the Code MRI development timeline within PanLL.
///
/// Holds the in-memory snapshot array (capped at 1000 entries by
/// TimelineEngine.addSnapshot), the currently selected scrubber position,
/// and UI state for the dashboard.
type timelineState = {
  /// All loaded timeline snapshots (newest last, capped at 1000).
  snapshots: array<TimelineEngine.timelineSnapshot>,

  /// Currently selected snapshot index for the "time machine" scrubber.
  /// None means the view is showing the latest (live) state.
  scrubberPosition: option<int>,

  /// Whether the timeline dashboard panel is expanded.
  dashboardExpanded: bool,

  /// Pre-computed metrics for the dashboard (refreshed on snapshot changes).
  cachedMetrics: array<TimelineEngine.timelineMetric>,

  /// Path to the VeriSimDB database file (set when a repo is loaded).
  dbPath: option<string>,

  /// Whether a snapshot capture is currently in progress.
  capturing: bool,

  /// Last error from VeriSimDB I/O operations.
  error: option<string>,

  /// Whether the timeline is connected to a VeriSimDB instance.
  connected: bool,
}

/// Default (empty) timeline state for model initialisation.
///
/// All fields are zeroed/None. The timeline becomes active when a repo
/// is loaded and TimelineCmd.connect establishes a VeriSimDB connection.
let defaultTimelineState = (): timelineState => {
  snapshots: [],
  scrubberPosition: None,
  dashboardExpanded: false,
  cachedMetrics: [],
  dbPath: None,
  capturing: false,
  error: None,
  connected: false,
}
