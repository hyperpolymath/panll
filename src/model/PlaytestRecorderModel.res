// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Playtest Recorder Model — types for recording, replaying,
/// and annotating gameplay sessions.
///
/// Captures player actions during a playtest, allows timestamped
/// annotations with optional screenshots, and supports full replay
/// with play/pause/seek controls. Session data can be exported for
/// QA review and balance analysis.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Current playback/recording state of the recorder.
type playbackState =
  /// Recorder is idle, not playing or recording.
  | Stopped
  /// Playing back a recorded session at the given timestamp (seconds).
  | Playing(float)
  /// Playback paused at the given timestamp (seconds).
  | Paused(float)
  /// Actively recording a new session.
  | Recording

/// A timestamped annotation attached to a recorded session.
type annotation = {
  /// Unique identifier for this annotation.
  id: string,
  /// Timestamp in seconds from session start.
  timestamp: float,
  /// Annotation text (e.g., "Guard spotted player here").
  text: string,
  /// Category tag (e.g., "bug", "balance", "design", "ux").
  category: string,
  /// Optional path to a screenshot taken at this moment.
  screenshotPath: option<string>,
}

/// A complete recorded playtest session.
type recordedSession = {
  /// Unique identifier for this session.
  id: string,
  /// Human-readable session name.
  name: string,
  /// ISO 8601 timestamp of when recording started.
  startedAt: string,
  /// Total session duration in milliseconds.
  durationMs: float,
  /// Annotations made during or after the session.
  annotations: array<annotation>,
  /// Total number of player actions recorded.
  actionCount: int,
  /// Serialised replay data (action log).
  replayData: string,
}

/// Category tabs for the Playtest Recorder panel.
type playtestRecorderCategory =
  /// Record a new playtest session.
  | Record
  /// Replay a previously recorded session.
  | Replay
  /// Browse and edit annotations for a session.
  | Annotations
  /// Browse all saved sessions.
  | Sessions

/// Root state for the Playtest Recorder panel.
type playtestRecorderState = {
  /// Active category tab.
  activeTab: playtestRecorderCategory,
  /// The session currently being recorded or replayed (if any).
  currentSession: option<recordedSession>,
  /// All saved recorded sessions.
  sessions: array<recordedSession>,
  /// Current playback/recording state.
  playback: playbackState,
  /// Annotations for the current session.
  annotations: array<annotation>,
  /// ID of the currently selected annotation (if any).
  selectedAnnotation: option<string>,
  /// Error message (if any).
  error: option<string>,
}
