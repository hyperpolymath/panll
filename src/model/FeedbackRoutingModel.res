// SPDX-License-Identifier: MPL-2.0

/// PanLL Feedback Routing Model — upstream bug report status and integration map.
///
/// Tracks Feedback-o-Tron upstream reports across platforms (GitHub Issues,
/// GitLab Issues, email, etc.). Provides visibility into which reports are
/// open, closed, or pending response.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Report status lifecycle.
type reportStatus =
  | ReportFiled
  | ReportAcknowledged
  | ReportInProgress
  | ReportResolved
  | ReportClosed
  | ReportWontFix

/// Platform where the report was filed.
type reportPlatform =
  | GitHub
  | GitLab
  | Email
  | Discourse
  | Other(string)

/// A single upstream feedback report.
type feedbackReport = {
  /// Unique report identifier.
  reportId: string,
  /// Report title/summary.
  title: string,
  /// Platform where filed.
  platform: reportPlatform,
  /// Current status.
  status: reportStatus,
  /// Target project/repo.
  targetRepo: string,
  /// Date filed (ISO 8601).
  dateFiled: string,
  /// Date last updated (ISO 8601).
  lastUpdated: string,
  /// External URL (if available).
  externalUrl: option<string>,
}

/// Per-platform statistics.
type platformStats = {
  /// Platform name.
  platform: reportPlatform,
  /// Total reports filed.
  totalFiled: int,
  /// Currently open reports.
  openCount: int,
  /// Resolved reports.
  resolvedCount: int,
}

/// Feedback Routing panel tabs.
type feedbackRoutingTab =
  | TabOverview
  | TabReports
  | TabPlatforms

/// Root state for the Feedback Routing panel.
type feedbackRoutingState = {
  /// Active tab.
  activeTab: feedbackRoutingTab,
  /// All tracked feedback reports.
  reports: array<feedbackReport>,
  /// Per-platform statistics.
  platformStats: array<platformStats>,
  /// Currently selected report for detail view.
  selectedReport: option<string>,
  /// Whether a refresh is in progress.
  refreshing: bool,
  /// Error from last refresh.
  error: option<string>,
  /// Search/filter text.
  filterText: string,
}
