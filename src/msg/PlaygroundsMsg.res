// SPDX-License-Identifier: PMPL-1.0-or-later

/// Playgrounds code sandbox messages.

open Model

type playgroundsMsg =
  | SetPlayCategory(playgroundsCategory)
  | SetLanguage(playgroundLanguage)
  | UpdateCode(string)
  | Execute
  | ExecuteResult(result<string, string>)
  | LoadSnippet(string)
  /// NQC console: update query input text.
  | SetNqcInput(string)
  /// NQC console: switch query language (VCL/KQL/GQL).
  | SetNqcLanguage(playgroundLanguage)
  /// NQC console: execute the current NQC query.
  | ExecuteNqc
  /// NQC console: query result received.
  | NqcResult(result<string, string>)
  /// NQC console: clear query history.
  | ClearNqcHistory
  /// TypeLL cross-panel type check result for sandbox code types.
  | TypeCheckResult(result<string, string>)
