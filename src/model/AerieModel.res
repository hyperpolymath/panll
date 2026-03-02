// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Aerie Model — types for the network diagnostics panel.
///
/// Aerie provides network health monitoring, speed tests, latency/jitter
/// measurement, BGP route analysis, and proof envelopes for network claims.
/// Backend is a V-lang API gateway (GraphQL:4000, REST:4000).
///
/// Dependency: leaf module — no imports from other PanLL models.

/// A network probe target — an endpoint being monitored.
type probeTarget = {
  /// Endpoint URL or IP address.
  endpoint: string,
  /// Human-readable label.
  label: string,
  /// Protocol used for probing (ICMP, TCP, HTTP, DNS).
  protocol: string,
  /// Whether this target is actively being monitored.
  active: bool,
}

/// A single latency measurement result.
type latencyResult = {
  /// Target endpoint.
  endpoint: string,
  /// Round-trip time in milliseconds.
  rttMs: float,
  /// Jitter (variation) in milliseconds.
  jitterMs: float,
  /// Packet loss percentage (0.0–100.0).
  packetLoss: float,
  /// Measurement timestamp (ISO 8601).
  timestamp: string,
}

/// Speed test result (upload + download).
type speedTestResult = {
  /// Download speed in Mbps.
  downloadMbps: float,
  /// Upload speed in Mbps.
  uploadMbps: float,
  /// Latency to speed test server in ms.
  pingMs: float,
  /// Test server location.
  serverLocation: string,
  /// Test timestamp.
  timestamp: string,
}

/// BGP route analysis entry.
type bgpRoute = {
  /// Destination prefix (e.g. "203.0.113.0/24").
  prefix: string,
  /// AS path as array of ASN numbers.
  asPath: array<int>,
  /// Next hop IP.
  nextHop: string,
  /// Whether this route is considered anomalous.
  anomalous: bool,
  /// Anomaly description (if anomalous).
  anomalyDetail: option<string>,
}

/// Category tabs for the Aerie panel.
type aerieCategory =
  /// Health dashboard with latency gauges.
  | AerieDashboard
  /// Speed test results.
  | AerieSpeedTests
  /// BGP route analysis.
  | AerieBgp
  /// Probe configuration.
  | AerieProbes

/// Root state for the Aerie panel.
type aerieState = {
  /// Whether data has been loaded.
  loaded: bool,
  /// Whether a measurement is in progress.
  loading: bool,
  /// Error from the last operation.
  error: option<string>,
  /// Configured probe targets.
  probes: array<probeTarget>,
  /// Recent latency measurements.
  latencyResults: array<latencyResult>,
  /// Recent speed test results.
  speedTests: array<speedTestResult>,
  /// BGP routes (if available).
  bgpRoutes: array<bgpRoute>,
  /// Active category tab.
  activeCategory: aerieCategory,
  /// Number of anomalous BGP routes detected.
  bgpAnomalyCount: int,
}
