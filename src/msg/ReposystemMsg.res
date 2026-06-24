// SPDX-License-Identifier: MPL-2.0

/// Reposystem RSR compliance messages.

open Model

type reposystemMsg =
  | ScanAll
  | ScanAllLoaded(result<string, string>)
  | SetRsrCategory(reposystemCategory)
  | SetRsrFilter(string)
  /// Select a requirement for drill-down (None to deselect).
  | SelectRequirement(option<rsrRequirement>)
  /// TypeLL cross-panel type check result for RSR compliance types.
  | TypeCheckResult(result<string, string>)
