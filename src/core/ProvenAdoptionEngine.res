// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Proven Adoption Engine — pure helpers for proven library tracking.

open ProvenAdoptionModel

/// Default initial state.
let defaultState: provenAdoptionState = {
  activeTab: TabRepoList,
  repos: [],
  selectedRepo: None,
  scanning: false,
  error: None,
  filterText: "",
}

/// Tab label for display.
let tabLabel = (tab: provenAdoptionTab): string => {
  switch tab {
  | TabRepoList => "Repos"
  | TabModuleMatrix => "Module Matrix"
  | TabGaps => "Gaps"
  }
}

/// All tabs for rendering.
let allTabs: array<provenAdoptionTab> = [TabRepoList, TabModuleMatrix, TabGaps]

/// Count repos that have adopted proven.
let adoptedCount = (repos: array<repoProvenSummary>): int => {
  repos->Array.filter(r => r.dependencyDeclared)->Array.length
}

/// Count repos with full binding status.
let fullyBoundCount = (repos: array<repoProvenSummary>): int => {
  repos->Array.filter(r => r.bindingStatus == Adopted)->Array.length
}
