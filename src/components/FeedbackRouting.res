// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Feedback Routing Component — upstream bug report status and integration map.
///
/// Two-column layout: left sidebar with report list, right content with
/// detail view showing report status, platform, and external links.

open Model
open Msg
open Tea.Html

/// Render a report status badge.
let statusBadge = (status: reportStatus): Tea_Vdom.t<msg> => {
  let (color, label) = switch status {
  | ReportFiled => ("text-blue-400", "Filed")
  | ReportAcknowledged => ("text-cyan-400", "Ack")
  | ReportInProgress => ("text-amber-400", "In Progress")
  | ReportResolved => ("text-green-400", "Resolved")
  | ReportClosed => ("text-gray-400", "Closed")
  | ReportWontFix => ("text-red-400", "Won't Fix")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Render a report row in the sidebar.
let reportRow = (report: feedbackReport, selected: bool): Tea_Vdom.t<msg> => {
  button(
    list{
      Attrs.class_(
        "w-full text-left px-3 py-2 border-b border-gray-800 hover:bg-gray-800/60 transition-colors " ++ if (
          selected
        ) {
          "bg-gray-800/80 border-l-2 border-l-blue-500"
        } else {
          ""
        },
      ),
      Events.onClick(FeedbackRouting(SelectReport(report.reportId))),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between")},
        list{
          span(list{Attrs.class_("text-sm text-gray-200 truncate")}, list{text(report.title)}),
          statusBadge(report.status),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-500 mt-0.5")},
        list{
          text(`${FeedbackRoutingEngine.platformLabel(report.platform)} | ${report.targetRepo}`),
        },
      ),
    },
  )
}

/// Render a tab button.
let tabBtn = (current: feedbackRoutingTab, target: feedbackRoutingTab, label: string): Tea_Vdom.t<
  msg,
> => {
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
      Events.onClick(FeedbackRouting(SetTab(target))),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Main view function for the Feedback Routing panel.
let view = (state: feedbackRoutingState): Tea_Vdom.t<msg> => {
  let openCount = FeedbackRoutingEngine.openReportCount(state.reports)
  let total = Array.length(state.reports)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Feedback Routing — Upstream Bug Report Status"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-bold text-pink-300")},
                list{text("Feedback Routing")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(`${Int.toString(openCount)} open / ${Int.toString(total)} total`)},
              ),
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs rounded bg-green-700 text-white hover:bg-green-600"),
              Events.onClick(FeedbackRouting(RefreshReports)),
            },
            list{
              text(
                if state.refreshing {
                  "Refreshing..."
                } else {
                  "Refresh"
                },
              ),
            },
          ),
        },
      ),
      // Tabs
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800"), Attrs.role("tablist")},
        FeedbackRoutingEngine.allTabs
        ->Array.map(t => tabBtn(state.activeTab, t, FeedbackRoutingEngine.tabLabel(t)))
        ->List.fromArray,
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200",
            ),
          },
          list{text(err)},
        )
      | None => noNode
      },
      // Two-column layout
      div(
        list{Attrs.class_("flex flex-1 overflow-hidden")},
        list{
          // Left sidebar
          div(
            list{Attrs.class_("w-72 border-r border-gray-800 overflow-y-auto")},
            state.reports
            ->Array.map(r => reportRow(r, state.selectedReport == Some(r.reportId)))
            ->List.fromArray,
          ),
          // Right content
          div(
            list{Attrs.class_("flex-1 overflow-y-auto px-4 py-2")},
            list{
              switch state.selectedReport {
              | None =>
                div(
                  list{Attrs.class_("flex items-center justify-center h-full text-gray-600")},
                  list{text("Select a report to view details")},
                )
              | Some(reportId) =>
                switch state.reports->Array.find(r => r.reportId == reportId) {
                | None => div(list{}, list{text("Report not found")})
                | Some(report) =>
                  div(
                    list{},
                    list{
                      h3(
                        list{Attrs.class_("text-md font-semibold text-gray-200 mb-3")},
                        list{text(report.title)},
                      ),
                      div(
                        list{Attrs.class_("space-y-2")},
                        list{
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-28")},
                                list{text("Status:")},
                              ),
                              statusBadge(report.status),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-28")},
                                list{text("Platform:")},
                              ),
                              span(
                                list{Attrs.class_("text-xs text-gray-300")},
                                list{text(FeedbackRoutingEngine.platformLabel(report.platform))},
                              ),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-28")},
                                list{text("Target:")},
                              ),
                              span(
                                list{Attrs.class_("text-xs text-gray-300")},
                                list{text(report.targetRepo)},
                              ),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-28")},
                                list{text("Filed:")},
                              ),
                              span(
                                list{Attrs.class_("text-xs text-gray-300 font-mono")},
                                list{text(report.dateFiled)},
                              ),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-28")},
                                list{text("Last Updated:")},
                              ),
                              span(
                                list{Attrs.class_("text-xs text-gray-300 font-mono")},
                                list{text(report.lastUpdated)},
                              ),
                            },
                          ),
                          switch report.externalUrl {
                          | Some(url) =>
                            div(
                              list{Attrs.class_("flex items-center gap-2")},
                              list{
                                span(
                                  list{Attrs.class_("text-xs text-gray-500 w-28")},
                                  list{text("URL:")},
                                ),
                                span(
                                  list{Attrs.class_("text-xs text-blue-400 font-mono truncate")},
                                  list{text(url)},
                                ),
                              },
                            )
                          | None => noNode
                          },
                        },
                      ),
                    },
                  )
                }
              },
            },
          ),
        },
      ),
      // Footer
      div(
        list{Attrs.class_("px-4 py-2 border-t border-gray-800 text-xs text-gray-500")},
        list{text(`${Int.toString(Array.length(state.platformStats))} platforms tracked`)},
      ),
    },
  )
}
