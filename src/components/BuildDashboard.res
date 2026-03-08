// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Build Dashboard Component — view for monitoring build processes,
/// test results, and compilation status across IDApTIK sub-projects.

open Model
open Msg
open Tea.Html

/// Render a category tab button.
let renderTab = (
  label: string,
  cat: buildDashboardCategory,
  active: buildDashboardCategory,
): Tea_Vdom.t<msg> => {
  let isActive = cat === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{Attrs.class_(cls), Events.onClick(BuildDashboard(SetBuildCategory(cat)))},
    list{text(label)},
  )
}

/// Render overview — target cards with status.
let renderOverview = (state: buildDashboardState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Stats row
      div(
        list{Attrs.class_("grid grid-cols-3 gap-3")},
        list{
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-red-400")},
                list{text(Int.toString(BuildDashboardEngine.errorCount(state.messages)))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Errors")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-amber-400")},
                list{text(Int.toString(BuildDashboardEngine.warningCount(state.messages)))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Warnings")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-emerald-400")},
                list{text(`${Int.toString(BuildDashboardEngine.passedTestCount(state.testResults))}/${Int.toString(Array.length(state.testResults))}`)},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Tests Passed")}),
            },
          ),
        },
      ),
      // Target cards
      div(
        list{Attrs.class_("grid grid-cols-2 lg:grid-cols-3 gap-3")},
        state.targets
        ->Array.map(((target, status)) => {
          let colourCls = BuildDashboardEngine.targetColour(target)
          let statusCls = BuildDashboardEngine.statusColour(status)
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded border border-gray-700")},
            list{
              div(
                list{Attrs.class_("flex items-center justify-between mb-2")},
                list{
                  span(list{Attrs.class_(`text-sm font-medium ${colourCls}`)}, list{text(BuildDashboardEngine.targetLabel(target))}),
                  span(list{Attrs.class_(`text-xs ${statusCls}`)}, list{text(BuildDashboardEngine.statusLabel(status))}),
                },
              ),
              div(
                list{Attrs.class_("flex items-center gap-2")},
                list{
                  button(
                    list{
                      Attrs.class_("px-2 py-1 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer"),
                      Events.onClick(BuildDashboard(TriggerBuild(target))),
                    },
                    list{text("Build")},
                  ),
                  button(
                    list{
                      Attrs.class_("px-2 py-1 text-xs bg-cyan-700 text-white rounded hover:bg-cyan-600 cursor-pointer"),
                      Events.onClick(BuildDashboard(RunTests(target))),
                    },
                    list{text("Test")},
                  ),
                },
              ),
            },
          )
        })
        ->List.fromArray,
      ),
      // Controls
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          button(
            list{
              Attrs.class_(
                if state.watchMode {
                  "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded"
                } else {
                  "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"
                },
              ),
              Events.onClick(BuildDashboard(ToggleWatchMode)),
            },
            list{text(if state.watchMode { "Watch Mode On" } else { "Watch Mode" })},
          ),
          button(
            list{
              Attrs.class_(
                if state.autoRebuild {
                  "px-3 py-1.5 text-xs bg-amber-700 text-white rounded"
                } else {
                  "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"
                },
              ),
              Events.onClick(BuildDashboard(ToggleAutoRebuild)),
            },
            list{text(if state.autoRebuild { "Auto-Rebuild On" } else { "Auto-Rebuild" })},
          ),
        },
      ),
    },
  )
}

/// Render errors/warnings list.
let renderErrors = (state: buildDashboardState): Tea_Vdom.t<msg> => {
  if Array.length(state.messages) === 0 {
    div(
      list{Attrs.class_("text-center text-emerald-400 text-sm py-8")},
      list{text("No build errors or warnings")},
    )
  } else {
    div(
      list{Attrs.class_("space-y-1 max-h-96 overflow-y-auto")},
      state.messages
      ->Array.map(m => {
        let sevCls = switch m.severity {
        | "error" => "border-red-800 bg-red-900/20"
        | "warning" => "border-amber-800 bg-amber-900/20"
        | _ => "border-gray-700 bg-gray-800"
        }
        let targetCls = BuildDashboardEngine.targetColour(m.target)
        div(
          list{
            Attrs.class_(`p-2 rounded border ${sevCls} cursor-pointer hover:opacity-80`),
            Events.onClick(EditorBridge(OpenFileInEditor(m.filePath, m.line))),
          },
          list{
            div(
              list{Attrs.class_("flex items-center gap-2 mb-1 text-xs")},
              list{
                span(list{Attrs.class_(`font-bold ${targetCls}`)}, list{text(BuildDashboardEngine.targetLabel(m.target))}),
                span(list{Attrs.class_("text-gray-400 font-mono")}, list{text(`${m.filePath}:${Int.toString(m.line)}:${Int.toString(m.col)}`)}),
              },
            ),
            div(list{Attrs.class_("text-xs text-gray-300")}, list{text(m.message)}),
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// Render test results.
let renderTests = (state: buildDashboardState): Tea_Vdom.t<msg> => {
  let results = if state.showPassedTests {
    state.testResults
  } else {
    state.testResults->Array.filter(r => !r.passed)
  }
  div(
    list{Attrs.class_("space-y-3")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                if state.showPassedTests {
                  "px-2 py-1 text-xs bg-gray-600 text-white rounded"
                } else {
                  "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                },
              ),
              Events.onClick(BuildDashboard(ToggleShowPassed)),
            },
            list{text("Show Passed")},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-400")},
            list{
              text(
                `${Int.toString(BuildDashboardEngine.passedTestCount(state.testResults))} passed, ${Int.toString(BuildDashboardEngine.failedTestCount(state.testResults))} failed`,
              ),
            },
          ),
        },
      ),
      if Array.length(results) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No test results")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-1")},
          results
          ->Array.map(r =>
            div(
              list{
                Attrs.class_(
                  `flex items-center gap-3 p-2 rounded text-xs ${if r.passed {
                      "bg-gray-800"
                    } else {
                      "bg-red-900/20 border border-red-800"
                    }}`,
                ),
              },
              list{
                span(
                  list{Attrs.class_(if r.passed { "text-emerald-400" } else { "text-red-400" })},
                  list{text(if r.passed { "PASS" } else { "FAIL" })},
                ),
                span(list{Attrs.class_("text-gray-200 flex-1")}, list{text(r.name)}),
                span(list{Attrs.class_("text-gray-500")}, list{text(r.suite)}),
                span(list{Attrs.class_("text-gray-400 font-mono")}, list{text(`${Float.toString(r.durationMs)}ms`)}),
              },
            )
          )
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render build history.
let renderHistory = (state: buildDashboardState): Tea_Vdom.t<msg> => {
  if Array.length(state.history) === 0 {
    div(
      list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
      list{text("No build history")},
    )
  } else {
    div(
      list{Attrs.class_("space-y-1")},
      state.history
      ->Array.map(entry => {
        let statusCls = BuildDashboardEngine.statusColour(entry.status)
        let targetCls = BuildDashboardEngine.targetColour(entry.target)
        div(
          list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-800 rounded text-xs")},
          list{
            span(list{Attrs.class_(`w-20 ${targetCls}`)}, list{text(BuildDashboardEngine.targetLabel(entry.target))}),
            span(list{Attrs.class_(statusCls)}, list{text(BuildDashboardEngine.statusLabel(entry.status))}),
            span(list{Attrs.class_("text-gray-400 font-mono")}, list{text(`${Float.toString(entry.durationMs)}ms`)}),
            span(
              list{Attrs.class_("text-gray-500")},
              list{text(`${Int.toString(entry.errorCount)}E ${Int.toString(entry.warningCount)}W`)},
            ),
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// Main view function.
let view = (state: buildDashboardState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Build Dashboard panel"),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          span(list{Attrs.class_("text-lg font-semibold text-gray-100")}, list{text("Build Dashboard")}),
          button(
            list{
              Attrs.class_("px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"),
              Events.onClick(BuildDashboard(RefreshBuildStatus)),
            },
            list{text("Refresh")},
          ),
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          renderTab("Overview", BuildOverview, state.activeCategory),
          renderTab("Errors", BuildErrors, state.activeCategory),
          renderTab("Tests", BuildTests, state.activeCategory),
          renderTab("History", BuildHistory, state.activeCategory),
        },
      ),
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("mx-4 mt-2 p-2 bg-red-900/50 border border-red-700 rounded text-xs text-red-300")},
          list{text(err)},
        )
      | None => noNode
      },
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4")},
        list{
          switch state.activeCategory {
          | BuildOverview => renderOverview(state)
          | BuildErrors => renderErrors(state)
          | BuildTests => renderTests(state)
          | BuildHistory => renderHistory(state)
          },
        },
      ),
    },
  )
}
