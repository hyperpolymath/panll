// SPDX-License-Identifier: MPL-2.0

/// PanLL Language Forge Model — leaf types for the nextgen-languages portfolio panel.
///
/// Tracks all 14 nextgen-languages with their component completion status,
/// development phase, and WASM readiness. Provides filtering by category
/// (production-ready, in-progress, needs-work) and sorting by name/score/phase.
///
/// Dependency: none (leaf module in the type DAG).

/// Development maturity phase for a language project.
type languagePhase =
  | Production
  | NearProduction
  | Alpha
  | DesignOnly
  | Concept
  | Vaporware

/// Completion status for an individual compiler/runtime component.
type componentStatus = {
  /// Component name (e.g. "Lexer", "Parser", "Type Checker").
  name: string,
  /// Completion percentage (0–100).
  completion: int,
  /// Whether the component has test coverage.
  hasTests: bool,
}

/// A single language project in the nextgen-languages portfolio.
type languageEntry = {
  /// Language name (e.g. "AffineScript", "Eclexia").
  name: string,
  /// Implementation language (e.g. "OCaml", "Rust", "Elixir").
  implLang: string,
  /// Overall completion score (0–100).
  score: int,
  /// Current development phase.
  phase: languagePhase,
  /// Whether the lexer is complete.
  lexerComplete: bool,
  /// Whether the parser is complete.
  parserComplete: bool,
  /// Whether the type checker is complete.
  typeCheckerComplete: bool,
  /// Whether a WASM compilation backend exists.
  hasWasmBackend: bool,
  /// Whether there is any test coverage.
  hasTests: bool,
  /// Per-component completion breakdown.
  components: array<componentStatus>,
  /// Count of outstanding TODO items.
  todoCount: int,
  /// Lines of code in the project.
  locCount: int,
}

/// Filter categories for the language portfolio view.
type forgeCategory =
  /// Show all 14 languages.
  | AllLanguages
  /// Languages at Production or NearProduction phase.
  | ProductionReady
  /// Languages at Alpha or DesignOnly phase.
  | InProgress
  /// Languages at Concept or Vaporware phase.
  | NeedsWork

/// Sort criteria for the language table.
type forgeSortBy =
  /// Alphabetical by language name.
  | SortByName
  /// Descending by overall completion score.
  | SortByScore
  /// By development phase (Production first).
  | SortByPhase

/// Root state for the Language Forge panel module.
type languageForgeState = {
  /// Whether language data has been loaded.
  loaded: bool,
  /// Loading indicator for async operations.
  loading: bool,
  /// Last error message, if any.
  error: option<string>,
  /// Full portfolio of language projects.
  languages: array<languageEntry>,
  /// Active filter category tab.
  activeCategory: forgeCategory,
  /// Currently selected language name for detail view.
  selectedLanguage: option<string>,
  /// Text filter for language name search.
  filterText: string,
  /// Current sort criterion.
  sortBy: forgeSortBy,
  /// Whether to show the MoSCoW breakdown in detail view.
  showMoscow: bool,
}

/// Initial state — empty portfolio, ready to load.
let initial: languageForgeState = {
  loaded: false,
  loading: false,
  error: None,
  languages: [],
  activeCategory: AllLanguages,
  selectedLanguage: None,
  filterText: "",
  sortBy: SortByScore,
  showMoscow: false,
}
