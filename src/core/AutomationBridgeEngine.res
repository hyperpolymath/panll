// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Automation Bridge Engine — pure computation and helpers for the
/// Automation Bridge panel. Provides default state, tab metadata, pipeline
/// status counting, trigger aggregation, and history formatting.

open AutomationBridgeModel

/// Default state for the Automation Bridge panel.
/// Starts on the Pipelines tab with empty pipeline, trigger, and history lists.
let defaultState: automationBridgeState = {
  activeTab: Pipelines,
  pipelines: [],
  triggers: [],
  buildHistory: [],
  running: false,
  error: None,
}

/// Human-readable label for each tab in the Automation Bridge panel.
let tabLabel = (tab: automationBridgeTab): string =>
  switch tab {
  | Pipelines => "Pipelines"
  | Triggers => "Triggers"
  | Status => "Status"
  | History => "History"
  }

/// All tabs in display order.
let allTabs: array<automationBridgeTab> = [Pipelines, Triggers, Status, History]

/// Count pipelines that are currently active (queued or running).
let countActivePipelines = (pipelines: array<pipeline>): int =>
  pipelines
  ->Array.filter(p =>
    switch p.status {
    | PipelineQueued | PipelineRunning => true
    | _ => false
    }
  )
  ->Array.length

/// Count pipelines matching a given status.
let countPipelinesByStatus = (pipelines: array<pipeline>, status: automationPipelineStatus): int =>
  pipelines->Array.filter(p => p.status === status)->Array.length

/// Count triggers that are currently pending (enabled and awaiting activation).
let countPendingTriggers = (triggers: array<trigger>): int =>
  triggers->Array.filter(t => t.enabled)->Array.length

/// Count triggers that are disabled.
let countDisabledTriggers = (triggers: array<trigger>): int =>
  triggers->Array.filter(t => !t.enabled)->Array.length

/// Human-readable label for a pipeline status.
let pipelineStatusLabel = (status: automationPipelineStatus): string =>
  switch status {
  | PipelineIdle => "Idle"
  | PipelineQueued => "Queued"
  | PipelineRunning => "Running"
  | PipelineSucceeded => "Succeeded"
  | PipelineFailed => "Failed"
  | PipelineCancelled => "Cancelled"
  }

/// Human-readable label for a trigger event type.
let triggerEventLabel = (event: automationTriggerEvent): string =>
  switch event {
  | TriggerPush => "Push"
  | TriggerPullRequest => "Pull Request"
  | TriggerTag => "Tag"
  | TriggerSchedule => "Schedule"
  | TriggerManual => "Manual"
  | TriggerFileChange => "File Change"
  }

/// Compute the success rate of historical builds as a percentage (0.0 to 100.0).
/// Returns 100.0 when there is no build history.
let buildSuccessRate = (history: array<automationBuildEntry>): float => {
  let total = Array.length(history)
  if total === 0 {
    100.0
  } else {
    let succeeded = history->Array.filter(h => h.status === PipelineSucceeded)->Array.length
    Int.toFloat(succeeded) /. Int.toFloat(total) *. 100.0
  }
}
