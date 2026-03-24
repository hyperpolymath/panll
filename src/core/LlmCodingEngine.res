// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL LLM Coding Engine — pure helpers for the multi-LLM coding supervisor.
///
/// All functions are pure (no side effects). Provides session state colours,
/// resource threshold checks, lock conflict detection, task list management,
/// and permission gate classification.

open LlmCodingModel

// ============================================================================
// Session State Helpers
// ============================================================================

/// Tailwind text colour for a session state.
let stateColor = (state: sessionState): string => {
  switch state {
  | Starting => "text-blue-400"
  | Active => "text-emerald-400"
  | Frozen => "text-amber-400"
  | Completed => "text-gray-400"
  | Failed(_) => "text-red-500"
  | Killed => "text-red-400"
  }
}

/// Tailwind border colour for a session card.
let stateBorderColor = (state: sessionState): string => {
  switch state {
  | Starting => "border-blue-500/40"
  | Active => "border-emerald-500/40"
  | Frozen => "border-amber-500/40"
  | Completed => "border-gray-500/40"
  | Failed(_) => "border-red-500/40"
  | Killed => "border-red-500/40"
  }
}

/// Human-readable label for a session state.
let stateLabel = (state: sessionState): string => {
  switch state {
  | Starting => "Starting"
  | Active => "Active"
  | Frozen => "FROZEN"
  | Completed => "Completed"
  | Failed(reason) => `Failed: ${reason}`
  | Killed => "Killed"
  }
}

/// Whether a session is still alive (accepting work).
let isAlive = (state: sessionState): bool => {
  switch state {
  | Starting | Active | Frozen => true
  | Completed | Failed(_) | Killed => false
  }
}

/// Whether a session can be frozen.
let canFreeze = (state: sessionState): bool => {
  switch state {
  | Active => true
  | _ => false
  }
}

/// Whether a session can be thawed.
let canThaw = (state: sessionState): bool => {
  switch state {
  | Frozen => true
  | _ => false
  }
}

// ============================================================================
// Provider Helpers
// ============================================================================

/// Display name for an LLM provider.
let providerName = (provider: llmProvider): string => {
  switch provider {
  | Claude => "Claude Code"
  | OtherLlm(name) => name
  }
}

/// Icon hint for an LLM provider.
let providerIcon = (provider: llmProvider): string => {
  switch provider {
  | Claude => "terminal"
  | OtherLlm(_) => "cpu"
  }
}

// ============================================================================
// Resource Monitoring
// ============================================================================

/// Resource health level for a session.
type resourceHealth =
  | Healthy
  | Warning
  | Critical

/// Assess a session's resource health against its limits.
let resourceHealth = (usage: resourceUsage, limits: resourceLimits): resourceHealth => {
  if usage.memoryMb > limits.maxMemoryMb {
    Critical
  } else if usage.memoryMb > limits.maxMemoryMb * 3 / 4 {
    Warning
  } else if usage.cpuPercent > limits.maxCpuPercent {
    Warning
  } else if usage.subagentCount > limits.maxSubagents {
    Warning
  } else {
    Healthy
  }
}

/// Tailwind colour for resource health.
let resourceHealthColor = (health: resourceHealth): string => {
  switch health {
  | Healthy => "text-emerald-400"
  | Warning => "text-amber-400"
  | Critical => "text-red-500"
  }
}

/// Resource health as a short label.
let resourceHealthLabel = (health: resourceHealth): string => {
  switch health {
  | Healthy => "OK"
  | Warning => "WARN"
  | Critical => "CRITICAL"
  }
}

/// System-wide memory health.
let systemMemoryHealth = (availableMb: int, totalMb: int): resourceHealth => {
  if totalMb <= 0 {
    Healthy
  } else {
    let pct = availableMb * 100 / totalMb
    if pct < 10 {
      Critical
    } else if pct < 25 {
      Warning
    } else {
      Healthy
    }
  }
}

// ============================================================================
// Lock Management
// ============================================================================

/// Check whether a new lock would conflict with existing locks.
let lockConflicts = (
  newPath: string,
  newExclusive: bool,
  existingLocks: array<workspaceLock>,
): array<workspaceLock> => {
  existingLocks->Array.filter(lock => {
    // Conflict if paths overlap and either lock is exclusive
    let pathOverlap =
      lock.path == newPath ||
      newPath->String.startsWith(lock.path) ||
      lock.path->String.startsWith(newPath)
    pathOverlap && (lock.exclusive || newExclusive)
  })
}

/// Check if a session holds a lock on the given path.
let sessionHoldsLock = (
  sessionId: string,
  path: string,
  locks: array<workspaceLock>,
): bool => {
  locks->Array.some(lock => lock.heldBy == sessionId && lock.path == path)
}

// ============================================================================
// Task Coordination
// ============================================================================

/// Count completed tasks in a task list.
let completedCount = (tasks: array<sharedTask>): int => {
  tasks->Array.filter(t => t.status == Done)->Array.length
}

/// Count remaining (non-completed) tasks.
let remainingCount = (tasks: array<sharedTask>): int => {
  tasks->Array.filter(t => {
    switch t.status {
    | Pending | InProgress | Blocked(_) => true
    | Done | Skipped => false
    }
  })->Array.length
}

/// Progress percentage (0-100).
let progressPercent = (tasks: array<sharedTask>): int => {
  let total = Array.length(tasks)
  if total == 0 {
    0
  } else {
    completedCount(tasks) * 100 / total
  }
}

/// Next available task for a session (first pending unassigned task).
let nextAvailableTask = (tasks: array<sharedTask>): option<sharedTask> => {
  tasks->Array.find(t => t.status == Pending && t.assignedTo == None)
}

// ============================================================================
// Permission Gating
// ============================================================================

/// Danger level of an action category.
type dangerLevel =
  | Low
  | Medium
  | High
  | Critical

/// Classify the danger level of an action.
let actionDanger = (category: actionCategory): dangerLevel => {
  switch category {
  | GitPush => Medium
  | GitForcePush => Critical
  | FileDelete => High
  | CiCdChange => High
  | GitHubAction => Medium
  | OtherDestructive(_) => High
  }
}

/// Tailwind colour for a danger level.
let dangerColor = (level: dangerLevel): string => {
  switch level {
  | Low => "text-gray-400"
  | Medium => "text-amber-400"
  | High => "text-orange-500"
  | Critical => "text-red-500"
  }
}

/// Action category display name.
let actionCategoryName = (category: actionCategory): string => {
  switch category {
  | GitPush => "git push"
  | GitForcePush => "git push --force"
  | FileDelete => "file delete"
  | CiCdChange => "CI/CD change"
  | GitHubAction => "GitHub action"
  | OtherDestructive(desc) => desc
  }
}

// ============================================================================
// Initial State
// ============================================================================

/// Default resource limits for new sessions.
let defaultLimits: resourceLimits = {
  maxMemoryMb: 4096,
  maxCpuPercent: 80.0,
  maxSubagents: 3,
}

/// Default initial state for the LLM Coding panel.
let init: llmCodingState = {
  sessions: [],
  locks: [],
  pendingActions: [],
  messages: [],
  systemMemoryAvailableMb: 0,
  systemMemoryTotalMb: 0,
  systemCpuPercent: 0.0,
  daemonConnected: false,
  selectedSession: None,
  showSpawnDialog: false,
  newSessionName: "",
  newSessionWorkDir: "",
  newSessionTaskList: "",
  loading: false,
  lastError: None,
}
