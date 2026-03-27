// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Floor Raise Engine — pure helpers for the campaign dashboard.

open FloorRaiseModel

/// Default initial state.
let defaultState: floorRaiseState = {
  activeTab: TabOverview,
  adoptions: [
    {name: "proven", adoptedCount: 0, targetCount: 0, percentage: 0.0, campaignActive: false},
    {
      name: "contractiles-trust",
      adoptedCount: 0,
      targetCount: 0,
      percentage: 0.0,
      campaignActive: false,
    },
    {
      name: "contractiles-dust",
      adoptedCount: 0,
      targetCount: 0,
      percentage: 0.0,
      campaignActive: false,
    },
    {name: "ai-manifest", adoptedCount: 0, targetCount: 0, percentage: 0.0, campaignActive: false},
    {
      name: "panic-attacker",
      adoptedCount: 0,
      targetCount: 0,
      percentage: 0.0,
      campaignActive: false,
    },
    {name: "verisimdb", adoptedCount: 0, targetCount: 0, percentage: 0.0, campaignActive: false},
    {
      name: "feedback-o-tron",
      adoptedCount: 0,
      targetCount: 0,
      percentage: 0.0,
      campaignActive: false,
    },
    {name: "vexometer", adoptedCount: 0, targetCount: 0, percentage: 0.0, campaignActive: false},
  ],
  outcomes: [],
  scanning: false,
  error: None,
  totalRepos: 0,
}

/// Tab label for display.
let tabLabel = (tab: floorRaiseTab): string => {
  switch tab {
  | TabOverview => "Overview"
  | TabCampaigns => "Campaigns"
  | TabOutcomes => "Outcomes"
  | TabGaps => "Gaps"
  }
}

/// All tabs for rendering.
let allTabs: array<floorRaiseTab> = [TabOverview, TabCampaigns, TabOutcomes, TabGaps]

/// Calculate overall floor raise progress (average adoption percentage).
let overallProgress = (state: floorRaiseState): float => {
  let total = state.adoptions->Array.reduce(0.0, (acc, a) => acc +. a.percentage)
  let count = state.adoptions->Array.length->Int.toFloat
  if count > 0.0 {
    total /. count
  } else {
    0.0
  }
}

/// Count tools with active campaigns.
let activeCampaignCount = (state: floorRaiseState): int => {
  state.adoptions->Array.filter(a => a.campaignActive)->Array.length
}

/// Count successful dispatch outcomes.
let successCount = (outcomes: array<dispatchOutcome>): int => {
  outcomes->Array.filter(o => o.success)->Array.length
}
