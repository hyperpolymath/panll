// SPDX-License-Identifier: MPL-2.0

/// PanLL Automation Router Engine — pure helpers for workflow orchestration.

open AutomationRouterModel

/// Category tab labels.
let categoryLabel = (cat: automationRouterCategory): string =>
  switch cat {
  | RouterDashboard => "Dashboard"
  | RouterRules => "Rules"
  | RouterPending => "Pending"
  | RouterHistory => "History"
  | RouterSettings => "Settings"
  }

/// Trigger event label.
let triggerLabel = (trigger: triggerEvent): string =>
  switch trigger {
  | FileChanged(pattern) => `File: ${pattern}`
  | PanelMessage(panel, msg) => `${panel}.${msg}`
  | Timer(seconds) => `Every ${Int.toString(seconds)}s`
  | Manual => "Manual"
  | PanelStateChange(panel, field) => `${panel}.${field} changed`
  }

/// Trigger event kind label (short).
let triggerKindLabel = (trigger: triggerEvent): string =>
  switch trigger {
  | FileChanged(_) => "File"
  | PanelMessage(_, _) => "Message"
  | Timer(_) => "Timer"
  | Manual => "Manual"
  | PanelStateChange(_, _) => "State"
  }

/// Trigger kind colour class.
let triggerColour = (trigger: triggerEvent): string =>
  switch trigger {
  | FileChanged(_) => "text-cyan-400"
  | PanelMessage(_, _) => "text-purple-400"
  | Timer(_) => "text-amber-400"
  | Manual => "text-gray-400"
  | PanelStateChange(_, _) => "text-emerald-400"
  }

/// Approval mode label.
let approvalLabel = (mode: approvalMode): string =>
  switch mode {
  | AutoFire => "Auto"
  | RequireApproval => "Approval Required"
  | ApproveOnce => "Approve Once"
  | DryRunFirst => "Dry Run"
  }

/// Approval mode colour.
let approvalColour = (mode: approvalMode): string =>
  switch mode {
  | AutoFire => "text-emerald-400"
  | RequireApproval => "text-amber-400"
  | ApproveOnce => "text-cyan-400"
  | DryRunFirst => "text-purple-400"
  }

/// Count enabled rules.
let enabledCount = (rules: array<automationRule>): int =>
  rules->Array.filter(r => r.enabled)->Array.length

/// Count pending actions.
let pendingCount = (actions: array<pendingAction>): int => Array.length(actions)

/// Filter rules by text and enabled state.
let filterRules = (rules: array<automationRule>, text: string, showDisabled: bool): array<
  automationRule,
> => {
  let lower = String.toLowerCase(text)
  rules->Array.filter(r => {
    let matchesText =
      text === "" ||
      String.toLowerCase(r.name)->String.includes(lower) ||
      String.toLowerCase(r.description)->String.includes(lower)
    let matchesEnabled = showDisabled || r.enabled
    matchesText && matchesEnabled
  })
}

/// Success rate from execution log.
let successRate = (log: array<executionLogEntry>): float => {
  let total = Array.length(log)
  if total === 0 {
    100.0
  } else {
    let successes = log->Array.filter(e => e.success)->Array.length
    Float.fromInt(successes) /. Float.fromInt(total) *. 100.0
  }
}

/// Format a timestamp as a relative time string.
let formatRelativeTime = (timestamp: float): string => {
  let now = Date.now()
  let diffMs = now -. timestamp
  let diffSecs = diffMs /. 1000.0
  if diffSecs < 60.0 {
    "just now"
  } else if diffSecs < 3600.0 {
    let mins = Float.toInt(diffSecs /. 60.0)
    `${Int.toString(mins)}m ago`
  } else if diffSecs < 86400.0 {
    let hours = Float.toInt(diffSecs /. 3600.0)
    `${Int.toString(hours)}h ago`
  } else {
    let days = Float.toInt(diffSecs /. 86400.0)
    `${Int.toString(days)}d ago`
  }
}

/// Format success rate as a percentage string.
let formatSuccessRate = (rate: float): string => {
  let rounded = Float.toInt(rate)
  `${Int.toString(rounded)}%`
}

/// Priority label.
let priorityLabel = (priority: string): string =>
  switch priority {
  | "before" => "Before"
  | "after" => "After"
  | "parallel" => "Parallel"
  | _ => priority
  }

/// Default state.
let defaultState: automationRouterState = {
  activeCategory: RouterDashboard,
  rules: [],
  pendingActions: [],
  executionLog: [],
  globalEnabled: true,
  filterText: "",
  showDisabled: true,
  editingRuleId: None,
  configSource: "local",
  loading: false,
  error: None,
  bojRouting: false,
}
