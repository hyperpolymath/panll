// SPDX-License-Identifier: PMPL-1.0-or-later

/// VerificationDashboard messages -- proof/test/benchmark status.

open Model

type verificationDashboardMsg =
  /// Set the active category tab.
  | SetVdCategory(verificationDashboardCategory)
  /// Select a language for detail view.
  | SelectVdLanguage(option<string>)
  /// Update the text filter.
  | SetVdFilter(string)
  /// Set the sort criterion.
  | SetVdSort(verificationSortBy)
  /// Toggle showing only languages with admitted/sorry debt.
  | ToggleDebtOnly
  /// Dismiss error.
  | DismissVdError
