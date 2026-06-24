// SPDX-License-Identifier: MPL-2.0

/// Language Forge panel messages -- nextgen-languages portfolio monitoring.

open Model

type languageForgeMsg =
  /// Load language data (re-initialise from hardcoded assessment).
  | LoadLanguages
  /// Change the active category tab.
  | SetForgeCategory(forgeCategory)
  /// Update the text filter for language search.
  | SetForgeFilter(string)
  /// Change the sort order.
  | SetForgeSort(forgeSortBy)
  /// Select a language for detail view (None to deselect).
  | SelectLanguage(option<string>)
  /// Toggle the MoSCoW breakdown in the detail view.
  | ToggleMoscow
