// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Code Review Model — pull request review, inline comments, and approval gates.
/// Scanner clade. This module has NO dependencies on other PanLL modules.

/// Pull request review status.
type prStatus =
  | PrOpen
  | PrApproved
  | PrChangesRequested
  | PrMerged
  | PrClosed

/// A pull request under review.
type pullRequest = {
  id: string,
  title: string,
  author: string,
  branch: string,
  filesChanged: int,
  additions: int,
  deletions: int,
  status: prStatus,
  createdAt: string,
}

/// An inline review comment on a file.
type reviewComment = {
  id: string,
  filePath: string,
  lineNumber: int,
  body: string,
  author: string,
  resolved: bool,
  createdAt: string,
}

/// Active tab within the Code Review panel.
type codeReviewTab =
  | TabPullRequests
  | TabFileChanges
  | TabComments
  | TabApprovalGate

/// Code Review panel state.
type codeReviewState = {
  activeTab: codeReviewTab,
  pullRequests: array<pullRequest>,
  comments: array<reviewComment>,
  selectedPr: option<string>,
  filter: string,
  error: option<string>,
}
