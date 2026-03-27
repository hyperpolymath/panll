// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL LoadTester — Phoenix channel stress testing and concurrency simulation
/// for IDApTIK multiplayer infrastructure.
///
/// Four tabs: Scenarios (editor with player count/ramp-up/duration), Live Test
/// (connected player count, latency, throughput), Results (table of completed
/// runs), and Saturation Curve (placeholder for latency-vs-concurrency chart).

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tab label lookup for loadTestTab variants.
let tabLabel = (tab: loadTestTab): string =>
  switch tab {
  | TabScenarios => "Scenarios"
  | TabLiveTest => "Live Test"
  | TabResults => "Results"
  | TabSaturationCurve => "Saturation Curve"
  }

/// Render the tab bar.
let renderTabs = (active: loadTestTab): Tea_Vdom.t<msg> => {
  let tabs: array<loadTestTab> = [TabScenarios, TabLiveTest, TabResults, TabSaturationCurve]
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
          Events.onClick(LoadTester(SetLtTab(tab))),
        },
        list{text(tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Player status badge.
let playerStatusBadge = (status: simulatedPlayerStatus): Tea_Vdom.t<msg> =>
  switch status {
  | PlayerConnecting =>
    span(
      list{
        Attrs.class_(
          "px-1.5 py-0.5 text-xs rounded bg-amber-500 text-white font-mono animate-pulse",
        ),
      },
      list{text("CONNECTING")},
    )
  | PlayerConnected =>
    span(
      list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-emerald-600 text-white font-mono")},
      list{text("CONNECTED")},
    )
  | PlayerDisconnected(_) =>
    span(
      list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-gray-600 text-gray-200 font-mono")},
      list{text("DISCONNECTED")},
    )
  | PlayerError(_) =>
    span(
      list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-red-600 text-white font-mono")},
      list{text("ERROR")},
    )
  }

// =========================================================================
// Tab content views
// =========================================================================

/// Scenarios tab: list of load test scenarios with configuration details.
let renderScenariosTab = (state: loadTesterState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4")},
    list{
      div(
        list{Attrs.class_("text-sm text-gray-400 mb-1")},
        list{text(`${Int.toString(Array.length(state.scenarios))} scenario(s)`)},
      ),
      div(
        list{Attrs.class_("flex flex-col gap-2 max-h-96 overflow-y-auto")},
        state.scenarios
        ->Array.map(scenario => {
          let isSelected = state.selectedScenario === Some(scenario.name)
          let borderCls = isSelected ? "border-cyan-600" : "border-gray-700"
          div(
            list{
              Attrs.class_(`bg-gray-800 rounded p-3 border ${borderCls} cursor-pointer`),
              Events.onClick(LoadTester(SelectScenario(scenario.name))),
            },
            list{
              div(
                list{Attrs.class_("flex items-center justify-between mb-2")},
                list{
                  span(
                    list{Attrs.class_("text-sm font-medium text-gray-200")},
                    list{text(scenario.name)},
                  ),
                  button(
                    list{
                      Attrs.class_(
                        "px-2 py-1 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer",
                      ),
                      Events.onClick(LoadTester(RunScenario(scenario.name))),
                    },
                    list{text("Run")},
                  ),
                },
              ),
              div(
                list{Attrs.class_("grid grid-cols-2 gap-2 text-xs")},
                list{
                  div(
                    list{Attrs.class_("text-gray-500")},
                    list{text(`Players: ${Int.toString(scenario.concurrentPlayers)}`)},
                  ),
                  div(
                    list{Attrs.class_("text-gray-500")},
                    list{text(`Ramp-up: ${Int.toString(scenario.rampUpSeconds)}s`)},
                  ),
                  div(
                    list{Attrs.class_("text-gray-500")},
                    list{text(`Duration: ${Int.toString(scenario.durationSeconds)}s`)},
                  ),
                  div(
                    list{Attrs.class_("text-gray-500")},
                    list{text(`Msg/s: ${Int.toString(scenario.messagesPerSecond)}`)},
                  ),
                },
              ),
              span(
                list{Attrs.class_("text-xs text-gray-600 mt-1")},
                list{text(`Channel: ${scenario.channelName}`)},
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Live Test tab: connected player count, latency, and throughput overview.
let renderLiveTestTab = (state: loadTesterState): Tea_Vdom.t<msg> => {
  let connectedCount =
    state.players
    ->Array.filter(p =>
      switch p.status {
      | PlayerConnected => true
      | _ => false
      }
    )
    ->Array.length
  let totalPlayers = Array.length(state.players)
  let avgLatency = if totalPlayers > 0 {
    state.players->Array.reduce(0.0, (acc, p) => acc +. p.latencyMs) /. Int.toFloat(totalPlayers)
  } else {
    0.0
  }
  let totalMessages =
    state.players->Array.reduce(0, (acc, p) => acc + p.messagesSent + p.messagesReceived)

  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      // Key metrics row
      div(
        list{Attrs.class_("grid grid-cols-4 gap-3")},
        list{
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-emerald-400")},
                list{text(Int.toString(connectedCount))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Connected")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-gray-300")},
                list{text(Int.toString(totalPlayers))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Total")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-cyan-400")},
                list{text(`${Float.toFixed(avgLatency, ~digits=1)}ms`)},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Avg Latency")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-gray-300")},
                list{text(Int.toString(totalMessages))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Messages")}),
            },
          ),
        },
      ),
      // Player list (capped to most recent 20)
      div(
        list{Attrs.class_("flex flex-col gap-1 max-h-64 overflow-y-auto")},
        state.players
        ->Array.sliceToEnd(~start=max(0, totalPlayers - 20))
        ->Array.map(player => {
          div(
            list{
              Attrs.class_(
                "flex items-center justify-between px-3 py-1.5 bg-gray-800 rounded text-xs",
              ),
            },
            list{
              span(
                list{Attrs.class_("text-gray-500 font-mono")},
                list{text(`P-${Int.toString(player.id)}`)},
              ),
              playerStatusBadge(player.status),
              span(
                list{Attrs.class_("text-gray-400 font-mono")},
                list{text(`${Float.toFixed(player.latencyMs, ~digits=1)}ms`)},
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Results tab: table of completed load test results.
let renderResultsTab = (state: loadTesterState): Tea_Vdom.t<msg> => {
  if Array.length(state.results) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No load test results yet. Run a scenario to see results here.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4 max-h-96 overflow-y-auto")},
      state.results
      ->Array.map(result => {
        let errRate = if result.messagesTotal > 0 {
          Int.toFloat(result.errorsTotal) /. Int.toFloat(result.messagesTotal) *. 100.0
        } else {
          0.0
        }
        let errColour = if errRate > 5.0 {
          "text-red-400"
        } else if errRate > 1.0 {
          "text-amber-400"
        } else {
          "text-emerald-400"
        }
        div(
          list{Attrs.class_("bg-gray-800 rounded p-3 border border-gray-700")},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between mb-2")},
              list{
                span(
                  list{Attrs.class_("text-sm font-medium text-gray-200")},
                  list{text(result.scenario.name)},
                ),
                span(list{Attrs.class_("text-xs text-gray-500")}, list{text(result.timestamp)}),
              },
            ),
            div(
              list{Attrs.class_("grid grid-cols-3 gap-2 text-xs")},
              list{
                div(
                  list{Attrs.class_("text-gray-400")},
                  list{text(`Peak: ${Int.toString(result.peakPlayers)} players`)},
                ),
                div(
                  list{Attrs.class_("text-gray-400")},
                  list{text(`Avg: ${Float.toFixed(result.avgLatencyMs, ~digits=1)}ms`)},
                ),
                div(
                  list{Attrs.class_("text-gray-400")},
                  list{text(`P99: ${Float.toFixed(result.p99LatencyMs, ~digits=1)}ms`)},
                ),
                div(
                  list{Attrs.class_("text-gray-400")},
                  list{text(`Throughput: ${Float.toFixed(result.throughputPerSec, ~digits=0)}/s`)},
                ),
                div(
                  list{Attrs.class_(errColour)},
                  list{text(`Errors: ${Float.toFixed(errRate, ~digits=1)}%`)},
                ),
                div(
                  list{Attrs.class_("text-gray-400")},
                  list{text(`Duration: ${Float.toFixed(result.durationMs, ~digits=0)}ms`)},
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

/// Saturation Curve tab: placeholder for latency-vs-concurrency chart.
let renderSaturationCurveTab = (_state: loadTesterState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4 flex items-center justify-center h-48")},
    list{
      span(
        list{Attrs.class_("text-gray-600 text-sm")},
        list{text("Saturation curve chart (latency vs. concurrency) — Phase 2")},
      ),
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function dispatching tab content based on active tab.
let view = (state: loadTesterState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabScenarios => renderScenariosTab(state)
  | TabLiveTest => renderLiveTestTab(state)
  | TabResults => renderResultsTab(state)
  | TabSaturationCurve => renderSaturationCurveTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(list{Attrs.class_("text-lg font-semibold text-cyan-300")}, list{text("Load Tester")}),
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer font-medium",
              ),
              Events.onClick(LoadTester(RunSelectedScenario)),
            },
            list{text("Run Scenario")},
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
            span(
              list{Attrs.class_("text-sm text-amber-300")},
              list{text("Load test in progress...")},
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
