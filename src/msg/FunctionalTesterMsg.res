// SPDX-License-Identifier: MPL-2.0

/// Functional Tester messages -- end-to-end game workflow simulation.

open Model

type functionalTesterMsg =
  | SetFtTab(functionalTestTab)
  | FtStarted
  | FtCompleted(result<string, string>)
  | DismissFtError
  | NewWorkflow
  | SelectWorkflow(string)
  | RunWorkflow(string)
  | LoadTemplate(string)
