// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Typing Bridge Engine — pure computation and helpers for the
/// Typing Bridge panel. Provides default state, tab metadata, constraint
/// counting, and inference result formatting.

open TypingBridgeModel

/// Default state for the Typing Bridge panel.
/// Starts on the Constraints tab with empty constraint and inference lists.
let defaultState: typingBridgeState = {
  activeTab: Constraints,
  constraints: [],
  inferenceResults: [],
  selectedConstraint: None,
  configFields: [],
  running: false,
  error: None,
}

/// Human-readable label for each tab in the Typing Bridge panel.
let tabLabel = (tab: typingBridgeTab): string =>
  switch tab {
  | Constraints => "Constraints"
  | Inference => "Inference"
  | Editor => "Editor"
  | Diagnostics => "Diagnostics"
  }

/// All tabs in display order.
let allTabs: array<typingBridgeTab> = [Constraints, Inference, Editor, Diagnostics]

/// Count the total number of registered type constraints.
let countConstraints = (state: typingBridgeState): int =>
  Array.length(state.constraints)

/// Count constraints that are currently violated (not satisfied).
let countViolated = (state: typingBridgeState): int =>
  state.constraints->Array.filter(c => !c.satisfied)->Array.length

/// Count constraints by severity.
let countBySeverity = (constraints: array<gameTypeConstraint>, severity: constraintSeverity): int =>
  constraints->Array.filter(c => c.severity === severity)->Array.length

/// Human-readable label for constraint severity.
let severityLabel = (severity: constraintSeverity): string =>
  switch severity {
  | ConstraintError => "Error"
  | ConstraintWarning => "Warning"
  | ConstraintInfo => "Info"
  }

/// Format a single inference result as a human-readable summary string.
/// Includes the target path, inferred type, and status indicator.
let formatInferenceResult = (result: inferenceResult): string => {
  let statusIcon = switch result.status {
  | InferenceSuccess => "[OK]"
  | InferencePartial => "[Partial]"
  | InferenceFailed => "[Failed]"
  }
  `${statusIcon} ${result.targetPath}: ${result.inferredType}`
}

/// Count inference results by status.
let countInferenceByStatus = (results: array<inferenceResult>, status: inferenceStatus): int =>
  results->Array.filter(r => r.status === status)->Array.length

/// Count configuration fields that have validation errors.
let countInvalidFields = (fields: array<typedConfigField>): int =>
  fields->Array.filter(f => !f.valid)->Array.length

/// Compute the constraint satisfaction percentage (0.0 to 100.0).
/// Returns 100.0 when there are no constraints.
let satisfactionPercent = (state: typingBridgeState): float => {
  let total = Array.length(state.constraints)
  if total === 0 {
    100.0
  } else {
    let satisfied = state.constraints->Array.filter(c => c.satisfied)->Array.length
    Int.toFloat(satisfied) /. Int.toFloat(total) *. 100.0
  }
}
