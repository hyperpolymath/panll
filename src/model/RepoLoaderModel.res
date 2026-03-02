// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Repo Loader Model — leaf types for the repository loading panel.
///
/// The Repo Loader allows opening a repo (`panll /path/to/repo` or directory
/// picker), scanning its manifests (0-AI-MANIFEST.a2ml, PANELS.a2ml, STATE.scm),
/// detecting languages, and suggesting which PanLL panels to activate.
/// Panel configs are saved as `.machine_readable/PANELS.a2ml` portfolios that
/// evolve through use.
///
/// Dependency: none (leaf module in the type DAG).

/// Information about a scanned repository — extracted from manifests,
/// git metadata, and file system analysis.
type repoInfo = {
  /// Filesystem path to the repo root.
  path: string,
  /// Repository name (last path component or from manifest).
  name: string,
  /// Short description from 0-AI-MANIFEST.a2ml or STATE.scm.
  description: string,
  /// Detected programming languages (from file extensions).
  languages: array<string>,
  /// Whether the repo has a .machine_readable/ directory.
  hasMachineReadable: bool,
  /// Whether PANELS.a2ml exists (previously configured).
  hasPanelsManifest: bool,
  /// Whether 0-AI-MANIFEST.a2ml exists.
  hasAiManifest: bool,
  /// Whether STATE.scm exists in .machine_readable/.
  hasState: bool,
}

/// A suggested panel configuration from the repo scanner.
/// Based on detected languages, manifests, and repo type.
type panelSuggestion = {
  /// Panel name (matches a panelId name like "AI", "Interfaces", "VoiceTag").
  panelName: string,
  /// Why this panel was suggested.
  reason: string,
  /// Suggested priority ("critical", "high", "medium", "low").
  priority: string,
  /// Whether this suggestion is pre-selected (user can toggle).
  enabled: bool,
}

/// Category tabs for the Repo Loader panel.
type repoLoaderCategory =
  /// Directory picker and repo scanner.
  | Browse
  /// Panel configuration wizard (after scan).
  | Configure
  /// Recently loaded repos for quick switching.
  | Recent
  /// Search across the git-private-farm for repos.
  | FarmSearch

/// Root state for the Repo Loader panel module.
type repoLoaderState = {
  /// Currently scanned repo (None if no repo loaded).
  currentRepo: option<repoInfo>,
  /// Panel suggestions from the last scan.
  suggestions: array<panelSuggestion>,
  /// Recently loaded repo paths (most recent first).
  recentPaths: array<string>,
  /// Active category tab.
  activeCategory: repoLoaderCategory,
  /// Whether a scan is in progress.
  scanning: bool,
  /// Search text for farm search.
  searchText: string,
  /// Last error from scan or save.
  error: option<string>,
  /// Whether the panel config has been saved since last change.
  saved: bool,
}
