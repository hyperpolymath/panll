// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Contractile Completeness Model — Mustfile/Trustfile/Dustfile/K9 coverage.
///
/// Scans repos for the presence and validity of contractile governance files.
/// Each repo should have a Mustfile, Trustfile, Dustfile, and at least one
/// K9 kennel configuration.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Contractile file presence for a single repository.
type repoContractileStatus = {
  /// Repository name.
  repoName: string,
  /// Whether a Mustfile is present.
  hasMustfile: bool,
  /// Whether a Trustfile is present.
  hasTrustfile: bool,
  /// Whether a Dustfile is present.
  hasDustfile: bool,
  /// Whether at least one K9 .k9.ncl file is present.
  hasK9: bool,
  /// Number of K9 configurations found.
  k9Count: int,
  /// Last scan timestamp (ISO 8601).
  lastScanned: string,
}

/// Contractile Completeness panel tabs.
type contractileCompletenessTab =
  | TabOverview
  | TabRepoList
  | TabMissing

/// Root state for the Contractile Completeness panel.
type contractileCompletenessState = {
  /// Active tab.
  activeTab: contractileCompletenessTab,
  /// Per-repo contractile file status.
  repos: array<repoContractileStatus>,
  /// Currently selected repo for detail view.
  selectedRepo: option<string>,
  /// Whether a filesystem scan is in progress.
  scanning: bool,
  /// Error from last scan.
  error: option<string>,
  /// Search/filter text.
  filterText: string,
}
