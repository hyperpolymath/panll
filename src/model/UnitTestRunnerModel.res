// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Unit Test Runner Model — test execution and coverage state.
/// This module has NO dependencies on other PanLL modules.

/// Status of a single test case.
type testCaseStatus =
  | TestPending
  | TestRunning
  | TestPassed(float) // duration ms
  | TestFailed(string, float) // error message, duration ms
  | TestSkipped(string) // reason

/// A single test case result.
type testCaseResult = {
  suiteName: string,
  testName: string,
  status: testCaseStatus,
  filePath: string,
  lineNumber: int,
}

/// Coverage status for a module.
type moduleCoverage = {
  moduleName: string,
  filePath: string,
  totalFunctions: int,
  testedFunctions: int,
  coveragePercent: float,
  untested: array<string>,
}

/// Test run summary.
type testRunSummary = {
  totalTests: int,
  passed: int,
  failed: int,
  skipped: int,
  durationMs: float,
  timestamp: string,
}

/// Active tab in the Unit Test Runner panel.
type unitTestTab =
  | TabTestResults
  | TabCoverage
  | TabHistory
  | TabDiffAware

/// Sort order for test results.
type testSortBy =
  | SortByName
  | SortByStatus
  | SortByDuration
  | SortBySuite

/// Unit test runner state.
type unitTestRunnerState = {
  activeTab: unitTestTab,
  results: array<testCaseResult>,
  coverage: array<moduleCoverage>,
  history: array<testRunSummary>,
  running: bool,
  filter: string,
  sortBy: testSortBy,
  diffAwareOnly: bool,
  error: option<string>,
}
