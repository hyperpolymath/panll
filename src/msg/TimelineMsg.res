// SPDX-License-Identifier: MPL-2.0

/// Code MRI Timeline messages (Layer 2) -- VeriSimDB-backed development timeline.
/// Handles database connection, snapshot capture, history loading, scrubber
/// navigation, and export. The timeline is append-only and passive -- it reads
/// metrics from other panels but never modifies the codebase.

type timelineMsg =
  /// Connect to the VeriSimDB timeline database for the loaded repo.
  | Connect
  /// Connection result (Ok = db path, Error = message).
  | Connected(result<string, string>)
  /// Capture a new snapshot of the current codebase state.
  | CaptureSnapshot
  /// Snapshot captured (Ok = snapshot JSON, Error = message).
  | SnapshotCaptured(result<string, string>)
  /// Load all historical snapshots from VeriSimDB.
  | LoadHistory
  /// History loaded (Ok = snapshots JSON array, Error = message).
  | HistoryLoaded(result<string, string>)
  /// Query snapshots within a date range (startDate, endDate in ISO 8601).
  | QueryRange(string, string)
  /// Range query result.
  | RangeLoaded(result<string, string>)
  /// Move the time-machine scrubber to a specific snapshot index.
  | SeekScrubber(option<int>)
  /// Toggle the dashboard panel expanded/collapsed.
  | ToggleDashboard
  /// Export timeline to a standalone JSON file.
  | ExportTimeline(string)
  /// Export result.
  | TimelineExported(result<string, string>)
  /// Dismiss a timeline error.
  | DismissError
