// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Neurosymbolic Bridge Component — ECHIDNA guard AI behaviour reasoning.
/// Displays guard rule lists, behaviour tree viewers, simulation controls, and
/// analysis results for guard AI correctness.

open Model
open Msg
open Tea.Html

/// Render a rule status badge.
let ruleStatusBadge = (status: ruleStatus): Tea_Vdom.t<msg> => {
  let (color, label) = switch status {
  | RuleVerified => ("bg-green-700 text-green-100", "Verified")
  | RuleUnverified => ("bg-gray-700 text-gray-300", "Unverified")
  | RuleViolated => ("bg-red-700 text-red-100", "Violated")
  | RuleConflict => ("bg-yellow-700 text-yellow-100", "Conflict")
  }
  span(list{Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color)}, list{text(label)})
}

/// Render a priority indicator.
let priorityIndicator = (prio: rulePriority): Tea_Vdom.t<msg> => {
  let (color, label) = switch prio {
  | PriorityCritical => ("text-red-400", "CRIT")
  | PriorityHigh => ("text-orange-400", "HIGH")
  | PriorityNormal => ("text-blue-400", "NORM")
  | PriorityLow => ("text-gray-500", "LOW")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Render a behaviour tree node type badge.
let nodeTypeBadge = (nt: behaviourNodeType): Tea_Vdom.t<msg> => {
  let (color, label) = switch nt {
  | NodeSequence => ("text-blue-400", "SEQ")
  | NodeSelector => ("text-purple-400", "SEL")
  | NodeParallel => ("text-cyan-400", "PAR")
  | NodeDecorator => ("text-yellow-400", "DEC")
  | NodeAction => ("text-green-400", "ACT")
  | NodeCondition => ("text-orange-400", "CND")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text("[" ++ label ++ "]")})
}

/// Main view function for the Neurosym Bridge panel.
let view = (state: neurosymBridgeState): Tea_Vdom.t<msg> => {
  let verifiedCount = state.guardRules->Array.filter(r => r.status == RuleVerified)->Array.length
  let totalRules = Array.length(state.guardRules)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Neurosymbolic Bridge — ECHIDNA Guard AI Reasoning"),
    },
    list{
      // Header row
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-bold text-violet-300")}, list{text("Neurosymbolic Bridge")}),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{text(Int.toString(verifiedCount) ++ "/" ++ Int.toString(totalRules) ++ " rules verified")},
              ),
              if state.simulating {
                span(list{Attrs.class_("text-xs text-yellow-400 animate-pulse")}, list{text("Simulating...")})
              } else {
                Tea_Html.noNode
              },
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-violet-800 hover:bg-violet-700 text-white rounded"),
              Events.onClick(NeurosymBridge(NbStarted)),
            },
            list{text("Run Simulation")},
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
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Rules { "bg-violet-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(NeurosymBridge(SetNbTab(Rules))),
            },
            list{text("Rules")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == BehaviourTree { "bg-violet-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(NeurosymBridge(SetNbTab(BehaviourTree))),
            },
            list{text("Behaviour Tree")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Simulation { "bg-violet-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(NeurosymBridge(SetNbTab(Simulation))),
            },
            list{text("Simulation")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Analysis { "bg-violet-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(NeurosymBridge(SetNbTab(Analysis))),
            },
            list{text("Analysis")},
          ),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200 flex justify-between items-center")},
          list{
            text(err),
            button(
              list{Attrs.class_("text-red-400 hover:text-red-200 text-xs ml-2"), Events.onClick(NeurosymBridge(DismissNbError))},
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
          | Rules =>
            div(
              list{},
              state.guardRules
              ->Array.map(r =>
                div(
                  list{Attrs.class_("flex items-center gap-3 py-2 border-b border-gray-800/50")},
                  list{
                    priorityIndicator(r.priority),
                    div(
                      list{Attrs.class_("flex-1 min-w-0")},
                      list{
                        div(list{Attrs.class_("text-sm font-mono text-gray-200")}, list{text(r.name)}),
                        div(list{Attrs.class_("text-xs text-gray-500")}, list{text(r.condition ++ " => " ++ r.expectedAction)}),
                      },
                    ),
                    ruleStatusBadge(r.status),
                  },
                )
              )
              ->List.fromArray,
            )
          | BehaviourTree =>
            div(
              list{Attrs.class_("font-mono text-sm")},
              state.behaviourNodes
              ->Array.map(node =>
                div(
                  list{Attrs.class_("py-1 flex items-center gap-2 pl-" ++ Int.toString(Array.length(node.children) > 0 ? 0 : 4))},
                  list{
                    nodeTypeBadge(node.nodeType),
                    span(list{Attrs.class_("text-gray-200")}, list{text(node.label)}),
                    switch node.condition {
                    | Some(cond) =>
                      span(list{Attrs.class_("text-xs text-yellow-400")}, list{text("when: " ++ cond)})
                    | None => Tea_Html.noNode
                    },
                    switch node.action {
                    | Some(act) =>
                      span(list{Attrs.class_("text-xs text-green-400")}, list{text("do: " ++ act)})
                    | None => Tea_Html.noNode
                    },
                    span(
                      list{Attrs.class_("text-xs text-gray-600")},
                      list{text(Int.toString(Array.length(node.children)) ++ " children")},
                    ),
                  },
                )
              )
              ->List.fromArray,
            )
          | Simulation =>
            switch state.simulationResults {
            | Some(sim) =>
              div(
                list{},
                list{
                  div(
                    list{Attrs.class_("flex gap-4 mb-4 text-xs text-gray-400")},
                    list{
                      span(list{}, list{text("Steps: " ++ Int.toString(sim.totalSteps))}),
                      span(list{}, list{text("Deviations: " ++ Int.toString(sim.deviations))}),
                      span(
                        list{Attrs.class_(if sim.completed { "text-green-400" } else { "text-red-400" })},
                        list{text(if sim.completed { "Completed" } else { "Interrupted" })},
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("space-y-1")},
                    sim.steps
                    ->Array.map(step => {
                      let outcomeColor = switch step.outcome {
                      | StepSuccess => "border-green-800"
                      | StepDeviation => "border-yellow-800"
                      | StepDeadlock => "border-red-800"
                      }
                      div(
                        list{Attrs.class_("flex items-center gap-3 py-1 border-l-2 pl-2 " ++ outcomeColor)},
                        list{
                          span(list{Attrs.class_("text-xs text-gray-500 w-8")}, list{text("#" ++ Int.toString(step.stepNumber))}),
                          span(list{Attrs.class_("text-sm text-gray-300 flex-1")}, list{text(step.actionTaken)}),
                          span(list{Attrs.class_("text-xs text-gray-500")}, list{text(Float.toFixed(step.elapsedMs, ~digits=1) ++ "ms")}),
                        },
                      )
                    })
                    ->List.fromArray,
                  ),
                },
              )
            | None =>
              div(
                list{Attrs.class_("text-center text-gray-500 py-8")},
                list{text("No simulation results yet. Run a simulation to see guard AI behaviour.")},
              )
            }
          | Analysis =>
            switch state.simulationResults {
            | Some(sim) =>
              div(
                list{Attrs.class_("space-y-4")},
                list{
                  div(
                    list{Attrs.class_("px-3 py-3 bg-gray-900 border border-gray-800 rounded")},
                    list{
                      h3(list{Attrs.class_("text-sm text-violet-300 mb-2")}, list{text("ECHIDNA Analysis Summary")}),
                      p(list{Attrs.class_("text-sm text-gray-300")}, list{text(sim.analysisSummary)}),
                    },
                  ),
                  div(
                    list{Attrs.class_("text-xs text-gray-400")},
                    list{
                      text(
                        "Guard rules: " ++ Int.toString(totalRules) ++ " total, " ++
                        Int.toString(verifiedCount) ++ " verified (" ++
                        Float.toFixed(
                          if totalRules > 0 { Int.toFloat(verifiedCount) /. Int.toFloat(totalRules) *. 100.0 } else { 0.0 },
                          ~digits=1,
                        ) ++ "%)",
                      ),
                    },
                  ),
                },
              )
            | None =>
              div(
                list{Attrs.class_("text-center text-gray-500 py-8")},
                list{text("Run a simulation to generate analysis results.")},
              )
            }
          },
        },
      ),
    },
  )
}
