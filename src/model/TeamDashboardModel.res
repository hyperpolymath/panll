// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Team Dashboard Model — team presence, activity feed, and progress tracking.
/// Viewer clade. This module has NO dependencies on other PanLL modules.

/// Online presence status for a team member.
type memberStatus =
  | MemberOnline
  | MemberBusy
  | MemberAway
  | MemberOffline

/// A team member with current activity.
type teamMember = {
  name: string,
  role: string,
  currentTask: option<string>,
  status: memberStatus,
  lastActiveAt: string,
}

/// An entry in the team activity feed.
type teamActivityEntry = {
  id: string,
  actor: string,
  action: string,
  target: string,
  timestamp: string,
}

/// Active tab within the Team Dashboard panel.
type teamDashboardTab =
  | TabTeam
  | TabActivity
  | TabProgress
  | TabSchedule

/// Team Dashboard panel state.
type teamDashboardState = {
  activeTab: teamDashboardTab,
  members: array<teamMember>,
  activity: array<teamActivityEntry>,
  filter: string,
  error: option<string>,
}
