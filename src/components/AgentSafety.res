// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Agent Safety Gate Panel — tool call safety review and approval
/// queue display.
///
/// Layout: Pending approvals queue at top (red/amber cards with Approve/Deny
/// buttons), event history below, stats sidebar showing approved/denied/
/// escalated counts.

open Msg
open AgentSafetyModel
open AgentSafetyEngine
open Tea.Html

// ============================================================================
// Stats Sidebar
// ============================================================================

/// A single stat counter in the sidebar.
let statCounter = (label: string, count: int, colorClass: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center justify-between py-1")},
    list{
      span(
        list{Attrs.class_("text-xs text-gray-400")},
        list{text(label)},
      ),
      span(
        list{Attrs.class_(`text-sm font-mono font-bold ${colorClass}`)},
        list{text(Int.toString(count))},
      ),
    },
  )
}

/// Stats sidebar showing aggregate counts.
let statsSidebar = (stats: safetyStats): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("w-48 shrink-0 p-3 bg-gray-900/50 rounded-lg border border-gray-800")},
    list{
      h3(
        list{Attrs.class_("text-sm font-semibold text-gray-200 mb-3")},
        list{text("Safety Stats")},
      ),
      statCounter("Total Events", stats.totalEvents, "text-gray-200"),
      statCounter("Auto-Approved", stats.autoApproved, "text-emerald-400"),
      statCounter("Human Approved", stats.humanApproved, "text-emerald-400"),
      statCounter("Denied", stats.denied, "text-red-400"),
      statCounter("Escalated", stats.escalated, "text-orange-400"),
      statCounter("Policy Blocked", stats.policyBlocked, "text-red-400"),
      div(
        list{Attrs.class_("border-t border-gray-700 mt-2 pt-2")},
        list{
          statCounter("Pending", stats.pendingCount, "text-amber-400"),
        },
      ),
    },
  )
}

// ============================================================================
// Pending Approval Card
// ============================================================================

/// A pending approval card with Approve and Deny buttons.
let pendingCard = (event: safetyEvent): Tea_Vdom.t<msg> => {
  let cardColor = eventColor(event.outcome)
  div(
    list{Attrs.class_(`flex flex-col p-3 rounded-lg border ${cardColor}`)},
    list{
      // Header: tool call type + agent
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          span(
            list{Attrs.class_("text-sm font-semibold text-gray-100")},
            list{text(toolCallLabel(event.toolCall))},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500 font-mono")},
            list{text(event.agentId)},
          ),
        },
      ),
      // Description
      p(
        list{Attrs.class_("text-xs text-gray-300 mb-1")},
        list{text(event.description)},
      ),
      // Resource
      div(
        list{Attrs.class_("text-xs text-gray-500 font-mono mb-3 truncate")},
        list{text(event.resource)},
      ),
      // Side effects warning
      if hasSideEffects(event.toolCall) {
        div(
          list{Attrs.class_("text-xs text-amber-400 mb-2")},
          list{text("This operation has side effects")},
        )
      } else {
        noNode
      },
      // Action buttons
      div(
        list{Attrs.class_("flex gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                "flex-1 px-3 py-1.5 text-sm rounded bg-emerald-600 text-white hover:bg-emerald-500",
              ),
            },
            list{text("Approve")},
          ),
          button(
            list{
              Attrs.class_(
                "flex-1 px-3 py-1.5 text-sm rounded bg-red-600 text-white hover:bg-red-500",
              ),
            },
            list{text("Deny")},
          ),
        },
      ),
      // Timestamp
      span(
        list{Attrs.class_("text-xs text-gray-600 mt-2")},
        list{text(event.timestamp)},
      ),
    },
  )
}

// ============================================================================
// History Row
// ============================================================================

/// A single event row in the history list.
let historyRow = (event: safetyEvent): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "flex items-center gap-3 px-3 py-2 border-b border-gray-800 hover:bg-gray-800/30",
      ),
    },
    list{
      // Outcome badge
      span(
        list{
          Attrs.class_(
            `px-2 py-0.5 text-xs rounded font-mono shrink-0 ${outcomeTextColor(event.outcome)}`,
          ),
        },
        list{text(outcomeLabel(event.outcome))},
      ),
      // Tool call type
      span(
        list{Attrs.class_("text-xs text-gray-300 w-24 shrink-0")},
        list{text(toolCallLabel(event.toolCall))},
      ),
      // Description (truncated)
      span(
        list{Attrs.class_("text-xs text-gray-400 flex-1 truncate")},
        list{text(event.description)},
      ),
      // Agent
      span(
        list{Attrs.class_("text-xs text-gray-500 font-mono shrink-0")},
        list{text(event.agentId)},
      ),
      // Timestamp
      span(
        list{Attrs.class_("text-xs text-gray-600 font-mono shrink-0")},
        list{text(event.timestamp)},
      ),
    },
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Top-level view for the Agent Safety Gate panel.
let view = (state: agentSafetyState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex h-full p-3 gap-3 bg-gray-950 text-gray-100")},
    list{
      // Main content area
      div(
        list{Attrs.class_("flex-1 flex flex-col overflow-hidden")},
        list{
          // Panel header
          h2(
            list{Attrs.class_("text-lg font-semibold mb-3")},
            list{text("Agent Safety Gate")},
          ),
          // Pending approvals section
          if Array.length(state.pendingEvents) > 0 {
            div(
              list{Attrs.class_("mb-4")},
              list{
                h3(
                  list{Attrs.class_("text-sm font-semibold text-amber-400 mb-2")},
                  list{
                    text(
                      `Pending Approvals (${Int.toString(Array.length(state.pendingEvents))})`,
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("grid grid-cols-1 gap-2 max-h-64 overflow-y-auto")},
                  state.pendingEvents->Array.map(pendingCard)->Array.toList,
                ),
              },
            )
          } else {
            div(
              list{Attrs.class_("p-3 mb-4 rounded bg-emerald-900/20 border border-emerald-500/30 text-xs text-emerald-400")},
              list{text("No pending approvals")},
            )
          },
          // History section
          h3(
            list{Attrs.class_("text-sm font-semibold text-gray-300 mb-2")},
            list{text("Event History")},
          ),
          div(
            list{Attrs.class_("flex-1 overflow-y-auto border border-gray-800 rounded")},
            list{
              div(
                list{Attrs.class_("divide-y divide-gray-800")},
                state.historyEvents->Array.map(historyRow)->Array.toList,
              ),
            },
          ),
        },
      ),
      // Stats sidebar (right)
      statsSidebar(state.stats),
    },
  )
}
