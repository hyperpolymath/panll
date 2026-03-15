// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Functional Tester Engine — pure functions for workflow simulation state.

open FunctionalTesterModel

/// Default initial state.
let defaultState: functionalTesterState = {
  activeTab: TabWorkflows,
  workflows: [],
  selectedWorkflow: None,
  editing: false,
  running: false,
  error: None,
}

/// Tab label for display.
let tabLabel = (tab: functionalTestTab): string =>
  switch tab {
  | TabWorkflows => "Workflows"
  | TabEditor => "Editor"
  | TabResults => "Results"
  | TabTemplates => "Templates"
  }

/// All tabs for rendering.
let allTabs: array<functionalTestTab> = [TabWorkflows, TabEditor, TabResults, TabTemplates]

/// Count workflow steps by status.
let completedSteps = (workflow: testWorkflow): int =>
  workflow.steps->Array.filter(s => s.passed == Some(true))->Array.length

/// Calculate workflow progress as percentage.
let workflowProgress = (workflow: testWorkflow): float => {
  let total = workflow.steps->Array.length
  if total == 0 { 0.0 }
  else { Float.fromInt(completedSteps(workflow)) /. Float.fromInt(total) *. 100.0 }
}

/// Get current step index for running workflow.
let currentStep = (status: workflowStatus): option<int> =>
  switch status { | WorkflowRunning(i) => Some(i) | _ => None }

/// Count workflows by status.
let countByStatus = (workflows: array<testWorkflow>, pred: workflowStatus => bool): int =>
  workflows->Array.filter(w => pred(w.status))->Array.length
