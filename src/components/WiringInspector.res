// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Wiring Inspector Panel — constraint-aware panel wiring verification.
///
/// Surfaces the Panel Contract Compiler's (PCC) constraint state inside
/// the PanLL UI. Shows per-panel obligation status, failure classification,
/// bottleneck analysis, and dependency graphs. Follows the DD-004 8-file
/// panel pattern.
///
/// Layout: Header bar, Summary cards, Filter bar, Panel cards with
/// expandable detail views showing obligation lists and dependency info.

open Model
open Msg
open Tea.Html

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Status icon helpers
// ════════════════════════════════════════════════════════════════════════

/// Render a status icon for an obligation.
let statusIcon = (status: WiringInspectorModel.obligationStatus): Tea_Vdom.t<msg> =>
  switch status {
  | Satisfied =>
    span(
      list{Attrs.class_("text-green-400 font-bold"), Attrs.ariaLabel("Satisfied")},
      list{text("[OK]")},
    )
  | Unsatisfied =>
    span(
      list{Attrs.class_("text-red-400 font-bold"), Attrs.ariaLabel("Unsatisfied")},
      list{text("[X]")},
    )
  | Blocked =>
    span(
      list{Attrs.class_("text-yellow-400 font-bold"), Attrs.ariaLabel("Blocked")},
      list{text("[!]")},
    )
  }

/// Render a repairability badge.
let repairBadge = (r: WiringInspectorModel.repairability): Tea_Vdom.t<msg> =>
  span(
    list{
      Attrs.class_(`text-xs px-1.5 py-0.5 rounded ${WiringInspectorEngine.repairabilityColor(r)} bg-gray-800 border border-gray-700`),
    },
    list{text(WiringInspectorEngine.repairabilityLabel(r))},
  )

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Summary cards
// ════════════════════════════════════════════════════════════════════════

/// Render a summary metric card.
let summaryCard = (label: string, count: int, colorClass: string): Tea_Vdom.t<msg> =>
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
      div(
        list{Attrs.class_(`text-2xl font-light ${colorClass}`)},
        list{text(Int.toString(count))},
      ),
    },
  )

/// Render the three summary cards.
let renderSummaryBar = (state: wiringInspectorState): Tea_Vdom.t<msg> => {
  let results = state.results
  div(
    list{Attrs.class_("flex gap-3 mb-4")},
    list{
      summaryCard("Total Panels", WiringInspectorEngine.totalPanels(results), "text-gray-200"),
      summaryCard("Complete", WiringInspectorEngine.completePanels(results), "text-green-400"),
      summaryCard("Incomplete", WiringInspectorEngine.incompletePanels(results), "text-red-400"),
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Filter bar
// ════════════════════════════════════════════════════════════════════════

/// Render the panel dropdown and status filter chips.
let renderFilterBar = (state: wiringInspectorState): Tea_Vdom.t<msg> => {
  let panelNames = state.results->Array.map(v => v.panelId)

  /// Render a single filter chip.
  let chip = (label: string, value: option<string>, isActive: bool) =>
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
        Attrs.ariaLabel(`Filter: ${label}`),
      },
      list{text(label)},
    )

  div(
    list{Attrs.class_("flex items-center gap-3 mb-4 flex-wrap")},
    list{
      // Panel dropdown
      select(
        list{
          Attrs.class_("bg-gray-800 text-gray-300 border border-gray-700 rounded px-3 py-1.5 text-sm"),
          Events.onChange(value =>
            WiringInspector(SelectPanel(if value == "__all__" { None } else { Some(value) }))
          ),
          Attrs.ariaLabel("Filter by panel"),
        },
        Array.concat(
          [{Tea.Html.option(list{Attrs.value("__all__")}, list{text("All Panels")})}],
          panelNames->Array.map(name =>
            Tea.Html.option(
              list{
                Attrs.value(name),
                if state.selectedPanel == Some(name) {
                  Attrs.selected(true)
                } else {
                  Attrs.noProp
                },
              },
              list{text(name)},
            )
          ),
        )->List.fromArray,
      ),
      // Status filter chips
      chip("All", None, state.filterStatus == None),
      chip("Complete", Some("Complete"), state.filterStatus == Some("Complete")),
      chip("Incomplete", Some("Incomplete"), state.filterStatus == Some("Incomplete")),
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Obligation row
// ════════════════════════════════════════════════════════════════════════

/// Render a single obligation row within a panel card.
let renderObligation = (o: WiringInspectorModel.obligation): Tea_Vdom.t<msg> => {
  let fileText = switch o.file {
  | Some(f) => f
  | None => ""
  }

  div(
    list{
      Attrs.class_("flex items-start gap-2 py-1.5 px-2 rounded hover:bg-gray-800/40 text-sm"),
    },
    list{
      // Status icon
      statusIcon(o.status),
      // Main content
      div(
        list{Attrs.class_("flex-1 min-w-0")},
        list{
          // Obligation ID and kind
          div(
            list{Attrs.class_("flex items-center gap-2 flex-wrap")},
            list{
              span(
                list{Attrs.class_("font-mono text-gray-200")},
                list{text(o.id)},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-600")},
                list{text(`[${o.kind}]`)},
              ),
              // Failure class badge for root/derived failures
              if o.failureClass != NotFailed {
                span(
                  list{
                    Attrs.class_(
                      `text-xs px-1.5 py-0.5 rounded ${if o.failureClass == Root {
                          "text-red-300 bg-red-900/30 border border-red-800"
                        } else {
                          "text-amber-300 bg-amber-900/30 border border-amber-800"
                        }}`,
                    ),
                  },
                  list{text(WiringInspectorEngine.failureClassLabel(o.failureClass))},
                )
              } else {
                noNode
              },
              // Repairability badge for non-satisfied
              if o.status != Satisfied { repairBadge(o.repairability) } else { noNode },
            },
          ),
          // Message
          if o.message != "" {
            div(
              list{Attrs.class_("text-gray-400 text-xs mt-0.5")},
              list{text(o.message)},
            )
          } else {
            noNode
          },
          // File path
          if fileText != "" {
            div(
              list{Attrs.class_("text-gray-500 text-xs font-mono mt-0.5 cursor-pointer hover:text-indigo-400")},
              list{text(fileText)},
            )
          } else {
            noNode
          },
          // Expected value
          switch o.expected {
          | Some(exp) =>
            div(
              list{Attrs.class_("text-xs text-gray-500 mt-0.5")},
              list{
                span(list{Attrs.class_("text-gray-600")}, list{text("Expected: ")}),
                span(list{Attrs.class_("font-mono text-amber-400")}, list{text(exp)}),
              },
            )
          | None => noNode
          },
          // Blocked downstream count
          if o.blockedDownstreamCount > 0 {
            div(
              list{Attrs.class_("text-xs text-red-400 mt-0.5 font-medium")},
              list{text(`Blocks ${Int.toString(o.blockedDownstreamCount)} downstream`)},
            )
          } else {
            noNode
          },
          // Dependencies
          if Array.length(o.dependsOn) > 0 && o.status == Blocked {
            div(
              list{Attrs.class_("text-xs text-yellow-500 mt-0.5")},
              list{
                text("Blocked by: "),
                span(
                  list{Attrs.class_("font-mono")},
                  list{text(o.dependsOn->Array.join(", "))},
                ),
              },
            )
          } else {
            noNode
          },
        },
      ),
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Dependency graph (text-based)
// ════════════════════════════════════════════════════════════════════════

/// Render a text-based dependency graph for a panel's obligations.
let renderDependencyGraph = (obligations: array<WiringInspectorModel.obligation>): Tea_Vdom.t<msg> =>
  div(
    list{Attrs.class_("bg-gray-900/40 border border-gray-800 rounded p-3 mt-2")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-2")},
        list{text("Dependency Graph")},
      ),
      div(
        list{Attrs.class_("font-mono text-xs space-y-1")},
        obligations
        ->Array.map(o => {
          let deps = if Array.length(o.dependsOn) > 0 {
            ` <- [${o.dependsOn->Array.join(", ")}]`
          } else {
            ""
          }
          let statusMark = switch o.status {
          | Satisfied => "[OK]"
          | Unsatisfied => "[X]"
          | Blocked => "[!]"
          }
          div(
            list{Attrs.class_(WiringInspectorEngine.statusColor(o.status))},
            list{text(`${statusMark} ${o.id}${deps}`)},
          )
        })
        ->List.fromArray,
      ),
    },
  )

// ════════════════════════════════════════════════════════════════════════
// Sub-view: Panel card
// ════════════════════════════════════════════════════════════════════════

/// Render a verification card for a single panel.
let renderPanelCard = (v: WiringInspectorModel.panelVerification, isSelected: bool): Tea_Vdom.t<msg> => {
  let complete = WiringInspectorEngine.isComplete(v)
  let statusBadgeClass = if complete {
    "bg-green-900/30 text-green-400 border-green-800"
  } else {
    "bg-red-900/30 text-red-400 border-red-800"
  }
  let statusText = if complete { "COMPLETE" } else { "INCOMPLETE" }

  div(
    list{
      Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg mb-3 overflow-hidden"),
    },
    list{
      // Card header — clickable to expand/collapse
      button(
        list{
          Attrs.class_("w-full text-left px-4 py-3 flex items-center justify-between hover:bg-gray-800/40 transition-colors"),
          Events.onClick(
            WiringInspector(
              SelectPanel(if isSelected { None } else { Some(v.panelId) }),
            ),
          ),
          Attrs.ariaLabel(`${v.panelId}: ${WiringInspectorEngine.summaryLabel(v)}`),
          Attrs.ariaExpanded(isSelected),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-gray-200 font-medium")},
                list{text(v.panelId)},
              ),
              span(
                list{Attrs.class_(`text-xs px-2 py-0.5 rounded border ${statusBadgeClass}`)},
                list{text(statusText)},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(`${Int.toString(v.satisfied)}/${Int.toString(v.total)}`)},
              ),
            },
          ),
          // Primary bottleneck indicator
          switch v.primaryBottleneck {
          | Some(bn) =>
            span(
              list{Attrs.class_("text-xs text-red-400 font-medium")},
              list{text(`Bottleneck: ${bn}`)},
            )
          | None => noNode
          },
        },
      ),
      // Expanded detail view
      if isSelected {
        div(
          list{Attrs.class_("border-t border-gray-800 px-4 py-3")},
          list{
            // Obligation list
            div(
              list{Attrs.class_("space-y-0.5")},
              v.obligations->Array.map(renderObligation)->List.fromArray,
            ),
            // Text dependency graph
            if Array.length(v.obligations) > 0 {
              renderDependencyGraph(v.obligations)
            } else {
              noNode
            },
          },
        )
      } else {
        noNode
      },
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Main view
// ════════════════════════════════════════════════════════════════════════

/// Main Wiring Inspector panel view.
let view = (state: wiringInspectorState): Tea_Vdom.t<msg> => {
  // Apply filters
  let filtered =
    state.results
    ->WiringInspectorEngine.filterByPanel(state.selectedPanel)
    ->WiringInspectorEngine.filterByStatus(state.filterStatus)

  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950 overflow-auto z-50"),
      Attrs.role("region"),
      Attrs.ariaLabel("Wiring Inspector panel"),
    },
    list{
      // Header bar
      div(
        list{Attrs.class_("flex items-center justify-between px-6 py-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-4")},
            list{
              span(
                list{Attrs.class_("text-lg font-medium text-gray-200")},
                list{text("Wiring Inspector")},
              ),
              // Last run timestamp
              switch state.lastRunAt {
              | Some(ts) =>
                span(
                  list{Attrs.class_("text-xs text-gray-500")},
                  list{text(`Last run: ${ts}`)},
                )
              | None => noNode
              },
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              // Run Verification button
              button(
                list{
                  Attrs.class_(
                    "px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-500 transition-colors text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed",
                  ),
                  Events.onClick(WiringInspector(RunVerification)),
                  Attrs.disabled(state.loading),
                  Attrs.ariaLabel("Run PCC verification against all panel contracts"),
                },
                list{text(if state.loading { "Verifying..." } else { "Run Verification" })},
              ),
              // Close button
              button(
                list{
                  Attrs.class_("px-3 py-2 bg-gray-800 text-gray-300 rounded hover:bg-gray-700 transition-colors text-sm"),
                  Events.onClick(PanelSwitcher(ClosePanels)),
                  Attrs.ariaLabel("Close Wiring Inspector panel"),
                },
                list{text("Close")},
              ),
            },
          ),
        },
      ),
      // Content area
      div(
        list{Attrs.class_("max-w-5xl mx-auto px-6 py-6")},
        list{
          // Error banner
          switch state.error {
          | Some(err) =>
            div(
              list{
                Attrs.class_("bg-red-900/30 border border-red-800 text-red-300 rounded-lg p-4 mb-4"),
                Attrs.role("alert"),
              },
              list{
                div(
                  list{Attrs.class_("font-medium mb-1")},
                  list{text("Verification Error")},
                ),
                div(
                  list{Attrs.class_("text-sm")},
                  list{text(err)},
                ),
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
                Attrs.ariaLabel("Verification in progress"),
              },
              list{
                div(
                  list{Attrs.class_("animate-spin w-8 h-8 border-2 border-gray-700 border-t-indigo-500 rounded-full")},
                  list{},
                ),
                span(list{Attrs.class_("ml-3 text-gray-400")}, list{text("Running PCC verification...")}),
              },
            )
          } else {
            noNode
          },
          // Summary cards (show when we have results)
          if Array.length(state.results) > 0 {
            renderSummaryBar(state)
          } else {
            noNode
          },
          // Filter bar (show when we have results)
          if Array.length(state.results) > 0 {
            renderFilterBar(state)
          } else {
            noNode
          },
          // Panel cards
          if Array.length(filtered) > 0 {
            div(
              list{},
              filtered
              ->Array.map(v => {
                let isSelected = state.selectedPanel == Some(v.panelId)
                renderPanelCard(v, isSelected)
              })
              ->List.fromArray,
            )
          } else if !state.loading && Array.length(state.results) == 0 {
            // Empty state
            div(
              list{Attrs.class_("text-center py-16")},
              list{
                div(
                  list{Attrs.class_("text-gray-500 text-lg mb-2")},
                  list{text("No verification results")},
                ),
                div(
                  list{Attrs.class_("text-gray-600 text-sm")},
                  list{text("Click \"Run Verification\" to check all panel contracts with PCC.")},
                ),
              },
            )
          } else {
            noNode
          },
        },
      ),
    },
  )
}
