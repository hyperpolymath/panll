// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Team Dashboard Engine — pure computation and helpers for the
/// Team Dashboard panel. Provides default state, presence counting,
/// activity filtering, contributor statistics, and member search.

open TeamDashboardModel

/// Default initial state for the Team Dashboard panel.
/// Starts on the Team tab with empty member and activity lists.
let defaultState: teamDashboardState = {
  activeTab: TabTeam,
  members: [],
  activity: [],
  contributorStats: [],
  filter: "",
  error: None,
}

/// Human-readable label for each tab in the Team Dashboard panel.
let tabLabel = (tab: teamDashboardTab): string =>
  switch tab {
  | TabTeam => "Team"
  | TabActivity => "Activity"
  | TabProgress => "Progress"
  | TabSchedule => "Schedule"
  }

/// All tabs in display order.
let allTabs: array<teamDashboardTab> = [TabTeam, TabActivity, TabProgress, TabSchedule]

/// Human-readable label for a member status.
let statusLabel = (status: memberStatus): string =>
  switch status {
  | MemberOnline => "Online"
  | MemberBusy => "Busy"
  | MemberAway => "Away"
  | MemberOffline => "Offline"
  }

/// CSS colour class for a member status.
let statusColor = (status: memberStatus): string =>
  switch status {
  | MemberOnline => "text-green-400"
  | MemberBusy => "text-orange-400"
  | MemberAway => "text-yellow-400"
  | MemberOffline => "text-gray-500"
  }

/// Status dot colour for presence indicator.
let statusDotColor = (status: memberStatus): string =>
  switch status {
  | MemberOnline => "bg-green-400"
  | MemberBusy => "bg-orange-400"
  | MemberAway => "bg-yellow-400"
  | MemberOffline => "bg-gray-500"
  }

/// Count online team members (Online or Busy).
let countOnline = (members: array<teamMember>): int =>
  members->Array.filter(m => m.status === MemberOnline || m.status === MemberBusy)->Array.length

/// Count offline team members.
let countOffline = (members: array<teamMember>): int =>
  members->Array.filter(m => m.status === MemberOffline)->Array.length

/// Get the most recent N activity entries.
let recentActivity = (entries: array<teamActivityEntry>, limit: int): array<teamActivityEntry> =>
  entries->Array.slice(~start=0, ~end=limit)

/// Filter members by name or role matching a search string (case-insensitive).
let filterMembers = (members: array<teamMember>, query: string): array<teamMember> => {
  if query === "" {
    members
  } else {
    let q = query->String.toLowerCase
    members->Array.filter(m =>
      m.name->String.toLowerCase->String.includes(q) ||
        m.role->String.toLowerCase->String.includes(q)
    )
  }
}

/// Total commits across all contributors in the current sprint.
let totalCommits = (stats: array<contributorStats>): int =>
  stats->Array.reduce(0, (acc, s) => acc + s.commitsThisSprint)

/// Total reviews completed across all contributors.
let totalReviews = (stats: array<contributorStats>): int =>
  stats->Array.reduce(0, (acc, s) => acc + s.reviewsCompleted)

/// Total issues closed across all contributors.
let totalIssuesClosed = (stats: array<contributorStats>): int =>
  stats->Array.reduce(0, (acc, s) => acc + s.issuesClosed)

/// Count members with active tasks.
let countActiveMembers = (members: array<teamMember>): int =>
  members->Array.filter(m => m.currentTask != None)->Array.length

/// Count distinct panels currently in use across the team.
let activePanels = (members: array<teamMember>): int => {
  let panels = members->Array.filterMap(m => m.currentPanel)
  panels->Array.reduce([], (acc, p) =>
    if acc->Array.some(x => x == p) { acc } else { Array.concat(acc, [p]) }
  )->Array.length
}
