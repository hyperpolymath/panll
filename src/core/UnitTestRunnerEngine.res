// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Unit Test Runner Engine — pure computation and helpers for the
/// Unit Test Runner panel. Provides default state, test counting, coverage
/// calculation, result filtering, sorting, and heatmap generation.

open UnitTestRunnerModel

/// Default initial state for the Unit Test Runner panel.
/// Starts on the Test Results tab with no filter and SortByName order.
let defaultState: unitTestRunnerState = {
  activeTab: TabTestResults,
  results: [],
  coverage: [],
  heatmap: [],
  history: [],
  running: false,
  filter: "",
  sortBy: SortByName,
  diffAwareOnly: false,
  error: None,
}

/// Human-readable label for each tab in the Unit Test Runner panel.
let tabLabel = (tab: unitTestTab): string =>
  switch tab {
  | TabTestResults => "Test Results"
  | TabCoverage => "Coverage"
  | TabHistory => "History"
  | TabDiffAware => "Diff-Aware"
  }

/// All tabs in display order.
let allTabs: array<unitTestTab> = [TabTestResults, TabCoverage, TabHistory, TabDiffAware]

/// Count passed tests.
let countPassed = (results: array<testCaseResult>): int =>
  results->Array.filter(r => switch r.status {
  | TestPassed(_) => true
  | _ => false
  })->Array.length

/// Count failed tests.
let countFailed = (results: array<testCaseResult>): int =>
  results->Array.filter(r => switch r.status {
  | TestFailed(_, _) => true
  | _ => false
  })->Array.length

/// Count skipped tests.
let countSkipped = (results: array<testCaseResult>): int =>
  results->Array.filter(r => switch r.status {
  | TestSkipped(_) => true
  | _ => false
  })->Array.length

/// Count running tests.
let countRunning = (results: array<testCaseResult>): int =>
  results->Array.filter(r => switch r.status {
  | TestRunning => true
  | _ => false
  })->Array.length

/// Calculate overall coverage percentage across all modules.
let overallCoverage = (coverage: array<moduleCoverage>): float => {
  let total = coverage->Array.reduce(0, (acc, m) => acc + m.totalFunctions)
  let tested = coverage->Array.reduce(0, (acc, m) => acc + m.testedFunctions)
  if total == 0 {
    0.0
  } else {
    Float.fromInt(tested) /. Float.fromInt(total) *. 100.0
  }
}

/// Filter results by search string (case-insensitive, matches test and suite names).
let filterResults = (results: array<testCaseResult>, filter: string): array<testCaseResult> =>
  if filter == "" {
    results
  } else {
    let q = filter->String.toLowerCase
    results->Array.filter(r =>
      r.testName->String.toLowerCase->String.includes(q) ||
        r.suiteName->String.toLowerCase->String.includes(q)
    )
  }

/// Sort results by the specified sort order.
let sortResults = (results: array<testCaseResult>, sortBy: testSortBy): array<testCaseResult> => {
  let compare = switch sortBy {
  | SortByName => (a: testCaseResult, b: testCaseResult) =>
      String.compare(a.testName, b.testName)
  | SortBySuite => (a: testCaseResult, b: testCaseResult) =>
      String.compare(a.suiteName, b.suiteName)
  | SortByStatus => (a: testCaseResult, b: testCaseResult) => {
      let statusRank = (s: testCaseStatus) =>
        switch s {
        | TestFailed(_, _) => 0
        | TestRunning => 1
        | TestPending => 2
        | TestSkipped(_) => 3
        | TestPassed(_) => 4
        }
      Int.compare(statusRank(a.status), statusRank(b.status))
    }
  | SortByDuration => (a: testCaseResult, b: testCaseResult) => {
      let dur = (s: testCaseStatus) =>
        switch s {
        | TestPassed(d) | TestFailed(_, d) => d
        | _ => 0.0
        }
      Float.compare(dur(b.status), dur(a.status))
    }
  }
  results->Array.toSorted(compare)
}

/// Generate heatmap cells from coverage data.
let generateHeatmap = (coverage: array<moduleCoverage>): array<coverageHeatCell> =>
  coverage->Array.map(m => {
    moduleName: m.moduleName,
    coveragePercent: m.coveragePercent,
    totalFunctions: m.totalFunctions,
  })

/// Human-readable label for test status.
let statusLabel = (status: testCaseStatus): string =>
  switch status {
  | TestPending => "Pending"
  | TestRunning => "Running"
  | TestPassed(ms) => `Passed (${Float.toFixed(ms, ~digits=1)}ms)`
  | TestFailed(err, _) => `Failed: ${err}`
  | TestSkipped(reason) => `Skipped: ${reason}`
  }

/// CSS colour class for test status.
let statusColor = (status: testCaseStatus): string =>
  switch status {
  | TestPending => "text-gray-400"
  | TestRunning => "text-yellow-400"
  | TestPassed(_) => "text-green-400"
  | TestFailed(_, _) => "text-red-400"
  | TestSkipped(_) => "text-gray-500"
  }

/// Pass rate from a run summary as a percentage.
let runPassRate = (summary: testRunSummary): float => {
  let run = summary.totalTests - summary.skipped
  if run == 0 { 0.0 } else { Float.fromInt(summary.passed) /. Float.fromInt(run) *. 100.0 }
}
