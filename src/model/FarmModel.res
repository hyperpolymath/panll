// SPDX-License-Identifier: MPL-2.0

/// PanLL Farm Model — leaf types for the Git-Private-Farm panel.
///
/// Represents the repo inventory from `~/.git-private-farm/farm-manifest.json`.
/// Each repo entry carries its metadata (description, language, forges, priority)
/// plus computed health indicators and three-tier enrollment status
/// (farm → hypatia → gitbot-fleet).
///
/// Dependency: none (leaf module in the type DAG).

/// Sync priority level for a repo — determines propagation urgency.
type farmPriority =
  | High
  | Medium
  | Low

/// Target forge where a repo is mirrored.
type farmForge = {
  /// Forge identifier (github, gitlab, sourcehut, codeberg, bitbucket, radicle).
  name: string,
  /// Whether this forge is the primary source of truth.
  primary: bool,
}

/// Three-tier enrollment status — tracks how deeply a repo is integrated
/// into the hyperpolymath automation pipeline.
///
/// Tier 1: git-private-farm (admin registry — always enrolled if in manifest)
/// Tier 2: hypatia (neurosymbolic scanning — has hypatia-scan.yml workflow)
/// Tier 3: gitbot-fleet (automated fixes — auto-discovers via hypatia findings)
type enrollmentTier = {
  /// Enrolled in git-private-farm (always true for manifest entries).
  farm: bool,
  /// Has hypatia-scan.yml workflow installed.
  hypatia: bool,
  /// Known to gitbot-fleet for automated dispatch.
  fleet: bool,
}

/// A single repo in the farm inventory.
type farmRepo = {
  /// Repo name (key from farm-manifest.json).
  name: string,
  /// Human-readable description.
  description: string,
  /// Primary programming language.
  language: string,
  /// Sync priority (high/medium/low).
  priority: farmPriority,
  /// Target forges for mirroring.
  forges: array<farmForge>,
  /// Whether auto-propagation is enabled.
  autoPropagation: bool,
  /// Repo group membership (ssg, cli_tools, security, bots, infra, etc.).
  group: option<string>,
  /// Three-tier enrollment status.
  enrollment: enrollmentTier,
  /// Computed health score (0.0–1.0), None if not yet assessed.
  healthScore: option<float>,
  /// Whether Dependabot or similar has open PRs.
  hasDependabotAlerts: bool,
}

/// Category tabs for the Farm panel — each filters the repo inventory
/// by a different lens.
type farmCategory =
  /// All repos in a flat inventory table.
  | AllRepos
  /// Grouped by repo group (ssg, cli_tools, security, etc.).
  | ByGroup
  /// Grouped by primary language.
  | ByLanguage
  /// Grouped by forge coverage (which forges each repo mirrors to).
  | ByForge
  /// Three-tier enrollment view (farm/hypatia/fleet columns).
  | Enrollment
  /// Health dashboard — sorted by health score ascending (sickest first).
  | Health

/// Sort order for the repo inventory table.
type farmSortBy =
  | SortByName
  | SortByPriority
  | SortByLanguage
  | SortByHealth

/// Root state for the Farm panel module.
type farmState = {
  /// Whether data has been loaded from the manifest.
  loaded: bool,
  /// Loading indicator for async operations.
  loading: bool,
  /// Last error message, if any.
  error: option<string>,
  /// Full repo inventory from the manifest.
  repos: array<farmRepo>,
  /// Currently selected repo names (multi-select for bulk operations).
  selectedRepoNames: array<string>,
  /// Active category tab.
  activeCategory: farmCategory,
  /// Text filter for repo name/description search.
  filterText: string,
  /// Current sort order.
  sortBy: farmSortBy,
  /// Summary statistics — total repos, languages, forges.
  totalRepos: int,
  /// Count of repos with health score below 0.5.
  unhealthyCount: int,
}
