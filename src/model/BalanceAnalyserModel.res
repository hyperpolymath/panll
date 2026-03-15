// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Balance Analyser Model — game balance statistical analysis and simulation.
/// This module has NO dependencies on other PanLL modules.

/// A level's balance statistics.
type levelBalanceStats = {
  levelId: string,
  levelName: string,
  guardSpawnRate: float,
  alertThreshold: float,
  difficultyScore: float,
  estimatedWinRate: float,
  simulationRuns: int,
  outlierScore: float,
}

/// Distribution data point for charts.
type distributionPoint = {
  bucket: string,
  count: int,
  percentage: float,
}

/// Monte Carlo simulation result.
type simulationResult = {
  levelId: string,
  runs: int,
  winRate: float,
  avgCompletionTime: float,
  medianCompletionTime: float,
  p95CompletionTime: float,
  deathsByGuard: int,
  deathsByTrap: int,
  deathsByTimeout: int,
  timestamp: string,
}

/// Balance recommendation.
type balanceRecommendation = {
  levelId: string,
  parameter: string,
  currentValue: float,
  suggestedValue: float,
  reason: string,
  impact: string,
}

/// Active tab.
type balanceTab =
  | TabOverview
  | TabDistributions
  | TabSimulations
  | TabRecommendations
  | TabDifficultyCurve

/// Balance analyser state.
type balanceAnalyserState = {
  activeTab: balanceTab,
  levelStats: array<levelBalanceStats>,
  distributions: array<distributionPoint>,
  simulations: array<simulationResult>,
  recommendations: array<balanceRecommendation>,
  simulationRuns: int,
  running: bool,
  selectedLevel: option<string>,
  error: option<string>,
}
