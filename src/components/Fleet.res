// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Fleet Component — Gitbot-Fleet orchestration dashboard.
///
/// Renders the 6-bot status grid, safety triangle visualisation,
/// findings queue with filtering, and dispatch controls. Every
/// interactive element has ARIA labels and keyboard navigation.

open Model
open Msg
open Tea.Html

// ============================================================================
// Bot Status Card
// ============================================================================

/// Render a single bot status card in the fleet grid.
let renderBotCard = (bot: botState): Tea_Vdom.t<msg> => {
  let dotColor = FleetEngine.statusColor(bot.status)
  let label = FleetEngine.botLabel(bot.id)
  let desc = FleetEngine.botDescription(bot.id)
  let statusText = FleetEngine.statusLabel(bot.status)
  let icon = FleetEngine.botIcon(bot.id)

  div(
    list{
      Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4 hover:border-gray-500 transition-colors"),
      Attrs.role("article"),
      Attrs.ariaLabel(`${label} — ${statusText}`),
    },
    list{
      // Header: icon + bot name + status dot
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-1.5")},
            list{
              span(
                list{
                  Attrs.class_("text-xs text-gray-500"),
                  Attrs.prop("aria-hidden", "true"),
                },
                list{text(icon)},
              ),
              span(
                list{Attrs.class_("text-sm font-medium text-gray-200")},
                list{text(label)},
              ),
            },
          ),
          span(
            list{
              Attrs.class_(`w-2.5 h-2.5 rounded-full ${dotColor}`),
              Attrs.ariaLabel(statusText),
              Attrs.role("status"),
            },
            list{},
          ),
        },
      ),
      // Description
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-3")},
        list{text(desc)},
      ),
      // Metrics row
      div(
        list{Attrs.class_("flex justify-between text-xs")},
        list{
          div(
            list{Attrs.class_("text-gray-400")},
            list{text(`Queued: ${Int.toString(bot.queuedFindings)}`)},
          ),
          div(
            list{Attrs.class_("text-gray-400")},
            list{text(`Done: ${Int.toString(bot.processedFindings)}`)},
          ),
        },
      ),
      // Confidence threshold
      div(
        list{Attrs.class_("mt-2 text-xs text-gray-500")},
        list{text(`Threshold: ${Float.toFixed(bot.confidenceThreshold, ~digits=0)}%`)},
      ),
    },
  )
}

// ============================================================================
// Safety Triangle
// ============================================================================

/// Render the safety triangle (Eliminate / Substitute / Control) with counts.
let renderSafetyTriangle = (health: fleetHealth): Tea_Vdom.t<msg> => {
  let (elim, sub, ctrl) = health.triangleCounts
  let total = elim + sub + ctrl
  let pct = (count: int): string => {
    if total <= 0 {
      "0"
    } else {
      Float.toFixed(Int.toFloat(count) /. Int.toFloat(total) *. 100.0, ~digits=0)
    }
  }
  div(
    list{
      Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-6"),
      Attrs.role("figure"),
      Attrs.ariaLabel("Safety triangle — hierarchy of controls"),
    },
    list{
      div(
        list{Attrs.class_("text-sm font-medium text-gray-300 mb-4")},
        list{text("Safety Triangle")},
      ),
      // Triangle tiers stacked vertically (inverted pyramid)
      div(
        list{Attrs.class_("space-y-2")},
        list{
          // Eliminate (top, narrowest = highest priority)
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              div(
                list{Attrs.class_("w-20 text-right text-xs text-red-400 font-medium")},
                list{text("Eliminate")},
              ),
              div(
                list{Attrs.class_("flex-1 bg-gray-800 rounded-full h-4 overflow-hidden")},
                list{
                  div(
                    list{
                      Attrs.class_("bg-red-600 h-full rounded-full transition-all"),
                      Attrs.prop("style", `width: ${pct(elim)}%`),
                    },
                    list{},
                  ),
                },
              ),
              div(
                list{Attrs.class_("w-8 text-xs text-gray-400 text-right")},
                list{text(Int.toString(elim))},
              ),
            },
          ),
          // Substitute (middle)
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              div(
                list{Attrs.class_("w-20 text-right text-xs text-amber-400 font-medium")},
                list{text("Substitute")},
              ),
              div(
                list{Attrs.class_("flex-1 bg-gray-800 rounded-full h-4 overflow-hidden")},
                list{
                  div(
                    list{
                      Attrs.class_("bg-amber-600 h-full rounded-full transition-all"),
                      Attrs.prop("style", `width: ${pct(sub)}%`),
                    },
                    list{},
                  ),
                },
              ),
              div(
                list{Attrs.class_("w-8 text-xs text-gray-400 text-right")},
                list{text(Int.toString(sub))},
              ),
            },
          ),
          // Control (bottom, widest = most common)
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              div(
                list{Attrs.class_("w-20 text-right text-xs text-blue-400 font-medium")},
                list{text("Control")},
              ),
              div(
                list{Attrs.class_("flex-1 bg-gray-800 rounded-full h-4 overflow-hidden")},
                list{
                  div(
                    list{
                      Attrs.class_("bg-blue-600 h-full rounded-full transition-all"),
                      Attrs.prop("style", `width: ${pct(ctrl)}%`),
                    },
                    list{},
                  ),
                },
              ),
              div(
                list{Attrs.class_("w-8 text-xs text-gray-400 text-right")},
                list{text(Int.toString(ctrl))},
              ),
            },
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Finding Row
// ============================================================================

/// Render a single finding in the findings list.
let renderFinding = (finding: fleetFinding): Tea_Vdom.t<msg> => {
  let tierBadge = FleetEngine.tierColor(finding.tier)
  let tierText = FleetEngine.tierLabel(finding.tier)
  let assignedText = switch finding.assignedBot {
  | Some(bot) => FleetEngine.botLabel(bot)
  | None => "Unassigned"
  }

  div(
    list{
      Attrs.class_(
        `flex items-center gap-4 p-3 border-b border-gray-800 ${finding.resolved ? "opacity-50" : ""}`,
      ),
      Attrs.role("row"),
      Attrs.ariaLabel(`${finding.summary} — ${tierText} — ${assignedText}`),
    },
    list{
      // Tier badge
      span(
        list{Attrs.class_(`text-xs px-2 py-0.5 rounded ${tierBadge}`)},
        list{text(tierText)},
      ),
      // Repo name
      span(
        list{Attrs.class_("text-xs text-gray-500 w-32 truncate")},
        list{text(finding.repoName)},
      ),
      // Summary
      span(
        list{Attrs.class_("flex-1 text-sm text-gray-300 truncate")},
        list{text(finding.summary)},
      ),
      // Confidence
      span(
        list{Attrs.class_("text-xs text-gray-400 w-16 text-right")},
        list{text(`${Float.toFixed(finding.confidence *. 100.0, ~digits=0)}%`)},
      ),
      // Assigned bot
      span(
        list{Attrs.class_("text-xs text-gray-500 w-24 text-right")},
        list{text(assignedText)},
      ),
    },
  )
}

// ============================================================================
// Dashboard View
// ============================================================================

/// Render the fleet dashboard — bot grid + safety triangle + health summary.
let renderDashboard = (fleet: fleetState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-6")},
    list{
      // Health summary bar
      switch fleet.health {
      | Some(health) =>
        div(
          list{Attrs.class_("flex gap-6 text-sm")},
          list{
            div(
              list{Attrs.class_("text-gray-400")},
              list{text(`Active: ${Int.toString(health.activeBots)}/6 bots`)},
            ),
            div(
              list{Attrs.class_("text-gray-400")},
              list{text(`Queued: ${Int.toString(health.totalQueued)}`)},
            ),
            div(
              list{Attrs.class_("text-gray-400")},
              list{text(`Processed: ${Int.toString(health.totalProcessed)}`)},
            ),
            div(
              list{Attrs.class_("text-gray-400")},
              list{text(`Avg confidence: ${Float.toFixed(health.avgConfidence *. 100.0, ~digits=0)}%`)},
            ),
          },
        )
      | None =>
        div(
          list{Attrs.class_("text-sm text-gray-500")},
          list{text("No health data available")},
        )
      },
      // Two-column layout: bot grid + safety triangle
      div(
        list{Attrs.class_("flex gap-6")},
        list{
          // Bot grid (2x3)
          div(
            list{
              Attrs.class_("flex-1 grid grid-cols-3 gap-3"),
              Attrs.role("list"),
              Attrs.ariaLabel("Fleet bot status"),
            },
            fleet.bots->Array.map(bot => renderBotCard(bot))->List.fromArray,
          ),
          // Safety triangle (right column)
          switch fleet.health {
          | Some(health) =>
            div(
              list{Attrs.class_("w-80")},
              list{renderSafetyTriangle(health)},
            )
          | None => noNode
          },
        },
      ),
    },
  )
}

// ============================================================================
// Findings View
// ============================================================================

/// Render the findings queue with filtering.
let renderFindings = (fleet: fleetState): Tea_Vdom.t<msg> => {
  let filtered = FleetEngine.filterFindings(fleet.findings, fleet.filterText)
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Filter input
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          input(
            list{
              Attrs.class_("flex-1 bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 placeholder-gray-600"),
              Attrs.placeholder("Filter findings by repo or summary..."),
              Attrs.ariaLabel("Filter findings"),
              Attrs.value(fleet.filterText),
              Events.onInput(v => Fleet(SetFleetFilter(v))),
            },
            list{},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text(`${Int.toString(Array.length(filtered))} findings`)},
          ),
        },
      ),
      // Findings list
      div(
        list{
          Attrs.class_("border border-gray-700 rounded-lg overflow-hidden"),
          Attrs.role("table"),
          Attrs.ariaLabel("Findings queue"),
        },
        list{
          // Header
          div(
            list{Attrs.class_("flex items-center gap-4 p-3 bg-gray-900 border-b border-gray-700 text-xs text-gray-500"), Attrs.role("row")},
            list{
              span(list{Attrs.class_("w-20")}, list{text("Tier")}),
              span(list{Attrs.class_("w-32")}, list{text("Repo")}),
              span(list{Attrs.class_("flex-1")}, list{text("Summary")}),
              span(list{Attrs.class_("w-16 text-right")}, list{text("Conf.")}),
              span(list{Attrs.class_("w-24 text-right")}, list{text("Assigned")}),
            },
          ),
          // Rows
          div(
            list{Attrs.class_("max-h-96 overflow-y-auto")},
            filtered->Array.map(f => renderFinding(f))->List.fromArray,
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Dispatch View
// ============================================================================

/// Render the dispatch summary — stats derived from bot and findings state.
/// Shows per-bot dispatch counts, resolution rates, and assignment coverage.
let renderDispatch = (fleet: fleetState): Tea_Vdom.t<msg> => {
  let totalResolved = fleet.findings->Array.filter(f => f.resolved)->Array.length
  let totalFindings = Array.length(fleet.findings)
  let assigned = fleet.findings->Array.filter(f => Option.isSome(f.assignedBot))->Array.length
  let unassigned = totalFindings - assigned
  div(
    list{
      Attrs.class_("space-y-6"),
      Attrs.role("region"),
      Attrs.ariaLabel("Dispatch manifest summary"),
    },
    list{
      // Summary stats row
      div(
        list{Attrs.class_("flex gap-6 text-sm")},
        list{
          div(
            list{Attrs.class_("text-gray-400")},
            list{text(`Total findings: ${Int.toString(totalFindings)}`)},
          ),
          div(
            list{Attrs.class_("text-gray-400")},
            list{text(`Resolved: ${Int.toString(totalResolved)}`)},
          ),
          div(
            list{Attrs.class_("text-gray-400")},
            list{text(`Assigned: ${Int.toString(assigned)}`)},
          ),
          div(
            list{Attrs.class_(unassigned > 0 ? "text-amber-400" : "text-gray-400")},
            list{text(`Unassigned: ${Int.toString(unassigned)}`)},
          ),
        },
      ),
      // Per-bot dispatch breakdown
      div(
        list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4")},
        list{
          div(
            list{Attrs.class_("text-sm font-medium text-gray-300 mb-3")},
            list{text("Per-Bot Dispatch")},
          ),
          div(
            list{Attrs.class_("space-y-2")},
            fleet.bots->Array.map(bot => {
              let assignedToBot = fleet.findings->Array.filter(f =>
                f.assignedBot === Some(bot.id)
              )->Array.length
              let resolvedByBot = fleet.findings->Array.filter(f =>
                f.assignedBot === Some(bot.id) && f.resolved
              )->Array.length
              let botName = FleetEngine.botLabel(bot.id)
              div(
                list{
                  Attrs.class_("flex items-center gap-3"),
                  Attrs.ariaLabel(`${botName}: ${Int.toString(assignedToBot)} assigned, ${Int.toString(resolvedByBot)} resolved`),
                },
                list{
                  div(
                    list{Attrs.class_("w-28 text-sm text-gray-300")},
                    list{text(botName)},
                  ),
                  div(
                    list{Attrs.class_("flex-1 h-3 bg-gray-800 rounded-full overflow-hidden")},
                    list{
                      div(
                        list{
                          Attrs.class_("h-full bg-indigo-500 rounded-full transition-all"),
                          Attrs.prop(
                            "style",
                            `width: ${if totalFindings > 0 {
                                Float.toFixed(
                                  Int.toFloat(assignedToBot) /. Int.toFloat(totalFindings) *. 100.0,
                                  ~digits=0,
                                )
                              } else {
                                "0"
                              }}%`,
                          ),
                        },
                        list{},
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("w-24 text-xs text-gray-500 text-right")},
                    list{text(`${Int.toString(resolvedByBot)}/${Int.toString(assignedToBot)}`)},
                  ),
                },
              )
            })->List.fromArray,
          ),
        },
      ),
      // Note about live dispatch history
      div(
        list{Attrs.class_("text-xs text-gray-600 italic")},
        list{text("Dispatch audit log requires a live connection to the fleet backend.")},
      ),
    },
  )
}

// ============================================================================
// Category Tabs
// ============================================================================

/// Render the category tab bar.
let renderTabs = (active: fleetCategory): Tea_Vdom.t<msg> => {
  let tabs: array<fleetCategory> = [FleetDashboard, FleetFindings, FleetDispatch]
  div(
    list{
      Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"),
      Attrs.role("tablist"),
      Attrs.ariaLabel("Fleet panel sections"),
    },
    tabs->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-indigo-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(Fleet(SetFleetCategory(tab))),
        },
        list{text(FleetEngine.categoryLabel(tab))},
      )
    })->List.fromArray,
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Main view for the Fleet panel — full-screen overlay.
let view = (fleet: fleetState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Gitbot Fleet orchestration panel"),
    },
    list{
      // Header bar
      div(
        list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-medium text-gray-200")},
                list{text("Gitbot Fleet")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("6-bot orchestration")},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              button(
                list{
                  Attrs.class_("px-3 py-1 text-xs bg-indigo-600 text-white rounded hover:bg-indigo-500"),
                  Attrs.ariaLabel("Refresh fleet status"),
                  Events.onClick(Fleet(LoadFleet)),
                },
                list{text("Refresh")},
              ),
              button(
                list{
                  Attrs.class_("px-3 py-1 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700"),
                  Attrs.ariaLabel("Close Fleet panel"),
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
          if fleet.loading {
            div(
              list{Attrs.class_("text-gray-400"), Attrs.role("status")},
              list{text("Loading fleet status...")},
            )
          } else if !fleet.loaded {
            div(
              list{Attrs.class_("text-center text-gray-500 mt-12")},
              list{
                div(list{Attrs.class_("text-4xl mb-4")}, list{text("Fleet")}),
                div(list{Attrs.class_("text-sm mb-6")}, list{text("6-bot gitbot-fleet orchestration")}),
                button(
                  list{
                    Attrs.class_("px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-500"),
                    Events.onClick(Fleet(LoadFleet)),
                  },
                  list{text("Connect to Fleet")},
                ),
              },
            )
          } else {
            div(
              list{Attrs.class_("space-y-4")},
              list{
                renderTabs(fleet.activeCategory),
                switch fleet.activeCategory {
                | FleetDashboard => renderDashboard(fleet)
                | FleetFindings => renderFindings(fleet)
                | FleetDispatch => renderDispatch(fleet)
                },
              },
            )
          },
          // Error display
          switch fleet.error {
          | Some(e) =>
            div(
              list{Attrs.class_("mt-4 p-3 bg-red-900/30 border border-red-700 rounded text-sm text-red-300"), Attrs.role("alert")},
              list{text(e)},
            )
          | None => noNode
          },
        },
      ),
    },
  )
}
