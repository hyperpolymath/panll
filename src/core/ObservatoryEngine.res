// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Observatory Engine — pure helpers for the integrative dashboard.

open ObservatoryModel

/// Default initial state.
let defaultState: observatoryState = {
  activeTab: TabOverview,
  snapshots: [],
  activity: [],
  checking: false,
  error: None,
  systemCpu: 0.0,
  systemMemory: 0,
  systemMemoryTotal: 0,
}

/// Tab label for display.
let tabLabel = (tab: observatoryTab): string => {
  switch tab {
  | TabOverview => "Overview"
  | TabServices => "Services"
  | TabResources => "Resources"
  | TabActivity => "Activity"
  }
}

/// All tabs for rendering.
let allTabs: array<observatoryTab> = [
  TabOverview, TabServices, TabResources, TabActivity,
]

/// Health label for display.
let healthLabel = (h: serviceHealth): string => {
  switch h {
  | Healthy => "Healthy"
  | Degraded(reason) => "Degraded: " ++ reason
  | Unreachable => "Unreachable"
  | Unknown => "Unknown"
  }
}

/// Count panels by health status.
let countByHealth = (snapshots: array<resourceSnapshot>, target: serviceHealth): int => {
  snapshots->Array.filter(s => s.health == target)->Array.length
}

/// Total memory usage across all snapshots.
let totalMemory = (snapshots: array<resourceSnapshot>): int => {
  snapshots->Array.reduce(0, (acc, s) => acc + s.memoryBytes)
}
