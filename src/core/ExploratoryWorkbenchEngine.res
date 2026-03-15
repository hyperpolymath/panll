// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Exploratory Workbench Engine — pure functions for play session recording.

open ExploratoryWorkbenchModel

let defaultState: exploratoryWorkbenchState = {
  activeTab: TabSession,
  currentSession: None,
  sessions: [],
  anomalies: [],
  recording: false,
  anomalyDetectionEnabled: true,
  error: None,
}

let tabLabel = (tab: exploratoryTab): string =>
  switch tab {
  | TabSession => "Session"
  | TabAnomalies => "Anomalies"
  | TabNotes => "Notes"
  | TabHistory => "History"
  }

let allTabs: array<exploratoryTab> = [TabSession, TabAnomalies, TabNotes, TabHistory]

/// Severity label.
let severityLabel = (s: anomalySeverity): string =>
  switch s {
  | AnomalyLow => "Low"
  | AnomalyMedium => "Medium"
  | AnomalyHigh => "High"
  | AnomalyCritical => "Critical"
  }

/// Severity colour class.
let severityColor = (s: anomalySeverity): string =>
  switch s {
  | AnomalyLow => "text-blue-400"
  | AnomalyMedium => "text-yellow-400"
  | AnomalyHigh => "text-orange-400"
  | AnomalyCritical => "text-red-400"
  }

/// Count anomalies by severity.
let anomalyCountBySeverity = (anomalies: array<anomalyFlag>, severity: anomalySeverity): int =>
  anomalies->Array.filter(a => a.severity == severity)->Array.length

/// Total anomalies across all sessions.
let totalAnomalies = (sessions: array<playSession>): int =>
  sessions->Array.reduce(0, (acc, s) => acc + s.anomalies->Array.length)
