// SPDX-License-Identifier: MPL-2.0

/// PanLL Automation Bridge Model — connects CI/CD pipeline automation to
/// IDApTIK game development. Bridges PanLL's build orchestration with game
/// asset pipelines, deployment workflows, and build dependency reasoning.
///
/// Three-panel model (L/N/W):
///   L: CI/CD pipeline rules, trigger conditions, build constraints
///   N: Pipeline reasoning about build order and dependency resolution
///   W: Build and deploy status dashboard with history
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Tab Navigation
// ============================================================================

/// Category tabs for the Automation Bridge panel.
type automationBridgeTab =
  /// Pipelines — define and browse CI/CD pipelines.
  | Pipelines
  /// Triggers — configure pipeline trigger conditions.
  | Triggers
  /// Status — live build and deploy status dashboard.
  | Status
  /// History — historical build and deploy records.
  | History

// ============================================================================
// Pipeline Domain
// ============================================================================

/// Status of a pipeline or pipeline step.
type automationPipelineStatus =
  /// Idle — pipeline has not been triggered.
  | PipelineIdle
  /// Queued — pipeline is waiting to start.
  | PipelineQueued
  /// Running — pipeline is currently executing.
  | PipelineRunning
  /// Succeeded — pipeline completed successfully.
  | PipelineSucceeded
  /// Failed — pipeline encountered an error.
  | PipelineFailed
  /// Cancelled — pipeline was manually cancelled.
  | PipelineCancelled

/// A single step within a CI/CD pipeline.
type pipelineStep = {
  /// Step identifier (unique within its pipeline).
  id: string,
  /// Human-readable step name (e.g., "Build Assets", "Run Tests").
  name: string,
  /// Command or action to execute.
  command: string,
  /// Current status of this step.
  status: automationPipelineStatus,
  /// Duration in milliseconds (if completed or running).
  durationMs: option<float>,
  /// Step output log (last N lines).
  outputTail: string,
}

/// A CI/CD pipeline definition with its steps and status.
type pipeline = {
  /// Unique pipeline identifier.
  id: string,
  /// Human-readable pipeline name (e.g., "Game Build", "Asset Pack Deploy").
  name: string,
  /// Ordered steps in this pipeline.
  steps: array<pipelineStep>,
  /// Overall pipeline status (derived from step statuses).
  status: automationPipelineStatus,
  /// Total duration in milliseconds (if completed or running).
  totalDurationMs: option<float>,
}

// ============================================================================
// Trigger Conditions
// ============================================================================

/// Type of event that triggers a pipeline.
type automationTriggerEvent =
  /// Git push to a specified branch.
  | TriggerPush
  /// Pull request opened or updated.
  | TriggerPullRequest
  /// Tag created matching a pattern.
  | TriggerTag
  /// Scheduled cron trigger.
  | TriggerSchedule
  /// Manual trigger by a user.
  | TriggerManual
  /// File change in a watched path.
  | TriggerFileChange

/// A trigger condition that activates a pipeline.
type trigger = {
  /// Unique trigger identifier.
  id: string,
  /// The pipeline this trigger activates.
  pipelineId: string,
  /// Type of event that fires this trigger.
  event: automationTriggerEvent,
  /// Filter pattern (branch name, path glob, cron expression, etc.).
  pattern: string,
  /// Whether this trigger is currently enabled.
  enabled: bool,
  /// Human-readable description.
  description: string,
}

// ============================================================================
// Build History
// ============================================================================

/// A historical build record.
type automationBuildEntry = {
  /// Unique build identifier.
  buildId: string,
  /// Pipeline that produced this build.
  pipelineId: string,
  /// Pipeline name (denormalised for display).
  pipelineName: string,
  /// Final status of the build.
  status: automationPipelineStatus,
  /// Trigger event that started this build.
  triggeredBy: automationTriggerEvent,
  /// Git commit SHA associated with this build.
  commitSha: string,
  /// Start timestamp (milliseconds since epoch).
  startedAt: float,
  /// Total duration in milliseconds.
  durationMs: float,
}

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Automation Bridge panel.
type automationBridgeState = {
  /// Active tab within the Automation Bridge panel.
  activeTab: automationBridgeTab,
  /// All registered pipelines.
  pipelines: array<pipeline>,
  /// All registered trigger conditions.
  triggers: array<trigger>,
  /// Historical build records (most recent first).
  buildHistory: array<automationBuildEntry>,
  /// Whether any pipeline is currently running.
  running: bool,
  /// Error from the last operation.
  error: option<string>,
}
