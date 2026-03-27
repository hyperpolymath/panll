// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Tentacles — panel component for the 7-Tentacles compiler agent orchestra.
///
/// Renders four category tabs: Agent (single-agent 3-panel view), Orchestra
/// (7-agent grid), Stage (progressive reveal config), Progress (stats dashboard).
/// Uses Tea_Html (no JSX) and Tailwind CSS, consistent with all PanLL panels.

open Model
open Msg
open TentaclesEngine
open Tea.Html

/// Render a category tab button.
let renderTab = (label: string, active: bool, cat: tentaclesCategory): Tea_Vdom.t<msg> => {
  let baseClass = "px-3 py-1.5 text-xs rounded-t border-b-2 transition-colors cursor-pointer"
  let cls = active
    ? `${baseClass} text-cyan-300 border-cyan-400 bg-gray-800`
    : `${baseClass} text-gray-500 border-transparent hover:text-gray-300`
  button(
    list{
      Attrs.class_(cls),
      Events.onClick(Tentacles(SetTentaclesCategory(cat))),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Render an OODA phase indicator.
let renderOodaIndicator = (currentPhase: oodaPhase): Tea_Vdom.t<msg> => {
  let phases = [(Observe, "O"), (Orient, "R"), (Decide, "D"), (Act, "A")]
  div(
    list{Attrs.class_("flex gap-1")},
    phases
    ->Array.map(((phase, letter)) => {
      let cls =
        phase == currentPhase
          ? "w-6 h-6 rounded-full bg-cyan-500 text-gray-950 flex items-center justify-center text-xs font-bold"
          : "w-6 h-6 rounded-full bg-gray-700 text-gray-400 flex items-center justify-center text-xs"
      div(list{Attrs.class_(cls)}, list{text(letter)})
    })
    ->List.fromArray,
  )
}

/// Render a constraint card for Panel-L feed.
let renderConstraint = (c: tentacleConstraint): Tea_Vdom.t<msg> => {
  let statusCls = c.satisfied ? "text-green-400" : "text-amber-400"
  let statusText = c.satisfied ? "SAT" : "UNSAT"
  div(
    list{Attrs.class_("p-2 mb-1 rounded bg-gray-800/60 border border-gray-700/50")},
    list{
      div(
        list{Attrs.class_("flex justify-between items-center")},
        list{
          span(list{Attrs.class_("text-xs text-gray-300")}, list{text(c.label)}),
          span(list{Attrs.class_(`text-xs font-mono ${statusCls}`)}, list{text(statusText)}),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-500 font-mono mt-0.5 truncate")},
        list{text(c.expression)},
      ),
    },
  )
}

/// Render a reasoning entry for Panel-N feed.
let renderReasoning = (r: reasoningEntry): Tea_Vdom.t<msg> => {
  let phaseColour = switch r.phase {
  | Observe => "text-blue-400"
  | Orient => "text-yellow-400"
  | Decide => "text-orange-400"
  | Act => "text-green-400"
  }
  div(
    list{Attrs.class_("p-2 mb-1 rounded bg-gray-800/40 border-l-2 border-gray-600")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          span(
            list{Attrs.class_(`text-xs font-mono ${phaseColour}`)},
            list{text(oodaIcon(r.phase))},
          ),
          span(list{Attrs.class_("text-xs text-gray-300")}, list{text(r.summary)}),
        },
      ),
    },
  )
}

/// Render a validated result card for Panel-W feed.
let renderResult = (r: validatedResult): Tea_Vdom.t<msg> => {
  let verifiedCls = r.verified ? "text-green-400" : "text-red-400"
  let verifiedText = r.verified ? "VERIFIED" : "UNVERIFIED"
  div(
    list{Attrs.class_("p-2 mb-1 rounded bg-gray-800/60 border border-gray-700/50")},
    list{
      div(
        list{Attrs.class_("flex justify-between items-center mb-1")},
        list{
          span(list{Attrs.class_("text-xs font-medium text-gray-200")}, list{text(r.title)}),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(list{Attrs.class_(`text-xs ${verifiedCls}`)}, list{text(verifiedText)}),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(Float.toFixed(r.confidence *. 100.0, ~digits=0) ++ "%")},
              ),
            },
          ),
        },
      ),
      div(list{Attrs.class_("text-xs text-gray-400 font-mono truncate")}, list{text(r.content)}),
    },
  )
}

/// Render a single agent card (used in both AgentView and Orchestra).
let renderAgentCard = (agent: tentacleAgentState, isSelected: bool, compact: bool): Tea_Vdom.t<
  msg,
> => {
  let borderCls = tentacleBorderClass(agent.id)
  let bgCls = tentacleBgClass(agent.id)
  let textCls = tentacleTextClass(agent.id)
  let selectedBorder = isSelected ? borderCls : "border-gray-700"
  let name = agentDisplayName(agent)

  if compact {
    // Compact mode: small coloured dot with status
    div(
      list{
        Attrs.class_(
          `p-2 rounded-lg border ${selectedBorder} ${bgCls} cursor-pointer hover:brightness-110 transition-all`,
        ),
        Events.onClick(Tentacles(SelectAgent(agent.id))),
      },
      list{
        div(
          list{Attrs.class_("flex items-center gap-2")},
          list{
            div(
              list{
                Attrs.class_(
                  `w-3 h-3 rounded-full ${tentacleBgClass(agent.id)} border ${borderCls}`,
                ),
              },
              list{},
            ),
            span(
              list{Attrs.class_(`text-xs ${textCls} font-medium`)},
              list{text(tentacleShortLabel(agent.id))},
            ),
            if agent.busy {
              span(list{Attrs.class_("text-xs text-cyan-400 animate-pulse")}, list{text("...")})
            } else {
              noNode
            },
          },
        ),
      },
    )
  } else {
    // Full card: name, role, OODA, status
    div(
      list{
        Attrs.class_(
          `p-3 rounded-lg border ${selectedBorder} ${bgCls} cursor-pointer hover:brightness-110 transition-all`,
        ),
        Events.onClick(Tentacles(SelectAgent(agent.id))),
      },
      list{
        // Header: name + busy indicator
        div(
          list{Attrs.class_("flex justify-between items-center mb-2")},
          list{
            div(
              list{Attrs.class_("flex items-center gap-2")},
              list{
                div(list{Attrs.class_(`w-3 h-3 rounded-full border ${borderCls}`)}, list{}),
                span(list{Attrs.class_(`text-sm font-medium ${textCls}`)}, list{text(name)}),
              },
            ),
            if agent.busy {
              span(list{Attrs.class_("text-xs text-cyan-400 animate-pulse")}, list{text("WORKING")})
            } else {
              span(list{Attrs.class_("text-xs text-gray-600")}, list{text("IDLE")})
            },
          },
        ),
        // Role
        div(list{Attrs.class_("text-xs text-gray-400 mb-2")}, list{text(agent.compilerRole)}),
        // OODA indicator
        renderOodaIndicator(agent.currentPhase),
        // Catchphrase
        div(
          list{Attrs.class_("text-xs text-gray-500 italic mt-2 truncate")},
          list{text(agent.personality.catchphrase)},
        ),
        // Stats row
        div(
          list{Attrs.class_("flex gap-3 mt-2 text-xs text-gray-500")},
          list{
            span(
              list{},
              list{text(Int.toString(Array.length(agent.constraints)) ++ " constraints")},
            ),
            span(list{}, list{text(Int.toString(Array.length(agent.results)) ++ " results")}),
          },
        ),
        // Error indicator
        switch agent.lastError {
        | Some(err) =>
          div(
            list{
              Attrs.class_(
                "mt-2 p-1.5 rounded bg-red-900/30 border border-red-700/50 text-xs text-red-400 truncate",
              ),
            },
            list{text(err)},
          )
        | None => noNode
        },
      },
    )
  }
}

/// Render the Agent View tab — single agent with 3-panel breakdown.
let renderAgentView = (state: tentaclesState): Tea_Vdom.t<msg> => {
  let agent = findAgent(state.agents, state.selectedAgent)
  switch agent {
  | None => div(list{Attrs.class_("p-4 text-gray-500 text-sm")}, list{text("No agent selected")})
  | Some(a) => {
      let textCls = tentacleTextClass(a.id)
      let borderCls = tentacleBorderClass(a.id)
      div(
        list{Attrs.class_("flex flex-col h-full")},
        list{
          // Agent selector strip
          div(
            list{Attrs.class_("flex gap-1 px-3 py-2 border-b border-gray-800")},
            allTentacles
            ->Array.map(id => {
              let isSelected = id == state.selectedAgent
              let cls = isSelected
                ? `px-2 py-1 text-xs rounded cursor-pointer ${tentacleBgClass(
                      id,
                    )} ${tentacleTextClass(id)} border ${tentacleBorderClass(id)}`
                : "px-2 py-1 text-xs rounded cursor-pointer text-gray-500 hover:text-gray-300 border border-transparent"
              button(
                list{Attrs.class_(cls), Events.onClick(Tentacles(SelectAgent(id)))},
                list{text(tentacleShortLabel(id))},
              )
            })
            ->List.fromArray,
          ),
          // Agent header
          div(
            list{Attrs.class_("px-4 py-3 border-b border-gray-800")},
            list{
              div(
                list{Attrs.class_("flex justify-between items-center")},
                list{
                  div(
                    list{Attrs.class_("flex items-center gap-3")},
                    list{
                      div(list{Attrs.class_(`w-4 h-4 rounded-full border-2 ${borderCls}`)}, list{}),
                      span(
                        list{Attrs.class_(`text-lg font-medium ${textCls}`)},
                        list{text(agentDisplayName(a))},
                      ),
                      span(
                        list{Attrs.class_("text-xs text-gray-500")},
                        list{text("(" ++ a.compilerRole ++ ")")},
                      ),
                    },
                  ),
                  renderOodaIndicator(a.currentPhase),
                },
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500 italic mt-1")},
                list{text(a.personality.catchphrase)},
              ),
            },
          ),
          // Three-column layout: Constraints | Reasoning | Results
          div(
            list{Attrs.class_("flex-1 flex overflow-hidden")},
            list{
              // Panel-L: Constraints
              div(
                list{Attrs.class_("flex-1 overflow-auto border-r border-gray-800 p-3")},
                list{
                  div(
                    list{
                      Attrs.class_(
                        "text-xs text-gray-500 font-medium mb-2 uppercase tracking-wider",
                      ),
                    },
                    list{text("Constraints (L)")},
                  ),
                  if Array.length(a.constraints) == 0 {
                    div(
                      list{Attrs.class_("text-xs text-gray-600 italic")},
                      list{text("No active constraints")},
                    )
                  } else {
                    div(list{}, a.constraints->Array.map(renderConstraint)->List.fromArray)
                  },
                },
              ),
              // Panel-N: Reasoning
              div(
                list{Attrs.class_("flex-1 overflow-auto border-r border-gray-800 p-3")},
                list{
                  div(
                    list{
                      Attrs.class_(
                        "text-xs text-gray-500 font-medium mb-2 uppercase tracking-wider",
                      ),
                    },
                    list{text("Reasoning (N)")},
                  ),
                  if Array.length(a.reasoning) == 0 {
                    div(
                      list{Attrs.class_("text-xs text-gray-600 italic")},
                      list{text("No reasoning entries")},
                    )
                  } else {
                    div(list{}, a.reasoning->Array.map(renderReasoning)->List.fromArray)
                  },
                },
              ),
              // Panel-W: Results
              div(
                list{Attrs.class_("flex-1 overflow-auto p-3")},
                list{
                  div(
                    list{
                      Attrs.class_(
                        "text-xs text-gray-500 font-medium mb-2 uppercase tracking-wider",
                      ),
                    },
                    list{text("Results (W)")},
                  ),
                  if Array.length(a.results) == 0 {
                    div(
                      list{Attrs.class_("text-xs text-gray-600 italic")},
                      list{text("No validated results")},
                    )
                  } else {
                    div(list{}, a.results->Array.map(renderResult)->List.fromArray)
                  },
                },
              ),
            },
          ),
        },
      )
    }
  }
}

/// Render the Orchestra tab — all 7 agents in a grid.
let renderOrchestra = (state: tentaclesState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4")},
    list{
      // Header with compact toggle
      div(
        list{Attrs.class_("flex justify-between items-center mb-4")},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-300 font-medium")},
            list{text("Agent Orchestra")},
          ),
          button(
            list{
              Attrs.class_("text-xs text-gray-500 hover:text-gray-300 cursor-pointer"),
              Events.onClick(Tentacles(ToggleOrchestraCompact)),
            },
            list{text(state.orchestraCompact ? "Expand" : "Compact")},
          ),
        },
      ),
      // Agent grid
      div(
        list{
          Attrs.class_(
            state.orchestraCompact
              ? "grid grid-cols-7 gap-2"
              : "grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3",
          ),
        },
        state.agents
        ->Array.map(a => renderAgentCard(a, a.id == state.selectedAgent, state.orchestraCompact))
        ->List.fromArray,
      ),
      // Summary stats
      div(
        list{Attrs.class_("mt-4 flex gap-6 text-xs text-gray-500 border-t border-gray-800 pt-3")},
        list{
          span(list{}, list{text(Int.toString(busyCount(state.agents)) ++ " active")}),
          span(list{}, list{text(Int.toString(errorCount(state.agents)) ++ " errors")}),
          span(list{}, list{text(Int.toString(totalConstraints(state.agents)) ++ " constraints")}),
          span(list{}, list{text(Int.toString(totalResults(state.agents)) ++ " results")}),
          if state.ffiConnected {
            span(list{Attrs.class_("text-green-500")}, list{text("FFI Connected")})
          } else {
            span(list{Attrs.class_("text-gray-600")}, list{text("FFI Disconnected")})
          },
        },
      ),
    },
  )
}

/// Render the Stage Config tab.
let renderStageConfig = (state: tentaclesState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4")},
    list{
      div(
        list{Attrs.class_("text-sm text-gray-300 font-medium mb-4")},
        list{text("Progressive Reveal Stage")},
      ),
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-4")},
        list{
          text(
            "Set the global stage to control which compiler concepts are revealed to all agents.",
          ),
        },
      ),
      // Stage selector
      div(
        list{Attrs.class_("flex flex-col gap-3")},
        allStages
        ->Array.map(stage => {
          let isActive = stage == state.globalStage
          let cls = isActive
            ? "p-3 rounded-lg border border-cyan-500 bg-cyan-900/20 cursor-pointer"
            : "p-3 rounded-lg border border-gray-700 bg-gray-800/40 cursor-pointer hover:border-gray-500"
          div(
            list{Attrs.class_(cls), Events.onClick(Tentacles(SetGlobalStage(stage)))},
            list{
              div(
                list{Attrs.class_("flex justify-between items-center")},
                list{
                  span(
                    list{
                      Attrs.class_(
                        isActive ? "text-sm text-cyan-300 font-medium" : "text-sm text-gray-300",
                      ),
                    },
                    list{text(stageLabel(stage))},
                  ),
                  if isActive {
                    span(list{Attrs.class_("text-xs text-cyan-400")}, list{text("ACTIVE")})
                  } else {
                    noNode
                  },
                },
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500 mt-1")},
                list{
                  text(
                    switch stage {
                    | Cuttle => "Introductory stage. Game-like interactions, gentle metaphors, hidden compiler concepts."
                    | Squidlet => "Intermediate stage. Pattern-matching challenges, revealed connections between games and code."
                    | Duet => "Paired reasoning stage. Two agents collaborate, showing how compiler subsystems interact."
                    | Octopus => "Full access stage. Direct compiler subsystem interaction, formal methods, proof obligations."
                    },
                  ),
                },
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Render the Progress tab.
let renderProgress = (state: tentaclesState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4")},
    list{
      div(
        list{Attrs.class_("text-sm text-gray-300 font-medium mb-4")},
        list{text("Progress Dashboard")},
      ),
      // Per-agent stats
      div(
        list{Attrs.class_("flex flex-col gap-2")},
        state.agents
        ->Array.map(a => {
          let textCls = tentacleTextClass(a.id)
          let bgCls = tentacleBgClass(a.id)
          let constraintCount = Array.length(a.constraints)
          let resultCount = Array.length(a.results)
          let verifiedCount = a.results->Array.filter(r => r.verified)->Array.length
          div(
            list{Attrs.class_(`p-3 rounded-lg ${bgCls} border border-gray-700/50`)},
            list{
              div(
                list{Attrs.class_("flex justify-between items-center mb-1")},
                list{
                  span(
                    list{Attrs.class_(`text-sm font-medium ${textCls}`)},
                    list{text(agentDisplayName(a))},
                  ),
                  span(list{Attrs.class_("text-xs text-gray-500")}, list{text(tentacleRole(a.id))}),
                },
              ),
              div(
                list{Attrs.class_("flex gap-4 text-xs text-gray-500")},
                list{
                  span(list{}, list{text(Int.toString(constraintCount) ++ " constraints")}),
                  span(list{}, list{text(Int.toString(resultCount) ++ " results")}),
                  span(list{}, list{text(Int.toString(verifiedCount) ++ " verified")}),
                  span(list{}, list{text("Stage: " ++ stageLabel(a.stage))}),
                },
              ),
            },
          )
        })
        ->List.fromArray,
      ),
      // FFI status
      div(
        list{Attrs.class_("mt-4 p-3 rounded-lg bg-gray-800/40 border border-gray-700/50")},
        list{
          div(
            list{Attrs.class_("flex justify-between items-center")},
            list{
              span(list{Attrs.class_("text-xs text-gray-400")}, list{text("ECHIDNA FFI Bridge")}),
              if state.ffiConnected {
                span(list{Attrs.class_("text-xs text-green-400")}, list{text("Connected")})
              } else {
                span(list{Attrs.class_("text-xs text-gray-600")}, list{text("Disconnected")})
              },
            },
          ),
          switch state.ffiError {
          | Some(err) => div(list{Attrs.class_("mt-1 text-xs text-red-400")}, list{text(err)})
          | None => noNode
          },
          div(
            list{Attrs.class_("mt-2")},
            list{
              button(
                list{
                  Attrs.class_("text-xs text-cyan-400 hover:text-cyan-300 cursor-pointer"),
                  Events.onClick(Tentacles(CheckFfiBridge)),
                },
                list{text("Check Connection")},
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Main view for the Tentacles panel.
let view = (state: tentaclesState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("fixed inset-0 z-40 bg-gray-950/95 flex flex-col")},
    list{
      // Panel header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-sm font-medium text-gray-200")},
                list{text("7-Tentacles")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("Compiler Agent Orchestra")},
              ),
            },
          ),
          // Close button
          button(
            list{
              Attrs.class_("text-gray-500 hover:text-gray-300 text-xs cursor-pointer"),
              Events.onClick(PanelSwitcher(TogglePanel(PanelTentacles))),
            },
            list{text("[X]")},
          ),
        },
      ),
      // Tab bar
      div(
        list{Attrs.class_("flex gap-1 px-4 pt-2 border-b border-gray-800")},
        allCategories
        ->Array.map(cat => renderTab(categoryLabel(cat), cat == state.activeCategory, cat))
        ->List.fromArray,
      ),
      // Content area
      div(
        list{Attrs.class_("flex-1 overflow-auto")},
        list{
          switch state.activeCategory {
          | AgentView => renderAgentView(state)
          | Orchestra => renderOrchestra(state)
          | StageConfig => renderStageConfig(state)
          | Progress => renderProgress(state)
          },
        },
      ),
    },
  )
}
