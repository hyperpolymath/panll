// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Manifest Coverage Model — AI manifest presence across all repos.
///
/// Scans repos for the presence and validity of 0-AI-MANIFEST.a2ml or
/// AI.a2ml files. Every hyperpolymath repo should have an AI manifest
/// as the universal entry point for AI agents.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Manifest presence and validity for a single repository.
type repoManifestStatus = {
  /// Repository name.
  repoName: string,
  /// Whether 0-AI-MANIFEST.a2ml or AI.a2ml is present.
  hasManifest: bool,
  /// Filename found (if any).
  manifestFile: option<string>,
  /// Whether the manifest parsed without errors.
  isValid: bool,
  /// Validation errors (empty if valid).
  validationErrors: array<string>,
  /// Last scan timestamp (ISO 8601).
  lastScanned: string,
}

/// Manifest Coverage panel tabs.
type manifestCoverageTab =
  | TabOverview
  | TabRepoList
  | TabInvalid

/// Root state for the Manifest Coverage panel.
type manifestCoverageState = {
  /// Active tab.
  activeTab: manifestCoverageTab,
  /// Per-repo manifest status.
  repos: array<repoManifestStatus>,
  /// Currently selected repo for detail view.
  selectedRepo: option<string>,
  /// Whether a filesystem scan is in progress.
  scanning: bool,
  /// Error from last scan.
  error: option<string>,
  /// Search/filter text.
  filterText: string,
}
