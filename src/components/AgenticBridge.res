// SPDX-License-Identifier: MPL-2.0

/// PanLL Agentic Bridge Component — automated playtesting agents with OODA loop
/// phases. Displays agent lists with phase badges, configuration panel,
/// execution log, and findings.

open Model
open Msg
open Tea.Html

/// Render an OODA phase badge with colour coding.
/// Observe=blue, Orient=yellow, Decide=orange, Act=green.
let oodaPhaseBadge = (phase: oodaPhase): Tea_Vdom.t<msg> => {
  let (color, label) = switch phase {
  | Observe => ("bg-blue-700 text-blue-100", "Observe")
  | Orient => ("bg-yellow-700 text-yellow-100", "Orient")
  | Decide => ("bg-orange-700 text-orange-100", "Decide")
  | Act => ("bg-green-700 text-green-100", "Act")
  }
  span(list{Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color)}, list{text(label)})
}

/// Render an agent status indicator.
let agentStatusBadge = (status: agentStatus): Tea_Vdom.t<msg> => {
  let (color, label) = switch status {
  | AgentIdle => ("text-gray-500", "Idle")
  | AgentRunning => ("text-green-400 animate-pulse", "Running")
  | AgentPaused => ("text-yellow-400", "Paused")
  | AgentCompleted => ("text-blue-400", "Completed")
  | AgentFailed => ("text-red-400", "Failed")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Render a finding severity badge.
let findingSevBadge = (sev: findingSeverity): Tea_Vdom.t<msg> => {
  let (color, label) = switch sev {
  | FindingCritical => ("bg-red-700 text-red-100", "Critical")
  | FindingMajor => ("bg-orange-700 text-orange-100", "Major")
  | FindingMinor => ("bg-yellow-700 text-yellow-100", "Minor")
  | FindingObservation => ("bg-gray-700 text-gray-300", "Obs")
  }
  span(list{Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color)}, list{text(label)})
}

/// Main view function for the Agentic Bridge panel.
let view = (state: agenticBridgeState): Tea_Vdom.t<msg> => {
  let totalAgents = Array.length(state.agents)
  let runningAgents = state.agents->Array.filter(a => a.status == AgentRunning)->Array.length
  let allFindings = state.agents->Array.flatMap(a => a.findings)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Agentic Bridge — Automated Playtesting Agents"),
    },
    list{
      // Header row
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-bold text-amber-300")},
                list{text("Agentic Bridge")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{
                  text(
                    Int.toString(totalAgents) ++
                    " agents, " ++
                    Int.toString(runningAgents) ++ " active",
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs bg-amber-800 hover:bg-amber-700 text-white rounded",
                  ),
                  Events.onClick(AgenticBridge(AbStarted)),
                  KeyboardNav.onActivate(AgenticBridge(AbStarted)),
                },
                list{text("Launch All")},
              ),
            },
          ),
        },
      ),
      // Tab bar
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Agents {
                  "bg-amber-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AgenticBridge(SetAbTab(Agents))),
            },
            list{text("Agents")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Config {
                  "bg-amber-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AgenticBridge(SetAbTab(Config))),
            },
            list{text("Config")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Execution {
                  "bg-amber-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AgenticBridge(SetAbTab(Execution))),
            },
            list{text("Execution")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Results {
                  "bg-amber-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AgenticBridge(SetAbTab(Results))),
            },
            list{text("Results")},
          ),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200 flex justify-between items-center",
            ),
          },
          list{
            text(err),
            button(
              list{
                Attrs.class_("text-red-400 hover:text-red-200 text-xs ml-2"),
                Events.onClick(AgenticBridge(DismissAbError)),
                KeyboardNav.onActivate(AgenticBridge(DismissAbError)),
              },
              list{text("Dismiss")},
            ),
          },
        )
      | None => Tea_Html.noNode
      },
      // Content area
      div(
        list{Attrs.class_("flex-1 overflow-y-auto px-4 py-4")},
        list{
          switch state.activeTab {
          | Agents =>
            div(
              list{Attrs.class_("space-y-2")},
              state.agents
              ->Array.map(agent =>
                div(
                  list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-3")},
                      list{
                        span(
                          list{Attrs.class_("text-sm font-bold text-gray-200")},
                          list{text(agent.name)},
                        ),
                        oodaPhaseBadge(agent.oodaPhase),
                        agentStatusBadge(agent.status),
                      },
                    ),
                    div(
                      list{Attrs.class_("flex gap-4 mt-1 text-xs text-gray-500")},
                      list{
                        span(
                          list{},
                          list{text(Int.toString(Array.length(agent.actions)) ++ " actions")},
                        ),
                        span(
                          list{},
                          list{text(Int.toString(Array.length(agent.findings)) ++ " findings")},
                        ),
                      },
                    ),
                  },
                )
              )
              ->List.fromArray,
            )
          | Config =>
            div(
              list{Attrs.class_("space-y-2")},
              state.agentConfigs
              ->Array.map(cfg => {
                let strategyLabel = switch cfg.strategy {
                | StrategyRandom => "Random"
                | StrategyExhaustive => "Exhaustive"
                | StrategyAdversarial => "Adversarial"
                | StrategyReplay => "Replay"
                }
                div(
                  list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                  list{
                    div(
                      list{Attrs.class_("text-sm text-gray-200 font-mono mb-1")},
                      list{text("Agent: " ++ cfg.agentId)},
                    ),
                    div(
                      list{Attrs.class_("grid grid-cols-2 gap-x-4 gap-y-1 text-xs text-gray-400")},
                      list{
                        span(
                          list{},
                          list{text("Speed: " ++ Float.toFixed(cfg.speed, ~digits=1) ++ "x")},
                        ),
                        span(list{}, list{text("Strategy: " ++ strategyLabel)}),
                        span(
                          list{},
                          list{
                            text(
                              "Thoroughness: " ++
                              Float.toFixed(cfg.thoroughness *. 100.0, ~digits=0) ++ "%",
                            ),
                          },
                        ),
                        span(list{}, list{text("Max cycles: " ++ Int.toString(cfg.maxCycles))}),
                        span(list{}, list{text("Seed: " ++ Int.toString(cfg.randomSeed))}),
                      },
                    ),
                  },
                )
              })
              ->List.fromArray,
            )
          | Execution =>
            div(
              list{Attrs.class_("space-y-1")},
              state.agents
              ->Array.filter(a => a.status == AgentRunning || a.status == AgentCompleted)
              ->Array.flatMap(a =>
                a.actions->Array.map(act =>
                  div(
                    list{Attrs.class_("flex items-center gap-3 py-1 border-b border-gray-800/30")},
                    list{
                      oodaPhaseBadge(act.phase),
                      span(
                        list{Attrs.class_("text-sm text-gray-300 flex-1")},
                        list{text(act.description)},
                      ),
                      span(
                        list{Attrs.class_("text-xs text-gray-500 font-mono")},
                        list{text(act.targetPath)},
                      ),
                      span(
                        list{Attrs.class_("text-xs text-gray-600")},
                        list{text(Float.toFixed(act.timestampMs, ~digits=0) ++ "ms")},
                      ),
                    },
                  )
                )
              )
              ->List.fromArray,
            )
          | Results =>
            div(
              list{Attrs.class_("space-y-2")},
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-400 mb-2")},
                  list{
                    text(
                      Int.toString(
                        Array.length(allFindings),
                      ) ++ " total findings across all agents",
                    ),
                  },
                ),
                div(
                  list{},
                  allFindings
                  ->Array.map(f =>
                    div(
                      list{
                        Attrs.class_("px-3 py-2 mb-2 bg-gray-900 border border-gray-800 rounded"),
                      },
                      list{
                        div(
                          list{Attrs.class_("flex items-center gap-2")},
                          list{
                            findingSevBadge(f.severity),
                            span(
                              list{Attrs.class_("text-sm text-gray-200")},
                              list{text(f.summary)},
                            ),
                          },
                        ),
                        div(list{Attrs.class_("text-xs text-gray-400 mt-1")}, list{text(f.detail)}),
                        div(
                          list{Attrs.class_("text-xs text-gray-500 font-mono mt-1")},
                          list{text(f.location)},
                        ),
                      },
                    )
                  )
                  ->List.fromArray,
                ),
              },
            )
          },
        },
      ),
    },
  )
}
