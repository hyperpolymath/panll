// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Exploratory Workbench Model — freeform play session recording and anomaly detection.
/// This module has NO dependencies on other PanLL modules.

/// Severity of flagged anomaly.
type anomalySeverity =
  | AnomalyLow
  | AnomalyMedium
  | AnomalyHigh
  | AnomalyCritical

/// An anomaly flagged during play.
type anomalyFlag = {
  id: string,
  timestamp: float,
  description: string,
  severity: anomalySeverity,
  category: string,
  autoDetected: bool,
  screenshotPath: option<string>,
}

/// A recorded play session.
type playSession = {
  id: string,
  name: string,
  startedAt: float,
  endedAt: option<float>,
  durationMinutes: float,
  anomalies: array<anomalyFlag>,
  notes: string,
  playerActions: int,
}

/// Active tab.
type exploratoryTab =
  | TabSession
  | TabAnomalies
  | TabNotes
  | TabHistory

/// Exploratory workbench state.
type exploratoryWorkbenchState = {
  activeTab: exploratoryTab,
  currentSession: option<playSession>,
  sessions: array<playSession>,
  anomalies: array<anomalyFlag>,
  recording: bool,
  anomalyDetectionEnabled: bool,
  error: option<string>,
}
