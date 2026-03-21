// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Vexometer Friction Model — irritation surface measurements across tools.
///
/// Tracks the 10 ISA (Irritation Surface Area) dimensions for each tool
/// in the ecosystem. Aggregates friction scores to identify tools that
/// cause the most developer frustration.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// A single ISA dimension measurement.
type isaDimension = {
  /// Dimension name (e.g. "latency", "error-messages", "docs", "onboarding").
  name: string,
  /// Score from 0.0 (no friction) to 10.0 (maximum friction).
  score: float,
  /// Number of data points contributing to this score.
  sampleCount: int,
}

/// Friction trend direction.
type frictionTrend =
  | Improving
  | Stable
  | Worsening
  | NoData

/// Friction profile for a single tool.
type toolFrictionProfile = {
  /// Tool name.
  toolName: string,
  /// The 10 ISA dimension measurements.
  dimensions: array<isaDimension>,
  /// Aggregated overall friction score (0.0 to 10.0).
  overallScore: float,
  /// Trend direction since last measurement.
  trend: frictionTrend,
  /// Last measurement timestamp (ISO 8601).
  lastMeasured: string,
}

/// Vexometer Friction panel tabs.
type vexometerFrictionTab =
  | TabOverview
  | TabToolList
  | TabDimensions

/// Root state for the Vexometer Friction panel.
type vexometerFrictionState = {
  /// Active tab.
  activeTab: vexometerFrictionTab,
  /// Friction profiles for all monitored tools.
  tools: array<toolFrictionProfile>,
  /// Currently selected tool for detail view.
  selectedTool: option<string>,
  /// Whether a measurement is in progress.
  measuring: bool,
  /// Error from last measurement.
  error: option<string>,
}
