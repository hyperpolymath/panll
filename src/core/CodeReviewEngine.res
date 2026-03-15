// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Code Review Engine — pure functions for pull request review management.

open CodeReviewModel

/// Default initial state for the Code Review panel.
let defaultState: codeReviewState = {
  activeTab: TabPullRequests,
  pullRequests: [],
  comments: [],
  selectedPr: None,
  filter: "",
  error: None,
}

/// Human-readable label for each tab.
let tabLabel = (tab: codeReviewTab): string =>
  switch tab {
  | TabPullRequests => "Pull Requests"
  | TabFileChanges => "File Changes"
  | TabComments => "Comments"
  | TabApprovalGate => "Approval Gate"
  }

/// All tabs in display order.
let allTabs: array<codeReviewTab> = [TabPullRequests, TabFileChanges, TabComments, TabApprovalGate]

/// Count pull requests by status.
let countByStatus = (prs: array<pullRequest>, status: prStatus): int =>
  prs->Array.filter(pr => pr.status === status)->Array.length

/// Count unresolved review comments.
let countUnresolved = (comments: array<reviewComment>): int =>
  comments->Array.filter(c => !c.resolved)->Array.length

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
