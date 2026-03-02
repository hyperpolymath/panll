// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Reposystem Component — RSR compliance dashboard.
///
/// Renders compliance rates per requirement (the "known audit" data:
/// .editorconfig 96.9%, STATE.scm 94.3%, AI manifest 34.7%, Justfile 28.3%,
/// TOPOLOGY.md 1.5%), per-repo audit tables, and language policy status.

open Model
open Msg
open Tea.Html

/// Render a compliance rate bar for a single RSR requirement.
let renderRequirementBar = (req: rsrRequirement, rate: float, count: int, total: int): Tea_Vdom.t<msg> => {
  let label = ReposystemEngine.requirementLabel(req)
  let pct = Float.toFixedWithPrecision(rate *. 100.0, ~digits=1)
  let barColor = if rate > 0.9 {
    "bg-green-500"
  } else if rate > 0.5 {
    "bg-amber-500"
  } else {
    "bg-red-500"
  }

  div(
    list{
      Attrs.class_("flex items-center gap-3 mb-2"),
      Attrs.role("meter"),
      Attrs.ariaLabel(`${label}: ${pct}% compliance`),
    },
    list{
      div(
        list{Attrs.class_("w-36 text-sm text-gray-300 text-right")},
        list{text(label)},
      ),
      div(
        list{Attrs.class_("flex-1 bg-gray-800 rounded-full h-3")},
        list{
          div(
            list{
              Attrs.class_(`${barColor} h-full rounded-full transition-all`),
              Attrs.prop("style", `width: ${pct}%`),
            },
            list{},
          ),
        },
      ),
      div(
        list{Attrs.class_("w-20 text-xs text-gray-400 text-right")},
        list{text(`${Int.toString(count)}/${Int.toString(total)}`)},
      ),
      div(
        list{Attrs.class_("w-14 text-xs text-gray-500 text-right")},
        list{text(`${pct}%`)},
      ),
    },
  )
}

/// Render a repo compliance row.
let renderRepoRow = (audit: repoCompliance): Tea_Vdom.t<msg> => {
  let scorePct = Float.toFixedWithPrecision(audit.score *. 100.0, ~digits=0)
  let scoreColor = if audit.score >= 1.0 {
    "text-green-400"
  } else if audit.score > 0.6 {
    "text-amber-400"
  } else {
    "text-red-400"
  }

  div(
    list{
      Attrs.class_("flex items-center gap-4 p-2 border-b border-gray-800 hover:bg-gray-900/50"),
      Attrs.role("row"),
    },
    list{
      span(list{Attrs.class_(`text-sm font-mono ${scoreColor} w-12 text-right`)}, list{text(`${scorePct}%`)}),
      span(list{Attrs.class_("text-sm text-gray-300 flex-1 truncate")}, list{text(audit.repoName)}),
      span(
        list{Attrs.class_("text-xs text-gray-500 w-24 text-right")},
        list{text(`${Int.toString(audit.metCount)}/${Int.toString(audit.totalCount)}`)},
      ),
    },
  )
}

/// Render category tabs.
let renderTabs = (active: reposystemCategory): Tea_Vdom.t<msg> => {
  let tabs: array<reposystemCategory> = [RsrDashboard, RsrRepoList, RsrRequirements, RsrLanguagePolicy]
  div(
    list{
      Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"),
      Attrs.role("tablist"),
    },
    tabs->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-cyan-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(Reposystem(SetRsrCategory(tab))),
        },
        list{text(ReposystemEngine.categoryLabel(tab))},
      )
    })->List.fromArray,
  )
}

/// Main view for the Reposystem panel.
let view = (rsr: reposystemState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Reposystem RSR compliance panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-medium text-gray-200")}, list{text("Reposystem")}),
              span(list{Attrs.class_("text-xs text-gray-500")}, list{text("RSR compliance across 265+ repos")}),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              button(
                list{
                  Attrs.class_("px-3 py-1 text-xs bg-cyan-600 text-white rounded hover:bg-cyan-500"),
                  Events.onClick(Reposystem(ScanAll)),
                },
                list{text("Scan All")},
              ),
              button(
                list{
                  Attrs.class_("px-3 py-1 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700"),
                  Events.onClick(PanelSwitcher(ClosePanels)),
                },
                list{text("Close")},
              ),
            },
          ),
        },
      ),
      // Content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-6")},
        list{
          if rsr.loading {
            div(list{Attrs.class_("text-gray-400"), Attrs.role("status")}, list{text("Scanning repositories...")})
          } else if !rsr.loaded {
            div(
              list{Attrs.class_("text-center text-gray-500 mt-12")},
              list{
                div(list{Attrs.class_("text-4xl mb-2")}, list{text("Reposystem")}),
                div(list{Attrs.class_("text-sm mb-6")}, list{text("Rhodium Standard Repository compliance auditing")}),
                button(
                  list{
                    Attrs.class_("px-4 py-2 bg-cyan-600 text-white rounded hover:bg-cyan-500"),
                    Events.onClick(Reposystem(ScanAll)),
                  },
                  list{text("Run Compliance Scan")},
                ),
              },
            )
          } else {
            div(
              list{Attrs.class_("space-y-4")},
              list{
                renderTabs(rsr.activeCategory),
                switch rsr.activeCategory {
                | RsrDashboard =>
                  switch rsr.stats {
                  | Some(stats) =>
                    div(
                      list{Attrs.class_("space-y-6")},
                      list{
                        // Summary
                        div(
                          list{Attrs.class_("flex gap-6 text-sm")},
                          list{
                            div(list{Attrs.class_("text-gray-400")}, list{text(`${Int.toString(stats.totalRepos)} repos audited`)}),
                            div(list{Attrs.class_("text-gray-400")}, list{text(`${Float.toFixedWithPrecision(stats.avgScore *. 100.0, ~digits=1)}% avg compliance`)}),
                            div(list{Attrs.class_("text-green-400")}, list{text(`${Int.toString(stats.fullyCompliant)} fully compliant`)}),
                          },
                        ),
                        // Requirement bars
                        div(
                          list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4")},
                          list{
                            div(list{Attrs.class_("text-sm font-medium text-gray-300 mb-4")}, list{text("Per-Requirement Compliance")}),
                            div(
                              list{},
                              stats.requirementRates->Array.map(((req, rate, count)) =>
                                renderRequirementBar(req, rate, count, stats.totalRepos)
                              )->List.fromArray,
                            ),
                          },
                        ),
                      },
                    )
                  | None => div(list{Attrs.class_("text-gray-500")}, list{text("No stats available")})
                  }
                | RsrRepoList => {
                    let filtered = ReposystemEngine.filterAudits(rsr.audits, rsr.filterText)
                    div(
                      list{Attrs.class_("space-y-4")},
                      list{
                        input(
                          list{
                            Attrs.class_("w-full bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 placeholder-gray-600"),
                            Attrs.placeholder("Filter repos..."),
                            Attrs.value(rsr.filterText),
                            Events.onInput(v => Reposystem(SetRsrFilter(v))),
                          },
                          list{},
                        ),
                        div(
                          list{Attrs.class_("border border-gray-700 rounded-lg overflow-hidden")},
                          list{
                            div(
                              list{Attrs.class_("max-h-96 overflow-y-auto")},
                              filtered->Array.map(a => renderRepoRow(a))->List.fromArray,
                            ),
                          },
                        ),
                      },
                    )
                  }
                | RsrRequirements =>
                  div(list{Attrs.class_("text-gray-500 text-sm")}, list{text("Per-requirement breakdown — run scan to populate")})
                | RsrLanguagePolicy =>
                  div(list{Attrs.class_("text-gray-500 text-sm")}, list{text("Language policy violations — TypeScript, npm, Go, Python detection")})
                },
              },
            )
          },
          switch rsr.error {
          | Some(e) => div(list{Attrs.class_("mt-4 p-3 bg-red-900/30 border border-red-700 rounded text-sm text-red-300"), Attrs.role("alert")}, list{text(e)})
          | None => noNode
          },
        },
      ),
    },
  )
}
