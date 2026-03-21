// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Functional Tester Engine — pure computation and helpers for the
/// Functional Tester panel. Provides default state, tab metadata, workflow
/// progress calculation, step counting, and status formatting.

open FunctionalTesterModel

/// Default state for the Functional Tester panel.
/// Starts on the Workflows tab with empty workflow list and no templates.
let defaultState: functionalTesterState = {
  activeTab: TabWorkflows,
  workflows: [],
  selectedWorkflow: None,
  editing: false,
  running: false,
  templates: [],
  error: None,
}

/// Human-readable label for each tab in the Functional Tester panel.
let tabLabel = (tab: functionalTestTab): string =>
  switch tab {
  | TabWorkflows => "Workflows"
  | TabEditor => "Editor"
  | TabResults => "Results"
  | TabTemplates => "Templates"
  }

/// All tabs in display order.
let allTabs: array<functionalTestTab> = [TabWorkflows, TabEditor, TabResults, TabTemplates]

/// Count the number of completed (passed) steps in a workflow.
let completedSteps = (workflow: testWorkflow): int =>
  workflow.steps->Array.filter(s => s.passed == Some(true))->Array.length

/// Count the number of failed steps in a workflow.
let failedSteps = (workflow: testWorkflow): int =>
  workflow.steps->Array.filter(s => s.passed == Some(false))->Array.length

/// Calculate workflow progress as a percentage (0.0 to 100.0).
let workflowProgress = (workflow: testWorkflow): float => {
  let total = workflow.steps->Array.length
  if total == 0 {
    0.0
  } else {
    Float.fromInt(completedSteps(workflow)) /. Float.fromInt(total) *. 100.0
  }
}

/// Get the current step index for a running workflow.
let currentStep = (status: workflowStatus): option<int> =>
  switch status {
  | WorkflowRunning(i) => Some(i)
  | _ => None
  }

/// Count workflows matching a predicate on their status.
let countByStatus = (workflows: array<testWorkflow>, pred: workflowStatus => bool): int =>
  workflows->Array.filter(w => pred(w.status))->Array.length

/// Human-readable label for a workflow status.
let statusLabel = (status: workflowStatus): string =>
  switch status {
  | WorkflowDraft => "Draft"
  | WorkflowReady => "Ready"
  | WorkflowRunning(step) => `Running (step ${Int.toString(step + 1)})`
  | WorkflowPassed(ms) => `Passed (${Float.toFixed(ms, ~digits=0)}ms)`
  | WorkflowFailed(step, _) => `Failed at step ${Int.toString(step + 1)}`
  }

/// CSS colour class for a workflow status.
let statusColor = (status: workflowStatus): string =>
  switch status {
  | WorkflowDraft => "text-gray-400"
  | WorkflowReady => "text-blue-400"
  | WorkflowRunning(_) => "text-yellow-400"
  | WorkflowPassed(_) => "text-green-400"
  | WorkflowFailed(_, _) => "text-red-400"
  }

/// Whether a workflow can be executed (Ready status with at least one step).
let canRun = (workflow: testWorkflow): bool =>
  switch workflow.status {
  | WorkflowReady => Array.length(workflow.steps) > 0
  | _ => false
  }

/// Total execution time of all completed steps in a workflow.
let totalStepDuration = (workflow: testWorkflow): float =>
  workflow.steps->Array.reduce(0.0, (acc, step) =>
    switch step.durationMs {
    | Some(ms) => acc +. ms
    | None => acc
    }
  )

/// Count workflows that have ever been run.
let countEverRun = (workflows: array<testWorkflow>): int =>
  workflows->Array.filter(w => w.lastRunAt != None)->Array.length
