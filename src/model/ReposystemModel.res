// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Reposystem Model — types for the RSR compliance panel.
///
/// Scans repositories for Rhodium Standard Repository compliance:
/// .editorconfig, 0-AI-MANIFEST.a2ml, STATE.scm in .machine_readable/,
/// Justfile, TOPOLOGY.md, required workflows, and language policy.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Individual RSR requirement that a repo must satisfy.
type rsrRequirement =
  /// .editorconfig present and valid.
  | EditorConfig
  /// 0-AI-MANIFEST.a2ml or AI.a2ml in root.
  | AiManifest
  /// STATE.scm in .machine_readable/ (NOT root).
  | StateMachineReadable
  /// META.scm in .machine_readable/.
  | MetaMachineReadable
  /// ECOSYSTEM.scm in .machine_readable/.
  | EcosystemMachineReadable
  /// Justfile with project recipes.
  | Justfile
  /// TOPOLOGY.md with architecture diagram.
  | TopologyDiagram
  /// SECURITY.md present.
  | SecurityPolicy
  /// LICENSE or LICENSE.txt with PMPL/MPL.
  | LicenseFile
  /// At least hypatia-scan.yml workflow.
  | HypatiaScanWorkflow

/// Compliance result for a single requirement in a single repo.
type requirementResult = {
  /// Which requirement was checked.
  requirement: rsrRequirement,
  /// Whether the repo satisfies this requirement.
  met: bool,
  /// Detail message (e.g. "Found .editorconfig" or "Missing TOPOLOGY.md").
  detail: string,
}

/// Compliance audit for a single repository.
type repoCompliance = {
  /// Repository name.
  repoName: string,
  /// Results for each RSR requirement.
  results: array<requirementResult>,
  /// Overall compliance score (0.0–1.0).
  score: float,
  /// Number of requirements met.
  metCount: int,
  /// Total requirements checked.
  totalCount: int,
}

/// Aggregate compliance statistics across the ecosystem.
type complianceStats = {
  /// Total repos audited.
  totalRepos: int,
  /// Per-requirement compliance rates (requirement, percentage, count).
  requirementRates: array<(rsrRequirement, float, int)>,
  /// Average compliance score across all repos.
  avgScore: float,
  /// Number of repos at 100% compliance.
  fullyCompliant: int,
}

/// Category tabs for the Reposystem panel.
type reposystemCategory =
  /// Dashboard with aggregate compliance metrics.
  | RsrDashboard
  /// Per-repo compliance table.
  | RsrRepoList
  /// Per-requirement breakdown showing which repos fail.
  | RsrRequirements
  /// Language policy violations.
  | RsrLanguagePolicy

/// Root state for the Reposystem panel.
type reposystemState = {
  /// Whether data has been loaded.
  loaded: bool,
  /// Whether a scan is in progress.
  loading: bool,
  /// Error from the last operation.
  error: option<string>,
  /// Per-repo compliance results.
  audits: array<repoCompliance>,
  /// Aggregate statistics.
  stats: option<complianceStats>,
  /// Active category tab.
  activeCategory: reposystemCategory,
  /// Text filter for repo search.
  filterText: string,
}
