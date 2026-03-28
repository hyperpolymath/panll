// SPDX-License-Identifier: PMPL-1.0-or-later

/// SpecBrowser messages -- language specification browsing and comparison.

open Model

type specBrowserMsg =
  /// Set the active category tab.
  | SetSpecCategory(specBrowserCategory)
  /// Select a language for detail/grammar/typing views.
  | SelectSpecLanguage(option<string>)
  /// Set the comparison side language.
  | SetComparisonSide(comparisonSide, string)
  /// Update the text filter.
  | SetSpecFilter(string)
  /// Toggle showing only incomplete languages.
  | ToggleIncompleteOnly
  /// Dismiss error.
  | DismissSpecError
