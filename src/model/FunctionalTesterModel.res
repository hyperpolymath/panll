// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Functional Tester Model — end-to-end game workflow simulation state.
/// This module has NO dependencies on other PanLL modules.

/// A step in a functional test workflow.
type workflowStep = {
  id: string,
  action: string,
  expectedOutcome: string,
  actualOutcome: option<string>,
  passed: option<bool>,
  screenshotPath: option<string>,
  durationMs: option<float>,
}

/// Overall workflow status.
type workflowStatus =
  | WorkflowDraft
  | WorkflowReady
  | WorkflowRunning(int) // current step index
  | WorkflowPassed(float) // total duration ms
  | WorkflowFailed(int, string) // failed step index, error

/// A complete functional test workflow.
type testWorkflow = {
  id: string,
  name: string,
  description: string,
  steps: array<workflowStep>,
  status: workflowStatus,
  createdAt: string,
  lastRunAt: option<string>,
}

/// Active tab.
type functionalTestTab =
  | TabWorkflows
  | TabEditor
  | TabResults
  | TabTemplates

/// Functional tester state.
type functionalTesterState = {
  activeTab: functionalTestTab,
  workflows: array<testWorkflow>,
  selectedWorkflow: option<string>,
  editing: bool,
  running: bool,
  error: option<string>,
}
