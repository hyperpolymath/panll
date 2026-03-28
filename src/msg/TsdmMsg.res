// SPDX-License-Identifier: PMPL-1.0-or-later

/// TSDM directive panel messages -- axis reordering, tier customisation,
/// cleanup configuration, work item aggregation, and directive persistence.

type tsdmMsg =
  /// Move an axis up in execution order.
  | MoveAxisUp(int)
  /// Move an axis down in execution order.
  | MoveAxisDown(int)
  /// Move a scope tier up in priority.
  | MoveScopeTierUp(int)
  /// Move a scope tier down in priority.
  | MoveScopeTierDown(int)
  /// Move a maintenance tier up in priority.
  | MoveMaintenanceTierUp(int)
  /// Move a maintenance tier down in priority.
  | MoveMaintenanceTierDown(int)
  /// Move an audit tier up in priority.
  | MoveAuditTierUp(int)
  /// Move an audit tier down in priority.
  | MoveAuditTierDown(int)
  /// Toggle a cleanup step on/off.
  | ToggleCleanupStep(TsdmModel.cleanupStep)
  /// Set axis filter for work items view.
  | SetAxisFilter(option<TsdmModel.axisId>)
  /// Set search text.
  | SetTsdmSearch(string)
  /// Toggle show completed items.
  | ToggleShowCompleted
  /// Lock/unlock the directive.
  | ToggleLock
  /// Reset all orderings to defaults.
  | ResetToDefaults
  /// Save directive to persistent storage.
  | SaveDirective
  /// Directive saved result.
  | DirectiveSaved(result<string, string>)
  /// Load directive from persistent storage.
  | LoadDirective
  /// Directive loaded result.
  | DirectiveLoaded(result<string, string>)
  /// Collect work items from consumer panels.
  | CollectWorkItems
  /// Work items collected result.
  | WorkItemsCollected(result<string, string>)
  /// Dismiss error.
  | DismissTsdmError
  /// TypeLL cross-panel type check result for directive types.
  | TypeCheckResult(result<string, string>)
