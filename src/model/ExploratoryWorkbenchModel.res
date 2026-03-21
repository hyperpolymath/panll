// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Exploratory Workbench Model — freeform play session recording and
/// anomaly detection for QA testers and designers.
///
/// Records player actions during unscripted play sessions, automatically flags
/// unexpected states as anomalies, and allows manual bug tagging with screenshots.
/// Designed for discovering issues that scripted tests miss.
///
/// Clade: Builder. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Anomaly Classification
// ============================================================================

/// Severity of a flagged anomaly detected during exploratory play.
type anomalySeverity =
  /// Low — cosmetic or minor, does not affect gameplay.
  | AnomalyLow
  /// Medium — noticeable issue that degrades the experience.
  | AnomalyMedium
  /// High — significant bug affecting core gameplay.
  | AnomalyHigh
  /// Critical — crash, data loss, or security issue.
  | AnomalyCritical

/// An anomaly flagged during a play session, either automatically detected
/// by heuristics or manually tagged by the QA tester.
type anomalyFlag = {
  /// Unique anomaly identifier.
  id: string,
  /// Epoch timestamp when the anomaly was observed.
  timestamp: float,
  /// Human-readable description of what went wrong.
  description: string,
  /// Severity classification.
  severity: anomalySeverity,
  /// Category tag (e.g., "rendering", "physics", "ai", "network").
  category: string,
  /// Whether this anomaly was detected by the automated heuristic engine.
  autoDetected: bool,
  /// Path to screenshot captured at the moment of the anomaly.
  screenshotPath: option<string>,
}

// ============================================================================
// Play Sessions
// ============================================================================

/// A recorded exploratory play session.
type playSession = {
  /// Unique session identifier.
  id: string,
  /// Human-readable session name (e.g., "Level 7 exploration #2").
  name: string,
  /// Epoch timestamp when the session started.
  startedAt: float,
  /// Epoch timestamp when the session ended (None if still recording).
  endedAt: option<float>,
  /// Duration of the session in minutes.
  durationMinutes: float,
  /// Anomalies flagged during this session.
  anomalies: array<anomalyFlag>,
  /// Free-text notes written by the tester during or after the session.
  notes: string,
  /// Total number of player actions captured during the session.
  playerActions: int,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Exploratory Workbench panel.
type exploratoryTab =
  /// Session — current live recording session with controls.
  | TabSession
  /// Anomalies — list of flagged anomalies with severity badges.
  | TabAnomalies
  /// Notes — tester's session notes and observations.
  | TabNotes
  /// History — past session recordings with anomaly summaries.
  | TabHistory

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Exploratory Workbench panel.
type exploratoryWorkbenchState = {
  /// Active tab within the panel.
  activeTab: exploratoryTab,
  /// Currently recording session (None if not recording).
  currentSession: option<playSession>,
  /// Historical play sessions.
  sessions: array<playSession>,
  /// Anomalies from the current session (also duplicated into the session record).
  anomalies: array<anomalyFlag>,
  /// Whether a play session is actively being recorded.
  recording: bool,
  /// Whether the automated anomaly detection heuristic is enabled.
  anomalyDetectionEnabled: bool,
  /// Error from the last operation.
  error: option<string>,
}
