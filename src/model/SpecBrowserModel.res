// SPDX-License-Identifier: MPL-2.0

/// PanLL SpecBrowser Model — leaf types for browsing language specifications.
///
/// Tracks all 16 language/query projects in nextgen-languages, showing their
/// grammar definitions (EBNF), typing rules (SPEC.core.scm), taxonomy
/// completeness, and verification status. Supports side-by-side comparison
/// of any two languages.
///
/// Dependency: none (leaf module in the type DAG).

/// Which standard file is being viewed or checked for existence.
type specFileKind =
  /// Grammar definition in Extended Backus-Naur Form.
  | GrammarEbnf
  /// Core specification in Scheme format.
  | SpecCoreScm
  /// Typing rules definition.
  | TypingRules
  /// Operational semantics.
  | OperationalSemantics
  /// Denotational semantics.
  | DenotationalSemantics
  /// Test suite (conformance tests).
  | ConformanceTests
  /// Benchmark suite.
  | Benchmarks
  /// Proof artefacts (Idris2/Coq/Lean).
  | ProofArtefacts

/// Existence status for a standard file in a language project.
type filePresence = {
  /// Which file kind.
  kind: specFileKind,
  /// Whether the file exists.
  exists: bool,
  /// Line count if the file exists, 0 otherwise.
  lineCount: int,
  /// Relative path within the language project.
  path: string,
}

/// Verification status summary for a language project.
type verificationSummary = {
  /// Total number of tests.
  totalTests: int,
  /// Number of passing tests.
  passingTests: int,
  /// Number of admitted/sorry proofs (formal verification debt).
  admittedCount: int,
  /// Number of fully discharged proofs.
  provedCount: int,
  /// Whether fuzzing coverage exists.
  hasFuzzing: bool,
  /// Whether conformance suite exists and passes.
  conformancePassing: bool,
}

/// A language project entry for the SpecBrowser.
type specLanguageEntry = {
  /// Language name (e.g., "AffineScript", "Eclexia").
  name: string,
  /// Short description of the language.
  description: string,
  /// Implementation language (e.g., "OCaml", "Rust").
  implLang: string,
  /// Standard file presence inventory.
  files: array<filePresence>,
  /// Grammar content (loaded on demand).
  grammarContent: option<string>,
  /// Spec content (loaded on demand).
  specContent: option<string>,
  /// Typing rules content (loaded on demand).
  typingRulesContent: option<string>,
  /// Verification summary.
  verification: verificationSummary,
  /// Taxonomy completeness percentage (0-100).
  taxonomyCompleteness: int,
}

/// Category tabs for the SpecBrowser panel.
type specBrowserCategory =
  /// Overview grid showing all languages and their taxonomy completeness.
  | SpecOverview
  /// Side-by-side comparison of two selected languages.
  | SpecComparison
  /// Grammar viewer for a single language.
  | SpecGrammar
  /// Typing rules viewer for a single language.
  | SpecTypingRules
  /// Verification status across all languages.
  | SpecVerification

/// Which content pane in the comparison view.
type comparisonSide =
  | LeftSide
  | RightSide

/// Root state for the SpecBrowser panel module.
type specBrowserState = {
  /// Whether language spec data has been loaded.
  loaded: bool,
  /// Loading indicator for async operations.
  loading: bool,
  /// Last error message, if any.
  error: option<string>,
  /// Full inventory of language specifications.
  languages: array<specLanguageEntry>,
  /// Active category tab.
  activeCategory: specBrowserCategory,
  /// Currently selected language for detail/grammar/typing views.
  selectedLanguage: option<string>,
  /// Left-side language for comparison view.
  comparisonLeft: option<string>,
  /// Right-side language for comparison view.
  comparisonRight: option<string>,
  /// Text filter for language name search.
  filterText: string,
  /// Whether to show only languages with missing files.
  showIncompleteOnly: bool,
}

/// Aggregate statistics across the language portfolio.
type portfolioStats = {
  /// Total number of languages tracked.
  totalLanguages: int,
  /// Average taxonomy completeness percentage.
  avgCompleteness: int,
  /// Number of languages at 100% completeness.
  fullySpecified: int,
  /// Total tests across all languages.
  totalTests: int,
  /// Total admitted/sorry proofs across all languages.
  totalAdmitted: int,
}

/// Initial state — empty inventory, ready to load.
let initial: specBrowserState = {
  loaded: false,
  loading: false,
  error: None,
  languages: [],
  activeCategory: SpecOverview,
  selectedLanguage: None,
  comparisonLeft: None,
  comparisonRight: None,
  filterText: "",
  showIncompleteOnly: false,
}
