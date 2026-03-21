// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Code Review Engine — pure computation and helpers for the
/// Code Review panel. Provides default state, PR counting, comment
/// filtering, status labelling, and file diff analysis.

open CodeReviewModel

/// Default initial state for the Code Review panel.
/// Starts on the Pull Requests tab with empty lists.
let defaultState: codeReviewState = {
  activeTab: TabPullRequests,
  pullRequests: [],
  comments: [],
  fileDiffs: [],
  selectedPr: None,
  filter: "",
  error: None,
}

/// Human-readable label for each tab in the Code Review panel.
let tabLabel = (tab: codeReviewTab): string =>
  switch tab {
  | TabPullRequests => "Pull Requests"
  | TabFileChanges => "File Changes"
  | TabComments => "Comments"
  | TabApprovalGate => "Approval Gate"
  }

/// All tabs in display order.
let allTabs: array<codeReviewTab> = [TabPullRequests, TabFileChanges, TabComments, TabApprovalGate]

/// Human-readable label for a PR status.
let statusLabel = (status: prStatus): string =>
  switch status {
  | PrOpen => "Open"
  | PrApproved => "Approved"
  | PrChangesRequested => "Changes Requested"
  | PrMerged => "Merged"
  | PrClosed => "Closed"
  }

/// CSS colour class for a PR status.
let statusColor = (status: prStatus): string =>
  switch status {
  | PrOpen => "text-green-400"
  | PrApproved => "text-blue-400"
  | PrChangesRequested => "text-yellow-400"
  | PrMerged => "text-purple-400"
  | PrClosed => "text-gray-500"
  }

/// Count pull requests by status.
let countByStatus = (prs: array<pullRequest>, status: prStatus): int =>
  prs->Array.filter(pr => pr.status === status)->Array.length

/// Count unresolved review comments.
let countUnresolved = (comments: array<reviewComment>): int =>
  comments->Array.filter(c => !c.resolved)->Array.length

/// Count resolved review comments.
let countResolved = (comments: array<reviewComment>): int =>
  comments->Array.filter(c => c.resolved)->Array.length

/// Filter pull requests by title or author matching a search string (case-insensitive).
let filterPrs = (prs: array<pullRequest>, query: string): array<pullRequest> => {
  if query === "" {
    prs
  } else {
    let q = query->String.toLowerCase
    prs->Array.filter(pr =>
      pr.title->String.toLowerCase->String.includes(q) ||
        pr.author->String.toLowerCase->String.includes(q)
    )
  }
}

/// Total lines changed (additions + deletions) for a PR.
let totalLinesChanged = (pr: pullRequest): int => pr.additions + pr.deletions

/// Whether a PR is ready to merge (approved, no unresolved comments).
let isReadyToMerge = (pr: pullRequest, comments: array<reviewComment>): bool =>
  pr.status === PrApproved && countUnresolved(comments) == 0

/// Total additions across all file diffs.
let totalAdditions = (diffs: array<fileDiffEntry>): int =>
  diffs->Array.reduce(0, (acc, d) => acc + d.additions)

/// Total deletions across all file diffs.
let totalDeletions = (diffs: array<fileDiffEntry>): int =>
  diffs->Array.reduce(0, (acc, d) => acc + d.deletions)

/// Count open PRs (convenience).
let openPrCount = (prs: array<pullRequest>): int =>
  countByStatus(prs, PrOpen)
