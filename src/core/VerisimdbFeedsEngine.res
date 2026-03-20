// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL VeriSimDB Feeds Engine — pure helpers for data feed monitoring.

open VerisimdbFeedsModel

/// Default initial state.
let defaultState: verisimdbFeedsState = {
  activeTab: TabDashboard,
  feeds: [],
  selectedFeed: None,
  checking: false,
  error: None,
}

/// Tab label for display.
let tabLabel = (tab: verisimdbFeedsTab): string => {
  switch tab {
  | TabDashboard => "Dashboard"
  | TabFeedList => "Feeds"
  | TabHealth => "Health"
  }
}

/// All tabs for rendering.
let allTabs: array<verisimdbFeedsTab> = [TabDashboard, TabFeedList, TabHealth]

/// Health label for display.
let healthLabel = (h: feedHealth): string => {
  switch h {
  | FeedHealthy => "Healthy"
  | FeedStale => "Stale"
  | FeedError(reason) => "Error: " ++ reason
  | FeedUnknown => "Unknown"
  }
}

/// Count feeds by health status.
let healthyFeedCount = (feeds: array<dataFeed>): int => {
  feeds->Array.filter(f => f.health == FeedHealthy)->Array.length
}

/// Total records across all feeds.
let totalRecords = (feeds: array<dataFeed>): int => {
  feeds->Array.reduce(0, (acc, f) => acc + f.recordCount)
}
