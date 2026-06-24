// SPDX-License-Identifier: MPL-2.0

/// PanLL Load Tester Model — Phoenix channel stress testing and concurrency
/// simulation for IDApTIK multiplayer infrastructure.
///
/// Ramps virtual players from zero to a target concurrency, measures latency
/// percentiles, throughput, and finds the saturation point where the server
/// begins dropping connections or increasing response times.
///
/// Clade: Scanner. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Simulated Players
// ============================================================================

/// Connection lifecycle status for a simulated player.
type simulatedPlayerStatus =
  /// Player is establishing a WebSocket connection.
  | PlayerConnecting
  /// Player is connected and actively exchanging messages.
  | PlayerConnected
  /// Player disconnected (payload is disconnect reason).
  | PlayerDisconnected(string)
  /// Player encountered an error (payload is error message).
  | PlayerError(string)

/// A single simulated player in the load test.
type simulatedPlayer = {
  /// Numeric player identifier within this load test.
  id: int,
  /// Current connection status.
  status: simulatedPlayerStatus,
  /// Latest measured round-trip latency in milliseconds.
  latencyMs: float,
  /// Total messages sent by this player.
  messagesSent: int,
  /// Total messages received by this player.
  messagesReceived: int,
  /// Timestamp when this player connected (None if not yet connected).
  connectedAt: option<float>,
}

// ============================================================================
// Load Scenarios
// ============================================================================

/// A load test scenario definition specifying concurrency, ramp-up, and
/// message rates for the Phoenix channel stress test.
type loadScenario = {
  /// Human-readable scenario name (e.g., "Peak Hour Simulation").
  name: string,
  /// Target number of concurrent players.
  concurrentPlayers: int,
  /// Seconds over which players ramp up from zero to target.
  rampUpSeconds: int,
  /// Total duration of the sustained load phase in seconds.
  durationSeconds: int,
  /// Target messages per second per player.
  messagesPerSecond: int,
  /// Phoenix channel to connect to (e.g., "game:lobby").
  channelName: string,
}

// ============================================================================
// Load Test Results
// ============================================================================

/// Result summary of a completed load test run.
type loadTestResult = {
  /// The scenario that was executed.
  scenario: loadScenario,
  /// Peak number of simultaneously connected players.
  peakPlayers: int,
  /// Average round-trip latency in milliseconds.
  avgLatencyMs: float,
  /// 99th percentile latency in milliseconds.
  p99LatencyMs: float,
  /// Total messages exchanged during the test.
  messagesTotal: int,
  /// Total error count during the test.
  errorsTotal: int,
  /// Measured throughput in messages per second.
  throughputPerSec: float,
  /// Total test duration in milliseconds.
  durationMs: float,
  /// ISO 8601 timestamp when this test completed.
  timestamp: string,
}

/// A point on the saturation curve (players vs latency).
type saturationPoint = {
  /// Number of concurrent players at this point.
  players: int,
  /// Measured average latency at this concurrency level.
  avgLatencyMs: float,
  /// Error rate (0.0 to 1.0) at this concurrency level.
  errorRate: float,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Load Tester panel.
type loadTestTab =
  /// Scenarios — browse and configure load test scenarios.
  | TabScenarios
  /// Live Test — real-time player connection status and latency gauges.
  | TabLiveTest
  /// Results — historical test results with percentile breakdowns.
  | TabResults
  /// Saturation Curve — chart of players vs latency to find breaking point.
  | TabSaturationCurve

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Load Tester panel.
type loadTesterState = {
  /// Active tab within the panel.
  activeTab: loadTestTab,
  /// Available load test scenarios.
  scenarios: array<loadScenario>,
  /// Currently selected scenario name for configuration.
  selectedScenario: option<string>,
  /// Live simulated player connections during an active test.
  players: array<simulatedPlayer>,
  /// Historical test result summaries.
  results: array<loadTestResult>,
  /// Saturation curve data points from the most recent graduated test.
  saturationCurve: array<saturationPoint>,
  /// Whether a load test is currently running.
  running: bool,
  /// Error from the last operation.
  error: option<string>,
}
