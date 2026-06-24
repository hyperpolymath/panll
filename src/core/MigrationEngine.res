// SPDX-License-Identifier: MPL-2.0

/// PanLL Migration Engine — pure computation for the Migration Observatory panel.
///
/// Parses panic-attack migration snapshots, feedback-o-tron session data,
/// and merge-resolver decision logs. Computes aggregate metrics, filters,
/// sorts, and provides display helpers.

open MigrationModel

/// Human-readable label for a version bracket.
let versionBracketLabel = (bracket: migrationVersionBracket): string =>
  switch bracket {
  | BuckleScript => "BuckleScript"
  | V11 => "v11"
  | V12Alpha => "v12-alpha"
  | V12Stable => "v12-stable"
  | V12Current => "v12-current"
  | V13PreRelease => "v13-prerelease"
  | VersionUnknown => "unknown"
  }

/// CSS class for version bracket badge.
let versionBracketColor = (bracket: migrationVersionBracket): string =>
  switch bracket {
  | BuckleScript => "bg-red-500"
  | V11 => "bg-orange-400"
  | V12Alpha => "bg-yellow-400"
  | V12Stable => "bg-blue-400"
  | V12Current => "bg-green-400"
  | V13PreRelease => "bg-purple-400"
  | VersionUnknown => "bg-gray-400"
  }

/// Human-readable label for config format.
let configFormatLabel = (fmt: migrationConfigFormat): string =>
  switch fmt {
  | BsConfig => "bsconfig.json"
  | RescriptJson => "rescript.json"
  | ConfigBoth => "both"
  | ConfigNone => "none"
  }

/// Human-readable label for health trend.
let trendLabel = (trend: healthTrend): string =>
  switch trend {
  | Improving => "Improving"
  | Stable => "Stable"
  | Regressing => "Regressing"
  }

/// CSS indicator for health trend.
let trendIndicator = (trend: healthTrend): string =>
  switch trend {
  | Improving => "text-green-400"
  | Stable => "text-gray-400"
  | Regressing => "text-red-400"
  }

/// Category tab label.
let categoryLabel = (cat: migrationCategory): string =>
  switch cat {
  | MigrationDashboard => "Dashboard"
  | MigrationTimeline => "Timeline"
  | MigrationReports => "Reports"
  | MigrationSubmissions => "Submissions"
  | MigrationMergeResolver => "Merge Resolver"
  }

/// Report type label.
let reportTypeLabel = (rt: migrationReportType): string =>
  switch rt {
  | PerRepoReport => "Per-Repo"
  | CrossRepoReport => "Cross-Repo"
  | V13TrialReport => "v13 Trial"
  }

/// Submission status label.
let submissionStatusLabel = (status: submissionStatus): string =>
  switch status {
  | SubmissionPending => "Pending"
  | SubmissionApproved => "Approved"
  | SubmissionRejected => "Rejected"
  | SubmissionSubmitted => "Submitted"
  }

/// CSS class for submission status.
let submissionStatusColor = (status: submissionStatus): string =>
  switch status {
  | SubmissionPending => "text-yellow-400"
  | SubmissionApproved => "text-green-400"
  | SubmissionRejected => "text-red-400"
  | SubmissionSubmitted => "text-blue-400"
  }

/// CSS class for health score.
let healthColor = (score: float): string =>
  if score >= 0.8 {
    "text-green-400"
  } else if score >= 0.5 {
    "text-yellow-400"
  } else {
    "text-red-400"
  }

/// Format health score as percentage.
let healthPercent = (score: float): string => {
  let pct = score *. 100.0
  Float.toFixed(pct, ~digits=0) ++ "%"
}

/// Filter repos by text search.
let filterRepos = (repos: array<migrationRepoSummary>, query: string): array<
  migrationRepoSummary,
> => {
  if query === "" {
    repos
  } else {
    let q = String.toLowerCase(query)
    repos->Array.filter(r => String.includes(String.toLowerCase(r.name), q))
  }
}

/// Sort repos by health score ascending (worst first).
let sortByHealth = (repos: array<migrationRepoSummary>): array<migrationRepoSummary> => {
  let sorted = Array.copy(repos)
  sorted->Array.sort((a, b) => a.healthScore -. b.healthScore)
  sorted
}

/// Sort repos by deprecated count descending (most deprecated first).
let sortByDeprecated = (repos: array<migrationRepoSummary>): array<migrationRepoSummary> => {
  let sorted = Array.copy(repos)
  sorted->Array.sort((a, b) => Int.toFloat(b.deprecatedCount - a.deprecatedCount))
  sorted
}

/// Compute average health across all repos.
let computeAvgHealth = (repos: array<migrationRepoSummary>): float => {
  let len = Array.length(repos)
  if len > 0 {
    repos->Array.map(r => r.healthScore)->Array.reduce(0.0, (a, b) => a +. b) /. Int.toFloat(len)
  } else {
    0.0
  }
}

/// Count repos ready for migration.
let countReady = (repos: array<migrationRepoSummary>): int =>
  repos->Array.filter(r => r.healthScore >= 0.8 && !r.blocked)->Array.length

/// Count blocked repos.
let countBlocked = (repos: array<migrationRepoSummary>): int =>
  repos->Array.filter(r => r.blocked)->Array.length

/// Group repos by version bracket.
let groupByVersion = (repos: array<migrationRepoSummary>): array<(
  migrationVersionBracket,
  array<migrationRepoSummary>,
)> => {
  let groups: array<(migrationVersionBracket, array<migrationRepoSummary>)> = [
    (BuckleScript, repos->Array.filter(r => r.versionBracket == BuckleScript)),
    (V11, repos->Array.filter(r => r.versionBracket == V11)),
    (V12Alpha, repos->Array.filter(r => r.versionBracket == V12Alpha)),
    (V12Stable, repos->Array.filter(r => r.versionBracket == V12Stable)),
    (V12Current, repos->Array.filter(r => r.versionBracket == V12Current)),
    (V13PreRelease, repos->Array.filter(r => r.versionBracket == V13PreRelease)),
    (VersionUnknown, repos->Array.filter(r => r.versionBracket == VersionUnknown)),
  ]
  groups->Array.filter(((_, rs)) => Array.length(rs) > 0)
}

/// Get pending submissions count.
let pendingSubmissions = (submissions: array<migrationSubmission>): int =>
  submissions->Array.filter(s => s.status == SubmissionPending)->Array.length

/// Get active sessions count.
let activeSessions = (sessions: array<migrationSession>): int =>
  sessions->Array.filter(s => s.active)->Array.length

/// Default state for the Migration Observatory panel.
let defaultState: migrationState = {
  loaded: false,
  loading: false,
  error: None,
  repos: [],
  sessions: [],
  submissions: [],
  constraints: [],
  obligations: [],
  mergeResolutions: [],
  activeCategory: MigrationDashboard,
  activeReportType: PerRepoReport,
  filterText: "",
  totalRepos: 0,
  readyCount: 0,
  blockedCount: 0,
  avgHealth: 0.0,
  velocity: 0.0,
}
