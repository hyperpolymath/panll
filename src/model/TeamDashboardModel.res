// SPDX-License-Identifier: MPL-2.0

/// PanLL Team Dashboard Model — team member presence, activity feed, and
/// progress overview for collaborative IDApTIK development.
///
/// Shows who is working on what, recent activity across the team, contributor
/// statistics, and panel usage patterns. Provides team awareness without
/// requiring constant communication overhead.
///
/// Clade: Viewer. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Team Presence
// ============================================================================

/// Online presence status for a team member.
type memberStatus =
  /// Online — actively working in PanLL.
  | MemberOnline
  /// Busy — online but in a focused session (do not disturb).
  | MemberBusy
  /// Away — temporarily away from keyboard.
  | MemberAway
  /// Offline — not currently connected.
  | MemberOffline

/// A team member with current activity and presence information.
type teamMember = {
  /// Team member display name.
  name: string,
  /// Role in the project (e.g., "Lead Developer", "QA Tester", "Designer").
  role: string,
  /// Current task description (None if idle).
  currentTask: option<string>,
  /// Current panel being used (None if not in a panel).
  currentPanel: option<string>,
  /// Online presence status.
  status: memberStatus,
  /// ISO 8601 timestamp of last activity.
  lastActiveAt: string,
}

// ============================================================================
// Activity Feed
// ============================================================================

/// An entry in the team activity feed showing recent actions.
type teamActivityEntry = {
  /// Unique activity identifier.
  id: string,
  /// Username of the person who performed the action.
  actor: string,
  /// Action verb (e.g., "committed", "reviewed", "merged", "deployed").
  action: string,
  /// Target of the action (e.g., "feature/level-7-puzzles", "PR #42").
  target: string,
  /// ISO 8601 timestamp of the activity.
  timestamp: string,
}

/// Contributor statistics for the progress overview.
type contributorStats = {
  /// Team member name.
  name: string,
  /// Number of commits in the current sprint.
  commitsThisSprint: int,
  /// Number of reviews completed.
  reviewsCompleted: int,
  /// Number of issues closed.
  issuesClosed: int,
  /// Lines of code changed.
  linesChanged: int,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Team Dashboard panel.
type teamDashboardTab =
  /// Team — member list with presence indicators and current tasks.
  | TabTeam
  /// Activity — chronological feed of team actions.
  | TabActivity
  /// Progress — contributor statistics and sprint metrics.
  | TabProgress
  /// Schedule — upcoming milestones and deadlines.
  | TabSchedule

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Team Dashboard panel.
type teamDashboardState = {
  /// Active tab within the panel.
  activeTab: teamDashboardTab,
  /// Team members with presence information.
  members: array<teamMember>,
  /// Recent activity feed entries.
  activity: array<teamActivityEntry>,
  /// Per-contributor statistics.
  contributorStats: array<contributorStats>,
  /// Text filter for member names and roles.
  filter: string,
  /// Error from the last operation.
  error: option<string>,
}
