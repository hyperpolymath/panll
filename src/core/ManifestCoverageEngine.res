// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Manifest Coverage Engine — pure helpers for AI manifest tracking.

open ManifestCoverageModel

/// Default initial state.
let defaultState: manifestCoverageState = {
  activeTab: TabOverview,
  repos: [],
  selectedRepo: None,
  scanning: false,
  error: None,
  filterText: "",
}

/// Tab label for display.
let tabLabel = (tab: manifestCoverageTab): string => {
  switch tab {
  | TabOverview => "Overview"
  | TabRepoList => "Repos"
  | TabInvalid => "Invalid"
  }
}

/// All tabs for rendering.
let allTabs: array<manifestCoverageTab> = [TabOverview, TabRepoList, TabInvalid]

/// Count repos with a valid manifest.
let validManifestCount = (repos: array<repoManifestStatus>): int => {
  repos->Array.filter(r => r.hasManifest && r.isValid)->Array.length
}

/// Count repos with no manifest at all.
let missingManifestCount = (repos: array<repoManifestStatus>): int => {
  repos->Array.filter(r => !r.hasManifest)->Array.length
}
