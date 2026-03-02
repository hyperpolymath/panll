// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Playgrounds Model — types for the code sandbox panel.
///
/// Multi-language code editor with NQC database console, output pane,
/// and educational/tutorial mode. Connects to VeriSimDB/QuandleDB/LithoGlyph
/// through the NQC proxy at :4000.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Supported playground languages.
type playgroundLanguage =
  /// VQL — VeriSimDB Query Language.
  | LangVql
  /// KQL — QuandleDB Query Language.
  | LangKql
  /// GQL — LithoGlyph Query Language.
  | LangGql
  /// ReScript — primary application language.
  | LangRescript
  /// Gleam — BEAM/JS backend language.
  | LangGleam
  /// Idris2 — dependently-typed ABI definitions.
  | LangIdris2
  /// Nickel — configuration language.
  | LangNickel

/// A saved code snippet in the playground.
type snippet = {
  /// Unique identifier.
  id: string,
  /// Human-readable title.
  title: string,
  /// The code content.
  code: string,
  /// Language this snippet is written in.
  language: playgroundLanguage,
  /// Whether this is a built-in tutorial snippet.
  isTutorial: bool,
}

/// Query execution result from the NQC proxy.
type queryResult = {
  /// Whether the query succeeded.
  success: bool,
  /// Result data (JSON string).
  data: option<string>,
  /// Error message if failed.
  error: option<string>,
  /// Execution time in milliseconds.
  durationMs: float,
  /// Number of rows/entities returned.
  rowCount: int,
}

/// Category tabs for the Playgrounds panel.
type playgroundsCategory =
  /// Code editor with language selector and output.
  | PlayEditor
  /// NQC database console (VQL/KQL/GQL).
  | PlayNqc
  /// Saved snippets library.
  | PlaySnippets
  /// Tutorial/educational mode.
  | PlayTutorials

/// Root state for the Playgrounds panel.
type playgroundsState = {
  /// Active category tab.
  activeCategory: playgroundsCategory,
  /// Currently selected language.
  activeLanguage: playgroundLanguage,
  /// Current editor content.
  editorContent: string,
  /// Last execution result.
  lastResult: option<queryResult>,
  /// Whether a query is currently executing.
  executing: bool,
  /// Error from the last operation.
  error: option<string>,
  /// Saved snippets.
  snippets: array<snippet>,
  /// NQC proxy connection status.
  nqcConnected: bool,
}
