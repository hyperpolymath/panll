// SPDX-License-Identifier: MPL-2.0

/// Clade Browser messages -- exploring and customising panel clades.

open Model

type cladeBrowserMsg =
  /// Switch the active category tab.
  | SetCladeCategory(cladeBrowserCategory)
  /// Select a clade for detail view.
  | SelectClade(option<string>)
  /// Set the kind filter.
  | SetKindFilter(cladeKind)
  /// Update search query.
  | UpdateCladeSearch(string)
  /// Load clades from filesystem (or use builtins).
  | LoadClades
  /// Clades loaded successfully.
  | CladesLoaded(array<cladeEntry>)
  /// Set the permission level for a target clade.
  | SetCladePermission(string, cladePermission)
  /// Remove a permission rule (revert to PermitAll).
  | RemoveCladePermission(string)
  /// TypeLL cross-panel type check result for clade spec types.
  | TypeCheckResult(result<string, string>)
