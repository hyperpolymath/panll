// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Code Review Model — pull request review, inline comments, and
/// approval gates for collaborative IDApTIK development.
///
/// Provides in-panel diff views, inline comment threads, and a multi-reviewer
/// approval workflow. Integrates with GitHub/GitLab via BoJ MCP cartridges.
///
/// Clade: Scanner. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Pull Request Status
// ============================================================================

/// Lifecycle status of a pull request under review.
type prStatus =
  /// Open — PR is active and awaiting review.
  | PrOpen
  /// Approved — all required reviewers have approved.
  | PrApproved
  /// Changes Requested — reviewer has asked for modifications.
  | PrChangesRequested
  /// Merged — PR has been merged into the target branch.
  | PrMerged
  /// Closed — PR was closed without merging.
  | PrClosed

// ============================================================================
// Pull Requests
// ============================================================================

/// A pull request under review in the Code Review panel.
type pullRequest = {
  /// Unique PR identifier (e.g., "PR-42" or GitHub number).
  id: string,
  /// PR title.
  title: string,
  /// Author username.
  author: string,
  /// Source branch name.
  branch: string,
  /// Target branch name (e.g., "main").
  targetBranch: string,
  /// Number of files changed in this PR.
  filesChanged: int,
  /// Total lines added.
  additions: int,
  /// Total lines removed.
  deletions: int,
  /// Current lifecycle status.
  status: prStatus,
  /// ISO 8601 timestamp when the PR was created.
  createdAt: string,
  /// Labels attached to the PR (e.g., ["bugfix", "urgent"]).
  labels: array<string>,
}

// ============================================================================
// Review Comments
// ============================================================================

/// An inline review comment attached to a specific file and line.
type reviewComment = {
  /// Unique comment identifier.
  id: string,
  /// File path the comment is attached to.
  filePath: string,
  /// Line number in the diff the comment refers to.
  lineNumber: int,
  /// Comment body text.
  body: string,
  /// Comment author username.
  author: string,
  /// Whether this comment thread has been resolved.
  resolved: bool,
  /// ISO 8601 timestamp when the comment was created.
  createdAt: string,
}

/// A file diff entry showing additions and deletions.
type fileDiffEntry = {
  /// File path.
  path: string,
  /// Lines added in this file.
  additions: int,
  /// Lines removed in this file.
  deletions: int,
  /// Whether the file is binary (not diffable).
  binary: bool,
  /// Language of the file (for syntax highlighting).
  language: string,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Code Review panel.
type codeReviewTab =
  /// Pull Requests — list of PRs with status badges and metadata.
  | TabPullRequests
  /// File Changes — per-file diff list with inline comments.
  | TabFileChanges
  /// Comments — all review comments with resolved/unresolved filter.
  | TabComments
  /// Approval Gate — reviewer approval status and merge readiness check.
  | TabApprovalGate

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Code Review panel.
type codeReviewState = {
  /// Active tab within the panel.
  activeTab: codeReviewTab,
  /// All pull requests visible to the current user.
  pullRequests: array<pullRequest>,
  /// Review comments on the selected PR.
  comments: array<reviewComment>,
  /// File diffs for the selected PR.
  fileDiffs: array<fileDiffEntry>,
  /// Currently selected PR ID for detail view.
  selectedPr: option<string>,
  /// Text filter for PR list (searches title and author).
  filter: string,
  /// Error from the last operation.
  error: option<string>,
}
