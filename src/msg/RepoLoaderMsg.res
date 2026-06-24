// SPDX-License-Identifier: MPL-2.0

/// Repo Loader messages -- repository scanning, panel configuration,
/// directory picking, and recent repo management.

open Model

type repoLoaderMsg =
  /// Open directory picker to select a repo.
  | PickRepoDirectory
  /// Directory picked (or cancelled).
  | DirectoryPicked(result<string, string>)
  /// Scan a repo by path.
  | ScanRepo(string)
  /// Scan result received.
  | ScanResult(result<string, string>)
  /// Toggle a panel suggestion's enabled state.
  | ToggleSuggestion(string)
  /// Save panel configuration to PANELS.a2ml.
  | SavePanels
  /// Panels saved.
  | PanelsSaved(result<string, string>)
  /// Load recent repos list.
  | LoadRecent
  /// Recent repos loaded.
  | RecentLoaded(result<string, string>)
  /// Search the git-private-farm.
  | SearchFarm(string)
  /// Farm search results.
  | FarmSearchResult(result<string, string>)
  /// Update the search text.
  | SetRepoSearchText(string)
  /// Switch category tab.
  | SetRepoCategory(repoLoaderCategory)
  /// TypeLL cross-panel type check result for repo config types.
  | TypeCheckResult(result<string, string>)
