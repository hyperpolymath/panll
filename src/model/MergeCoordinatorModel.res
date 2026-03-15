// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Merge Coordinator Model — branch management, conflict resolution, and merge queue.
/// Directive clade. This module has NO dependencies on other PanLL modules.

/// Branch lifecycle status.
type branchStatus =
  | BrActive
  | BrMerging
  | BrConflicted
  | BrMerged
  | BrStale

/// A tracked branch under merge coordination.
type managedBranch = {
  name: string,
  baseBranch: string,
  author: string,
  status: branchStatus,
  lastCommitAt: string,
  aheadBy: int,
  behindBy: int,
}

/// A merge conflict in a specific file.
type mergeConflict = {
  filePath: string,
  ours: string,
  theirs: string,
  resolved: bool,
}

/// Active tab within the Merge Coordinator panel.
type mergeCoordinatorTab =
  | TabBranches
  | TabConflicts
  | TabMergeQueue
  | TabHistory

/// Merge Coordinator panel state.
type mergeCoordinatorState = {
  activeTab: mergeCoordinatorTab,
  branches: array<managedBranch>,
  conflicts: array<mergeConflict>,
  mergeQueue: array<string>,
  selectedBranch: option<string>,
  error: option<string>,
}
