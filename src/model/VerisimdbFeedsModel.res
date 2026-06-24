// SPDX-License-Identifier: MPL-2.0

/// PanLL VeriSimDB Feeds Model — cross-repo analytics health and flow.
///
/// Monitors the health and throughput of VeriSimDB data feeds across the
/// ecosystem. Tracks feed status, last update times, record counts, and
/// data freshness.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Health status for a data feed.
type feedHealth =
  | FeedHealthy
  | FeedStale
  | FeedError(string)
  | FeedUnknown

/// A single VeriSimDB data feed.
type dataFeed = {
  /// Feed identifier.
  feedId: string,
  /// Human-readable feed name.
  name: string,
  /// Source repository or service.
  source: string,
  /// Current health status.
  health: feedHealth,
  /// Record count in this feed.
  recordCount: int,
  /// Last successful update timestamp (ISO 8601).
  lastUpdate: string,
  /// Average records per day.
  throughput: float,
}

/// VeriSimDB Feeds panel tabs.
type verisimdbFeedsTab =
  | TabDashboard
  | TabFeedList
  | TabHealth

/// Root state for the VeriSimDB Feeds panel.
type verisimdbFeedsState = {
  /// Active tab.
  activeTab: verisimdbFeedsTab,
  /// All monitored data feeds.
  feeds: array<dataFeed>,
  /// Currently selected feed for detail view.
  selectedFeed: option<string>,
  /// Whether a health check is in progress.
  checking: bool,
  /// Error from last check.
  error: option<string>,
}
