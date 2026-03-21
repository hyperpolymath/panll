// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL OODA Session Monitor Panel — agent OODA loop lifecycle tracking
/// display.
///
/// Layout: Session list (left column), selected session detail (right column)
/// showing OODA state diagram with current state highlighted, loop count,
/// and advance/halt control buttons.

open Msg
open AgentOodaModel
open AgentOodaEngine
open Tea.Html

// ============================================================================
// OODA State Diagram
// ============================================================================

/// A single state node in the OODA diagram.
let stateNode = (state: agentState, isCurrent: bool): Tea_Vdom.t<msg> => {
  let bgColor = if isCurrent {
    stateColor(state)
  } else {
    "bg-gray-800 text-gray-400"
  }
  let borderClass = if isCurrent {
    stateBorderColor(state) ++ " ring-2 ring-offset-1 ring-offset-gray-950"
  } else {
    "border-gray-700"
  }
  div(
    list{Attrs.class_(`flex flex-col items-center p-3 rounded-lg border ${borderClass} ${bgColor} min-w-20`)},
    list{
      span(
        list{Attrs.class_("text-sm font-semibold")},
        list{text(stateLabel(state))},
      ),
    },
  )
}

/// Arrow connector between OODA states.
let stateArrow: Tea_Vdom.t<msg> = {
  span(
    list{Attrs.class_("text-gray-600 text-lg self-center")},
    list{text("->")},
  )
}

/// The full OODA state diagram showing all 4 states + Halted.
let oodaDiagram = (currentState: agentState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-3")},
    list{
      // Main OODA loop (horizontal)
      div(
        list{Attrs.class_("flex items-center gap-2 flex-wrap")},
        list{
          stateNode(Observing, currentState == Observing),
          stateArrow,
          stateNode(Orienting, currentState == Orienting),
          stateArrow,
          stateNode(Deciding, currentState == Deciding),
          stateArrow,
          stateNode(Acting, currentState == Acting),
        },
      ),
      // Halted state (separate, below)
      div(
        list{Attrs.class_("flex items-center gap-2 mt-2")},
        list{
          stateNode(Halted, currentState == Halted),
        },
      ),
    },
  )
}

// ============================================================================
// Session List Item
// ============================================================================

/// A single session row in the left-hand session list.
let sessionListItem = (
  session: oodaSession,
  isSelected: bool,
): Tea_Vdom.t<msg> => {
  let health = sessionHealth(session)
  let healthCls = healthColor(health)
  let selectedCls = if isSelected {
    "bg-gray-800 border-emerald-500"
  } else {
    "bg-gray-900/50 border-gray-800 hover:bg-gray-800/50"
  }
  div(
    list{Attrs.class_(`flex items-center gap-3 p-3 rounded border cursor-pointer ${selectedCls}`)},
    list{
      // Health indicator dot
      span(
        list{Attrs.class_(`w-2 h-2 rounded-full ${healthCls} shrink-0`)},
        list{},
      ),
      // Agent name + state
      div(
        list{Attrs.class_("flex-1 min-w-0")},
        list{
          div(
            list{Attrs.class_("text-sm font-semibold text-gray-100 truncate")},
            list{text(session.agentName)},
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(
                list{Attrs.class_(`text-xs ${stateTextColor(session.state)}`)},
                list{text(stateLabel(session.state))},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(`${Int.toString(session.loopCount)} loops`)},
              ),
            },
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Session Detail View
// ============================================================================

/// Detailed view of the selected session (right column).
let sessionDetailView = (detail: sessionDetail): Tea_Vdom.t<msg> => {
  let session = detail.session
  div(
    list{Attrs.class_("flex flex-col gap-4")},
    list{
      // Session header
      div(
        list{Attrs.class_("flex items-center justify-between")},
        list{
          h3(
            list{Attrs.class_("text-lg font-semibold text-gray-100")},
            list{text(session.agentName)},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500 font-mono")},
            list{text(session.id)},
          ),
        },
      ),
      // OODA state diagram
      oodaDiagram(session.state),
      // Stats row
      div(
        list{Attrs.class_("flex gap-4 p-3 bg-gray-900/50 rounded-lg")},
        list{
          div(
            list{Attrs.class_("flex flex-col items-center")},
            list{
              span(
                list{Attrs.class_("text-xl font-bold font-mono text-gray-100")},
                list{text(Int.toString(session.loopCount))},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("Loops")},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex flex-col items-center")},
            list{
              span(
                list{Attrs.class_("text-xl font-bold font-mono text-gray-100")},
                list{
                  text(
                    Float.toFixed(loopRate(detail), ~digits=2) ++ "/s",
                  ),
                },
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("Loop Rate")},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex flex-col items-center")},
            list{
              span(
                list{Attrs.class_("text-xl font-bold font-mono text-gray-100")},
                list{
                  text(
                    Float.toFixed(detail.avgLoopMs, ~digits=0) ++ "ms",
                  ),
                },
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("Avg Loop")},
              ),
            },
          ),
        },
      ),
      // Control buttons
      div(
        list{Attrs.class_("flex gap-2")},
        list{
          if session.state != Halted {
            button(
              list{
                Attrs.class_(
                  "px-4 py-2 text-sm rounded bg-blue-600 text-white hover:bg-blue-500",
                ),
              },
              list{text("Advance")},
            )
          } else {
            noNode
          },
          if session.state != Halted {
            button(
              list{
                Attrs.class_(
                  "px-4 py-2 text-sm rounded bg-red-600 text-white hover:bg-red-500",
                ),
              },
              list{text("Halt")},
            )
          } else {
            noNode
          },
        },
      ),
      // Halt reason (if halted)
      switch session.haltReason {
      | Some(reason) =>
        div(
          list{
            Attrs.class_(
              "p-2 rounded bg-red-900/30 border border-red-500/40 text-xs text-red-400",
            ),
          },
          list{text("Halt reason: " ++ reason)},
        )
      | None => noNode
      },
    },
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Top-level view for the OODA Session Monitor panel.
let view = (state: agentOodaState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex h-full p-3 gap-3 bg-gray-950 text-gray-100")},
    list{
      // Left column: session list
      div(
        list{Attrs.class_("w-64 flex flex-col gap-2 overflow-y-auto shrink-0")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold mb-2")},
            list{text("OODA Sessions")},
          ),
          div(
            list{Attrs.class_("flex flex-col gap-1")},
            state.sessions
            ->Array.map(session =>
              sessionListItem(session, state.selectedSessionId == Some(session.id))
            )
            ->List.fromArray,
          ),
        },
      ),
      // Right column: session detail
      div(
        list{Attrs.class_("flex-1 overflow-y-auto")},
        list{
          switch state.selectedDetail {
          | Some(detail) => sessionDetailView(detail)
          | None =>
            div(
              list{Attrs.class_("flex items-center justify-center h-full text-gray-600")},
              list{text("Select a session to view details")},
            )
          },
        },
      ),
    },
  )
}
