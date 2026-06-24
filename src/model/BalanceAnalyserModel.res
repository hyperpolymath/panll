// SPDX-License-Identifier: MPL-2.0

/// PanLL Balance Analyser Model — game balance statistical analysis and
/// Monte Carlo simulation for IDApTIK level difficulty curves.
///
/// Validates game balance statistically by analysing guard spawn distributions,
/// running Monte Carlo win-rate simulations, tracking difficulty curves across
/// levels, and generating specific recommendations for parameter adjustments.
///
/// Clade: Inspector. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Level Balance Statistics
// ============================================================================

/// Statistical summary of a single level's balance characteristics.
type levelBalanceStats = {
  /// Level identifier from the IDApTIK level system.
  levelId: string,
  /// Human-readable level name.
  levelName: string,
  /// Average guard spawn rate (guards per minute).
  guardSpawnRate: float,
  /// Guard alert threshold (0.0 = deaf, 1.0 = hyper-vigilant).
  alertThreshold: float,
  /// Computed overall difficulty score (0.0 = trivial, 1.0 = impossible).
  difficultyScore: float,
  /// Estimated player win rate from simulation (0.0 to 1.0).
  estimatedWinRate: float,
  /// Number of simulation runs contributing to these stats.
  simulationRuns: int,
  /// Outlier score — how far this level deviates from the expected curve.
  outlierScore: float,
}

// ============================================================================
// Distribution Analysis
// ============================================================================

/// A single data point in a distribution chart (histogram bucket).
type distributionPoint = {
  /// Bucket label (e.g., "0-10", "10-20").
  bucket: string,
  /// Number of observations in this bucket.
  count: int,
  /// Percentage of total observations.
  percentage: float,
}

/// Named distribution for a specific metric.
type namedDistribution = {
  /// Metric name (e.g., "Guard Spawn Rate", "Completion Time").
  name: string,
  /// Data points for the distribution histogram.
  points: array<distributionPoint>,
  /// Statistical mean of the distribution.
  mean: float,
  /// Standard deviation.
  standardDeviation: float,
}

// ============================================================================
// Monte Carlo Simulation
// ============================================================================

/// Result of a Monte Carlo simulation run for a specific level.
type simulationResult = {
  /// Level identifier.
  levelId: string,
  /// Number of simulation runs executed.
  runs: int,
  /// Win rate across all runs (0.0 to 1.0).
  winRate: float,
  /// Average completion time in seconds.
  avgCompletionTime: float,
  /// Median completion time in seconds.
  medianCompletionTime: float,
  /// 95th percentile completion time in seconds.
  p95CompletionTime: float,
  /// Number of simulated deaths caused by guards.
  deathsByGuard: int,
  /// Number of simulated deaths caused by traps.
  deathsByTrap: int,
  /// Number of simulated deaths caused by time running out.
  deathsByTimeout: int,
  /// ISO 8601 timestamp of this simulation run.
  timestamp: string,
}

// ============================================================================
// Recommendations
// ============================================================================

/// A balance recommendation suggesting a parameter adjustment.
type balanceRecommendation = {
  /// Level identifier this recommendation applies to.
  levelId: string,
  /// Parameter to adjust (e.g., "guard_spawn_rate").
  parameter: string,
  /// Current value of the parameter.
  currentValue: float,
  /// Suggested new value.
  suggestedValue: float,
  /// Human-readable reason for the suggestion.
  reason: string,
  /// Expected impact classification ("high", "medium", "low").
  impact: string,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Balance Analyser panel.
type balanceTab =
  /// Overview — sortable level table with key balance metrics.
  | TabOverview
  /// Distributions — histogram charts for spawn rates, completion times, etc.
  | TabDistributions
  /// Simulations — Monte Carlo simulation runner and results.
  | TabSimulations
  /// Recommendations — AI-generated parameter adjustment suggestions.
  | TabRecommendations
  /// Difficulty Curve — level-by-level difficulty progression chart.
  | TabDifficultyCurve

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Balance Analyser panel.
type balanceAnalyserState = {
  /// Active tab within the panel.
  activeTab: balanceTab,
  /// Per-level balance statistics.
  levelStats: array<levelBalanceStats>,
  /// Distribution data for charting.
  distributions: array<distributionPoint>,
  /// Named distributions with statistical summaries.
  namedDistributions: array<namedDistribution>,
  /// Monte Carlo simulation results.
  simulations: array<simulationResult>,
  /// Balance adjustment recommendations.
  recommendations: array<balanceRecommendation>,
  /// Number of simulation runs per level (configurable).
  simulationRuns: int,
  /// Whether a simulation or analysis is currently running.
  running: bool,
  /// Currently selected level ID for detail view.
  selectedLevel: option<string>,
  /// Error from the last operation.
  error: option<string>,
}
