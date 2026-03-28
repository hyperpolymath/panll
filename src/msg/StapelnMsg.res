// SPDX-License-Identifier: PMPL-1.0-or-later

/// Stapeln messages -- container assembly pipeline operations.

open Model

type stapelnMsg =
  /// Set the pipeline backend URL.
  | SetPipelineUrl(string)
  /// Initiate connection to the stapeln backend.
  | Connect
  /// Connection result (true = connected, false = failed).
  | Connected(bool)
  /// Update a constraint field by key and value.
  | UpdateConstraint(string, string)
  /// Request validation of the current assembly.
  | RequestValidation
  /// Validation results received from backend.
  | ValidationReceived(validationSummary)
  /// Request artifact generation in specified format.
  | RequestGenerate(string)
  /// Generated artifact content received from backend.
  | GenerateReceived(string)
  /// Refresh pipeline status from backend.
  | RefreshStatus
  /// Pipeline status received from backend.
  | StatusReceived(pipelineStatus)
  /// Switch the active tab ("constraints" | "reasoning" | "results").
  | SetActiveTab(string)
  /// Dismiss the error banner.
  | DismissError
