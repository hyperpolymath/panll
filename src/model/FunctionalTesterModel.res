// SPDX-License-Identifier: MPL-2.0

/// PanLL Functional Tester Model — end-to-end game workflow simulation and
/// validation for IDApTIK game testing.
///
/// Provides scriptable test scenarios that define step-by-step game workflows
/// (start -> hack -> win) with expected outcomes at each stage. Steps capture
/// screenshots, measure timing, and report pass/fail against expected results.
///
/// Clade: Scanner. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Workflow Steps
// ============================================================================

/// A single step in a functional test workflow.
/// Each step describes an action to perform, the expected outcome, and
/// captures the actual result when the workflow is executed.
type workflowStep = {
  /// Unique step identifier within the workflow.
  id: string,
  /// Human-readable action description (e.g., "Navigate to Level 3 entrance").
  action: string,
  /// Expected outcome after this step completes (e.g., "Player enters Level 3").
  expectedOutcome: string,
  /// Actual outcome observed during execution (populated after run).
  actualOutcome: option<string>,
  /// Whether this step passed (None = not yet run).
  passed: option<bool>,
  /// Path to screenshot captured at this step (if screenshot capture enabled).
  screenshotPath: option<string>,
  /// Duration of this step in milliseconds (populated after run).
  durationMs: option<float>,
}

// ============================================================================
// Workflow Status
// ============================================================================

/// Overall execution status of a functional test workflow.
type workflowStatus =
  /// Draft — workflow is being designed, not yet ready to run.
  | WorkflowDraft
  /// Ready — all steps defined, workflow can be executed.
  | WorkflowReady
  /// Running — currently executing, payload is the current step index.
  | WorkflowRunning(int)
  /// Passed — all steps completed successfully, payload is total duration in ms.
  | WorkflowPassed(float)
  /// Failed — a step did not match expected outcome, payload is (step index, error).
  | WorkflowFailed(int, string)

// ============================================================================
// Test Workflows
// ============================================================================

/// A complete functional test workflow — a named sequence of steps that
/// exercises a specific game path end-to-end.
type testWorkflow = {
  /// Unique workflow identifier.
  id: string,
  /// Human-readable workflow name (e.g., "Level 5 speed-run").
  name: string,
  /// Longer description of what this workflow tests.
  description: string,
  /// Ordered array of steps to execute.
  steps: array<workflowStep>,
  /// Current execution status.
  status: workflowStatus,
  /// ISO 8601 timestamp when this workflow was created.
  createdAt: string,
  /// ISO 8601 timestamp of the most recent execution (None if never run).
  lastRunAt: option<string>,
}

// ============================================================================
// Workflow Templates
// ============================================================================

/// A reusable workflow template that can be instantiated into a testWorkflow.
type workflowTemplate = {
  /// Template identifier.
  id: string,
  /// Template name (e.g., "Standard Level Completion").
  name: string,
  /// Template description.
  description: string,
  /// Template step definitions (action + expectedOutcome).
  stepDefinitions: array<(string, string)>,
  /// Tags for categorising templates (e.g., ["combat", "stealth"]).
  tags: array<string>,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Functional Tester panel.
type functionalTestTab =
  /// Workflows — list all defined test workflows with status badges.
  | TabWorkflows
  /// Editor — step-by-step workflow builder with drag-and-drop reordering.
  | TabEditor
  /// Results — execution results with pass/fail indicators and screenshots.
  | TabResults
  /// Templates — browse and instantiate reusable workflow templates.
  | TabTemplates

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Functional Tester panel.
type functionalTesterState = {
  /// Active tab within the panel.
  activeTab: functionalTestTab,
  /// All defined test workflows.
  workflows: array<testWorkflow>,
  /// Currently selected workflow ID for detail view.
  selectedWorkflow: option<string>,
  /// Whether the workflow editor is active.
  editing: bool,
  /// Whether a workflow is currently being executed.
  running: bool,
  /// Available workflow templates.
  templates: array<workflowTemplate>,
  /// Error from the last operation.
  error: option<string>,
}
