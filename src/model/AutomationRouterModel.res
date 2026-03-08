// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Automation Router Model — types for cross-panel workflow
/// orchestration via event-driven rules. The "hybrid" aspect means
/// rules can fire automatically OR require human approval gates.

/// Trigger event kinds.
type triggerEvent =
  | FileChanged(string)
  | PanelMessage(string, string)
  | Timer(int)
  | Manual
  | PanelStateChange(string, string)

/// Condition for a rule to fire.
type ruleCondition = {
  panelId: string,
  field: string,
  operator: string,
  value: string,
}

/// Action to dispatch when a rule fires.
type ruleAction = {
  panelId: string,
  message: string,
  args: array<(string, string)>,
}

/// Approval requirement for hybrid automation.
type approvalMode =
  | AutoFire
  | RequireApproval
  | ApproveOnce
  | DryRunFirst

/// An automation rule definition.
type automationRule = {
  id: string,
  name: string,
  description: string,
  enabled: bool,
  trigger: triggerEvent,
  conditions: array<ruleCondition>,
  actions: array<ruleAction>,
  approval: approvalMode,
  priority: string,
  firedCount: int,
  lastFired: option<float>,
  lastResult: option<string>,
}

/// A pending action awaiting approval.
type pendingAction = {
  ruleId: string,
  ruleName: string,
  actions: array<ruleAction>,
  triggeredAt: float,
  triggerDetail: string,
}

/// An entry in the execution history.
type executionLogEntry = {
  ruleId: string,
  ruleName: string,
  triggeredAt: float,
  completedAt: float,
  success: bool,
  detail: string,
}

/// Category tabs for the Automation Router panel.
type automationRouterCategory =
  | RouterDashboard
  | RouterRules
  | RouterPending
  | RouterHistory
  | RouterSettings

/// Root state for the Automation Router panel.
type automationRouterState = {
  activeCategory: automationRouterCategory,
  rules: array<automationRule>,
  pendingActions: array<pendingAction>,
  executionLog: array<executionLogEntry>,
  globalEnabled: bool,
  filterText: string,
  showDisabled: bool,
  editingRuleId: option<string>,
  configSource: string,
  loading: bool,
  error: option<string>,
}
