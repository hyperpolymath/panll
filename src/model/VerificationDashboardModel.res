// SPDX-License-Identifier: MPL-2.0

/// PanLL VerificationDashboard Model — leaf types for the verification status panel.
///
/// Aggregates proof, test, benchmark, and fuzzing status across all
/// nextgen-languages repos. Shows admitted/sorry counts, conformance suite
/// results, and benchmark performance data.
///
/// Dependency: none (leaf module in the type DAG).

/// Proof system used for formal verification.
type proofSystem =
  | Idris2Proof
  | CoqProof
  | LeanProof
  | IsabelleProof
  | AgdaProof
  | ManualProof

/// Conformance level for a test suite.
type conformanceLevel =
  /// All conformance tests pass.
  | FullConformance
  /// Most conformance tests pass (>80%).
  | PartialConformance
  /// Conformance suite exists but significant failures.
  | FailingConformance
  /// No conformance suite exists.
  | NoConformanceSuite

/// A benchmark result entry.
type benchmarkEntry = {
  /// Benchmark name (e.g., "fibonacci(30)", "sort-10k").
  name: string,
  /// Language this benchmark is for.
  language: string,
  /// Mean execution time in milliseconds.
  meanMs: float,
  /// Standard deviation in milliseconds.
  stddevMs: float,
  /// Number of iterations.
  iterations: int,
  /// Whether this is a regression from previous run.
  regression: bool,
}

/// Fuzzing coverage summary for a language.
type fuzzingCoverage = {
  /// Language name.
  language: string,
  /// Total fuzz targets.
  targets: int,
  /// Lines covered by fuzzing.
  linesCovered: int,
  /// Total lines in scope.
  totalLines: int,
  /// Crashes found by fuzzer.
  crashesFound: int,
  /// Hours of fuzzing accumulated.
  fuzzHours: float,
}

/// Verification status for a single language project.
type languageVerificationStatus = {
  /// Language name.
  name: string,
  /// Total test count.
  totalTests: int,
  /// Passing test count.
  passingTests: int,
  /// Failing test count.
  failingTests: int,
  /// Skipped test count.
  skippedTests: int,
  /// Count of admitted/sorry proofs (formal verification debt).
  admittedCount: int,
  /// Count of fully discharged proofs.
  provedCount: int,
  /// Which proof system(s) are used.
  proofSystems: array<proofSystem>,
  /// Conformance level.
  conformance: conformanceLevel,
  /// Available benchmark results.
  benchmarks: array<benchmarkEntry>,
  /// Fuzzing coverage, if available.
  fuzzing: option<fuzzingCoverage>,
  /// Last verification run timestamp (ISO 8601).
  lastRun: option<string>,
}

/// Category tabs for the VerificationDashboard.
type verificationDashboardCategory =
  /// Summary view — aggregated counts across all languages.
  | VdSummary
  /// Per-language detail view.
  | VdByLanguage
  /// Proof status — admitted/sorry tracking.
  | VdProofs
  /// Benchmark results table.
  | VdBenchmarks
  /// Fuzzing coverage report.
  | VdFuzzing

/// Sort mode for the verification table.
type verificationSortBy =
  /// Sort by language name.
  | VdSortByName
  /// Sort by test count (descending).
  | VdSortByTests
  /// Sort by pass rate (ascending — worst first).
  | VdSortByPassRate
  /// Sort by admitted count (descending — most debt first).
  | VdSortByAdmitted

/// Root state for the VerificationDashboard panel.
type verificationDashboardState = {
  /// Whether data has been loaded.
  loaded: bool,
  /// Loading indicator for async operations.
  loading: bool,
  /// Last error message, if any.
  error: option<string>,
  /// Verification status for all languages.
  languages: array<languageVerificationStatus>,
  /// Active category tab.
  activeCategory: verificationDashboardCategory,
  /// Currently selected language for detail view.
  selectedLanguage: option<string>,
  /// Text filter for language name search.
  filterText: string,
  /// Current sort criterion.
  sortBy: verificationSortBy,
  /// Whether to show only languages with admitted/sorry debt.
  showDebtOnly: bool,
}

/// Initial state — empty, ready to load.
let initial: verificationDashboardState = {
  loaded: false,
  loading: false,
  error: None,
  languages: [],
  activeCategory: VdSummary,
  selectedLanguage: None,
  filterText: "",
  sortBy: VdSortByTests,
  showDebtOnly: false,
}
