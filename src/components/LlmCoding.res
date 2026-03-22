// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL LLM Coding Panel View — headed supervisor for parallel Claude/LLM
/// coding sessions. Spawns, monitors, freezes, and coordinates multiple
/// sessions from a single control panel.
///
/// Layout:
///   Top bar: system resources + daemon status + spawn button
///   Left column: session cards with state/resource indicators
///   Right column: selected session detail (tasks, locks, messages)
///   Bottom bar: pending actions requiring approval

open Msg
open LlmCodingModel
open LlmCodingEngine
open Tea.Html

// ============================================================================
// System Status Bar
// ============================================================================

/// System resource summary and daemon connection status.
let systemBar = (state: llmCodingState): Tea_Vdom.t<msg> => {
  let memHealth = systemMemoryHealth(state.systemMemoryAvailableMb, state.systemMemoryTotalMb)
  let memColor = resourceHealthColor(memHealth)
  div(
    list{Attrs.class_("flex items-center justify-between p-2 bg-gray-900 border-b border-gray-800")},
    list{
      // Left: daemon status
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          span(
            list{
              Attrs.class_(
                `w-2 h-2 rounded-full ${if state.daemonConnected {
                    "bg-emerald-400"
                  } else {
                    "bg-red-400"
                  }}`,
              ),
            },
            list{},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-400")},
            list{
              text(
                if state.daemonConnected {
                  "Daemon connected"
                } else {
                  "Daemon offline"
                },
              ),
            },
          ),
        },
      ),
      // Centre: system resources
      div(
        list{Attrs.class_("flex items-center gap-4 text-xs")},
        list{
          span(
            list{Attrs.class_(memColor)},
            list{
              text(
                `RAM: ${Int.toString(state.systemMemoryAvailableMb)}/${Int.toString(state.systemMemoryTotalMb)}MB`,
              ),
            },
          ),
          span(
            list{Attrs.class_("text-gray-400")},
            list{
              text(`CPU: ${Float.toFixed(state.systemCpuPercent, ~digits=0)}%`),
            },
          ),
          span(
            list{Attrs.class_("text-gray-500")},
            list{
              text(`${Int.toString(Array.length(state.sessions))} sessions`),
            },
          ),
        },
      ),
      // Right: spawn button
      button(
        list{
          Attrs.class_(
            "px-3 py-1 text-xs font-semibold rounded bg-emerald-600 hover:bg-emerald-500 text-white",
          ),
        },
        list{text("+ Spawn Session")},
      ),
    },
  )
}

// ============================================================================
// Session Card
// ============================================================================

/// Resource usage bar for a session.
let resourceBar = (usage: resourceUsage, limits: resourceLimits): Tea_Vdom.t<msg> => {
  let health = resourceHealth(usage, limits)
  let color = resourceHealthColor(health)
  div(
    list{Attrs.class_("flex items-center gap-2 text-xs mt-2")},
    list{
      span(list{Attrs.class_(color)}, list{text(`${Int.toString(usage.memoryMb)}MB`)}),
      span(
        list{Attrs.class_("text-gray-600")},
        list{text(`CPU ${Float.toFixed(usage.cpuPercent, ~digits=0)}%`)},
      ),
      span(
        list{Attrs.class_("text-gray-600")},
        list{text(`${Int.toString(usage.subagentCount)} agents`)},
      ),
      span(
        list{Attrs.class_(`ml-auto font-mono ${color}`)},
        list{text(resourceHealthLabel(health))},
      ),
    },
  )
}

/// Progress bar for a session's task list.
let taskProgress = (tasks: array<sharedTask>): Tea_Vdom.t<msg> => {
  let total = Array.length(tasks)
  if total == 0 {
    noNode
  } else {
    let pct = progressPercent(tasks)
    let done = completedCount(tasks)
    div(
      list{Attrs.class_("mt-2")},
      list{
        div(
          list{Attrs.class_("flex justify-between text-xs text-gray-500 mb-1")},
          list{
            span(list{}, list{text(`${Int.toString(done)}/${Int.toString(total)} tasks`)}),
            span(list{}, list{text(`${Int.toString(pct)}%`)}),
          },
        ),
        div(
          list{Attrs.class_("w-full h-1 bg-gray-800 rounded")},
          list{
            div(
              list{
                Attrs.class_("h-1 bg-emerald-500 rounded"),
                Attrs.style("width", `${Int.toString(pct)}%`),
              },
              list{},
            ),
          },
        ),
      },
    )
  }
}

/// A single session card in the sidebar.
let sessionCard = (session: llmSession, isSelected: bool): Tea_Vdom.t<msg> => {
  let borderClass = stateBorderColor(session.state)
  let selectedRing = if isSelected {
    " ring-2 ring-emerald-500/30"
  } else {
    ""
  }
  div(
    list{
      Attrs.class_(
        `flex flex-col p-3 rounded-lg border ${borderClass}${selectedRing} bg-gray-900/50 cursor-pointer hover:brightness-110 transition-all`,
      ),
    },
    list{
      // Header: name + state
      div(
        list{Attrs.class_("flex items-center justify-between")},
        list{
          span(
            list{Attrs.class_("font-semibold text-sm text-gray-100")},
            list{text(session.name)},
          ),
          span(
            list{Attrs.class_(`text-xs font-mono ${stateColor(session.state)}`)},
            list{text(stateLabel(session.state))},
          ),
        },
      ),
      // Provider + PID
      div(
        list{Attrs.class_("flex items-center gap-2 mt-1 text-xs text-gray-500")},
        list{
          span(list{}, list{text(providerName(session.provider))}),
          switch session.pid {
          | Some(pid) =>
            span(list{Attrs.class_("font-mono")}, list{text(`PID ${Int.toString(pid)}`)})
          | None => noNode
          },
        },
      ),
      // Allowed repos
      div(
        list{Attrs.class_("flex gap-1 flex-wrap mt-1")},
        session.allowedRepos
        ->Array.map(repo =>
          span(
            list{Attrs.class_("px-1 py-0.5 text-xs rounded bg-gray-800 text-gray-400 font-mono")},
            list{text(repo)},
          )
        )
        ->List.fromArray,
      ),
      // Resource usage
      resourceBar(session.resources, session.limits),
      // Task progress
      taskProgress(session.tasks),
      // Action buttons (only for alive sessions)
      if isAlive(session.state) {
        div(
          list{Attrs.class_("flex gap-1 mt-2")},
          list{
            if canFreeze(session.state) {
              button(
                list{
                  Attrs.class_(
                    "px-2 py-0.5 text-xs rounded bg-amber-700 hover:bg-amber-600 text-white",
                  ),
                },
                list{text("Freeze")},
              )
            } else if canThaw(session.state) {
              button(
                list{
                  Attrs.class_(
                    "px-2 py-0.5 text-xs rounded bg-blue-700 hover:bg-blue-600 text-white",
                  ),
                },
                list{text("Thaw")},
              )
            } else {
              noNode
            },
            button(
              list{
                Attrs.class_(
                  "px-2 py-0.5 text-xs rounded bg-red-800 hover:bg-red-700 text-white",
                ),
              },
              list{text("Kill")},
            ),
          },
        )
      } else {
        noNode
      },
    },
  )
}

// ============================================================================
// Pending Actions Bar
// ============================================================================

/// A single pending action requiring approval.
let pendingActionView = (action: pendingAction): Tea_Vdom.t<msg> => {
  let danger = actionDanger(action.category)
  let color = dangerColor(danger)
  div(
    list{
      Attrs.class_(
        "flex items-center justify-between p-2 bg-gray-900 border border-gray-700 rounded",
      ),
    },
    list{
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          span(list{Attrs.class_(`text-xs font-mono ${color}`)}, list{text(actionCategoryName(action.category))}),
          span(
            list{Attrs.class_("text-xs text-gray-300")},
            list{text(action.description)},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-600")},
            list{text(`from ${action.sessionId}`)},
          ),
        },
      ),
      div(
        list{Attrs.class_("flex gap-1")},
        list{
          button(
            list{
              Attrs.class_(
                "px-2 py-0.5 text-xs rounded bg-emerald-700 hover:bg-emerald-600 text-white",
              ),
            },
            list{text("Approve")},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-0.5 text-xs rounded bg-red-800 hover:bg-red-700 text-white",
              ),
            },
            list{text("Deny")},
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Messages View
// ============================================================================

/// Cross-session message in the log.
let messageView = (msg_: sessionMessage): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex gap-2 text-xs py-1 border-b border-gray-800/50")},
    list{
      span(
        list{Attrs.class_("text-gray-600 font-mono shrink-0")},
        list{text(msg_.sentAt)},
      ),
      span(
        list{Attrs.class_("text-emerald-400 font-mono shrink-0")},
        list{text(msg_.fromSession)},
      ),
      span(list{Attrs.class_("text-gray-300")}, list{text(msg_.content)}),
    },
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Top-level view for the LLM Coding panel.
let view = (state: llmCodingState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100")},
    list{
      // System status bar
      systemBar(state),
      // Main content area
      div(
        list{Attrs.class_("flex flex-1 overflow-hidden")},
        list{
          // Left: session cards
          div(
            list{Attrs.class_("w-80 border-r border-gray-800 overflow-y-auto p-2 flex flex-col gap-2")},
            if Array.length(state.sessions) == 0 {
              list{
                div(
                  list{Attrs.class_("flex items-center justify-center h-32 text-gray-600 text-sm")},
                  list{text("No sessions. Click '+ Spawn Session' to begin.")},
                ),
              }
            } else {
              state.sessions
              ->Array.map(s => sessionCard(s, state.selectedSession == Some(s.id)))
              ->List.fromArray
            },
          ),
          // Right: detail / messages
          div(
            list{Attrs.class_("flex-1 overflow-y-auto p-3")},
            list{
              // Cross-session messages
              div(
                list{Attrs.class_("mb-4")},
                list{
                  h3(
                    list{Attrs.class_("text-sm font-semibold text-gray-400 mb-2")},
                    list{text("Cross-Session Messages")},
                  ),
                  if Array.length(state.messages) == 0 {
                    div(
                      list{Attrs.class_("text-xs text-gray-600")},
                      list{text("No messages yet")},
                    )
                  } else {
                    div(
                      list{Attrs.class_("flex flex-col")},
                      state.messages->Array.map(messageView)->List.fromArray,
                    )
                  },
                },
              ),
              // Workspace locks
              div(
                list{Attrs.class_("mb-4")},
                list{
                  h3(
                    list{Attrs.class_("text-sm font-semibold text-gray-400 mb-2")},
                    list{text(`Workspace Locks (${Int.toString(Array.length(state.locks))})`)},
                  ),
                  div(
                    list{Attrs.class_("flex flex-col gap-1")},
                    state.locks
                    ->Array.map(lock =>
                      div(
                        list{Attrs.class_("flex items-center gap-2 text-xs")},
                        list{
                          span(
                            list{
                              Attrs.class_(
                                if lock.exclusive {
                                  "text-red-400"
                                } else {
                                  "text-blue-400"
                                },
                              ),
                            },
                            list{
                              text(
                                if lock.exclusive {
                                  "EXCL"
                                } else {
                                  "READ"
                                },
                              ),
                            },
                          ),
                          span(
                            list{Attrs.class_("text-gray-300 font-mono")},
                            list{text(lock.path)},
                          ),
                          span(
                            list{Attrs.class_("text-gray-600")},
                            list{text(`held by ${lock.heldBy}`)},
                          ),
                        },
                      )
                    )
                    ->List.fromArray,
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Bottom: pending actions
      if Array.length(state.pendingActions) > 0 {
        div(
          list{
            Attrs.class_(
              "border-t border-amber-800 bg-amber-950/30 p-2 flex flex-col gap-1",
            ),
          },
          list{
            h3(
              list{Attrs.class_("text-xs font-semibold text-amber-400 mb-1")},
              list{
                text(
                  `${Int.toString(Array.length(state.pendingActions))} action(s) awaiting approval`,
                ),
              },
            ),
            div(
              list{Attrs.class_("flex flex-col gap-1")},
              state.pendingActions->Array.map(pendingActionView)->List.fromArray,
            ),
          },
        )
      } else {
        noNode
      },
      // Error display
      switch state.lastError {
      | Some(err) =>
        div(
          list{Attrs.class_("p-2 bg-red-950 border-t border-red-800 text-xs text-red-300")},
          list{text(err)},
        )
      | None => noNode
      },
    },
  )
}
