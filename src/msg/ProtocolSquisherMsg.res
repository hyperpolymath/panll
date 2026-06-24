// SPDX-License-Identifier: MPL-2.0

/// Protocol-Squisher format analysis messages.

open Model

type protocolSquisherMsg =
  /// Set the active category tab.
  | SetPsCategory(protocolSquisherCategory)
  /// Check whether CLI binary is available.
  | CheckPsCli
  /// CLI check result.
  | PsCliResult(result<string, string>)
  /// Update the analyse file path input.
  | SetAnalyseInput(string)
  /// Run analysis on the current input path.
  | RunAnalysis
  /// Analysis result from Gossamer backend.
  | AnalysisResult(result<string, string>)
  /// Update the left comparison input.
  | SetCompareLeft(string)
  /// Update the right comparison input.
  | SetCompareRight(string)
  /// Run comparison between left and right schemas.
  | RunComparison
  /// Comparison result from Gossamer backend.
  | ComparisonResult(result<string, string>)
  /// TypeLL cross-panel type check result for the last schema analysis.
  | SchemaTypeCheckResult(result<string, string>)
  /// Import IR analysis results as Panel-L constraints.
  | ImportIrConstraints
  /// Toggle transport compatibility display in Panel-W.
  | ToggleTransportDisplay
