// SPDX-License-Identifier: MPL-2.0

/// Evangeliser messages -- JS->ReScript pattern detection and teaching.

open Model

type evangeliserMsg =
  /// Set the JS code input for scanning.
  | SetJsInput(string)
  /// Run the pattern scanner on the current JS input.
  | RunScan
  /// Scan completed (or failed).
  | ScanComplete(result<evangeliserAnalysis, string>)
  /// Switch the active tab.
  | SetTab(evangeliserTab)
  /// Set the view layer (RAW, FOLDED, GLYPHED, WYSIWYG).
  | SetViewLayer(evangeliserViewLayer)
  /// Set the minimum confidence threshold.
  | SetMinConfidence(float)
  /// Set the difficulty filter.
  | SetDifficultyFilter(option<evangeliserDifficulty>)
  /// Toggle a category in the constraint filter.
  | ToggleCategory(evangeliserCategory)
  /// Select a match in the results view.
  | SelectMatch(option<int>)
  /// Set the pattern filter text.
  | SetFilterText(string)
  /// Dismiss error.
  | DismissError
