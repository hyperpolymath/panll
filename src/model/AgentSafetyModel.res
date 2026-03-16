// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Agent Safety Gate Model — types for tool call safety review
/// and approval queuing.
///
/// Tracks agent tool calls against safety policies, queues dangerous
/// operations for human approval, and maintains approval/denial history
/// with aggregate statistics.
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Tool Call Classification
// ============================================================================

/// Category of tool call an agent is attempting.
type toolCall =
  /// Read-only file system access.
  | FileRead
  /// File system write or modification.
  | FileWrite
  /// Network request (HTTP, WebSocket, etc.).
  | NetworkRequest
  /// Shell command execution.
  | ShellExec
  /// Database query or mutation.
  | DatabaseOp
  /// External API invocation (third-party service).
  | ExternalApi

/// Outcome of a safety check on a tool call.
type safetyCheck =
  /// Automatically approved — tool call is safe.
  | AutoApproved
  /// Queued for human review — tool call has potential side effects.
  | PendingReview
  /// Approved by human reviewer.
  | HumanApproved
  /// Denied by human reviewer.
  | HumanDenied
  /// Escalated to a higher authority (e.g., admin).
  | Escalated
  /// Blocked by policy — tool call is explicitly forbidden.
  | PolicyBlocked

// ============================================================================
// Safety Events
// ============================================================================

/// A single safety event representing a tool call and its outcome.
type safetyEvent = {
  /// Unique event identifier.
  id: string,
  /// ISO 8601 timestamp of the event.
  timestamp: string,
  /// The type of tool call attempted.
  toolCall: toolCall,
  /// The safety check outcome.
  outcome: safetyCheck,
  /// Identifier of the agent that made the tool call.
  agentId: string,
  /// OODA session identifier, if applicable.
  sessionId: string,
  /// Human-readable description of the tool call.
  description: string,
  /// The specific resource being accessed (file path, URL, command, etc.).
  resource: string,
}

// ============================================================================
// Statistics
// ============================================================================

/// Aggregate safety statistics.
type safetyStats = {
  /// Total events processed.
  totalEvents: int,
  /// Auto-approved events count.
  autoApproved: int,
  /// Human-approved events count.
  humanApproved: int,
  /// Denied events count.
  denied: int,
  /// Escalated events count.
  escalated: int,
  /// Policy-blocked events count.
  policyBlocked: int,
  /// Currently pending review count.
  pendingCount: int,
}

// ============================================================================
// Panel State
// ============================================================================

/// Top-level state for the Agent Safety Gate panel.
type agentSafetyState = {
  /// Events pending human review (approve/deny queue).
  pendingEvents: array<safetyEvent>,
  /// Historical safety events (newest first).
  historyEvents: array<safetyEvent>,
  /// Aggregate safety statistics.
  stats: safetyStats,
  /// Whether a refresh is in progress.
  loading: bool,
}
