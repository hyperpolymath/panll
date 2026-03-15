// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL TeamDashboard — team member presence, activity feed, and progress overview.
/// Viewer clade panel for team collaboration visibility.
///
/// Four tabs: Team (member cards with status dots), Activity (feed),
/// Progress (overview), and Schedule (placeholder).

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tailwind colour class for status dot.
let statusDotColour = (status: memberStatus): string =>
  switch status {
  | MemberOnline => "bg-emerald-400"
  | MemberBusy => "bg-amber-400"
  | MemberAway => "bg-gray-400"
  | MemberOffline => "bg-gray-600"
  }

/// Label for member status.
let statusLabel = (status: memberStatus): string =>
  switch status {
  | MemberOnline => "Online"
  | MemberBusy => "Busy"
  | MemberAway => "Away"
  | MemberOffline => "Offline"
  }

/// Tab bar rendering.
let renderTabs = (active: teamDashboardTab): Tea_Vdom.t<msg> => {
  let tabs = TeamDashboardEngine.allTabs
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-3 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-cyan-400 border-b-2 border-cyan-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900 cursor-pointer"}`,
          ),
          Events.onClick(TeamDashboard(SetTdTab(tab))),
        },
        list{text(TeamDashboardEngine.tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

// =========================================================================
// Tab content views
// =========================================================================

/// Team tab: member cards with presence indicators and current task.
let renderTeamTab = (state: teamDashboardState): Tea_Vdom.t<msg> => {
  let filtered = TeamDashboardEngine.filterMembers(state.members, state.filter)
  let onlineCount = TeamDashboardEngine.countOnline(state.members)
  if Array.length(filtered) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No team members loaded.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4")},
      list{
        div(
          list{Attrs.class_("text-sm text-gray-400 mb-1")},
          list{
            text(
              `${Int.toString(onlineCount)} of ${Int.toString(Array.length(state.members))} online`,
            ),
          },
        ),
        div(
          list{Attrs.class_("grid grid-cols-2 gap-3 max-h-96 overflow-y-auto")},
          filtered
          ->Array.map(member => {
            div(
              list{Attrs.class_("bg-gray-800 rounded p-3 border border-gray-700")},
              list{
                div(
                  list{Attrs.class_("flex items-center gap-2 mb-2")},
                  list{
                    div(
                      list{
                        Attrs.class_(
                          `w-2.5 h-2.5 rounded-full ${statusDotColour(member.status)}`,
                        ),
                      },
                      list{},
                    ),
                    span(
                      list{Attrs.class_("text-sm font-medium text-gray-200")},
                      list{text(member.name)},
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-500 mb-1")},
                  list{text(`${member.role} - ${statusLabel(member.status)}`)},
                ),
                switch member.currentTask {
                | Some(task) =>
                  div(
                    list{Attrs.class_("text-xs text-gray-400 bg-gray-900 rounded px-2 py-1 mt-1")},
                    list{text(task)},
                  )
                | None => noNode
                },
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Activity tab: chronological feed of team actions.
let renderActivityTab = (state: teamDashboardState): Tea_Vdom.t<msg> => {
  let recent = TeamDashboardEngine.recentActivity(state.activity, 50)
  if Array.length(recent) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No recent activity.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-1 p-4 max-h-96 overflow-y-auto")},
      recent
      ->Array.map(entry => {
        div(
          list{Attrs.class_("flex items-start gap-2 p-2 bg-gray-800 rounded")},
          list{
            div(list{Attrs.class_("w-1.5 h-1.5 rounded-full bg-cyan-500 mt-1.5")}, list{}),
            div(
              list{Attrs.class_("flex-1")},
              list{
                div(
                  list{Attrs.class_("text-sm text-gray-300")},
                  list{
                    span(
                      list{Attrs.class_("font-medium text-gray-200")},
                      list{text(entry.actor)},
                    ),
                    text(` ${entry.action} `),
                    span(
                      list{Attrs.class_("text-cyan-400")},
                      list{text(entry.target)},
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-600")},
                  list{text(entry.timestamp)},
                ),
              },
            ),
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// Progress tab: overview of team progress metrics.
let renderProgressTab = (state: teamDashboardState): Tea_Vdom.t<msg> => {
  let onlineCount = TeamDashboardEngine.countOnline(state.members)
  let totalMembers = Array.length(state.members)
  let activityCount = Array.length(state.activity)
  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      div(
        list{Attrs.class_("grid grid-cols-3 gap-3")},
        list{
          div(
            list{Attrs.class_("bg-gray-800 rounded p-4 border border-gray-700 text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-emerald-400")},
                list{text(Int.toString(onlineCount))},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500 mt-1")},
                list{text("Online")},
              ),
            },
          ),
          div(
            list{Attrs.class_("bg-gray-800 rounded p-4 border border-gray-700 text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-gray-300")},
                list{text(Int.toString(totalMembers))},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500 mt-1")},
                list{text("Team Size")},
              ),
            },
          ),
          div(
            list{Attrs.class_("bg-gray-800 rounded p-4 border border-gray-700 text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-cyan-400")},
                list{text(Int.toString(activityCount))},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500 mt-1")},
                list{text("Activities")},
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Schedule tab: placeholder for future calendar integration.
let renderScheduleTab = (_state: teamDashboardState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4")},
    list{
      div(
        list{Attrs.class_("bg-gray-800 rounded p-4 h-48 flex items-center justify-center")},
        list{
          span(
            list{Attrs.class_("text-gray-600 text-sm")},
            list{text("Schedule integration coming soon.")},
          ),
        },
      ),
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function for the Team Dashboard panel.
let view = (state: teamDashboardState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabTeam => renderTeamTab(state)
  | TabActivity => renderActivityTab(state)
  | TabProgress => renderProgressTab(state)
  | TabSchedule => renderScheduleTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold text-cyan-300")},
            list{text("Team Dashboard")},
          ),
          // Filter input
          input(
            list{
              Attrs.class_(
                "bg-gray-800 border border-gray-700 rounded px-2 py-1 text-sm text-gray-300 w-48 placeholder-gray-600",
              ),
              Attrs.placeholder("Filter members..."),
              Attrs.value(state.filter),
              Events.onInput(value => TeamDashboard(SetTdFilter(value))),
            },
            list{},
          ),
        },
      ),
      // Error display
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("px-4 py-2 bg-red-900/30 text-red-300 text-sm border-b border-red-800")},
          list{text(err)},
        )
      | None => noNode
      },
      // Tab bar
      renderTabs(state.activeTab),
      // Content
      div(list{Attrs.class_("flex-1 overflow-y-auto")}, list{content}),
    },
  )
}
