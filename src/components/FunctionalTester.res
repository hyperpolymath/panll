// SPDX-License-Identifier: MPL-2.0

/// PanLL FunctionalTester — end-to-end game workflow simulation and validation.
///
/// Provides four tabs: a workflow list with progress indicators, a step-by-step
/// editor for composing workflow sequences, a results view showing pass/fail
/// per step, and a templates library for common game-testing patterns.

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tab label lookup for functionalTestTab variants.
let tabLabel = (tab: functionalTestTab): string =>
  switch tab {
  | TabWorkflows => "Workflows"
  | TabEditor => "Editor"
  | TabResults => "Results"
  | TabTemplates => "Templates"
  }

/// Render the tab bar.
let renderTabs = (active: functionalTestTab): Tea_Vdom.t<msg> => {
  let tabs: array<functionalTestTab> = [TabWorkflows, TabEditor, TabResults, TabTemplates]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-cyan-400 border-b-2 border-cyan-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900 cursor-pointer"}`,
          ),
          Events.onClick(FunctionalTester(SetFtTab(tab))),
        },
        list{text(tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Workflow status badge with colour and animation for running workflows.
let workflowStatusBadge = (status: workflowStatus): Tea_Vdom.t<msg> => {
  let (colour, lbl) = switch status {
  | WorkflowDraft => ("bg-gray-600 text-gray-200", "DRAFT")
  | WorkflowReady => ("bg-blue-600 text-white", "READY")
  | WorkflowRunning(step) => (
      "bg-amber-500 text-white animate-pulse",
      `STEP ${Int.toString(step + 1)}`,
    )
  | WorkflowPassed(ms) => ("bg-emerald-600 text-white", `PASS ${Float.toFixed(ms, ~digits=0)}ms`)
  | WorkflowFailed(_, _) => ("bg-red-600 text-white", "FAIL")
  }
  span(list{Attrs.class_(`px-2 py-0.5 text-xs rounded font-mono ${colour}`)}, list{text(lbl)})
}

/// Progress bar for a workflow based on completed steps vs total.
let workflowProgress = (workflow: testWorkflow): Tea_Vdom.t<msg> => {
  let total = Array.length(workflow.steps)
  if total === 0 {
    noNode
  } else {
    let completed = workflow.steps->Array.filter(s => Option.isSome(s.passed))->Array.length
    let pct = Int.toString(Int.fromFloat(Int.toFloat(completed) /. Int.toFloat(total) *. 100.0))
    div(
      list{Attrs.class_("w-full h-1.5 bg-gray-700 rounded overflow-hidden mt-1")},
      list{
        div(
          list{Attrs.class_(`h-full bg-cyan-500 transition-all duration-300 w-[${pct}%]`)},
          list{},
        ),
      },
    )
  }
}

// =========================================================================
// Tab content views
// =========================================================================

/// Workflows tab: list of all workflows with status badges and progress.
let renderWorkflowsTab = (state: functionalTesterState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4")},
    list{
      div(
        list{Attrs.class_("text-sm text-gray-400 mb-1")},
        list{text(`${Int.toString(Array.length(state.workflows))} workflow(s)`)},
      ),
      div(
        list{Attrs.class_("flex flex-col gap-2 max-h-96 overflow-y-auto")},
        state.workflows
        ->Array.map(wf => {
          let isSelected = state.selectedWorkflow === Some(wf.id)
          let borderCls = isSelected ? "border-cyan-600" : "border-gray-700"
          div(
            list{
              Attrs.class_(`bg-gray-800 rounded p-3 border ${borderCls} cursor-pointer`),
              Events.onClick(FunctionalTester(SelectWorkflow(wf.id))),
            },
            list{
              div(
                list{Attrs.class_("flex items-center justify-between")},
                list{
                  span(
                    list{Attrs.class_("text-sm font-medium text-gray-200")},
                    list{text(wf.name)},
                  ),
                  workflowStatusBadge(wf.status),
                },
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500 mt-1")},
                list{text(`${Int.toString(Array.length(wf.steps))} step(s)`)},
              ),
              workflowProgress(wf),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Editor tab: step-by-step view for the selected workflow.
let renderEditorTab = (state: functionalTesterState): Tea_Vdom.t<msg> => {
  let selectedWf = state.workflows->Array.find(wf => Some(wf.id) === state.selectedWorkflow)
  switch selectedWf {
  | None =>
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("Select a workflow from the Workflows tab to edit its steps.")},
    )
  | Some(wf) =>
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4")},
      list{
        h3(
          list{Attrs.class_("text-sm font-medium text-gray-300")},
          list{text(`Editing: ${wf.name}`)},
        ),
        div(
          list{Attrs.class_("flex flex-col gap-2 max-h-96 overflow-y-auto")},
          wf.steps
          ->Array.mapWithIndex((step, idx) => {
            let stepColour = switch step.passed {
            | Some(true) => "border-emerald-700"
            | Some(false) => "border-red-700"
            | None => "border-gray-700"
            }
            div(
              list{Attrs.class_(`bg-gray-800 rounded p-3 border ${stepColour}`)},
              list{
                div(
                  list{Attrs.class_("flex items-center gap-2 mb-1")},
                  list{
                    span(
                      list{Attrs.class_("text-xs text-gray-500 font-mono")},
                      list{text(`#${Int.toString(idx + 1)}`)},
                    ),
                    span(list{Attrs.class_("text-sm text-gray-200")}, list{text(step.action)}),
                  },
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-500")},
                  list{text(`Expected: ${step.expectedOutcome}`)},
                ),
                switch step.actualOutcome {
                | Some(actual) =>
                  div(
                    list{Attrs.class_("text-xs text-gray-400 mt-1")},
                    list{text(`Actual: ${actual}`)},
                  )
                | None => noNode
                },
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Results tab: aggregated pass/fail results for all workflows.
let renderResultsTab = (state: functionalTesterState): Tea_Vdom.t<msg> => {
  let passedCount =
    state.workflows
    ->Array.filter(wf =>
      switch wf.status {
      | WorkflowPassed(_) => true
      | _ => false
      }
    )
    ->Array.length
  let failedCount =
    state.workflows
    ->Array.filter(wf =>
      switch wf.status {
      | WorkflowFailed(_, _) => true
      | _ => false
      }
    )
    ->Array.length

  div(
    list{Attrs.class_("flex flex-col gap-3 p-4")},
    list{
      div(
        list{Attrs.class_("grid grid-cols-3 gap-3")},
        list{
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-gray-300")},
                list{text(Int.toString(Array.length(state.workflows)))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Total")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-emerald-400")},
                list{text(Int.toString(passedCount))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Passed")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-red-400")},
                list{text(Int.toString(failedCount))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Failed")}),
            },
          ),
        },
      ),
    },
  )
}

/// Templates tab: library of reusable workflow templates.
let renderTemplatesTab = (_state: functionalTesterState): Tea_Vdom.t<msg> => {
  let templates = [
    ("Login Flow", "Complete user authentication cycle"),
    ("Tutorial Walkthrough", "First-time user experience path"),
    ("Combat Loop", "Engage guard, evade, complete level"),
    ("Inventory CRUD", "Create, equip, drop, destroy items"),
    ("Multiplayer Join", "Connect, sync, verify game state"),
  ]
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4")},
    templates
    ->Array.map(((name, desc)) => {
      div(
        list{Attrs.class_("bg-gray-800 rounded p-3 border border-gray-700")},
        list{
          div(
            list{Attrs.class_("flex items-center justify-between")},
            list{
              span(list{Attrs.class_("text-sm font-medium text-gray-200")}, list{text(name)}),
              button(
                list{
                  Attrs.class_(
                    "px-2 py-1 text-xs bg-cyan-700 text-white rounded hover:bg-cyan-600 cursor-pointer",
                  ),
                  Events.onClick(FunctionalTester(LoadTemplate(name))),
                },
                list{text("Use")},
              ),
            },
          ),
          span(list{Attrs.class_("text-xs text-gray-500")}, list{text(desc)}),
        },
      )
    })
    ->List.fromArray,
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function dispatching tab content based on active tab.
let view = (state: functionalTesterState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabWorkflows => renderWorkflowsTab(state)
  | TabEditor => renderEditorTab(state)
  | TabResults => renderResultsTab(state)
  | TabTemplates => renderTemplatesTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold text-cyan-300")},
            list{text("Functional Tester")},
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-blue-700 text-white rounded hover:bg-blue-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(FunctionalTester(NewWorkflow)),
                  KeyboardNav.onActivate(FunctionalTester(NewWorkflow)),
                },
                list{text("New Workflow")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(FunctionalTester(RunWorkflow(""))),
                },
                list{text("Run")},
              ),
            },
          ),
        },
      ),
      // Running indicator
      if state.running {
        div(
          list{
            Attrs.class_("flex items-center gap-2 px-4 py-2 bg-gray-800 border-b border-gray-700"),
          },
          list{
            div(list{Attrs.class_("w-3 h-3 bg-amber-400 rounded-full animate-pulse")}, list{}),
            span(list{Attrs.class_("text-sm text-amber-300")}, list{text("Workflow running...")}),
          },
        )
      } else {
        noNode
      },
      // Error display
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_("px-4 py-2 bg-red-900/30 text-red-300 text-sm border-b border-red-800"),
          },
          list{text(err)},
        )
      | None => noNode
      },
      // Tab bar
      renderTabs(state.activeTab),
      // Content
      div(list{Attrs.class_("flex-1 overflow-y-auto")}, list{content}),
    },
  )
}
