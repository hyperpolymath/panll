// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL LLM Coding Panel Model — types for multi-LLM session coordination,
/// resource monitoring, workspace locking, and task orchestration.
///
/// This panel is the headed supervisor for parallel Claude/LLM coding sessions.
/// It sits OUTSIDE the LLM processes so it can enforce resource limits, gate
/// destructive actions, and prevent conflicts without the LLM being able to
/// override those controls.
///
/// Designed to work with both Gossamer backends.
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// LLM Provider
// ============================================================================

/// Supported LLM providers for coding sessions.
type llmProvider =
  /// Claude Code (Anthropic CLI).
  | Claude
  /// Other LLM via CLI (e.g. aider, continue, cursor).
  | OtherLlm(string)

// ============================================================================
// Session State
// ============================================================================

/// Lifecycle state of a spawned LLM coding session.
type sessionState =
  /// Starting — process spawned, waiting for readiness signal.
  | Starting
  /// Active — session is running and accepting input.
  | Active
  /// Frozen — SIGSTOP sent by resource guardian or user.
  | Frozen
  /// Completed — session finished its task list.
  | Completed
  /// Failed — session crashed or errored.
  | Failed(string)
  /// Killed — terminated by supervisor (resource limit or user).
  | Killed

// ============================================================================
// Resource Usage
// ============================================================================

/// Snapshot of a session's resource consumption.
type resourceUsage = {
  /// Resident memory in megabytes.
  memoryMb: int,
  /// CPU usage percentage (0-100).
  cpuPercent: float,
  /// Number of subagent processes spawned by this session.
  subagentCount: int,
  /// Cumulative tokens consumed (if trackable).
  tokensUsed: option<int>,
}

/// Resource limits for a session.
type resourceLimits = {
  /// Maximum RSS in megabytes before freeze.
  maxMemoryMb: int,
  /// Maximum CPU percentage before throttle warning.
  maxCpuPercent: float,
  /// Maximum concurrent subagents.
  maxSubagents: int,
}

// ============================================================================
// Workspace Locks
// ============================================================================

/// A lock on a workspace resource (repo, file, or directory).
type workspaceLock = {
  /// Path being locked (repo root or specific file/dir).
  path: string,
  /// Session ID that holds the lock.
  heldBy: string,
  /// When the lock was acquired (ISO 8601).
  acquiredAt: string,
  /// Whether this is exclusive (write) or shared (read).
  exclusive: bool,
}

// ============================================================================
// Permission Gate
// ============================================================================

/// Categories of actions that require gating.
type actionCategory =
  /// Git push to any remote.
  | GitPush
  /// Git force push.
  | GitForcePush
  /// Delete files or directories.
  | FileDelete
  /// Modify CI/CD workflows.
  | CiCdChange
  /// Create or close PRs/issues.
  | GitHubAction
  /// Any other destructive action.
  | OtherDestructive(string)

/// Destructive action requiring supervisor approval.
type pendingAction = {
  /// Unique action ID.
  id: string,
  /// Session requesting the action.
  sessionId: string,
  /// Human-readable description of the action.
  description: string,
  /// Category of action.
  category: actionCategory,
  /// When the request was made.
  requestedAt: string,
}

// ============================================================================
// Task Coordination
// ============================================================================

/// Task completion state.
type taskStatus =
  /// Pending — not yet started.
  | Pending
  /// InProgress — being worked on.
  | InProgress
  /// Done — completed successfully.
  | Done
  /// Skipped — skipped (completed by another session or irrelevant).
  | Skipped
  /// Blocked — waiting on another task or resource.
  | Blocked(string)

/// A task in the shared task list.
type sharedTask = {
  /// Unique task ID.
  id: string,
  /// Task description.
  description: string,
  /// Current status.
  status: taskStatus,
  /// Session assigned to this task (if any).
  assignedTo: option<string>,
  /// When the task was completed (if done).
  completedAt: option<string>,
}

// ============================================================================
// Cross-Session Messages
// ============================================================================

/// A message from one session to others.
type sessionMessage = {
  /// Source session ID.
  fromSession: string,
  /// Message content.
  content: string,
  /// When the message was sent.
  sentAt: string,
  /// Whether this message has been acknowledged by the panel.
  acknowledged: bool,
}

// ============================================================================
// Session Definition
// ============================================================================

/// A single LLM coding session managed by this panel.
type llmSession = {
  /// Unique session ID (UUID).
  id: string,
  /// Human-readable name (e.g. "V-lang connectors").
  name: string,
  /// LLM provider running this session.
  provider: llmProvider,
  /// Current lifecycle state.
  state: sessionState,
  /// OS process ID of the terminal/LLM process.
  pid: option<int>,
  /// Working directory for this session.
  workDir: string,
  /// Repos this session is allowed to touch.
  allowedRepos: array<string>,
  /// Current resource consumption.
  resources: resourceUsage,
  /// Resource limits enforced on this session.
  limits: resourceLimits,
  /// Task list assigned to this session.
  tasks: array<sharedTask>,
  /// When this session was spawned.
  startedAt: string,
}

// ============================================================================
// Panel State
// ============================================================================

/// Top-level state for the LLM Coding panel.
type llmCodingState = {
  /// All managed sessions.
  sessions: array<llmSession>,
  /// Active workspace locks across all sessions.
  locks: array<workspaceLock>,
  /// Pending actions requiring supervisor approval.
  pendingActions: array<pendingAction>,
  /// Cross-session message log.
  messages: array<sessionMessage>,
  /// System-wide resource snapshot (from resource-guardian).
  systemMemoryAvailableMb: int,
  systemMemoryTotalMb: int,
  systemCpuPercent: float,
  /// Whether the coordination daemon is connected.
  daemonConnected: bool,
  /// Currently selected session (for detail view).
  selectedSession: option<string>,
  /// Whether we are in "spawn new session" mode.
  showSpawnDialog: bool,
  /// New session form fields.
  newSessionName: string,
  newSessionWorkDir: string,
  newSessionTaskList: string,
  /// Whether data is loading.
  loading: bool,
  /// Last error message.
  lastError: option<string>,
}
