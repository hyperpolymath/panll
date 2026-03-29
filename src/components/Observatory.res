// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Observatory Component — integrative dashboard.
///
/// Single pane of glass for all panel health, service status, resource
/// usage, and ambient metrics. Aggregates data from PanelRegistry and
/// Gossamer system info queries.

open Model
open Msg
open Tea.Html

/// Render a health badge.
let healthBadge = (health: serviceHealth): Tea_Vdom.t<msg> => {
  let (color, label) = switch health {
  | Healthy => ("text-green-400", "Healthy")
  | Degraded(reason) => ("text-yellow-400", "Degraded: " ++ reason)
  | Unreachable => ("text-red-400", "Unreachable")
  | Unknown => ("text-gray-500", "Unknown")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Render a resource snapshot row.
let snapshotRow = (snapshot: resourceSnapshot): Tea_Vdom.t<msg> => {
  let memLabel = if snapshot.memoryBytes > 0 {
    Int.toString(snapshot.memoryBytes / (1024 * 1024)) ++ " MiB"
  } else {
    "N/A"
  }
  div(
    list{
      Attrs.class_("flex items-center justify-between py-1 px-2 border-b border-gray-800"),
      Attrs.role("row"),
    },
    list{
      span(list{Attrs.class_("text-sm text-gray-200 w-40")}, list{text(snapshot.name)}),
      span(list{Attrs.class_("text-xs text-gray-400 w-20")}, list{text(memLabel)}),
      span(
        list{
          Attrs.class_(
            "text-xs w-16 " ++ if snapshot.active {
              "text-blue-400"
            } else {
              "text-gray-600"
            },
          ),
        },
        list{
          text(
            if snapshot.active {
              "Active"
            } else {
              "Idle"
            },
          ),
        },
      ),
      healthBadge(snapshot.health),
    },
  )
}

/// Render a tab button.
let tabBtn = (current: observatoryTab, target: observatoryTab, label: string): Tea_Vdom.t<msg> => {
  let active = current == target
  button(
    list{
      Attrs.class_(
        "px-3 py-1 text-xs rounded " ++ if active {
          "bg-blue-600 text-white"
        } else {
          "bg-gray-800 text-gray-400 hover:bg-gray-700"
        },
      ),
      Events.onClick(Observatory(SetObsTab(target))),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Main view function for the Observatory panel.
let view = (state: observatoryState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Observatory — Integrative Dashboard"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          h2(list{Attrs.class_("text-lg font-bold text-blue-300")}, list{text("Observatory")}),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs rounded bg-green-700 text-white hover:bg-green-600",
                  ),
                  Events.onClick(Observatory(RunHealthCheck)),
                  KeyboardNav.onActivate(Observatory(RunHealthCheck)),
                },
                list{
                  text(
                    if state.checking {
                      "Checking..."
                    } else {
                      "Health Check"
                    },
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Tabs
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800"), Attrs.role("tablist")},
        list{
          tabBtn(state.activeTab, TabOverview, "Overview"),
          tabBtn(state.activeTab, TabServices, "Services"),
          tabBtn(state.activeTab, TabResources, "Resources"),
          tabBtn(state.activeTab, TabActivity, "Activity"),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200",
            ),
            Events.onClick(Observatory(DismissObsError)),
            KeyboardNav.onActivate(Observatory(DismissObsError)),
          },
          list{text(err)},
        )
      | None => Tea_Html.noNode
      },
      // System summary bar
      div(
        list{Attrs.class_("flex gap-6 px-4 py-2 text-xs text-gray-400 border-b border-gray-800")},
        list{
          span(list{}, list{text("CPU: " ++ Float.toFixed(state.systemCpu, ~digits=1) ++ "%")}),
          span(
            list{},
            list{
              text(
                "Memory: " ++
                Int.toString(state.systemMemory / (1024 * 1024)) ++
                " / " ++
                Int.toString(state.systemMemoryTotal / (1024 * 1024)) ++ " MiB",
              ),
            },
          ),
          span(list{}, list{text("Panels: " ++ Int.toString(Array.length(state.snapshots)))}),
        },
      ),
      // Content
      div(
        list{Attrs.class_("flex-1 overflow-y-auto px-4 py-2")},
        list{
          switch state.activeTab {
          | TabOverview | TabServices | TabResources =>
            div(
              list{Attrs.role("table"), Attrs.ariaLabel("Panel health")},
              state.snapshots->Array.map(snapshotRow)->List.fromArray,
            )
          | TabActivity =>
            div(
              list{},
              state.activity
              ->Array.map(entry =>
                div(
                  list{Attrs.class_("flex gap-4 py-1 text-xs border-b border-gray-800")},
                  list{
                    span(
                      list{Attrs.class_("text-gray-500 w-40 shrink-0")},
                      list{text(entry.timestamp)},
                    ),
                    span(
                      list{Attrs.class_("text-blue-300 w-28 shrink-0")},
                      list{text(entry.panelName)},
                    ),
                    span(list{Attrs.class_("text-gray-300")}, list{text(entry.event)}),
                  },
                )
              )
              ->List.fromArray,
            )
          },
        },
      ),
    },
  )
}
