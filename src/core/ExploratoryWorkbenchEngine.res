// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Exploratory Workbench Engine — pure computation and helpers for the
/// Exploratory Workbench panel. Provides default state, anomaly counting,
/// severity labelling, session analysis, and filtering.

open ExploratoryWorkbenchModel

/// Default state for the Exploratory Workbench panel.
/// Starts on the Session tab with anomaly detection enabled.
let defaultState: exploratoryWorkbenchState = {
  activeTab: TabSession,
  currentSession: None,
  sessions: [],
  anomalies: [],
  recording: false,
  anomalyDetectionEnabled: true,
  error: None,
}

/// Human-readable label for each tab in the Exploratory Workbench panel.
let tabLabel = (tab: exploratoryTab): string =>
  switch tab {
  | TabSession => "Session"
  | TabAnomalies => "Anomalies"
  | TabNotes => "Notes"
  | TabHistory => "History"
  }

/// All tabs in display order.
let allTabs: array<exploratoryTab> = [TabSession, TabAnomalies, TabNotes, TabHistory]

/// Human-readable label for anomaly severity.
let severityLabel = (s: anomalySeverity): string =>
  switch s {
  | AnomalyLow => "Low"
  | AnomalyMedium => "Medium"
  | AnomalyHigh => "High"
  | AnomalyCritical => "Critical"
  }

/// CSS colour class for anomaly severity.
let severityColor = (s: anomalySeverity): string =>
  switch s {
  | AnomalyLow => "text-blue-400"
  | AnomalyMedium => "text-yellow-400"
  | AnomalyHigh => "text-orange-400"
  | AnomalyCritical => "text-red-400"
  }

/// CSS background colour class for anomaly severity badges.
let severityBgColor = (s: anomalySeverity): string =>
  switch s {
  | AnomalyLow => "bg-blue-900/30"
  | AnomalyMedium => "bg-yellow-900/30"
  | AnomalyHigh => "bg-orange-900/30"
  | AnomalyCritical => "bg-red-900/30"
  }

/// Count anomalies by severity.
let anomalyCountBySeverity = (anomalies: array<anomalyFlag>, severity: anomalySeverity): int =>
  anomalies->Array.filter(a => a.severity == severity)->Array.length

/// Total anomalies across all past sessions.
let totalAnomalies = (sessions: array<playSession>): int =>
  sessions->Array.reduce(0, (acc, s) => acc + s.anomalies->Array.length)

/// Count auto-detected anomalies vs manually flagged.
let autoDetectedCount = (anomalies: array<anomalyFlag>): int =>
  anomalies->Array.filter(a => a.autoDetected)->Array.length

/// Count manually flagged anomalies.
let manuallyFlaggedCount = (anomalies: array<anomalyFlag>): int =>
  anomalies->Array.filter(a => !a.autoDetected)->Array.length

/// Filter anomalies by category.
let filterByCategory = (anomalies: array<anomalyFlag>, category: string): array<anomalyFlag> =>
  if category == "" {
    anomalies
  } else {
    anomalies->Array.filter(a => a.category == category)
  }

/// Get unique anomaly categories from a list of anomalies.
let uniqueCategories = (anomalies: array<anomalyFlag>): array<string> => {
  let cats = anomalies->Array.map(a => a.category)
  cats->Array.reduce([], (acc, cat) =>
    if acc->Array.some(c => c == cat) {
      acc
    } else {
      Array.concat(acc, [cat])
    }
  )
}

/// Average anomaly rate per session (anomalies per hour of play).
let anomalyRate = (sessions: array<playSession>): float => {
  let totalHours = sessions->Array.reduce(0.0, (acc, s) => acc +. s.durationMinutes /. 60.0)
  let totalAnom = totalAnomalies(sessions)
  if totalHours <= 0.0 {
    0.0
  } else {
    Float.fromInt(totalAnom) /. totalHours
  }
}
