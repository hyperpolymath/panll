// SPDX-License-Identifier: PMPL-1.0-or-later

/// Git-Private-Farm panel messages -- repo inventory loading, filtering,
/// and category navigation. The farm backend reads local JSON, no HTTP.

open Model

type farmMsg =
  /// Trigger loading the repo inventory from farm-manifest.json.
  | LoadRepos
  /// Repo inventory loaded (or failed).
  | ReposLoaded(result<string, string>)
  /// Change the active category tab.
  | SetFarmCategory(farmCategory)
  /// Update the text filter for repo search.
  | SetFarmFilter(string)
  /// Change the sort order.
  | SetFarmSort(farmSortBy)
  /// TypeLL cross-panel type check result for repo manifest types.
  | TypeCheckResult(result<string, string>)
