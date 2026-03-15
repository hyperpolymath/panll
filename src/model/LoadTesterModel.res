// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Load Tester Model — Phoenix channel stress testing and concurrency simulation.
/// This module has NO dependencies on other PanLL modules.

/// Status of a simulated player connection.
type simulatedPlayerStatus =
  | PlayerConnecting
  | PlayerConnected
  | PlayerDisconnected(string)
  | PlayerError(string)

/// A simulated player entry.
type simulatedPlayer = {
  id: int,
  status: simulatedPlayerStatus,
  latencyMs: float,
  messagesSent: int,
  messagesReceived: int,
  connectedAt: option<float>,
}

/// Load test scenario.
type loadScenario = {
  name: string,
  concurrentPlayers: int,
  rampUpSeconds: int,
  durationSeconds: int,
  messagesPerSecond: int,
  channelName: string,
}

/// Load test result.
type loadTestResult = {
  scenario: loadScenario,
  peakPlayers: int,
  avgLatencyMs: float,
  p99LatencyMs: float,
  messagesTotal: int,
  errorsTotal: int,
  throughputPerSec: float,
  durationMs: float,
  timestamp: string,
}

/// Active tab.
type loadTestTab =
  | TabScenarios
  | TabLiveTest
  | TabResults
  | TabSaturationCurve

/// Load tester state.
type loadTesterState = {
  activeTab: loadTestTab,
  scenarios: array<loadScenario>,
  selectedScenario: option<string>,
  players: array<simulatedPlayer>,
  results: array<loadTestResult>,
  running: bool,
  error: option<string>,
}
