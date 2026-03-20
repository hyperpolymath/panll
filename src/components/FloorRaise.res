// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Floor Raise Component — foundational tool adoption dashboard.
///
/// Master dashboard for the Floor Raise campaign. Shows adoption metrics
/// for all foundational tools, active dispatch campaigns, recent fix
/// outcomes, and gap analysis.

open Model
open Msg
open Tea.Html

/// Render a progress bar for a tool adoption metric.
let progressBar = (adoption: toolAdoption): Tea_Vdom.t<msg> => {
  let pctStr = Float.toFixed(adoption.percentage, ~digits=1)
  let barColor = if adoption.percentage > 80.0 {
    "bg-green-500"
  } else if adoption.percentage > 50.0 {
    "bg-amber-500"
  } else {
    "bg-red-500"
  }
  div(
    list{Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg p-3")},
    list{
      div(list{Attrs.class_("flex items-center justify-between mb-2")}, list{
        span(list{Attrs.class_("text-sm text-gray-200 font-medium")}, list{text(adoption.name)}),
        span(list{Attrs.class_("text-xs text-gray-400")}, list{
          text(`${Int.toString(adoption.adoptedCount)}/${Int.toString(adoption.targetCount)}`),
        }),
      }),
      div(list{Attrs.class_("w-full bg-gray-800 rounded-full h-2")}, list{
        div(
          list{
            Attrs.class_(`${barColor} h-2 rounded-full transition-all duration-300`),
            Attrs.style("width", `${pctStr}%`),
          },
          list{},
        ),
      }),
      div(list{Attrs.class_("flex items-center justify-between mt-1")}, list{
        span(list{Attrs.class_("text-xs text-gray-500")}, list{text(`${pctStr}%`)}),
        if adoption.campaignActive {
          span(list{Attrs.class_("text-xs text-blue-400 animate-pulse")}, list{text("Campaign Active")})
        } else {
          noNode
        },
      }),
    },
  )
}

/// Render a dispatch outcome row.
let outcomeRow = (outcome: dispatchOutcome): Tea_Vdom.t<msg> => {
  let statusColor = if outcome.success {"text-green-400"} else {"text-red-400"}
  let statusLabel = if outcome.success {"OK"} else {"FAIL"}
  div(
    list{Attrs.class_("flex items-center gap-3 py-2 px-2 border-b border-gray-800 text-xs")},
    list{
      span(list{Attrs.class_("text-gray-500 w-36 shrink-0")}, list{text(outcome.timestamp)}),
      span(list{Attrs.class_("text-gray-300 w-40 shrink-0 truncate")}, list{text(outcome.repo)}),
      span(list{Attrs.class_("text-gray-400 w-32 shrink-0 truncate")}, list{text(outcome.fixScript)}),
      span(list{Attrs.class_("text-gray-400 w-32 shrink-0")}, list{text(outcome.category)}),
      span(list{Attrs.class_(`${statusColor} w-12 font-mono`)}, list{text(statusLabel)}),
    },
  )
}

/// Render a tab button.
let tabBtn = (current: floorRaiseTab, target: floorRaiseTab, label: string): Tea_Vdom.t<msg> => {
  let active = current == target
  button(
    list{
      Attrs.class_(
        "px-3 py-1 text-xs rounded " ++
        if active {"bg-blue-600 text-white"} else {"bg-gray-800 text-gray-400 hover:bg-gray-700"},
      ),
      Events.onClick(FloorRaise(SetTab(target))),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Main view function for the Floor Raise panel.
let view = (state: floorRaiseState): Tea_Vdom.t<msg> => {
  let progress = FloorRaiseEngine.overallProgress(state)
  let progressStr = Float.toFixed(progress, ~digits=1)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Floor Raise — Foundational Tool Adoption Dashboard"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(list{Attrs.class_("flex items-center gap-3")}, list{
            h2(list{Attrs.class_("text-lg font-bold text-blue-300")}, list{text("Floor Raise")}),
            span(list{Attrs.class_("text-xs text-gray-500")}, list{
              text(`Overall: ${progressStr}% | ${Int.toString(state.totalRepos)} repos`),
            }),
          }),
          div(list{Attrs.class_("flex gap-2")}, list{
            button(
              list{
                Attrs.class_("px-3 py-1 text-xs rounded bg-green-700 text-white hover:bg-green-600"),
                Events.onClick(FloorRaise(ScanAdoption)),
              },
              list{text(if state.scanning {"Scanning..."} else {"Scan Adoption"})},
            ),
          }),
        },
      ),
      // Tabs
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800"), Attrs.role("tablist")},
        list{
          tabBtn(state.activeTab, TabOverview, "Overview"),
          tabBtn(state.activeTab, TabCampaigns, "Campaigns"),
          tabBtn(state.activeTab, TabOutcomes, "Outcomes"),
          tabBtn(state.activeTab, TabGaps, "Gaps"),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_("mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200"),
            Events.onClick(FloorRaise(ClearError)),
          },
          list{text(err)},
        )
      | None => noNode
      },
      // Content
      div(
        list{Attrs.class_("flex-1 overflow-y-auto px-4 py-2")},
        list{
          switch state.activeTab {
          | TabOverview =>
            div(
              list{Attrs.class_("grid grid-cols-2 gap-3")},
              state.adoptions->Array.map(a => progressBar(a))->List.fromArray,
            )
          | TabCampaigns =>
            div(
              list{},
              state.adoptions
              ->Array.filter(a => a.campaignActive)
              ->Array.map(a =>
                div(
                  list{Attrs.class_("flex items-center justify-between py-2 px-3 border-b border-gray-800")},
                  list{
                    span(list{Attrs.class_("text-sm text-gray-200")}, list{text(a.name)}),
                    div(list{Attrs.class_("flex items-center gap-3")}, list{
                      span(list{Attrs.class_("text-xs text-gray-400")}, list{
                        text(`${Float.toFixed(a.percentage, ~digits=1)}% adopted`),
                      }),
                      button(
                        list{
                          Attrs.class_("px-2 py-1 text-xs rounded bg-blue-700 text-white hover:bg-blue-600"),
                          Events.onClick(FloorRaise(RunCampaign(a.name))),
                        },
                        list{text("Dispatch")},
                      ),
                    }),
                  },
                )
              )
              ->List.fromArray,
            )
          | TabOutcomes =>
            div(
              list{Attrs.role("table"), Attrs.ariaLabel("Dispatch outcomes")},
              state.outcomes->Array.map(o => outcomeRow(o))->List.fromArray,
            )
          | TabGaps =>
            div(
              list{},
              state.adoptions
              ->Array.filter(a => a.percentage < 100.0)
              ->Array.map(a =>
                div(
                  list{Attrs.class_("flex items-center justify-between py-2 px-3 border-b border-gray-800")},
                  list{
                    span(list{Attrs.class_("text-sm text-gray-200")}, list{text(a.name)}),
                    span(list{Attrs.class_("text-xs text-red-400")}, list{
                      text(`${Int.toString(a.targetCount - a.adoptedCount)} repos missing`),
                    }),
                  },
                )
              )
              ->List.fromArray,
            )
          },
        },
      ),
      // Footer
      div(
        list{Attrs.class_("px-4 py-2 border-t border-gray-800 text-xs text-gray-500 flex justify-between")},
        list{
          span(list{}, list{
            text(`${Int.toString(FloorRaiseEngine.activeCampaignCount(state))} active campaigns`),
          }),
          span(list{}, list{
            text(`${Int.toString(FloorRaiseEngine.successCount(state.outcomes))}/${Int.toString(Array.length(state.outcomes))} dispatches succeeded`),
          }),
        },
      ),
    },
  )
}
