// SPDX-License-Identifier: MPL-2.0

/// Observatory messages -- integrative dashboard health and resource monitoring.

open Model

type observatoryMsg =
  /// Switch the active tab.
  | SetObsTab(observatoryTab)
  /// Start a health check sweep across all panels.
  | RunHealthCheck
  /// Health check completed with resource snapshots.
  | HealthCheckComplete(result<array<resourceSnapshot>, string>)
  /// Dismiss error banner.
  | DismissObsError
