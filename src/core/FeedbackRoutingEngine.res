// SPDX-License-Identifier: MPL-2.0

/// PanLL Feedback Routing Engine — pure helpers for upstream report tracking.

open FeedbackRoutingModel

/// Default initial state.
let defaultState: feedbackRoutingState = {
  activeTab: TabOverview,
  reports: [],
  platformStats: [],
  selectedReport: None,
  refreshing: false,
  error: None,
  filterText: "",
}

/// Tab label for display.
let tabLabel = (tab: feedbackRoutingTab): string => {
  switch tab {
  | TabOverview => "Overview"
  | TabReports => "Reports"
  | TabPlatforms => "Platforms"
  }
}

/// All tabs for rendering.
let allTabs: array<feedbackRoutingTab> = [TabOverview, TabReports, TabPlatforms]

/// Report status label for display.
let statusLabel = (s: reportStatus): string => {
  switch s {
  | ReportFiled => "Filed"
  | ReportAcknowledged => "Acknowledged"
  | ReportInProgress => "In Progress"
  | ReportResolved => "Resolved"
  | ReportClosed => "Closed"
  | ReportWontFix => "Won't Fix"
  }
}

/// Platform label for display.
let platformLabel = (p: reportPlatform): string => {
  switch p {
  | GitHub => "GitHub"
  | GitLab => "GitLab"
  | Email => "Email"
  | Discourse => "Discourse"
  | Other(name) => name
  }
}

/// Count open reports (filed, acknowledged, or in progress).
let openReportCount = (reports: array<feedbackReport>): int => {
  reports
  ->Array.filter(r =>
    switch r.status {
    | ReportFiled | ReportAcknowledged | ReportInProgress => true
    | _ => false
    }
  )
  ->Array.length
}
