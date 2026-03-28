// SPDX-License-Identifier: PMPL-1.0-or-later

/// Load Tester messages -- Phoenix channel stress testing, concurrent simulation.

open Model

type loadTesterMsg =
  | SetLtTab(loadTestTab)
  | LtStarted
  | LtCompleted(result<string, string>)
  | DismissLtError
  | RunScenario(string)
  | RunSelectedScenario
  | SelectScenario(string)
