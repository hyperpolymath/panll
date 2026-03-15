// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Load Tester Engine — pure functions for load test simulation state.

open LoadTesterModel

/// Default initial state.
let defaultState: loadTesterState = {
  activeTab: TabScenarios,
  scenarios: [],
  selectedScenario: None,
  players: [],
  results: [],
  running: false,
  error: None,
}

/// Tab label for display.
let tabLabel = (tab: loadTestTab): string =>
  switch tab {
  | TabScenarios => "Scenarios"
  | TabLiveTest => "Live Test"
  | TabResults => "Results"
  | TabSaturationCurve => "Saturation Curve"
  }

/// All tabs for rendering.
let allTabs: array<loadTestTab> = [TabScenarios, TabLiveTest, TabResults, TabSaturationCurve]

/// Count connected players.
let connectedCount = (players: array<simulatedPlayer>): int =>
  players->Array.filter(p => switch p.status { | PlayerConnected => true | _ => false })->Array.length

/// Count errored players.
let errorCount = (players: array<simulatedPlayer>): int =>
  players->Array.filter(p => switch p.status { | PlayerError(_) => true | _ => false })->Array.length

/// Average latency across connected players.
let avgLatency = (players: array<simulatedPlayer>): float => {
  let connected = players->Array.filter(p => switch p.status { | PlayerConnected => true | _ => false })
  let count = connected->Array.length
  if count == 0 { 0.0 }
  else {
    let sum = connected->Array.reduce(0.0, (acc, p) => acc +. p.latencyMs)
    sum /. Float.fromInt(count)
  }
}

/// Default scenario for quick testing.
let defaultScenario: loadScenario = {
  name: "Standard Load Test",
  concurrentPlayers: 10,
  rampUpSeconds: 5,
  durationSeconds: 60,
  messagesPerSecond: 10,
  channelName: "game:lobby",
}
