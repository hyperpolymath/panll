// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Guard AI Tuner Engine — pure computation and helpers for tuning
/// guard patrol behaviour, alert thresholds, and spawn rates.
///
/// Provides default state, tab labels, and utility functions for averaging
/// spawn rates and alert thresholds, counting patrol points, and formatting
/// patrol pattern names.

open GuardAiTunerModel

/// Default state for the Guard AI Tuner panel.
let defaultState: guardAiTunerState = {
  activeTab: Profiles,
  guards: [],
  routes: [],
  presets: [],
  selectedGuard: None,
  editing: false,
  error: None,
}

/// Human-readable label for a guard AI tuner category tab.
let tabLabel = (cat: guardAiTunerCategory): string =>
  switch cat {
  | Profiles => "Profiles"
  | PatrolEditor => "Patrol Editor"
  | Thresholds => "Thresholds"
  | Presets => "Presets"
  }

/// All category tabs in display order.
let allTabs: array<guardAiTunerCategory> = [Profiles, PatrolEditor, Thresholds, Presets]

/// Average spawn rate across all guard profiles. Returns 0.0 if no guards.
let avgSpawnRate = (guards: array<guardProfile>): float => {
  let len = guards->Array.length
  if len === 0 {
    0.0
  } else {
    guards->Array.reduce(0.0, (acc, g) => acc +. g.spawnRate) /. Int.toFloat(len)
  }
}

/// Average alert threshold across all guard profiles. Returns 0.0 if no guards.
let avgAlertThreshold = (guards: array<guardProfile>): float => {
  let len = guards->Array.length
  if len === 0 {
    0.0
  } else {
    guards->Array.reduce(0.0, (acc, g) => acc +. g.alertThreshold) /. Int.toFloat(len)
  }
}

/// Count total patrol points across all routes.
let countPatrolPoints = (routes: array<patrolRoute>): int =>
  routes->Array.reduce(0, (acc, r) => acc + r.points->Array.length)

/// Human-readable label for a patrol pattern string.
let formatPatrolPattern = (pattern: string): string =>
  switch pattern {
  | "loop" => "Loop"
  | "pingpong" => "Ping-Pong"
  | "random" => "Random"
  | "stationary" => "Stationary"
  | other => other
  }
