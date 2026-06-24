// SPDX-License-Identifier: MPL-2.0

/// PanLL Proven Adoption Model — per-repo proven library adoption tracking.
///
/// Scans repos for formally verified safety primitives from the `proven`
/// library. Tracks which SafeX modules each repo uses and whether bindings
/// are properly configured.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Status of a single proven module binding in a repo.
type provenModuleStatus =
  | Adopted
  | PartiallyAdopted
  | NotAdopted

/// Proven module usage summary for a single repository.
type repoProvenSummary = {
  /// Repository name.
  repoName: string,
  /// Proven SafeX modules in use (e.g. "SafeArray", "SafeMap", "SafeString").
  modules: array<string>,
  /// Whether the proven dependency is declared in the build file.
  dependencyDeclared: bool,
  /// Binding status: are all imported modules bound correctly?
  bindingStatus: provenModuleStatus,
  /// Last scan timestamp (ISO 8601).
  lastScanned: string,
}

/// Proven Adoption panel tabs.
type provenAdoptionTab =
  | TabRepoList
  | TabModuleMatrix
  | TabGaps

/// Root state for the Proven Adoption panel.
type provenAdoptionState = {
  /// Active tab.
  activeTab: provenAdoptionTab,
  /// Per-repo proven adoption summaries.
  repos: array<repoProvenSummary>,
  /// Currently selected repo for detail view.
  selectedRepo: option<string>,
  /// Whether a filesystem scan is in progress.
  scanning: bool,
  /// Error from last scan.
  error: option<string>,
  /// Search/filter text.
  filterText: string,
}
