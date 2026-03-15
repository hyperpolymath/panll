// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL BalanceAnalyser — game balance statistical analysis and Monte Carlo
/// simulation for IDApTIK level tuning.
///
/// Five tabs: Overview (level stats table with difficulty scores and win rates),
/// Distributions (placeholder charts), Simulations (Monte Carlo results),
/// Recommendations (suggested parameter changes), and Difficulty Curve
/// (placeholder chart for the intended difficulty arc).

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tab label lookup for balanceTab variants.
let tabLabel = (tab: balanceTab): string =>
  switch tab {
  | TabOverview => "Overview"
  | TabDistributions => "Distributions"
  | TabSimulations => "Simulations"
  | TabRecommendations => "Recommendations"
  | TabDifficultyCurve => "Difficulty Curve"
  }

/// Render the tab bar.
let renderTabs = (active: balanceTab): Tea_Vdom.t<msg> => {
  let tabs: array<balanceTab> = [
    TabOverview,
    TabDistributions,
    TabSimulations,
    TabRecommendations,
    TabDifficultyCurve,
  ]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-3 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-cyan-400 border-b-2 border-cyan-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900 cursor-pointer"}`,
          ),
          Events.onClick(BalanceAnalyser(SetBaTab(tab))),
        },
        list{text(tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Difficulty colour from score (0-10 scale).
let difficultyColour = (score: float): string =>
  if score >= 8.0 {
    "text-red-400"
  } else if score >= 5.0 {
    "text-amber-400"
  } else if score >= 3.0 {
    "text-emerald-400"
  } else {
    "text-blue-400"
  }

/// Win rate colour (higher is greener, lower is redder).
let winRateColour = (rate: float): string =>
  if rate >= 0.7 {
    "text-emerald-400"
  } else if rate >= 0.4 {
    "text-amber-400"
  } else {
    "text-red-400"
  }

// =========================================================================
// Tab content views
// =========================================================================

/// Overview tab: level stats table with difficulty scores and estimated win rates.
let renderOverviewTab = (state: balanceAnalyserState): Tea_Vdom.t<msg> => {
  if Array.length(state.levelStats) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No level statistics loaded. Run a simulation to generate balance data.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4")},
      list{
        // Summary
        div(
          list{Attrs.class_("text-sm text-gray-400 mb-1")},
          list{text(`${Int.toString(Array.length(state.levelStats))} level(s) analysed`)},
        ),
        // Table header
        div(
          list{
            Attrs.class_(
              "grid grid-cols-6 gap-2 px-3 py-2 text-xs text-gray-500 font-medium border-b border-gray-800",
            ),
          },
          list{
            span(list{}, list{text("Level")}),
            span(list{Attrs.class_("text-right")}, list{text("Difficulty")}),
            span(list{Attrs.class_("text-right")}, list{text("Win Rate")}),
            span(list{Attrs.class_("text-right")}, list{text("Guard Rate")}),
            span(list{Attrs.class_("text-right")}, list{text("Alert Threshold")}),
            span(list{Attrs.class_("text-right")}, list{text("Outlier")}),
          },
        ),
        // Table rows
        div(
          list{Attrs.class_("flex flex-col gap-1 max-h-80 overflow-y-auto")},
          state.levelStats
          ->Array.map(level => {
            let isSelected = state.selectedLevel === Some(level.levelId)
            let bgCls = isSelected ? "bg-gray-750 border border-cyan-700" : "bg-gray-800"
            let diffColour = difficultyColour(level.difficultyScore)
            let wrColour = winRateColour(level.estimatedWinRate)
            let outlierColour = if level.outlierScore > 2.0 {
              "text-red-400"
            } else if level.outlierScore > 1.0 {
              "text-amber-400"
            } else {
              "text-gray-400"
            }
            div(
              list{
                Attrs.class_(
                  `grid grid-cols-6 gap-2 px-3 py-2 text-sm rounded cursor-pointer hover:bg-gray-750 ${bgCls}`,
                ),
                Events.onClick(BalanceAnalyser(SelectLevel(level.levelId))),
              },
              list{
                span(
                  list{Attrs.class_("text-gray-300 truncate")},
                  list{text(level.levelName)},
                ),
                span(
                  list{Attrs.class_(`text-right font-mono ${diffColour}`)},
                  list{text(Float.toFixed(level.difficultyScore, ~digits=1))},
                ),
                span(
                  list{Attrs.class_(`text-right font-mono ${wrColour}`)},
                  list{text(`${Float.toFixed(level.estimatedWinRate *. 100.0, ~digits=0)}%`)},
                ),
                span(
                  list{Attrs.class_("text-right font-mono text-gray-400")},
                  list{text(Float.toFixed(level.guardSpawnRate, ~digits=2))},
                ),
                span(
                  list{Attrs.class_("text-right font-mono text-gray-400")},
                  list{text(Float.toFixed(level.alertThreshold, ~digits=2))},
                ),
                span(
                  list{Attrs.class_(`text-right font-mono ${outlierColour}`)},
                  list{text(Float.toFixed(level.outlierScore, ~digits=2))},
                ),
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Distributions tab: placeholder for distribution charts.
let renderDistributionsTab = (state: balanceAnalyserState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      div(
        list{Attrs.class_("bg-gray-800 rounded p-4 h-40 flex items-center justify-center")},
        list{
          span(
            list{Attrs.class_("text-gray-600 text-sm")},
            list{
              text(
                `Difficulty distribution chart (${Int.toString(Array.length(state.distributions))} buckets)`,
              ),
            },
          ),
        },
      ),
      // Distribution data summary
      if Array.length(state.distributions) > 0 {
        div(
          list{Attrs.class_("flex flex-col gap-1 max-h-48 overflow-y-auto")},
          state.distributions
          ->Array.map(point => {
            let widthPct = Int.toString(Int.fromFloat(point.percentage))
            div(
              list{Attrs.class_("flex items-center gap-2 text-xs")},
              list{
                span(
                  list{Attrs.class_("w-16 text-gray-400 font-mono text-right")},
                  list{text(point.bucket)},
                ),
                div(
                  list{Attrs.class_("flex-1 h-3 bg-gray-700 rounded overflow-hidden")},
                  list{
                    div(
                      list{
                        Attrs.class_(
                          `h-full bg-cyan-600 transition-all duration-300 w-[${widthPct}%]`,
                        ),
                      },
                      list{},
                    ),
                  },
                ),
                span(
                  list{Attrs.class_("text-gray-500 font-mono w-12 text-right")},
                  list{text(`${Int.toString(point.count)}`)},
                ),
              },
            )
          })
          ->List.fromArray,
        )
      } else {
        noNode
      },
    },
  )
}

/// Simulations tab: Monte Carlo simulation results.
let renderSimulationsTab = (state: balanceAnalyserState): Tea_Vdom.t<msg> => {
  if Array.length(state.simulations) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No simulation results. Click Run Simulation to generate balance data.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4")},
      list{
        div(
          list{Attrs.class_("text-sm text-gray-400 mb-1")},
          list{
            text(
              `${Int.toString(Array.length(state.simulations))} simulation(s) (${Int.toString(state.simulationRuns)} runs each)`,
            ),
          },
        ),
        div(
          list{Attrs.class_("flex flex-col gap-2 max-h-80 overflow-y-auto")},
          state.simulations
          ->Array.map(sim => {
            let wrColour = winRateColour(sim.winRate)
            div(
              list{Attrs.class_("bg-gray-800 rounded p-3 border border-gray-700")},
              list{
                div(
                  list{Attrs.class_("flex items-center justify-between mb-2")},
                  list{
                    span(
                      list{Attrs.class_("text-sm font-medium text-gray-200")},
                      list{text(sim.levelId)},
                    ),
                    span(
                      list{Attrs.class_("text-xs text-gray-500")},
                      list{text(`${Int.toString(sim.runs)} runs`)},
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("grid grid-cols-3 gap-2 text-xs")},
                  list{
                    div(
                      list{Attrs.class_(`${wrColour}`)},
                      list{text(`Win: ${Float.toFixed(sim.winRate *. 100.0, ~digits=1)}%`)},
                    ),
                    div(
                      list{Attrs.class_("text-gray-400")},
                      list{text(`Avg: ${Float.toFixed(sim.avgCompletionTime, ~digits=0)}s`)},
                    ),
                    div(
                      list{Attrs.class_("text-gray-400")},
                      list{text(`P95: ${Float.toFixed(sim.p95CompletionTime, ~digits=0)}s`)},
                    ),
                    div(
                      list{Attrs.class_("text-red-400")},
                      list{text(`Guard: ${Int.toString(sim.deathsByGuard)}`)},
                    ),
                    div(
                      list{Attrs.class_("text-amber-400")},
                      list{text(`Trap: ${Int.toString(sim.deathsByTrap)}`)},
                    ),
                    div(
                      list{Attrs.class_("text-gray-500")},
                      list{text(`Timeout: ${Int.toString(sim.deathsByTimeout)}`)},
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
}

/// Recommendations tab: suggested parameter changes for balance improvement.
let renderRecommendationsTab = (state: balanceAnalyserState): Tea_Vdom.t<msg> => {
  if Array.length(state.recommendations) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No recommendations yet. Run simulations to generate balance suggestions.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4 max-h-96 overflow-y-auto")},
      state.recommendations
      ->Array.map(item => {
        let delta = item.suggestedValue -. item.currentValue
        let deltaSign = delta >= 0.0 ? "+" : ""
        let deltaColour = if Float.parseFloat(Float.toFixed(delta, ~digits=2)) === 0.0 {
          "text-gray-400"
        } else if delta > 0.0 {
          "text-emerald-400"
        } else {
          "text-red-400"
        }
        div(
          list{Attrs.class_("bg-gray-800 rounded p-3 border border-gray-700")},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between mb-1")},
              list{
                span(
                  list{Attrs.class_("text-sm text-gray-300")},
                  list{text(`${item.levelId}: ${item.parameter}`)},
                ),
                span(
                  list{Attrs.class_(`text-xs font-mono ${deltaColour}`)},
                  list{
                    text(
                      `${Float.toFixed(item.currentValue, ~digits=2)} -> ${Float.toFixed(item.suggestedValue, ~digits=2)} (${deltaSign}${Float.toFixed(delta, ~digits=2)})`,
                    ),
                  },
                ),
              },
            ),
            div(
              list{Attrs.class_("text-xs text-gray-400 mb-1")},
              list{text(item.reason)},
            ),
            div(
              list{Attrs.class_("text-xs text-gray-500")},
              list{text(`Impact: ${item.impact}`)},
            ),
            // Apply button
            div(
              list{Attrs.class_("flex justify-end mt-2")},
              list{
                button(
                  list{
                    Attrs.class_(
                      "px-2 py-1 text-xs bg-cyan-700 text-white rounded hover:bg-cyan-600 cursor-pointer",
                    ),
                    Events.onClick(
                      BalanceAnalyser(
                        ApplyRecommendation(item.levelId, item.parameter, item.suggestedValue),
                      ),
                    ),
                  },
                  list{text("Apply")},
                ),
              },
            ),
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// Difficulty Curve tab: placeholder chart for the intended difficulty arc.
let renderDifficultyCurveTab = (state: balanceAnalyserState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      div(
        list{Attrs.class_("bg-gray-800 rounded p-4 h-48 flex items-center justify-center")},
        list{
          span(
            list{Attrs.class_("text-gray-600 text-sm")},
            list{
              text(
                `Difficulty curve chart (${Int.toString(Array.length(state.levelStats))} levels)`,
              ),
            },
          ),
        },
      ),
      // Level difficulty as horizontal bars for visual reference
      div(
        list{Attrs.class_("flex flex-col gap-1 max-h-48 overflow-y-auto")},
        state.levelStats
        ->Array.map(level => {
          let widthPct = Int.toString(Int.fromFloat(level.difficultyScore *. 10.0))
          let barColour = if level.difficultyScore >= 8.0 {
            "bg-red-500"
          } else if level.difficultyScore >= 5.0 {
            "bg-amber-500"
          } else {
            "bg-emerald-500"
          }
          div(
            list{Attrs.class_("flex items-center gap-2 text-xs")},
            list{
              span(
                list{Attrs.class_("w-24 text-gray-400 truncate text-right")},
                list{text(level.levelName)},
              ),
              div(
                list{Attrs.class_("flex-1 h-3 bg-gray-700 rounded overflow-hidden")},
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
              span(
                list{Attrs.class_("text-gray-500 font-mono w-8 text-right")},
                list{text(Float.toFixed(level.difficultyScore, ~digits=1))},
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function dispatching tab content based on active tab.
let view = (state: balanceAnalyserState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabOverview => renderOverviewTab(state)
  | TabDistributions => renderDistributionsTab(state)
  | TabSimulations => renderSimulationsTab(state)
  | TabRecommendations => renderRecommendationsTab(state)
  | TabDifficultyCurve => renderDifficultyCurveTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header with Run Simulation
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold text-cyan-300")},
            list{text("Balance Analyser")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer font-medium",
              ),
              Events.onClick(BalanceAnalyser(RunSimulation)),
            },
            list{text("Run Simulation")},
          ),
        },
      ),
      // Running indicator
      if state.running {
        div(
          list{Attrs.class_("flex items-center gap-2 px-4 py-2 bg-gray-800 border-b border-gray-700")},
          list{
            div(list{Attrs.class_("w-3 h-3 bg-amber-400 rounded-full animate-pulse")}, list{}),
            span(
              list{Attrs.class_("text-sm text-amber-300")},
              list{text("Simulation running...")},
            ),
          },
        )
      } else {
        noNode
      },
      // Error display
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("px-4 py-2 bg-red-900/30 text-red-300 text-sm border-b border-red-800")},
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
