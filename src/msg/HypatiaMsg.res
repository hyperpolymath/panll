// SPDX-License-Identifier: PMPL-1.0-or-later

/// Hypatia neurosymbolic scanner messages -- network status, scan results,
/// learning cycle, quarantine, and category navigation.

open Model

type hypatiaMsg =
  /// Load all Hypatia data (networks + scans).
  | LoadHypatia
  /// Neural network states loaded.
  | NetworksLoaded(result<string, string>)
  /// Scan results loaded.
  | ScansLoaded(result<string, string>)
  /// Change the active category tab.
  | SetHypatiaCategory(hypatiaCategory)
  /// Update the scan results text filter.
  | SetHypatiaFilter(string)
  /// TypeLL cross-panel type check result for scan config types.
  | TypeCheckResult(result<string, string>)
  /// Select a recipe for detail drill-down (None to deselect).
  | SelectRecipe(option<string>)
  /// Update recipe filter text.
  | SetRecipeFilter(string)
