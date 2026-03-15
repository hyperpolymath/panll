// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Team Dashboard Engine — pure functions for team presence and activity tracking.

open TeamDashboardModel

/// Default initial state for the Team Dashboard panel.
let defaultState: teamDashboardState = {
  activeTab: TabTeam,
  members: [],
  activity: [],
  filter: "",
  error: None,
}

/// Human-readable label for each tab.
let tabLabel = (tab: teamDashboardTab): string =>
  switch tab {
  | TabTeam => "Team"
  | TabActivity => "Activity"
  | TabProgress => "Progress"
  | TabSchedule => "Schedule"
  }

/// All tabs in display order.
let allTabs: array<teamDashboardTab> = [TabTeam, TabActivity, TabProgress, TabSchedule]

/// Count online team members (Online or Busy).
let countOnline = (members: array<teamMember>): int =>
  members->Array.filter(m => m.status === MemberOnline || m.status === MemberBusy)->Array.length

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
