// SPDX-License-Identifier: MPL-2.0

/// PanLL UnitTestRunner — interactive test execution dashboard with coverage
/// heatmaps, run history, and diff-aware filtering for IDApTIK game testing.
///
/// Renders four tabs: test results (pass/fail list with durations), module
/// coverage (percentage bars with heatmap colouring), run history (summary
/// cards), and diff-aware mode (only changed-module tests). The Run/Stop
/// header buttons dispatch lifecycle messages and a spinner overlays when
/// tests are in flight.

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tab label lookup for unitTestTab variants.
let tabLabel = (tab: unitTestTab): string =>
  switch tab {
  | TabTestResults => "Results"
  | TabCoverage => "Coverage"
  | TabHistory => "History"
  | TabDiffAware => "Diff-Aware"
  }

/// Render the tab bar. Active tab gets a cyan bottom border; others are
/// ghost buttons with hover highlight.
let renderTabs = (active: unitTestTab): Tea_Vdom.t<msg> => {
  let tabs: array<unitTestTab> = [TabTestResults, TabCoverage, TabHistory, TabDiffAware]
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
          Events.onClick(UnitTestRunner(SetUtrTab(tab))),
        },
        list{text(tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Status icon for a single test case result.
let statusIcon = (status: testCaseStatus): Tea_Vdom.t<msg> =>
  switch status {
  | TestPending => span(list{Attrs.class_("text-gray-500 text-xs font-mono")}, list{text("--")})
  | TestRunning =>
    span(list{Attrs.class_("text-amber-400 text-xs font-mono animate-pulse")}, list{text("...")})
  | TestPassed(_) =>
    span(list{Attrs.class_("text-emerald-400 text-xs font-mono")}, list{text("OK")})
  | TestFailed(_, _) =>
    span(list{Attrs.class_("text-red-400 text-xs font-mono")}, list{text("FAIL")})
  | TestSkipped(_) =>
    span(list{Attrs.class_("text-blue-400 text-xs font-mono")}, list{text("SKIP")})
  }

/// Duration display (right-aligned, dimmed).
let durationDisplay = (status: testCaseStatus): Tea_Vdom.t<msg> =>
  switch status {
  | TestPassed(ms) =>
    span(
      list{Attrs.class_("text-gray-500 text-xs font-mono")},
      list{text(`${Float.toString(ms)}ms`)},
    )
  | TestFailed(_, ms) =>
    span(
      list{Attrs.class_("text-gray-500 text-xs font-mono")},
      list{text(`${Float.toString(ms)}ms`)},
    )
  | _ => noNode
  }

// =========================================================================
// Tab content views
// =========================================================================

/// Test results tab: scrollable list of test cases with pass/fail icons,
/// suite grouping, test name, and duration.
let renderResultsTab = (state: unitTestRunnerState): Tea_Vdom.t<msg> => {
  let count = Array.length(state.results)
  let passed =
    state.results
    ->Array.filter(r =>
      switch r.status {
      | TestPassed(_) => true
      | _ => false
      }
    )
    ->Array.length
  let failed =
    state.results
    ->Array.filter(r =>
      switch r.status {
      | TestFailed(_, _) => true
      | _ => false
      }
    )
    ->Array.length

  div(
    list{Attrs.class_("flex flex-col gap-3 p-4")},
    list{
      // Summary counts
      div(
        list{Attrs.class_("flex gap-4 text-sm")},
        list{
          span(list{Attrs.class_("text-gray-400")}, list{text(`Total: ${Int.toString(count)}`)}),
          span(
            list{Attrs.class_("text-emerald-400")},
            list{text(`Passed: ${Int.toString(passed)}`)},
          ),
          span(list{Attrs.class_("text-red-400")}, list{text(`Failed: ${Int.toString(failed)}`)}),
        },
      ),
      // Result rows
      div(
        list{Attrs.class_("flex flex-col gap-1 max-h-96 overflow-y-auto")},
        state.results
        ->Array.map(result => {
          div(
            list{
              Attrs.class_(
                "flex items-center justify-between gap-3 px-3 py-2 bg-gray-800 rounded text-sm",
              ),
            },
            list{
              statusIcon(result.status),
              span(
                list{Attrs.class_("text-gray-500 font-mono text-xs min-w-24")},
                list{text(result.suiteName)},
              ),
              span(list{Attrs.class_("text-gray-300 flex-1")}, list{text(result.testName)}),
              durationDisplay(result.status),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Coverage tab: module heatmap with percentage bars. Colour graduates from
/// red (< 40%) through amber (40-70%) to emerald (> 70%).
let renderCoverageTab = (state: unitTestRunnerState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4")},
    list{
      h3(
        list{Attrs.class_("text-sm font-medium text-gray-300 mb-1")},
        list{text("Module Coverage Heatmap")},
      ),
      div(
        list{Attrs.class_("flex flex-col gap-2 max-h-96 overflow-y-auto")},
        state.coverage
        ->Array.map(mod => {
          let pct = mod.coveragePercent
          let pctStr = Float.toFixed(pct, ~digits=1)
          let barColour = if pct < 40.0 {
            "bg-red-500"
          } else if pct < 70.0 {
            "bg-amber-500"
          } else {
            "bg-emerald-500"
          }
          let widthPct = Int.toString(Int.fromFloat(pct))
          div(
            list{Attrs.class_("bg-gray-800 rounded p-2")},
            list{
              div(
                list{Attrs.class_("flex justify-between text-xs mb-1")},
                list{
                  span(list{Attrs.class_("text-gray-300 font-mono")}, list{text(mod.moduleName)}),
                  span(
                    list{Attrs.class_("text-gray-500")},
                    list{
                      text(
                        `${Int.toString(mod.testedFunctions)}/${Int.toString(
                            mod.totalFunctions,
                          )} (${pctStr}%)`,
                      ),
                    },
                  ),
                },
              ),
              div(
                list{Attrs.class_("w-full h-2 bg-gray-700 rounded overflow-hidden")},
                list{
                  div(
                    list{
                      Attrs.class_(
                        `h-full ${barColour} transition-all duration-300 w-[${widthPct}%]`,
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
      ),
    },
  )
}

/// History tab: summary cards for previous test runs.
let renderHistoryTab = (state: unitTestRunnerState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4")},
    list{
      h3(list{Attrs.class_("text-sm font-medium text-gray-300 mb-1")}, list{text("Run History")}),
      div(
        list{Attrs.class_("flex flex-col gap-2 max-h-96 overflow-y-auto")},
        state.history
        ->Array.map(run => {
          let allPassed = run.failed === 0
          let borderCls = allPassed ? "border-emerald-700" : "border-red-700"
          div(
            list{Attrs.class_(`bg-gray-800 rounded p-3 border ${borderCls}`)},
            list{
              div(
                list{Attrs.class_("flex justify-between text-xs text-gray-400 mb-1")},
                list{
                  span(list{}, list{text(run.timestamp)}),
                  span(list{}, list{text(`${Float.toFixed(run.durationMs, ~digits=0)}ms`)}),
                },
              ),
              div(
                list{Attrs.class_("flex gap-4 text-sm")},
                list{
                  span(
                    list{Attrs.class_("text-emerald-400")},
                    list{text(`${Int.toString(run.passed)} passed`)},
                  ),
                  span(
                    list{Attrs.class_("text-red-400")},
                    list{text(`${Int.toString(run.failed)} failed`)},
                  ),
                  span(
                    list{Attrs.class_("text-blue-400")},
                    list{text(`${Int.toString(run.skipped)} skipped`)},
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

/// Diff-aware tab: toggle and filtered results for changed modules only.
let renderDiffAwareTab = (state: unitTestRunnerState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-3 p-4")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          button(
            list{
              Attrs.class_(
                `px-3 py-1.5 text-xs rounded font-medium cursor-pointer ${state.diffAwareOnly
                    ? "bg-cyan-700 text-white"
                    : "bg-gray-700 text-gray-400"}`,
              ),
              Events.onClick(UnitTestRunner(ToggleDiffAware)),
              KeyboardNav.onActivate(UnitTestRunner(ToggleDiffAware)),
            },
            list{text(state.diffAwareOnly ? "Diff-Aware: ON" : "Diff-Aware: OFF")},
          ),
          span(
            list{Attrs.class_("text-gray-500 text-xs")},
            list{text("Only run tests for modules changed since last commit")},
          ),
        },
      ),
      div(
        list{Attrs.class_("text-sm text-gray-400")},
        list{
          text(`${Int.toString(Array.length(state.results))} test(s) matched by diff-aware filter`),
        },
      ),
    },
  )
}

// =========================================================================
// Running spinner overlay
// =========================================================================

/// Full-width pulsing indicator shown when a test run is in progress.
let runningSpinner = (running: bool): Tea_Vdom.t<msg> => {
  if running {
    div(
      list{Attrs.class_("flex items-center gap-2 px-4 py-2 bg-gray-800 border-b border-gray-700")},
      list{
        div(list{Attrs.class_("w-3 h-3 bg-amber-400 rounded-full animate-pulse")}, list{}),
        span(list{Attrs.class_("text-sm text-amber-300")}, list{text("Tests running...")}),
      },
    )
  } else {
    noNode
  }
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function dispatching tab content based on active tab.
let view = (state: unitTestRunnerState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabTestResults => renderResultsTab(state)
  | TabCoverage => renderCoverageTab(state)
  | TabHistory => renderHistoryTab(state)
  | TabDiffAware => renderDiffAwareTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header with title and Run/Stop buttons
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold text-cyan-300")},
            list{text("Unit Test Runner")},
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(UnitTestRunner(RunAllTests)),
                  KeyboardNav.onActivate(UnitTestRunner(RunAllTests)),
                },
                list{text("Run")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-red-700 text-white rounded hover:bg-red-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(UnitTestRunner(StopTests)),
                  KeyboardNav.onActivate(UnitTestRunner(StopTests)),
                },
                list{text("Stop")},
              ),
            },
          ),
        },
      ),
      // Running indicator
      runningSpinner(state.running),
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
      // Tab content
      div(list{Attrs.class_("flex-1 overflow-y-auto")}, list{content}),
    },
  )
}
