// SPDX-License-Identifier: MPL-2.0

/// PanLL Automation Bridge Component — CI/CD pipeline orchestration for game
/// builds. Displays pipeline lists with step progress, trigger rules, build
/// status, and history table.

open Model
open Msg
open Tea.Html

/// Render a pipeline status badge.
let pipelineStatusBadge = (status: automationPipelineStatus): Tea_Vdom.t<msg> => {
  let (color, label) = switch status {
  | PipelineIdle => ("bg-gray-700 text-gray-300", "Idle")
  | PipelineQueued => ("bg-blue-700 text-blue-100", "Queued")
  | PipelineRunning => ("bg-yellow-700 text-yellow-100", "Running")
  | PipelineSucceeded => ("bg-green-700 text-green-100", "Passed")
  | PipelineFailed => ("bg-red-700 text-red-100", "Failed")
  | PipelineCancelled => ("bg-gray-600 text-gray-300", "Cancelled")
  }
  span(list{Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color)}, list{text(label)})
}

/// Render a trigger event label.
let triggerEventLabel = (evt: automationTriggerEvent): string => {
  switch evt {
  | TriggerPush => "Push"
  | TriggerPullRequest => "PR"
  | TriggerTag => "Tag"
  | TriggerSchedule => "Cron"
  | TriggerManual => "Manual"
  | TriggerFileChange => "FileChange"
  }
}

/// Main view function for the Automation Bridge panel.
let view = (state: automationBridgeState): Tea_Vdom.t<msg> => {
  let totalPipelines = Array.length(state.pipelines)
  let runningCount = state.pipelines->Array.filter(p => p.status == PipelineRunning)->Array.length

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Automation Bridge — CI/CD Pipeline Orchestration"),
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
                list{Attrs.class_("text-lg font-bold text-emerald-300")},
                list{text("Automation Bridge")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{
                  text(
                    Int.toString(totalPipelines) ++
                    " pipelines, " ++
                    Int.toString(runningCount) ++ " running",
                  ),
                },
              ),
            },
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs bg-emerald-800 hover:bg-emerald-700 text-white rounded",
              ),
              Events.onClick(AutomationBridge(AutoBStarted)),
              KeyboardNav.onActivate(AutomationBridge(AutoBStarted)),
            },
            list{text("Trigger Build")},
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
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Pipelines {
                  "bg-emerald-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AutomationBridge(SetAutoBTab(Pipelines))),
            },
            list{text("Pipelines")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Triggers {
                  "bg-emerald-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AutomationBridge(SetAutoBTab(Triggers))),
            },
            list{text("Triggers")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Status {
                  "bg-emerald-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AutomationBridge(SetAutoBTab(Status))),
            },
            list{text("Status")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == History {
                  "bg-emerald-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(AutomationBridge(SetAutoBTab(History))),
            },
            list{text("History")},
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
                Events.onClick(AutomationBridge(DismissAutoBError)),
                KeyboardNav.onActivate(AutomationBridge(DismissAutoBError)),
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
          | Pipelines =>
            div(
              list{Attrs.class_("space-y-3")},
              state.pipelines
              ->Array.map(pipe =>
                div(
                  list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center justify-between mb-2")},
                      list{
                        span(
                          list{Attrs.class_("text-sm font-bold text-gray-200")},
                          list{text(pipe.name)},
                        ),
                        pipelineStatusBadge(pipe.status),
                      },
                    ),
                    // Step progress
                    div(
                      list{Attrs.class_("space-y-1")},
                      pipe.steps
                      ->Array.map(step =>
                        div(
                          list{Attrs.class_("flex items-center gap-2")},
                          list{
                            span(
                              list{
                                Attrs.class_(
                                  "w-2 h-2 rounded-full " ++
                                  switch step.status {
                                  | PipelineSucceeded => "bg-green-500"
                                  | PipelineFailed => "bg-red-500"
                                  | PipelineRunning => "bg-yellow-500 animate-pulse"
                                  | _ => "bg-gray-600"
                                  },
                                ),
                              },
                              list{},
                            ),
                            span(
                              list{Attrs.class_("text-xs text-gray-400 flex-1")},
                              list{text(step.name)},
                            ),
                            switch step.durationMs {
                            | Some(d) =>
                              span(
                                list{Attrs.class_("text-xs text-gray-600")},
                                list{text(Float.toFixed(d, ~digits=0) ++ "ms")},
                              )
                            | None => Tea_Html.noNode
                            },
                          },
                        )
                      )
                      ->List.fromArray,
                    ),
                  },
                )
              )
              ->List.fromArray,
            )
          | Triggers =>
            div(
              list{Attrs.class_("space-y-2")},
              state.triggers
              ->Array.map(t =>
                div(
                  list{Attrs.class_("flex items-center gap-3 py-2 border-b border-gray-800/50")},
                  list{
                    span(
                      list{
                        Attrs.class_(
                          "w-2 h-2 rounded-full " ++ if t.enabled {
                            "bg-green-500"
                          } else {
                            "bg-gray-600"
                          },
                        ),
                      },
                      list{},
                    ),
                    div(
                      list{Attrs.class_("flex-1 min-w-0")},
                      list{
                        div(list{Attrs.class_("text-sm text-gray-200")}, list{text(t.description)}),
                        div(
                          list{Attrs.class_("text-xs text-gray-500")},
                          list{text(triggerEventLabel(t.event) ++ " | " ++ t.pattern)},
                        ),
                      },
                    ),
                    span(
                      list{Attrs.class_("text-xs font-mono text-gray-500")},
                      list{text(t.pipelineId)},
                    ),
                  },
                )
              )
              ->List.fromArray,
            )
          | Status =>
            div(
              list{Attrs.class_("space-y-2")},
              state.pipelines
              ->Array.filter(p => p.status == PipelineRunning || p.status == PipelineQueued)
              ->Array.map(pipe => {
                let completedSteps =
                  pipe.steps->Array.filter(s => s.status == PipelineSucceeded)->Array.length
                let totalSteps = Array.length(pipe.steps)
                div(
                  list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center justify-between mb-1")},
                      list{
                        span(list{Attrs.class_("text-sm text-gray-200")}, list{text(pipe.name)}),
                        span(
                          list{Attrs.class_("text-xs text-gray-400")},
                          list{
                            text(
                              Int.toString(completedSteps) ++
                              "/" ++
                              Int.toString(totalSteps) ++ " steps",
                            ),
                          },
                        ),
                      },
                    ),
                    // Progress bar
                    div(
                      list{Attrs.class_("w-full h-2 bg-gray-800 rounded overflow-hidden")},
                      list{
                        div(
                          list{
                            Attrs.class_("h-full bg-emerald-500 transition-all"),
                            Attrs.style(
                              "width",
                              Float.toFixed(
                                if totalSteps > 0 {
                                  Int.toFloat(completedSteps) /. Int.toFloat(totalSteps) *. 100.0
                                } else {
                                  0.0
                                },
                                ~digits=1,
                              ) ++ "%",
                            ),
                          },
                          list{},
                        ),
                      },
                    ),
                  },
                )
              })
              ->List.fromArray,
            )
          | History =>
            div(
              list{},
              list{
                // History table header
                div(
                  list{
                    Attrs.class_(
                      "flex gap-2 text-xs text-gray-500 font-mono border-b border-gray-800 pb-1 mb-2",
                    ),
                  },
                  list{
                    span(list{Attrs.class_("w-24")}, list{text("Build")}),
                    span(list{Attrs.class_("flex-1")}, list{text("Pipeline")}),
                    span(list{Attrs.class_("w-16")}, list{text("Trigger")}),
                    span(list{Attrs.class_("w-20")}, list{text("Duration")}),
                    span(list{Attrs.class_("w-20")}, list{text("Status")}),
                  },
                ),
                div(
                  list{Attrs.class_("space-y-1")},
                  state.buildHistory
                  ->Array.map(entry =>
                    div(
                      list{Attrs.class_("flex gap-2 text-xs py-1 border-b border-gray-800/30")},
                      list{
                        span(
                          list{Attrs.class_("w-24 font-mono text-gray-500 truncate")},
                          list{text(entry.commitSha->String.slice(~start=0, ~end=7))},
                        ),
                        span(
                          list{Attrs.class_("flex-1 text-gray-300")},
                          list{text(entry.pipelineName)},
                        ),
                        span(
                          list{Attrs.class_("w-16 text-gray-500")},
                          list{text(triggerEventLabel(entry.triggeredBy))},
                        ),
                        span(
                          list{Attrs.class_("w-20 text-gray-500")},
                          list{text(Float.toFixed(entry.durationMs /. 1000.0, ~digits=1) ++ "s")},
                        ),
                        span(list{Attrs.class_("w-20")}, list{pipelineStatusBadge(entry.status)}),
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
