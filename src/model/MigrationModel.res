// SPDX-License-Identifier: MPL-2.0

/// PanLL Migration Model — leaf types for the ReScript Migration Observatory panel.
///
/// Represents migration health data from panic-attack snapshots, feedback-o-tron
/// observation sessions, and merge-resolver decision logs. Three-panel mapping:
///
/// Panel-L: Migration constraints — deprecated APIs, version requirements, proof obligations
/// Panel-N: Hypatia reasoning — migration order, API replacements, merge decisions
/// Panel-W: Results dashboard — health scores, build times, submission queue, timeline
///
/// Dependency: none (leaf module in the type DAG).

/// ReScript version bracket for a repository.
type migrationVersionBracket =
  | BuckleScript
  | V11
  | V12Alpha
  | V12Stable
  | V12Current
  | V13PreRelease
  | VersionUnknown

/// Configuration format detected in a repository.
type migrationConfigFormat =
  | BsConfig
  | RescriptJson
  | ConfigBoth
  | ConfigNone

/// Health trend direction for a repository.
type healthTrend =
  | Improving
  | Stable
  | Regressing

/// A single repository's migration summary.
type migrationRepoSummary = {
  /// Repository name.
  name: string,
  /// Overall migration health score (0.0 - 1.0).
  healthScore: float,
  /// Health score trend.
  trend: healthTrend,
  /// ReScript version bracket.
  versionBracket: migrationVersionBracket,
  /// Config format.
  configFormat: migrationConfigFormat,
  /// Count of deprecated API calls remaining.
  deprecatedCount: int,
  /// Count of modern @rescript/core API calls.
  modernCount: int,
  /// API migration ratio (0.0 - 1.0).
  migrationRatio: float,
  /// Number of ReScript source files.
  fileCount: int,
  /// Whether migration is blocked (merge conflicts, build failing, etc.).
  blocked: bool,
  /// Block reason (if blocked).
  blockReason: option<string>,
  /// Last snapshot timestamp.
  lastSnapshot: option<string>,
  /// Build time in milliseconds (if measured).
  buildTimeMs: option<int>,
  /// Bundle size in bytes (if measured).
  bundleSizeBytes: option<int>,
}

/// A migration observation session from feedback-o-tron.
type migrationSession = {
  /// Session ID (UUID).
  sessionId: string,
  /// Repository path.
  repoPath: string,
  /// Session label.
  label: string,
  /// Before health score.
  beforeHealth: float,
  /// After health score (None if session still in progress).
  afterHealth: option<float>,
  /// Health delta.
  healthDelta: option<float>,
  /// Number of issues discovered.
  issueCount: int,
  /// Number of complications encountered.
  complicationCount: int,
  /// Session start timestamp.
  startedAt: string,
  /// Session end timestamp (None if in progress).
  endedAt: option<string>,
  /// Whether session is still active.
  active: bool,
}

/// Status of a submission in the review queue.
type submissionStatus =
  | SubmissionPending
  | SubmissionApproved
  | SubmissionRejected
  | SubmissionSubmitted

/// An issue queued for submission to the ReScript team.
type migrationSubmission = {
  /// Unique identifier.
  id: string,
  /// Issue title.
  title: string,
  /// Issue body (markdown).
  body: string,
  /// Source repository.
  repo: string,
  /// Severity level.
  severity: string,
  /// Current review status.
  status: submissionStatus,
  /// Who approved/rejected (if reviewed).
  reviewedBy: option<string>,
  /// Review notes.
  reviewNotes: option<string>,
}

/// A deprecated pattern constraint for Panel-L.
type migrationConstraint = {
  /// Constraint identifier.
  id: string,
  /// Pattern name (e.g., "Js.Array2", "Belt.Map").
  pattern: string,
  /// Modern replacement.
  replacement: string,
  /// Number of occurrences across all repos.
  totalCount: int,
  /// Number of repos affected.
  repoCount: int,
  /// Whether this constraint is satisfied (count == 0).
  satisfied: bool,
}

/// A proof obligation from Hypatia migration rules.
type migrationObligation = {
  /// Repository name.
  repo: string,
  /// Property to verify (e.g., "no_js_dict_calls", "rescript_json_only").
  property: string,
  /// Whether the obligation is met.
  met: bool,
}

/// A merge conflict resolution for the timeline.
type mergeResolution = {
  /// Session ID from merge-resolver.
  sessionId: string,
  /// Repository name.
  repo: string,
  /// Source branch.
  sourceBranch: string,
  /// Target branch.
  targetBranch: string,
  /// Number of conflicts.
  conflictCount: int,
  /// Number resolved.
  resolvedCount: int,
  /// Average confidence.
  avgConfidence: float,
  /// Session status.
  status: string,
  /// Timestamp.
  timestamp: string,
}

/// Category tabs for the Migration Observatory panel.
type migrationCategory =
  /// Overview dashboard with health scores and sparklines.
  | MigrationDashboard
  /// Timeline of migration sessions and snapshots.
  | MigrationTimeline
  /// Generated reports (per-repo, cross-repo, v13 trial).
  | MigrationReports
  /// Issue submission queue for ReScript team.
  | MigrationSubmissions
  /// Merge conflict resolution timeline and rollback controls.
  | MigrationMergeResolver

/// Report type for the reports tab.
type migrationReportType =
  | PerRepoReport
  | CrossRepoReport
  | V13TrialReport

/// Root state for the Migration Observatory panel module.
type migrationState = {
  /// Whether data has been loaded.
  loaded: bool,
  /// Loading indicator for async operations.
  loading: bool,
  /// Last error message.
  error: option<string>,
  /// All repository migration summaries.
  repos: array<migrationRepoSummary>,
  /// Active observation sessions.
  sessions: array<migrationSession>,
  /// Submission review queue.
  submissions: array<migrationSubmission>,
  /// Migration constraints (Panel-L).
  constraints: array<migrationConstraint>,
  /// Proof obligations from Hypatia.
  obligations: array<migrationObligation>,
  /// Merge resolution history.
  mergeResolutions: array<mergeResolution>,
  /// Active category tab.
  activeCategory: migrationCategory,
  /// Selected report type.
  activeReportType: migrationReportType,
  /// Text filter for repo search.
  filterText: string,
  /// Total repos tracked.
  totalRepos: int,
  /// Count of repos ready for migration.
  readyCount: int,
  /// Count of blocked repos.
  blockedCount: int,
  /// Average health score across all repos.
  avgHealth: float,
  /// Migration velocity (avg health improvement per session).
  velocity: float,
}
