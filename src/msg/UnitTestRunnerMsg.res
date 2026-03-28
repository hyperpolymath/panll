// SPDX-License-Identifier: PMPL-1.0-or-later

/// Unit Test Runner messages -- test execution, coverage, diff-aware testing.

open Model

type unitTestRunnerMsg =
  | SetUtrTab(unitTestTab)
  | UtrStarted
  | UtrCompleted(result<string, string>)
  | DismissUtrError
  | RunAllTests
  | StopTests
  | ToggleDiffAware
