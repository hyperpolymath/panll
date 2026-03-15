// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Merge Coordinator Engine — pure functions for branch and merge management.

open MergeCoordinatorModel

/// Default initial state for the Merge Coordinator panel.
let defaultState: mergeCoordinatorState = {
  activeTab: TabBranches,
  branches: [],
  conflicts: [],
  mergeQueue: [],
  selectedBranch: None,
  error: None,
}

/// Human-readable label for each tab.
let tabLabel = (tab: mergeCoordinatorTab): string =>
  switch tab {
  | TabBranches => "Branches"
  | TabConflicts => "Conflicts"
  | TabMergeQueue => "Merge Queue"
  | TabHistory => "History"
  }

/// All tabs in display order.
let allTabs: array<mergeCoordinatorTab> = [TabBranches, TabConflicts, TabMergeQueue, TabHistory]

/// Count unresolved merge conflicts.
let countConflicts = (conflicts: array<mergeConflict>): int =>
  conflicts->Array.filter(c => !c.resolved)->Array.length

/// Count stale branches (no recent activity, not merged).
let countStale = (branches: array<managedBranch>): int =>
  branches->Array.filter(b => b.status === BrStale)->Array.length

/// Number of branches waiting in the merge queue.
let queueLength = (queue: array<string>): int =>
  Array.length(queue)
