// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Balance Analyser Engine — pure functions for game balance analysis.

open BalanceAnalyserModel

let defaultState: balanceAnalyserState = {
  activeTab: TabOverview,
  levelStats: [],
  distributions: [],
  simulations: [],
  recommendations: [],
  simulationRuns: 1000,
  running: false,
  selectedLevel: None,
  error: None,
}

let tabLabel = (tab: balanceTab): string =>
  switch tab {
  | TabOverview => "Overview"
  | TabDistributions => "Distributions"
  | TabSimulations => "Simulations"
  | TabRecommendations => "Recommendations"
  | TabDifficultyCurve => "Difficulty Curve"
  }

let allTabs: array<balanceTab> = [TabOverview, TabDistributions, TabSimulations, TabRecommendations, TabDifficultyCurve]

/// Average difficulty score across all levels.
let avgDifficulty = (stats: array<levelBalanceStats>): float => {
  let count = stats->Array.length
  if count == 0 { 0.0 }
  else {
    let sum = stats->Array.reduce(0.0, (acc, s) => acc +. s.difficultyScore)
    sum /. Float.fromInt(count)
  }
}

/// Find outlier levels (outlierScore > threshold).
let findOutliers = (stats: array<levelBalanceStats>, threshold: float): array<levelBalanceStats> =>
  stats->Array.filter(s => s.outlierScore > threshold)

/// Average win rate from simulations.
let avgWinRate = (sims: array<simulationResult>): float => {
  let count = sims->Array.length
  if count == 0 { 0.0 }
  else {
    let sum = sims->Array.reduce(0.0, (acc, s) => acc +. s.winRate)
    sum /. Float.fromInt(count)
  }
}

/// Count recommendations by impact level.
let highImpactCount = (recs: array<balanceRecommendation>): int =>
  recs->Array.filter(r => r.impact == "high")->Array.length

/// Difficulty curve data (sorted by level order).
let difficultyCurve = (stats: array<levelBalanceStats>): array<(string, float)> =>
  stats->Array.map(s => (s.levelName, s.difficultyScore))
