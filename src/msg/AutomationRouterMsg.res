// SPDX-License-Identifier: MPL-2.0

/// Automation Router messages -- rule management, execution, approval gates,
/// history, and configuration for the hybrid cross-panel workflow orchestrator.

open Model

type automationRouterMsg =
  /// Switch the active category tab.
  | SetRouterCategory(automationRouterCategory)
  /// Toggle global automation on/off.
  | ToggleGlobalEnabled
  /// Toggle a specific rule on/off.
  | ToggleRule(string)
  /// Execute a rule manually.
  | ExecuteRule(string)
  /// Rule execution result.
  | ExecutionResult(string, result<string, string>)
  /// Approve a pending action by index.
  | ApproveAction(int)
  /// Reject a pending action by index.
  | RejectAction(int)
  /// Approve all pending actions.
  | ApproveAll
  /// Reject all pending actions.
  | RejectAll
  /// Load rules from storage or repo.
  | LoadRules
  /// Rules loaded.
  | RulesLoaded(result<string, string>)
  /// Save rules to local storage.
  | SaveRules
  /// Rules saved.
  | RulesSaved(result<string, string>)
  /// Load rules from repo's .machine_readable/ENSAID_CONFIG.a2ml.
  | LoadFromRepo
  /// Repo rules loaded.
  | RepoRulesLoaded(result<string, string>)
  /// Set filter text.
  | SetRouterFilter(string)
  /// Toggle show disabled rules.
  | ToggleShowDisabled
  /// Dismiss the error banner.
  | DismissRouterError
  /// Export automation rules to ENSAID_CONFIG.a2ml.
  | ExportAutomationConfig
  /// Toggle BoJ routing for automation operations (agent-mcp cartridge).
  | ToggleAutomationBojRouting
  /// TypeLL cross-panel type check result for rule types.
  | TypeCheckResult(result<string, string>)
