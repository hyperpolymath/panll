// SPDX-License-Identifier: MPL-2.0

/// Script Gist messages -- portable computation gist lifecycle.
/// Covers gist CRUD, execution, template expansion, MCP tool registration,
/// and diachronic/synchronic state document management (Minskian cardfiles).

open Model

type scriptGistMsg =
  /// Switch the active category tab.
  | SetGistCategory(gistCategory)
  /// Select a gist for editing/viewing.
  | SelectGist(option<string>)
  /// Create a new empty gist.
  | CreateGist
  /// Create a gist from a template.
  | CreateFromTemplate(string) // template id
  /// Update the code of the currently selected gist.
  | UpdateGistCode(string)
  /// Update the title of the currently selected gist.
  | UpdateGistTitle(string)
  /// Update the language of the currently selected gist.
  | UpdateGistLanguage(gistLanguage)
  /// Update the target of the currently selected gist.
  | UpdateGistTarget(gistTarget)
  /// Update the visibility of the currently selected gist.
  | UpdateGistVisibility(gistVisibility)
  /// Toggle pinned status of a gist.
  | ToggleGistPin(string)
  /// Delete a gist by id.
  | DeleteGist(string)
  /// Save the current gist (persist to storage).
  | SaveGist
  /// Execute the currently selected gist.
  | ExecuteGist
  /// Execution result returned.
  | GistExecutionResult(result<gistResult, string>)
  /// Set filter/search text.
  | SetGistFilter(string)
  /// Set sort order.
  | SetGistSort(gistSortBy)
  /// Toggle the gist editor panel open/closed.
  | ToggleGistEditor
  /// Toggle MCP tool registration (advertise gists as tools).
  | ToggleMcpTools
  /// Dismiss error.
  | DismissGistError
  /// Update a schema parameter on the current gist.
  | UpdateGistSchemaName(string)
  /// Update schema summary.
  | UpdateGistSchemaSummary(string)
  /// Add a schema input parameter.
  | AddGistSchemaParam
  /// Remove a schema input parameter by index.
  | RemoveGistSchemaParam(int)
  /// Snapshot current gist state as a diachronic checkpoint (time-based rollback).
  | SnapshotDiachronic
  /// Restore a diachronic checkpoint by index.
  | RestoreDiachronic(int)
  /// Insert gist into a synchronic cardfile (space-based composition).
  | InsertIntoCardfile(string) // cardfile id
  /// Remove gist from a synchronic cardfile.
  | RemoveFromCardfile(string) // cardfile id
