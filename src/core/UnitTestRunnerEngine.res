// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Unit Test Runner Engine — pure functions for test execution state management.

open UnitTestRunnerModel

/// Default initial state.
let defaultState: unitTestRunnerState = {
  activeTab: TabTestResults,
  results: [],
  coverage: [],
  history: [],
  running: false,
  filter: "",
  sortBy: SortByName,
  diffAwareOnly: false,
  error: None,
}

/// Tab label for display.
let tabLabel = (tab: unitTestTab): string =>
  switch tab {
  | TabTestResults => "Test Results"
  | TabCoverage => "Coverage"
  | TabHistory => "History"
  | TabDiffAware => "Diff-Aware"
  }

/// All tabs for rendering.
let allTabs: array<unitTestTab> = [TabTestResults, TabCoverage, TabHistory, TabDiffAware]

/// Count tests by status.
let countPassed = (results: array<testCaseResult>): int =>
  results->Array.filter(r => switch r.status { | TestPassed(_) => true | _ => false })->Array.length

let countFailed = (results: array<testCaseResult>): int =>
  results->Array.filter(r => switch r.status { | TestFailed(_, _) => true | _ => false })->Array.length

let countSkipped = (results: array<testCaseResult>): int =>
  results->Array.filter(r => switch r.status { | TestSkipped(_) => true | _ => false })->Array.length

/// Calculate overall coverage percentage.
let overallCoverage = (coverage: array<moduleCoverage>): float => {
  let total = coverage->Array.reduce(0, (acc, m) => acc + m.totalFunctions)
  let tested = coverage->Array.reduce(0, (acc, m) => acc + m.testedFunctions)
  if total == 0 { 0.0 } else { Float.fromInt(tested) /. Float.fromInt(total) *. 100.0 }
}

/// Filter results by search string.
let filterResults = (results: array<testCaseResult>, filter: string): array<testCaseResult> =>
  if filter == "" { results }
  else { results->Array.filter(r => String.includes(r.testName, filter) || String.includes(r.suiteName, filter)) }

/// Sort results.
let sortResults = (results: array<testCaseResult>, sortBy: testSortBy): array<testCaseResult> => {
  let compare = switch sortBy {
  | SortByName => (a: testCaseResult, b: testCaseResult) => String.compare(a.testName, b.testName)
  | SortBySuite => (a: testCaseResult, b: testCaseResult) => String.compare(a.suiteName, b.suiteName)
  | SortByStatus => (a: testCaseResult, b: testCaseResult) => {
      let statusRank = (s: testCaseStatus) => switch s { | TestFailed(_, _) => 0 | TestRunning => 1 | TestPending => 2 | TestSkipped(_) => 3 | TestPassed(_) => 4 }
      Int.compare(statusRank(a.status), statusRank(b.status))
    }
  | SortByDuration => (a: testCaseResult, b: testCaseResult) => {
      let dur = (s: testCaseStatus) => switch s { | TestPassed(d) | TestFailed(_, d) => d | _ => 0.0 }
      Float.compare(dur(b.status), dur(a.status))
    }
  }
  results->Array.toSorted(compare)
}
