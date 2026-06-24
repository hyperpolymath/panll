// SPDX-License-Identifier: MPL-2.0

/// PanLL Merge Coordinator Model — branch management, conflict resolution,
/// and merge queue for coordinated IDApTIK development workflows.
///
/// Tracks branch lifecycle, detects merge conflicts, manages a merge queue
/// with pre-merge checks, and provides conflict resolution assistance.
///
/// Clade: Directive. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Branch Lifecycle
// ============================================================================

/// Lifecycle status of a tracked branch.
type branchStatus =
  /// Active — branch has recent commits, not yet merged.
  | BrActive
  /// Merging — merge is in progress.
  | BrMerging
  /// Conflicted — merge attempt discovered conflicts.
  | BrConflicted
  /// Merged — branch has been merged into its target.
  | BrMerged
  /// Stale — branch has no recent activity, may need cleanup.
  | BrStale

// ============================================================================
// Branch Management
// ============================================================================

/// A tracked branch under merge coordination.
type managedBranch = {
  /// Branch name (e.g., "feature/level-7-puzzles").
  name: string,
  /// Target branch for merging (e.g., "main").
  baseBranch: string,
  /// Branch author username.
  author: string,
  /// Current lifecycle status.
  status: branchStatus,
  /// ISO 8601 timestamp of the most recent commit on this branch.
  lastCommitAt: string,
  /// Number of commits ahead of the base branch.
  aheadBy: int,
  /// Number of commits behind the base branch.
  behindBy: int,
}

// ============================================================================
// Conflict Resolution
// ============================================================================

/// A merge conflict in a specific file.
type mergeConflict = {
  /// File path with the conflict.
  filePath: string,
  /// Our side of the conflict (content from the current branch).
  ours: string,
  /// Their side of the conflict (content from the incoming branch).
  theirs: string,
  /// Whether this conflict has been resolved.
  resolved: bool,
}

/// A merge queue entry with pre-merge check status.
type mergeQueueEntry = {
  /// Branch name queued for merging.
  branchName: string,
  /// Position in the merge queue (1-based).
  position: int,
  /// Whether all pre-merge checks have passed.
  checksPassed: bool,
  /// Names of checks that have not yet passed.
  pendingChecks: array<string>,
  /// ISO 8601 timestamp when the branch entered the queue.
  enqueuedAt: string,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Merge Coordinator panel.
type mergeCoordinatorTab =
  /// Branches — list of tracked branches with status badges.
  | TabBranches
  /// Conflicts — active merge conflicts with resolution tools.
  | TabConflicts
  /// Merge Queue — ordered queue of branches awaiting merge.
  | TabMergeQueue
  /// History — past merge events with success/failure timeline.
  | TabHistory

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Merge Coordinator panel.
type mergeCoordinatorState = {
  /// Active tab within the panel.
  activeTab: mergeCoordinatorTab,
  /// All tracked branches.
  branches: array<managedBranch>,
  /// Active merge conflicts.
  conflicts: array<mergeConflict>,
  /// Merge queue entries.
  mergeQueue: array<mergeQueueEntry>,
  /// Currently selected branch name for detail view.
  selectedBranch: option<string>,
  /// Error from the last operation.
  error: option<string>,
}
