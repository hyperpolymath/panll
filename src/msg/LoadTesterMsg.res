// SPDX-License-Identifier: MPL-2.0

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
