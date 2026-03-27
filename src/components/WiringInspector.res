// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Constraint Audit Dashboard — Phase 5 Audit & Operator Trust.
///
/// Upgraded from the original Wiring Inspector panel to a full audit
/// dashboard. Shows lifecycle state distribution, health scores,
/// bottleneck analysis, and per-state panel breakdowns using PCC
/// constraint data.
///
/// Tabs: Overview | By State | Bottlenecks | History
///
/// Layout:
///   - Header: title, health badge, Run Audit button, Close button
///   - Tab bar: four audit tabs with active indicator
///   - Content: tab-specific sub-views
///
/// Uses Tea_Html pattern (NOT JSX): div(list{attrs}, list{children})

open Model
open Msg
open Tea.Html

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Health score badge
// ════════════════════════════════════════════════════════════════════════

/// Render the health score as a coloured badge.
let renderHealthBadge = (dist: stateDistribution): Tea_Vdom.t<msg> => {
  let score = WiringInspectorEngine.healthScore(dist)
  let colorClass = WiringInspectorEngine.healthScoreColor(score)
  let bgClass = WiringInspectorEngine.healthScoreBgColor(score)
  span(
    list{
      Attrs.class_(`text-sm font-medium px-3 py-1 rounded border ${colorClass} ${bgClass}`),
      Attrs.ariaLabel(`Health score: ${Int.toString(score)} percent`),
    },
    list{text(`${Int.toString(score)}% healthy`)},
  )
}

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Repairability badge
// ════════════════════════════════════════════════════════════════════════

/// Render a repairability badge.
let repairBadge = (r: WiringInspectorModel.repairability): Tea_Vdom.t<msg> =>
  span(
    list{
      Attrs.class_(
        `text-xs px-1.5 py-0.5 rounded ${WiringInspectorEngine.repairabilityColor(
            r,
          )} bg-gray-800 border border-gray-700`,
      ),
    },
    list{text(WiringInspectorEngine.repairabilityLabel(r))},
  )

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Header bar
// ════════════════════════════════════════════════════════════════════════

/// Render the top header with title, health badge, timestamp, and action buttons.
let renderHeader = (state: wiringInspectorState): Tea_Vdom.t<msg> =>
  div(
    list{
      Attrs.class_("flex items-center justify-between px-6 py-4 border-b border-gray-800"),
      Attrs.role("banner"),
    },
    list{
      div(
        list{Attrs.class_("flex items-center gap-4")},
        list{
          span(
            list{Attrs.class_("text-lg font-medium text-gray-200")},
            list{text("Constraint Audit Dashboard")},
          ),
          // Health score badge (only when results exist)
          if Array.length(state.results) > 0 {
            renderHealthBadge(state.distribution)
          } else {
            noNode
          },
          // Last run timestamp
          switch state.lastRunAt {
          | Some(ts) =>
            span(list{Attrs.class_("text-xs text-gray-500")}, list{text(`Last run: ${ts}`)})
          | None => noNode
          },
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          // Run Audit button
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-500 transition-colors text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed",
              ),
              Events.onClick(WiringInspector(RunVerification)),
              Attrs.disabled(state.loading),
              Attrs.ariaLabel("Run PCC audit against all panel contracts"),
            },
            list{
              text(
                if state.loading {
                  "Auditing..."
                } else {
                  "Run Audit"
                },
              ),
            },
          ),
          // Close button
          button(
            list{
              Attrs.class_(
                "px-3 py-2 bg-gray-800 text-gray-300 rounded hover:bg-gray-700 transition-colors text-sm",
              ),
              Events.onClick(PanelSwitcher(ClosePanels)),
              Attrs.ariaLabel("Close Constraint Audit Dashboard"),
            },
            list{text("Close")},
          ),
        },
      ),
    },
  )

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Tab bar
// ════════════════════════════════════════════════════════════════════════

/// Render the tab bar with four audit tabs.
let renderTabBar = (activeTab: auditTab): Tea_Vdom.t<msg> => {
  let allTabs: array<auditTab> = [Overview, ByState, Bottlenecks, History]
  div(
    list{
      Attrs.class_("flex border-b border-gray-800 px-6"),
      Attrs.role("tablist"),
      Attrs.ariaLabel("Audit dashboard tabs"),
    },
    allTabs
    ->Array.map(tab => {
      let isActive = tab == activeTab
      let label = WiringInspectorEngine.tabLabel(tab)
      button(
        list{
          Attrs.class_(
            `px-4 py-2.5 text-sm font-medium transition-colors border-b-2 -mb-px ${if isActive {
                "text-indigo-400 border-indigo-500"
              } else {
                "text-gray-500 border-transparent hover:text-gray-300 hover:border-gray-600"
              }}`,
          ),
          Events.onClick(WiringInspector(SetAuditTab(tab))),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Attrs.ariaLabel(`${label} tab`),
        },
        list{text(label)},
      )
    })
    ->List.fromArray,
  )
}

// ════════════════════════════════════════════════════════════════════════
// Sub-view: State distribution bar
// ════════════════════════════════════════════════════════════════════════

/// Render a single segment of the stacked state distribution bar.
let renderSegment = (
  label: string,
  count: int,
  total: int,
  colorClass: string,
  bgClass: string,
): Tea_Vdom.t<msg> => {
  if count == 0 || total == 0 {
    noNode
  } else {
    let pct = Int.toFloat(count) *. 100.0 /. Int.toFloat(total)
    let widthStr = Float.toString(pct)
    div(
      list{
        Attrs.class_(
          `${bgClass} flex items-center justify-center py-2 text-xs font-medium ${colorClass} overflow-hidden`,
        ),
        Attrs.style("width", `${widthStr}%`),
        Attrs.ariaLabel(`${label}: ${Int.toString(count)} panels`),
      },
      list{
        if pct > 8.0 {
          text(`${label} ${Int.toString(count)}`)
        } else if pct > 3.0 {
          text(Int.toString(count))
        } else {
          noNode
        },
      },
    )
  }
}

/// Render the full horizontal stacked distribution bar.
let renderDistributionBar = (dist: stateDistribution): Tea_Vdom.t<msg> =>
  div(
    list{
      Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg p-4 mb-4"),
      Attrs.ariaLabel("Panel state distribution"),
    },
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-3")},
        list{text("State Distribution")},
      ),
      div(
        list{Attrs.class_("flex rounded overflow-hidden border border-gray-700")},
        list{
          renderSegment(
            "Releasable",
            dist.releasable,
            dist.total,
            "text-green-300",
            "bg-green-800/60",
          ),
          renderSegment("Viable", dist.viable, dist.total, "text-cyan-300", "bg-cyan-800/60"),
          renderSegment("Wired", dist.wired, dist.total, "text-blue-300", "bg-blue-800/60"),
          renderSegment("Draft", dist.draft, dist.total, "text-yellow-300", "bg-yellow-800/60"),
          renderSegment("Broken", dist.broken, dist.total, "text-red-300", "bg-red-800/60"),
        },
      ),
      // Legend
      div(
        list{Attrs.class_("flex gap-4 mt-3 text-xs text-gray-500 flex-wrap")},
        list{
          span(
            list{},
            list{
              span(
                list{Attrs.class_("inline-block w-2 h-2 rounded-full bg-green-500 mr-1")},
                list{},
              ),
              text(`Releasable (${Int.toString(dist.releasable)})`),
            },
          ),
          span(
            list{},
            list{
              span(
                list{Attrs.class_("inline-block w-2 h-2 rounded-full bg-cyan-500 mr-1")},
                list{},
              ),
              text(`Viable (${Int.toString(dist.viable)})`),
            },
          ),
          span(
            list{},
            list{
              span(
                list{Attrs.class_("inline-block w-2 h-2 rounded-full bg-blue-500 mr-1")},
                list{},
              ),
              text(`Wired (${Int.toString(dist.wired)})`),
            },
          ),
          span(
            list{},
            list{
              span(
                list{Attrs.class_("inline-block w-2 h-2 rounded-full bg-yellow-500 mr-1")},
                list{},
              ),
              text(`Draft (${Int.toString(dist.draft)})`),
            },
          ),
          span(
            list{},
            list{
              span(list{Attrs.class_("inline-block w-2 h-2 rounded-full bg-red-500 mr-1")}, list{}),
              text(`Broken (${Int.toString(dist.broken)})`),
            },
          ),
        },
      ),
    },
  )

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Quick stats grid
// ════════════════════════════════════════════════════════════════════════

/// Render a single quick stat card.
let statCard = (label: string, count: int, colorClass: string): Tea_Vdom.t<msg> =>
  div(
    list{
      Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg p-4 flex-1"),
      Attrs.role("status"),
      Attrs.ariaLabel(`${label}: ${Int.toString(count)}`),
    },
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-1")},
        list{text(label)},
      ),
      div(list{Attrs.class_(`text-2xl font-light ${colorClass}`)}, list{text(Int.toString(count))}),
    },
  )

/// Render the four quick stat cards.
let renderQuickStats = (dist: stateDistribution): Tea_Vdom.t<msg> =>
  div(
    list{Attrs.class_("grid grid-cols-4 gap-3 mb-4")},
    list{
      statCard("Total Panels", dist.total, "text-gray-200"),
      statCard("Releasable", dist.releasable, "text-green-400"),
      statCard("Need Tests", dist.wired, "text-blue-400"),
      statCard("Need Attention", dist.draft + dist.broken, "text-yellow-400"),
    },
  )

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Bottleneck row
// ════════════════════════════════════════════════════════════════════════

/// Render a single bottleneck row.
let renderBottleneckRow = (bn: bottleneck): Tea_Vdom.t<msg> =>
  div(
    list{
      Attrs.class_(
        "flex items-center gap-3 py-2 px-3 rounded hover:bg-gray-800/40 text-sm border-b border-gray-800/50",
      ),
    },
    list{
      // Panel name
      span(list{Attrs.class_("text-gray-300 font-medium w-32 shrink-0")}, list{text(bn.panelId)}),
      // Obligation kind
      span(list{Attrs.class_("text-xs text-gray-600 w-20 shrink-0")}, list{text(`[${bn.kind}]`)}),
      // Blocked count
      span(
        list{Attrs.class_("text-red-400 font-mono text-xs w-20 shrink-0")},
        list{text(`blocks ${Int.toString(bn.blockedCount)}`)},
      ),
      // Repairability badge
      repairBadge(bn.repairability),
      // Message
      span(list{Attrs.class_("text-gray-400 text-xs flex-1 truncate")}, list{text(bn.message)}),
      // File
      switch bn.file {
      | Some(f) =>
        span(list{Attrs.class_("text-gray-500 text-xs font-mono truncate max-w-48")}, list{text(f)})
      | None => noNode
      },
    },
  )

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Top 5 bottlenecks card
// ════════════════════════════════════════════════════════════════════════

/// Render the top 5 bottlenecks card for the overview tab.
let renderTopBottlenecks = (bottlenecks: array<bottleneck>): Tea_Vdom.t<msg> => {
  let top5 = WiringInspectorEngine.topBottlenecks(bottlenecks, 5)
  div(
    list{
      Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg p-4 mb-4"),
      Attrs.ariaLabel("Top 5 bottlenecks"),
    },
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-3")},
        list{text("Top 5 Bottlenecks")},
      ),
      if Array.length(top5) > 0 {
        div(list{}, top5->Array.map(renderBottleneckRow)->List.fromArray)
      } else {
        div(
          list{Attrs.class_("text-gray-600 text-sm py-4 text-center")},
          list{text("No bottlenecks found")},
        )
      },
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Overview tab
// ════════════════════════════════════════════════════════════════════════

/// Render the Overview tab content.
let renderOverviewTab = (state: wiringInspectorState): Tea_Vdom.t<msg> => {
  let dist = state.distribution
  let score = WiringInspectorEngine.healthScore(dist)
  let colorClass = WiringInspectorEngine.healthScoreColor(score)
  div(
    list{Attrs.role("tabpanel"), Attrs.ariaLabel("Overview tab content")},
    list{
      // Large health score display
      div(
        list{Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg p-6 mb-4 text-center")},
        list{
          div(
            list{Attrs.class_(`text-5xl font-light ${colorClass} mb-2`)},
            list{text(`${Int.toString(score)}%`)},
          ),
          div(
            list{Attrs.class_("text-gray-500 text-sm uppercase tracking-wider")},
            list{text("Healthy")},
          ),
        },
      ),
      // State distribution bar
      renderDistributionBar(dist),
      // Top 5 bottlenecks
      renderTopBottlenecks(state.bottlenecks),
      // Quick stats
      renderQuickStats(dist),
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Sub-view: By State tab
// ════════════════════════════════════════════════════════════════════════

/// Render a single panel row within a state section.
let renderStatePanelRow = (v: panelVerification): Tea_Vdom.t<msg> =>
  div(
    list{Attrs.class_("flex items-center gap-3 py-2 px-3 text-sm hover:bg-gray-800/40 rounded")},
    list{
      // Panel name
      span(list{Attrs.class_("text-gray-200 font-medium w-40 shrink-0")}, list{text(v.panelId)}),
      // Obligation summary
      span(
        list{Attrs.class_("text-gray-500 text-xs w-24 shrink-0")},
        list{text(`${Int.toString(v.satisfied)}/${Int.toString(v.total)} satisfied`)},
      ),
      // Primary bottleneck
      switch v.primaryBottleneck {
      | Some(bn) =>
        span(list{Attrs.class_("text-red-400 text-xs")}, list{text(`Bottleneck: ${bn}`)})
      | None => noNode
      },
      // Next requirement
      switch v.policy.nextRequirement {
      | Some(req) =>
        span(list{Attrs.class_("text-amber-400 text-xs ml-auto")}, list{text(`Next: ${req}`)})
      | None => noNode
      },
    },
  )

/// Render a collapsible section for a single lifecycle state.
let renderStateSection = (
  state: panelState,
  panels: array<panelVerification>,
  isExpanded: bool,
): Tea_Vdom.t<msg> => {
  let label = WiringInspectorEngine.stateLabel(state)
  let colorClass = WiringInspectorEngine.stateColor(state)
  let bgClass = WiringInspectorEngine.stateBgColor(state)
  let borderClass = WiringInspectorEngine.stateBorderColor(state)
  let count = Array.length(panels)
  div(
    list{Attrs.class_("mb-2 rounded-lg overflow-hidden border border-gray-800")},
    list{
      // Section header — clickable to expand/collapse
      button(
        list{
          Attrs.class_(
            `w-full text-left px-4 py-3 flex items-center justify-between ${bgClass} hover:opacity-90 transition-opacity`,
          ),
          Events.onClick(WiringInspector(ToggleStateSection(state))),
          Attrs.ariaExpanded(isExpanded),
          Attrs.ariaLabel(`${label} section, ${Int.toString(count)} panels`),
          Attrs.role("button"),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(list{Attrs.class_(`font-medium ${colorClass}`)}, list{text(label)}),
              span(
                list{
                  Attrs.class_(`text-xs px-2 py-0.5 rounded border ${borderClass} ${colorClass}`),
                },
                list{text(Int.toString(count))},
              ),
            },
          ),
          span(
            list{Attrs.class_("text-gray-500 text-sm")},
            list{
              text(
                if isExpanded {
                  "[-]"
                } else {
                  "[+]"
                },
              ),
            },
          ),
        },
      ),
      // Expanded panel list
      if isExpanded && count > 0 {
        div(
          list{Attrs.class_("bg-gray-950/40 px-2 py-1 space-y-0.5")},
          panels->Array.map(renderStatePanelRow)->List.fromArray,
        )
      } else if isExpanded {
        div(
          list{Attrs.class_("bg-gray-950/40 px-4 py-3 text-gray-600 text-sm text-center")},
          list{text("No panels in this state")},
        )
      } else {
        noNode
      },
    },
  )
}

/// Render the By State tab with five collapsible sections.
let renderByStateTab = (state: wiringInspectorState): Tea_Vdom.t<msg> => {
  let results = state.results
  let allStates: array<panelState> = [Releasable, Viable, Wired, Draft, Broken]
  div(
    list{Attrs.role("tabpanel"), Attrs.ariaLabel("By State tab content")},
    allStates
    ->Array.map(panelState => {
      let panels = WiringInspectorEngine.panelsByState(results, panelState)
      let sectionId = WiringInspectorEngine.stateLabel(panelState)
      let isExpanded = state.selectedPanel == Some(sectionId)
      renderStateSection(panelState, panels, isExpanded)
    })
    ->List.fromArray,
  )
}

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Bottlenecks tab
// ════════════════════════════════════════════════════════════════════════

/// Render the full bottleneck table header.
let renderBottleneckHeader = (): Tea_Vdom.t<msg> =>
  div(
    list{
      Attrs.class_(
        "flex items-center gap-3 py-2 px-3 text-xs text-gray-500 uppercase tracking-wider border-b border-gray-700 font-medium",
      ),
      Attrs.role("row"),
    },
    list{
      span(list{Attrs.class_("w-32 shrink-0")}, list{text("Panel")}),
      span(list{Attrs.class_("w-40 shrink-0")}, list{text("Obligation")}),
      span(list{Attrs.class_("w-20 shrink-0")}, list{text("Kind")}),
      span(list{Attrs.class_("w-20 shrink-0")}, list{text("Blocked")}),
      span(list{Attrs.class_("w-16 shrink-0")}, list{text("Repair")}),
      span(list{Attrs.class_("flex-1")}, list{text("Message")}),
      span(list{Attrs.class_("w-48 shrink-0")}, list{text("File")}),
    },
  )

/// Render a full bottleneck table row (more detailed than the overview row).
let renderFullBottleneckRow = (bn: bottleneck): Tea_Vdom.t<msg> =>
  div(
    list{
      Attrs.class_(
        "flex items-center gap-3 py-2 px-3 text-sm hover:bg-gray-800/40 border-b border-gray-800/50",
      ),
      Attrs.role("row"),
    },
    list{
      span(list{Attrs.class_("text-gray-300 font-medium w-32 shrink-0")}, list{text(bn.panelId)}),
      span(
        list{Attrs.class_("text-gray-200 font-mono text-xs w-40 shrink-0 truncate")},
        list{text(bn.obligationId)},
      ),
      span(list{Attrs.class_("text-gray-600 text-xs w-20 shrink-0")}, list{text(bn.kind)}),
      span(
        list{Attrs.class_("text-red-400 font-mono text-xs w-20 shrink-0")},
        list{text(Int.toString(bn.blockedCount))},
      ),
      span(list{Attrs.class_("w-16 shrink-0")}, list{repairBadge(bn.repairability)}),
      span(list{Attrs.class_("text-gray-400 text-xs flex-1 truncate")}, list{text(bn.message)}),
      switch bn.file {
      | Some(f) =>
        span(
          list{Attrs.class_("text-gray-500 text-xs font-mono w-48 shrink-0 truncate")},
          list{text(f)},
        )
      | None => span(list{Attrs.class_("w-48 shrink-0")}, list{})
      },
    },
  )

/// Render the filter bar for the bottleneck table.
let renderBottleneckFilterBar = (state: wiringInspectorState): Tea_Vdom.t<msg> => {
  let kindChip = (label: string, value: option<string>, isActive: bool) =>
    button(
      list{
        Attrs.class_(
          `px-3 py-1 text-xs rounded-full border transition-colors ${if isActive {
              "bg-indigo-600 border-indigo-500 text-white"
            } else {
              "bg-gray-800 border-gray-700 text-gray-400 hover:bg-gray-700"
            }}`,
        ),
        Events.onClick(WiringInspector(SetFilterStatus(value))),
        Attrs.ariaLabel(`Filter by: ${label}`),
      },
      list{text(label)},
    )
  div(
    list{Attrs.class_("flex items-center gap-2 mb-3 flex-wrap")},
    list{
      span(list{Attrs.class_("text-xs text-gray-500 mr-1")}, list{text("Filter:")}),
      kindChip("All", None, state.filterStatus == None),
      kindChip("Registry", Some("registry"), state.filterStatus == Some("registry")),
      kindChip("Model", Some("model"), state.filterStatus == Some("model")),
      kindChip("Msg", Some("msg"), state.filterStatus == Some("msg")),
      kindChip("View", Some("view"), state.filterStatus == Some("view")),
      kindChip("Test", Some("test"), state.filterStatus == Some("test")),
      span(list{Attrs.class_("border-l border-gray-700 h-4 mx-1")}, list{}),
      kindChip("Safe", Some("safe"), state.filterStatus == Some("safe")),
      kindChip("Unsafe", Some("unsafe"), state.filterStatus == Some("unsafe")),
      kindChip("Manual", Some("manual"), state.filterStatus == Some("manual")),
    },
  )
}

/// Apply bottleneck filters to the full list.
let filterBottlenecks = (bottlenecks: array<bottleneck>, filterStatus: option<string>): array<
  bottleneck,
> =>
  switch filterStatus {
  | None => bottlenecks
  | Some("safe") => bottlenecks->Array.filter(bn => bn.repairability == Safe)
  | Some("unsafe") => bottlenecks->Array.filter(bn => bn.repairability == Unsafe)
  | Some("manual") => bottlenecks->Array.filter(bn => bn.repairability == Manual)
  | Some(kind) => bottlenecks->Array.filter(bn => bn.kind == kind)
  }

/// Render the Bottlenecks tab with the full table.
let renderBottlenecksTab = (state: wiringInspectorState): Tea_Vdom.t<msg> => {
  let filtered = filterBottlenecks(state.bottlenecks, state.filterStatus)
  div(
    list{Attrs.role("tabpanel"), Attrs.ariaLabel("Bottlenecks tab content")},
    list{
      renderBottleneckFilterBar(state),
      div(
        list{
          Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg overflow-hidden"),
          Attrs.role("table"),
          Attrs.ariaLabel("Bottleneck obligations table"),
        },
        list{
          renderBottleneckHeader(),
          if Array.length(filtered) > 0 {
            div(
              list{Attrs.role("rowgroup")},
              filtered->Array.map(renderFullBottleneckRow)->List.fromArray,
            )
          } else {
            div(
              list{Attrs.class_("text-gray-600 text-sm py-8 text-center")},
              list{text("No bottlenecks match the current filter")},
            )
          },
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-600 mt-2 text-right")},
        list{
          text(
            `${Int.toString(Array.length(filtered))} of ${Int.toString(
                Array.length(state.bottlenecks),
              )} bottlenecks shown`,
          ),
        },
      ),
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Sub-view: History tab (placeholder)
// ════════════════════════════════════════════════════════════════════════

/// Render the History tab placeholder.
let renderHistoryTab = (): Tea_Vdom.t<msg> =>
  div(
    list{
      Attrs.class_("text-center py-16"),
      Attrs.role("tabpanel"),
      Attrs.ariaLabel("History tab content"),
    },
    list{
      div(list{Attrs.class_("text-gray-500 text-lg mb-2")}, list{text("Coming soon")}),
      div(
        list{Attrs.class_("text-gray-600 text-sm")},
        list{text("Audit history tracking will show how panel health evolves over time.")},
      ),
    },
  )

// ════════════════════════════════════════════════════════════════════════
// Main view
// ════════════════════════════════════════════════════════════════════════

/// Main Constraint Audit Dashboard panel view (Phase 5).
let view = (state: wiringInspectorState): Tea_Vdom.t<msg> =>
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950 overflow-auto z-50"),
      Attrs.role("region"),
      Attrs.ariaLabel("Constraint Audit Dashboard"),
    },
    list{
      // Header bar
      renderHeader(state),
      // Tab bar
      renderTabBar(state.activeTab),
      // Content area
      div(
        list{Attrs.class_("max-w-6xl mx-auto px-6 py-6")},
        list{
          // Error banner
          switch state.error {
          | Some(err) =>
            div(
              list{
                Attrs.class_(
                  "bg-red-900/30 border border-red-800 text-red-300 rounded-lg p-4 mb-4",
                ),
                Attrs.role("alert"),
              },
              list{
                div(list{Attrs.class_("font-medium mb-1")}, list{text("Audit Error")}),
                div(list{Attrs.class_("text-sm")}, list{text(err)}),
              },
            )
          | None => noNode
          },
          // Loading spinner
          if state.loading {
            div(
              list{
                Attrs.class_("flex items-center justify-center py-12"),
                Attrs.role("status"),
                Attrs.ariaLabel("Audit in progress"),
              },
              list{
                div(
                  list{
                    Attrs.class_(
                      "animate-spin w-8 h-8 border-2 border-gray-700 border-t-indigo-500 rounded-full",
                    ),
                  },
                  list{},
                ),
                span(
                  list{Attrs.class_("ml-3 text-gray-400")},
                  list{text("Running constraint audit...")},
                ),
              },
            )
          } else if Array.length(state.results) == 0 {
            // Empty state
            div(
              list{Attrs.class_("text-center py-16")},
              list{
                div(
                  list{Attrs.class_("text-gray-500 text-lg mb-2")},
                  list{text("No audit results")},
                ),
                div(
                  list{Attrs.class_("text-gray-600 text-sm")},
                  list{text("Click \"Run Audit\" to check all panel contracts with PCC.")},
                ),
              },
            )
          } else {
            // Tab content
            switch state.activeTab {
            | Overview => renderOverviewTab(state)
            | ByState => renderByStateTab(state)
            | Bottlenecks => renderBottlenecksTab(state)
            | History => renderHistoryTab()
            }
          },
        },
      ),
    },
  )
