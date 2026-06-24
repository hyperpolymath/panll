// SPDX-License-Identifier: MPL-2.0

/// PanLL Unit Test Runner Model — interactive test execution dashboard with
/// coverage heatmaps, run history, and diff-aware filtering for IDApTIK.
///
/// Runs ReScript tests with per-module coverage tracking, provides a sortable
/// pass/fail tree with line-level coverage overlay, and supports diff-aware
/// mode that only runs tests affected by recent file changes.
///
/// Clade: Scanner. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Test Case Status
// ============================================================================

/// Execution status of a single test case.
type testCaseStatus =
  /// Test has not yet been executed in this run.
  | TestPending
  /// Test is currently executing.
  | TestRunning
  /// Test passed — payload is duration in milliseconds.
  | TestPassed(float)
  /// Test failed — payload is (error message, duration in milliseconds).
  | TestFailed(string, float)
  /// Test was skipped — payload is the skip reason.
  | TestSkipped(string)

// ============================================================================
// Test Results
// ============================================================================

/// A single test case result within a test suite.
type testCaseResult = {
  /// Name of the test suite containing this test.
  suiteName: string,
  /// Name of this individual test case.
  testName: string,
  /// Current execution status.
  status: testCaseStatus,
  /// File path of the test source.
  filePath: string,
  /// Line number where the test is defined.
  lineNumber: int,
}

// ============================================================================
// Coverage Tracking
// ============================================================================

/// Coverage statistics for a single module.
type moduleCoverage = {
  /// Module name (e.g., "LevelArchitectEngine").
  moduleName: string,
  /// File path to the module source.
  filePath: string,
  /// Total number of functions in the module.
  totalFunctions: int,
  /// Number of functions exercised by at least one test.
  testedFunctions: int,
  /// Coverage percentage (0.0 to 100.0).
  coveragePercent: float,
  /// Names of untested functions.
  untested: array<string>,
}

/// Coverage heatmap cell for visual display.
type coverageHeatCell = {
  /// Module name.
  moduleName: string,
  /// Coverage percentage (drives the cell colour intensity).
  coveragePercent: float,
  /// Total functions in the module.
  totalFunctions: int,
}

// ============================================================================
// Run History
// ============================================================================

/// Aggregate summary of a test run (all suites).
type testRunSummary = {
  /// Total number of tests in this run.
  totalTests: int,
  /// Number of passed tests.
  passed: int,
  /// Number of failed tests.
  failed: int,
  /// Number of skipped tests.
  skipped: int,
  /// Total duration of the run in milliseconds.
  durationMs: float,
  /// ISO 8601 timestamp of this run.
  timestamp: string,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Unit Test Runner panel.
type unitTestTab =
  /// Test Results — sortable pass/fail tree grouped by suite.
  | TabTestResults
  /// Coverage — module coverage heatmap and untested function list.
  | TabCoverage
  /// History — run-over-run trend showing pass rate and duration.
  | TabHistory
  /// Diff-Aware — only tests affected by recent file changes.
  | TabDiffAware

/// Sort order for the test results list.
type testSortBy =
  /// Alphabetical by test name.
  | SortByName
  /// Failed tests first, then pending, then passed.
  | SortByStatus
  /// Slowest tests first.
  | SortByDuration
  /// Group by suite name.
  | SortBySuite

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Unit Test Runner panel.
type unitTestRunnerState = {
  /// Active tab within the panel.
  activeTab: unitTestTab,
  /// Individual test case results from the most recent run.
  results: array<testCaseResult>,
  /// Per-module coverage statistics.
  coverage: array<moduleCoverage>,
  /// Coverage heatmap cells for the visual grid.
  heatmap: array<coverageHeatCell>,
  /// Historical run summaries.
  history: array<testRunSummary>,
  /// Whether tests are currently executing.
  running: bool,
  /// Text filter for test/suite names.
  filter: string,
  /// Sort order for test results.
  sortBy: testSortBy,
  /// Whether diff-aware mode is active (only run changed tests).
  diffAwareOnly: bool,
  /// Error from the last operation.
  error: option<string>,
}
