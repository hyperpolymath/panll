// SPDX-License-Identifier: MPL-2.0

/// PanLL Load Tester Engine — pure computation and helpers for the
/// Load Tester panel. Provides default state, player counting, latency
/// statistics, throughput calculation, and saturation analysis.

open LoadTesterModel

/// Default state for the Load Tester panel.
/// Starts on the Scenarios tab with a standard scenario pre-loaded.
let defaultState: loadTesterState = {
  activeTab: TabScenarios,
  scenarios: [],
  selectedScenario: None,
  players: [],
  results: [],
  saturationCurve: [],
  running: false,
  error: None,
}

/// Human-readable label for each tab in the Load Tester panel.
let tabLabel = (tab: loadTestTab): string =>
  switch tab {
  | TabScenarios => "Scenarios"
  | TabLiveTest => "Live Test"
  | TabResults => "Results"
  | TabSaturationCurve => "Saturation Curve"
  }

/// All tabs in display order.
let allTabs: array<loadTestTab> = [TabScenarios, TabLiveTest, TabResults, TabSaturationCurve]

/// Count connected players.
let connectedCount = (players: array<simulatedPlayer>): int =>
  players
  ->Array.filter(p =>
    switch p.status {
    | PlayerConnected => true
    | _ => false
    }
  )
  ->Array.length

/// Count errored players.
let errorCount = (players: array<simulatedPlayer>): int =>
  players
  ->Array.filter(p =>
    switch p.status {
    | PlayerError(_) => true
    | _ => false
    }
  )
  ->Array.length

/// Count connecting players (in-flight connections).
let connectingCount = (players: array<simulatedPlayer>): int =>
  players
  ->Array.filter(p =>
    switch p.status {
    | PlayerConnecting => true
    | _ => false
    }
  )
  ->Array.length

/// Average latency across connected players in milliseconds.
let avgLatency = (players: array<simulatedPlayer>): float => {
  let connected = players->Array.filter(p =>
    switch p.status {
    | PlayerConnected => true
    | _ => false
    }
  )
  let count = connected->Array.length
  if count == 0 {
    0.0
  } else {
    let sum = connected->Array.reduce(0.0, (acc, p) => acc +. p.latencyMs)
    sum /. Float.fromInt(count)
  }
}

/// Maximum latency across connected players in milliseconds.
let maxLatency = (players: array<simulatedPlayer>): float =>
  players->Array.reduce(0.0, (acc, p) =>
    switch p.status {
    | PlayerConnected =>
      if p.latencyMs > acc {
        p.latencyMs
      } else {
        acc
      }
    | _ => acc
    }
  )

/// Total messages sent across all players.
let totalMessagesSent = (players: array<simulatedPlayer>): int =>
  players->Array.reduce(0, (acc, p) => acc + p.messagesSent)

/// Total messages received across all players.
let totalMessagesReceived = (players: array<simulatedPlayer>): int =>
  players->Array.reduce(0, (acc, p) => acc + p.messagesReceived)

/// Human-readable player status label.
let playerStatusLabel = (status: simulatedPlayerStatus): string =>
  switch status {
  | PlayerConnecting => "Connecting..."
  | PlayerConnected => "Connected"
  | PlayerDisconnected(reason) => "Disconnected: " ++ reason
  | PlayerError(err) => "Error: " ++ err
  }

/// CSS colour class for player status.
let playerStatusColor = (status: simulatedPlayerStatus): string =>
  switch status {
  | PlayerConnecting => "text-yellow-400"
  | PlayerConnected => "text-green-400"
  | PlayerDisconnected(_) => "text-gray-500"
  | PlayerError(_) => "text-red-400"
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

/// Error rate from a load test result (0.0 to 1.0).
let errorRate = (result: loadTestResult): float => {
  let total = result.messagesTotal + result.errorsTotal
  if total == 0 {
    0.0
  } else {
    Float.fromInt(result.errorsTotal) /. Float.fromInt(total)
  }
}
