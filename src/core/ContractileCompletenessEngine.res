// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Contractile Completeness Engine — pure helpers for contractile coverage.

open ContractileCompletenessModel

/// Default initial state.
let defaultState: contractileCompletenessState = {
  activeTab: TabOverview,
  repos: [],
  selectedRepo: None,
  scanning: false,
  error: None,
  filterText: "",
}

/// Tab label for display.
let tabLabel = (tab: contractileCompletenessTab): string => {
  switch tab {
  | TabOverview => "Overview"
  | TabRepoList => "Repos"
  | TabMissing => "Missing"
  }
}

/// All tabs for rendering.
let allTabs: array<contractileCompletenessTab> = [TabOverview, TabRepoList, TabMissing]

/// Count repos with all four contractile files present.
let fullyCompleteCount = (repos: array<repoContractileStatus>): int => {
  repos
  ->Array.filter(r => r.hasMustfile && r.hasTrustfile && r.hasDustfile && r.hasK9)
  ->Array.length
}

/// Count repos missing any contractile file.
let incompleteCount = (repos: array<repoContractileStatus>): int => {
  repos
  ->Array.filter(r => !(r.hasMustfile && r.hasTrustfile && r.hasDustfile && r.hasK9))
  ->Array.length
}
