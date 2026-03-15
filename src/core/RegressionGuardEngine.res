// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Regression Guard Engine — pure functions for snapshot comparison state.

open RegressionGuardModel

/// Default initial state.
let defaultState: regressionGuardState = {
  activeTab: TabSnapshots,
  snapshots: [],
  results: [],
  running: false,
  autoUpdate: false,
  filter: "",
  error: None,
}

/// Tab label for display.
let tabLabel = (tab: regressionTab): string =>
  switch tab {
  | TabSnapshots => "Snapshots"
  | TabDiffs => "Diffs"
  | TabHistory => "History"
  | TabSettings => "Settings"
  }

/// All tabs for rendering.
let allTabs: array<regressionTab> = [TabSnapshots, TabDiffs, TabHistory, TabSettings]

/// Count mismatched snapshots.
let mismatchCount = (snapshots: array<regressionSnapshot>): int =>
  snapshots->Array.filter(s => s.matched == Some(false))->Array.length

/// Count snapshots needing review.
let needsReview = (snapshots: array<regressionSnapshot>): int =>
  snapshots->Array.filter(s => s.matched == None && s.currentPath != None)->Array.length

/// Snapshot kind label.
let kindLabel = (kind: snapshotKind): string =>
  switch kind {
  | SnapshotGameState => "Game State"
  | SnapshotRenderOutput => "Render"
  | SnapshotApiResponse => "API Response"
  | SnapshotTestOutput => "Test Output"
  | SnapshotCustom(name) => name
  }

/// Filter snapshots by search string.
let filterSnapshots = (snapshots: array<regressionSnapshot>, filter: string): array<regressionSnapshot> =>
  if filter == "" { snapshots }
  else { snapshots->Array.filter(s => String.includes(s.name, filter)) }
