// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Vexometer Friction Engine — pure helpers for irritation surface measurements.

open VexometerFrictionModel

/// Default initial state.
let defaultState: vexometerFrictionState = {
  activeTab: TabOverview,
  tools: [],
  selectedTool: None,
  measuring: false,
  error: None,
}

/// Tab label for display.
let tabLabel = (tab: vexometerFrictionTab): string => {
  switch tab {
  | TabOverview => "Overview"
  | TabToolList => "Tools"
  | TabDimensions => "Dimensions"
  }
}

/// All tabs for rendering.
let allTabs: array<vexometerFrictionTab> = [TabOverview, TabToolList, TabDimensions]

/// Trend label for display.
let trendLabel = (t: frictionTrend): string => {
  switch t {
  | Improving => "Improving"
  | Stable => "Stable"
  | Worsening => "Worsening"
  | NoData => "No Data"
  }
}

/// Sort tools by overall friction score (highest first).
let sortByFriction = (tools: array<toolFrictionProfile>): array<toolFrictionProfile> => {
  tools->Array.toSorted((a, b) => b.overallScore -. a.overallScore)
}

/// Average overall friction across all tools.
let averageFriction = (tools: array<toolFrictionProfile>): float => {
  let total = tools->Array.reduce(0.0, (acc, t) => acc +. t.overallScore)
  let count = tools->Array.length->Int.toFloat
  if count > 0.0 {total /. count} else {0.0}
}
