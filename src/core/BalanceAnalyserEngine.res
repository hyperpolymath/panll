// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Balance Analyser Engine — pure computation and helpers for the
/// Balance Analyser panel. Provides default state, statistical analysis,
/// outlier detection, simulation averaging, and difficulty curve extraction.

open BalanceAnalyserModel

/// Default state for the Balance Analyser panel.
/// Starts on the Overview tab with 1000 simulation runs per level.
let defaultState: balanceAnalyserState = {
  activeTab: TabOverview,
  levelStats: [],
  distributions: [],
  namedDistributions: [],
  simulations: [],
  recommendations: [],
  simulationRuns: 1000,
  running: false,
  selectedLevel: None,
  error: None,
}

/// Human-readable label for each tab in the Balance Analyser panel.
let tabLabel = (tab: balanceTab): string =>
  switch tab {
  | TabOverview => "Overview"
  | TabDistributions => "Distributions"
  | TabSimulations => "Simulations"
  | TabRecommendations => "Recommendations"
  | TabDifficultyCurve => "Difficulty Curve"
  }

/// All tabs in display order.
let allTabs: array<balanceTab> = [
  TabOverview,
  TabDistributions,
  TabSimulations,
  TabRecommendations,
  TabDifficultyCurve,
]

/// Average difficulty score across all levels.
let avgDifficulty = (stats: array<levelBalanceStats>): float => {
  let count = stats->Array.length
  if count == 0 {
    0.0
  } else {
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
  if count == 0 {
    0.0
  } else {
    let sum = sims->Array.reduce(0.0, (acc, s) => acc +. s.winRate)
    sum /. Float.fromInt(count)
  }
}

/// Average completion time from simulations.
let avgCompletionTime = (sims: array<simulationResult>): float => {
  let count = sims->Array.length
  if count == 0 {
    0.0
  } else {
    let sum = sims->Array.reduce(0.0, (acc, s) => acc +. s.avgCompletionTime)
    sum /. Float.fromInt(count)
  }
}

/// Count recommendations by impact level.
let highImpactCount = (recs: array<balanceRecommendation>): int =>
  recs->Array.filter(r => r.impact == "high")->Array.length

/// Count medium impact recommendations.
let mediumImpactCount = (recs: array<balanceRecommendation>): int =>
  recs->Array.filter(r => r.impact == "medium")->Array.length

/// Difficulty curve data (sorted by level order).
/// Returns an array of (levelName, difficultyScore) pairs.
let difficultyCurve = (stats: array<levelBalanceStats>): array<(string, float)> =>
  stats->Array.map(s => (s.levelName, s.difficultyScore))

/// Win rate curve data (sorted by level order).
/// Returns an array of (levelName, winRate) pairs.
let winRateCurve = (stats: array<levelBalanceStats>): array<(string, float)> =>
  stats->Array.map(s => (s.levelName, s.estimatedWinRate))

/// Identify levels with extreme difficulty (score > 0.9 or < 0.1).
let extremeLevels = (stats: array<levelBalanceStats>): array<levelBalanceStats> =>
  stats->Array.filter(s => s.difficultyScore > 0.9 || s.difficultyScore < 0.1)

/// Total simulation deaths broken down by cause for a single result.
let totalDeaths = (sim: simulationResult): int =>
  sim.deathsByGuard + sim.deathsByTrap + sim.deathsByTimeout

/// Death cause percentages for a simulation result.
let deathBreakdown = (sim: simulationResult): (float, float, float) => {
  let total = Float.fromInt(totalDeaths(sim))
  if total == 0.0 {
    (0.0, 0.0, 0.0)
  } else {
    (
      Float.fromInt(sim.deathsByGuard) /. total *. 100.0,
      Float.fromInt(sim.deathsByTrap) /. total *. 100.0,
      Float.fromInt(sim.deathsByTimeout) /. total *. 100.0,
    )
  }
}
