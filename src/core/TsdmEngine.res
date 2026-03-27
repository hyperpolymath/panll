// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL TSDM Engine — pure functions for the Triaxial Software Development
/// Methodology directive panel.
///
/// Handles axis/tier reordering, cleanup step management, work item
/// filtering and sorting, and directive serialisation helpers. All
/// functions are side-effect-free.
///
/// The three axes (Scope → Maintenance → Audit) each have internal
/// priority tiers that users can reorder. This engine provides the
/// array-swap primitives and display helpers the component needs.

open TsdmModel

// =========================================================================
// Default state
// =========================================================================

/// Initial state for the TSDM panel — canonical axis ordering.
let defaultState: tsdmState = init

// =========================================================================
// Array reordering primitives
// =========================================================================

/// Swap element at index `i` with the element above it (i-1).
/// Returns the array unchanged if i is 0 or out of bounds.
let moveUp = (arr: array<'a>, i: int): array<'a> => {
  if i <= 0 || i >= Array.length(arr) {
    arr
  } else {
    let copy = Array.copy(arr)
    let tmp = copy->Array.getUnsafe(i - 1)
    copy->Array.setUnsafe(i - 1, copy->Array.getUnsafe(i))
    copy->Array.setUnsafe(i, tmp)
    copy
  }
}

/// Swap element at index `i` with the element below it (i+1).
/// Returns the array unchanged if i is the last element or out of bounds.
let moveDown = (arr: array<'a>, i: int): array<'a> => {
  if i < 0 || i >= Array.length(arr) - 1 {
    arr
  } else {
    let copy = Array.copy(arr)
    let tmp = copy->Array.getUnsafe(i + 1)
    copy->Array.setUnsafe(i + 1, copy->Array.getUnsafe(i))
    copy->Array.setUnsafe(i, tmp)
    copy
  }
}

// =========================================================================
// Display label helpers
// =========================================================================

/// Human-readable label for an axis.
let axisLabel = (axis: axisId): string =>
  switch axis {
  | AxisScope => "Scope"
  | AxisMaintenance => "Maintenance"
  | AxisAudit => "Audit"
  }

/// CSS colour class for an axis (for visual differentiation).
let axisColour = (axis: axisId): string =>
  switch axis {
  | AxisScope => "text-emerald-400"
  | AxisMaintenance => "text-amber-400"
  | AxisAudit => "text-cyan-400"
  }

/// Human-readable label for a scope tier.
let scopeTierLabel = (tier: scopeTier): string =>
  switch tier {
  | Must => "Must"
  | Intend => "Intend"
  | Like => "Like"
  }

/// Human-readable label for a maintenance tier.
let maintenanceTierLabel = (tier: maintenanceTier): string =>
  switch tier {
  | Corrective => "Corrective"
  | Adaptive => "Adaptive"
  | Perfective => "Perfective"
  }

/// Human-readable label for an audit tier.
let auditTierLabel = (tier: auditTier): string =>
  switch tier {
  | Systems => "Systems"
  | Compliance => "Compliance"
  | Effects => "Effects"
  }

/// Human-readable label for a scope input source.
let scopeInputLabel = (src: scopeInput): string =>
  switch src {
  | Readme => "README"
  | Roadmap => "ROADMAP"
  | StatusDocs => "Status Docs"
  | CiAndSecurityDocs => "CI & Security Docs"
  | MarkerScan => "Marker Scan (TODO/FIXME/XXX)"
  | IdrisUnsoundScan => "Idris Unsound Scan (believe_me)"
  }

/// Human-readable label for a cleanup step.
let cleanupStepLabel = (step: cleanupStep): string =>
  switch step {
  | RootCleanup => "Root Cleanup"
  | StaleWorkCull => "Stale Work Cull"
  | DocsSyncHumanMachine => "Docs Sync (Human ↔ Machine)"
  | ComplianceAudit => "Compliance Audit"
  | EffectsAudit => "Effects Audit"
  | ReleaseSummary => "Release Summary (must/should/could)"
  | NextActions => "Next Actions (corrective/adaptive/perfective)"
  }

/// Human-readable label for a dialogue topic.
let dialogueTopicLabel = (topic: dialogueTopic): string =>
  switch topic {
  | WhatChanged => "What Changed"
  | Why => "Why"
  | RemainingRisks => "Remaining Risks"
  }

// =========================================================================
// Cleanup step management
// =========================================================================

/// Check whether a cleanup step is enabled.
let isCleanupEnabled = (enabled: array<cleanupStep>, step: cleanupStep): bool =>
  enabled->Array.some(s => s == step)

/// Toggle a cleanup step on/off in the enabled set.
let toggleCleanupStep = (enabled: array<cleanupStep>, step: cleanupStep): array<cleanupStep> =>
  if isCleanupEnabled(enabled, step) {
    enabled->Array.filter(s => s != step)
  } else {
    Array.concat(enabled, [step])
  }

// =========================================================================
// Work item helpers
// =========================================================================

/// Filter work items by axis. None means show all axes.
let filterByAxis = (items: array<tsdmWorkItem>, axis: option<axisId>): array<tsdmWorkItem> =>
  switch axis {
  | None => items
  | Some(a) => items->Array.filter(item => item.axis == a)
  }

/// Filter work items by text search across title and description.
let filterBySearch = (items: array<tsdmWorkItem>, query: string): array<tsdmWorkItem> =>
  if query == "" {
    items
  } else {
    let q = String.toLowerCase(query)
    items->Array.filter(item =>
      String.includes(String.toLowerCase(item.title), q) ||
      String.includes(String.toLowerCase(item.description), q)
    )
  }

/// Filter out completed items unless showCompleted is true.
let filterCompleted = (items: array<tsdmWorkItem>, showCompleted: bool): array<tsdmWorkItem> =>
  if showCompleted {
    items
  } else {
    items->Array.filter(item => !item.done)
  }

/// Composite filter: axis → search → completed in one pipeline.
let applyFilters = (
  items: array<tsdmWorkItem>,
  axisFilter: option<axisId>,
  searchText: string,
  showCompleted: bool,
): array<tsdmWorkItem> =>
  items->filterByAxis(axisFilter)->filterBySearch(searchText)->filterCompleted(showCompleted)

/// Sort work items according to the active axis and tier orderings.
/// Items are grouped by axis (in axisOrder), then sorted within each
/// axis by their tier priority (in the corresponding tier ordering).
let sortByDirective = (
  items: array<tsdmWorkItem>,
  axisOrder: array<axisId>,
  scopeOrder: array<scopeTier>,
  maintenanceOrder: array<maintenanceTier>,
  auditOrder: array<auditTier>,
): array<tsdmWorkItem> => {
  /// Find the index of an axis in the axis ordering.
  let axisIndex = (axis: axisId): int =>
    axisOrder->Array.findIndex(a => a == axis)->Int.clamp(~min=0, ~max=2)

  /// Find the tier index within the relevant tier ordering.
  let tierIndex = (item: tsdmWorkItem): int =>
    switch item.axis {
    | AxisScope =>
      switch item.scopeTier {
      | Some(tier) => scopeOrder->Array.findIndex(t => t == tier)->Int.clamp(~min=0, ~max=2)
      | None => 99
      }
    | AxisMaintenance =>
      switch item.maintenanceTier {
      | Some(tier) => maintenanceOrder->Array.findIndex(t => t == tier)->Int.clamp(~min=0, ~max=2)
      | None => 99
      }
    | AxisAudit =>
      switch item.auditTier {
      | Some(tier) => auditOrder->Array.findIndex(t => t == tier)->Int.clamp(~min=0, ~max=2)
      | None => 99
      }
    }

  let sorted = Array.copy(items)
  sorted->Array.sort((a, b) => {
    let axisCmp = Int.compare(axisIndex(a.axis), axisIndex(b.axis))
    if axisCmp != 0.0 {
      axisCmp
    } else {
      Int.compare(tierIndex(a), tierIndex(b))
    }
  })
  sorted
}

// =========================================================================
// Aggregate statistics
// =========================================================================

/// Count work items by axis.
let countByAxis = (items: array<tsdmWorkItem>, axis: axisId): int =>
  items->Array.filter(item => item.axis == axis)->Array.length

/// Count completed work items.
let completedCount = (items: array<tsdmWorkItem>): int =>
  items->Array.filter(item => item.done)->Array.length

/// Completion percentage (0.0–100.0).
let completionPercentage = (items: array<tsdmWorkItem>): float => {
  let total = Array.length(items)
  if total == 0 {
    0.0
  } else {
    Float.fromInt(completedCount(items)) /. Float.fromInt(total) *. 100.0
  }
}

/// Count items from a specific source panel.
let countBySource = (items: array<tsdmWorkItem>, sourcePanel: string): int =>
  items->Array.filter(item => item.sourcePanel == sourcePanel)->Array.length

// =========================================================================
// Directive state helpers
// =========================================================================

/// Check whether the directive is in its default (canonical) ordering.
let isDefaultOrdering = (state: tsdmState): bool =>
  state.axisOrder == init.axisOrder &&
  state.scopeOrder == init.scopeOrder &&
  state.maintenanceOrder == init.maintenanceOrder &&
  state.auditOrder == init.auditOrder

/// All axes for iteration.
let allAxes: array<axisId> = [AxisScope, AxisMaintenance, AxisAudit]

/// All cleanup steps for iteration.
let allCleanupSteps: array<cleanupStep> = [
  RootCleanup,
  StaleWorkCull,
  DocsSyncHumanMachine,
  ComplianceAudit,
  EffectsAudit,
  ReleaseSummary,
  NextActions,
]

/// All dialogue topics for iteration.
let allDialogueTopics: array<dialogueTopic> = [WhatChanged, Why, RemainingRisks]
