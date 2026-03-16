// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Agent Safety Engine — pure helpers for the safety gate panel.
///
/// All functions are pure (no side effects). Provides tool call classification,
/// safety check logic, colour mappings, and filtering.

open AgentSafetyModel

// ============================================================================
// Tool Call Classification
// ============================================================================

/// Whether a tool call type has side effects (modifies external state).
let hasSideEffects = (tc: toolCall): bool => {
  switch tc {
  | FileRead => false
  | FileWrite => true
  | NetworkRequest => true
  | ShellExec => true
  | DatabaseOp => true
  | ExternalApi => true
  }
}

/// Whether a tool call type requires a safety check before execution.
let requiresSafetyCheck = (tc: toolCall): bool => {
  hasSideEffects(tc)
}

/// Whether a safety check outcome allows execution to proceed.
let allowsExecution = (check: safetyCheck): bool => {
  switch check {
  | AutoApproved => true
  | HumanApproved => true
  | PendingReview => false
  | HumanDenied => false
  | Escalated => false
  | PolicyBlocked => false
  }
}

/// Whether a safety check outcome needs human intervention.
let needsHuman = (check: safetyCheck): bool => {
  switch check {
  | PendingReview => true
  | Escalated => true
  | AutoApproved => false
  | HumanApproved => false
  | HumanDenied => false
  | PolicyBlocked => false
  }
}

// ============================================================================
// Colour Mappings
// ============================================================================

/// Tailwind background colour class for a safety event based on its outcome.
let eventColor = (outcome: safetyCheck): string => {
  switch outcome {
  | AutoApproved => "bg-emerald-900/20 border-emerald-500/40"
  | HumanApproved => "bg-emerald-900/20 border-emerald-500/40"
  | PendingReview => "bg-amber-900/20 border-amber-500/40"
  | HumanDenied => "bg-red-900/20 border-red-500/40"
  | Escalated => "bg-orange-900/20 border-orange-500/40"
  | PolicyBlocked => "bg-red-900/20 border-red-500/40"
  }
}

/// Tailwind text colour class for a safety check outcome.
let outcomeTextColor = (outcome: safetyCheck): string => {
  switch outcome {
  | AutoApproved => "text-emerald-400"
  | HumanApproved => "text-emerald-400"
  | PendingReview => "text-amber-400"
  | HumanDenied => "text-red-400"
  | Escalated => "text-orange-400"
  | PolicyBlocked => "text-red-400"
  }
}

// ============================================================================
// Filtering
// ============================================================================

/// Filter events to only those pending human review.
let filterPending = (events: array<safetyEvent>): array<safetyEvent> => {
  events->Array.filter(e => e.outcome == PendingReview)
}

/// Filter events by agent identifier.
let filterByAgent = (
  events: array<safetyEvent>,
  agentId: string,
): array<safetyEvent> => {
  events->Array.filter(e => e.agentId == agentId)
}

// ============================================================================
// Display Labels
// ============================================================================

/// Human-readable label for a tool call type.
let toolCallLabel = (tc: toolCall): string => {
  switch tc {
  | FileRead => "File Read"
  | FileWrite => "File Write"
  | NetworkRequest => "Network Request"
  | ShellExec => "Shell Exec"
  | DatabaseOp => "Database Op"
  | ExternalApi => "External API"
  }
}

/// Human-readable label for a safety check outcome.
let outcomeLabel = (check: safetyCheck): string => {
  switch check {
  | AutoApproved => "Auto-Approved"
  | PendingReview => "Pending Review"
  | HumanApproved => "Approved"
  | HumanDenied => "Denied"
  | Escalated => "Escalated"
  | PolicyBlocked => "Policy Blocked"
  }
}

// ============================================================================
// Statistics Computation
// ============================================================================

/// Compute aggregate safety statistics from pending and history arrays.
let computeStats = (
  pending: array<safetyEvent>,
  history: array<safetyEvent>,
): safetyStats => {
  let all = Array.concat(pending, history)
  let totalEvents = Array.length(all)
  let autoApproved = all->Array.filter(e => e.outcome == AutoApproved)->Array.length
  let humanApproved = all->Array.filter(e => e.outcome == HumanApproved)->Array.length
  let denied = all->Array.filter(e => e.outcome == HumanDenied)->Array.length
  let escalated = all->Array.filter(e => e.outcome == Escalated)->Array.length
  let policyBlocked = all->Array.filter(e => e.outcome == PolicyBlocked)->Array.length
  let pendingCount = Array.length(pending)
  {totalEvents, autoApproved, humanApproved, denied, escalated, policyBlocked, pendingCount}
}

// ============================================================================
// Initial State
// ============================================================================

/// Default initial state for the Agent Safety Gate.
let init: agentSafetyState = {
  pendingEvents: [],
  historyEvents: [],
  stats: {
    totalEvents: 0,
    autoApproved: 0,
    humanApproved: 0,
    denied: 0,
    escalated: 0,
    policyBlocked: 0,
    pendingCount: 0,
  },
  loading: false,
}
