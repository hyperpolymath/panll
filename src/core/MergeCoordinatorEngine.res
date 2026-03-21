// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Merge Coordinator Engine — pure computation and helpers for the
/// Merge Coordinator panel. Provides default state, branch counting,
/// conflict analysis, queue management, and status formatting.

open MergeCoordinatorModel

/// Default initial state for the Merge Coordinator panel.
/// Starts on the Branches tab with empty lists.
let defaultState: mergeCoordinatorState = {
  activeTab: TabBranches,
  branches: [],
  conflicts: [],
  mergeQueue: [],
  selectedBranch: None,
  error: None,
}

/// Human-readable label for each tab in the Merge Coordinator panel.
let tabLabel = (tab: mergeCoordinatorTab): string =>
  switch tab {
  | TabBranches => "Branches"
  | TabConflicts => "Conflicts"
  | TabMergeQueue => "Merge Queue"
  | TabHistory => "History"
  }

/// All tabs in display order.
let allTabs: array<mergeCoordinatorTab> = [TabBranches, TabConflicts, TabMergeQueue, TabHistory]

/// Human-readable label for a branch status.
let statusLabel = (status: branchStatus): string =>
  switch status {
  | BrActive => "Active"
  | BrMerging => "Merging"
  | BrConflicted => "Conflicted"
  | BrMerged => "Merged"
  | BrStale => "Stale"
  }

/// CSS colour class for a branch status.
let statusColor = (status: branchStatus): string =>
  switch status {
  | BrActive => "text-green-400"
  | BrMerging => "text-yellow-400"
  | BrConflicted => "text-red-400"
  | BrMerged => "text-purple-400"
  | BrStale => "text-gray-500"
  }

/// Count unresolved merge conflicts.
let countConflicts = (conflicts: array<mergeConflict>): int =>
  conflicts->Array.filter(c => !c.resolved)->Array.length

/// Count resolved conflicts.
let countResolvedConflicts = (conflicts: array<mergeConflict>): int =>
  conflicts->Array.filter(c => c.resolved)->Array.length

/// Count stale branches (no recent activity, not merged).
let countStale = (branches: array<managedBranch>): int =>
  branches->Array.filter(b => b.status === BrStale)->Array.length

/// Count active branches.
let countActive = (branches: array<managedBranch>): int =>
  branches->Array.filter(b => b.status === BrActive)->Array.length

/// Count conflicted branches.
let countConflicted = (branches: array<managedBranch>): int =>
  branches->Array.filter(b => b.status === BrConflicted)->Array.length

/// Number of entries in the merge queue.
let queueLength = (queue: array<mergeQueueEntry>): int =>
  Array.length(queue)

/// Count queue entries where all checks have passed.
let readyToMerge = (queue: array<mergeQueueEntry>): int =>
  queue->Array.filter(e => e.checksPassed)->Array.length

/// Count queue entries still waiting for checks.
let pendingChecks = (queue: array<mergeQueueEntry>): int =>
  queue->Array.filter(e => !e.checksPassed)->Array.length

/// Whether a branch is diverged (both ahead and behind its base).
let isDiverged = (branch: managedBranch): bool =>
  branch.aheadBy > 0 && branch.behindBy > 0

/// Find branches that need rebasing (behind base by more than N commits).
let needsRebase = (branches: array<managedBranch>, threshold: int): array<managedBranch> =>
  branches->Array.filter(b => b.behindBy > threshold && b.status === BrActive)

/// Conflict resolution progress as a percentage.
let conflictResolutionProgress = (conflicts: array<mergeConflict>): float => {
  let total = Array.length(conflicts)
  if total == 0 {
    100.0
  } else {
    Float.fromInt(countResolvedConflicts(conflicts)) /. Float.fromInt(total) *. 100.0
  }
}
