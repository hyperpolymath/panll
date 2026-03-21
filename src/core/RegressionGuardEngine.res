// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Regression Guard Engine — pure computation and helpers for the
/// Regression Guard panel. Provides default state, snapshot counting,
/// filtering, kind labelling, and regression result analysis.

open RegressionGuardModel

/// Default state for the Regression Guard panel.
/// Starts on the Snapshots tab with empty snapshot list and auto-update off.
let defaultState: regressionGuardState = {
  activeTab: TabSnapshots,
  snapshots: [],
  results: [],
  blameEntries: [],
  running: false,
  autoUpdate: false,
  filter: "",
  error: None,
}

/// Human-readable label for each tab in the Regression Guard panel.
let tabLabel = (tab: regressionTab): string =>
  switch tab {
  | TabSnapshots => "Snapshots"
  | TabDiffs => "Diffs"
  | TabHistory => "History"
  | TabSettings => "Settings"
  }

/// All tabs in display order.
let allTabs: array<regressionTab> = [TabSnapshots, TabDiffs, TabHistory, TabSettings]

/// Count mismatched snapshots (current does not match golden).
let mismatchCount = (snapshots: array<regressionSnapshot>): int =>
  snapshots->Array.filter(s => s.matched == Some(false))->Array.length

/// Count snapshots needing review (have a current capture but no comparison yet).
let needsReview = (snapshots: array<regressionSnapshot>): int =>
  snapshots->Array.filter(s => s.matched == None && s.currentPath != None)->Array.length

/// Count matched (passing) snapshots.
let matchCount = (snapshots: array<regressionSnapshot>): int =>
  snapshots->Array.filter(s => s.matched == Some(true))->Array.length

/// Human-readable label for a snapshot kind.
let kindLabel = (kind: snapshotKind): string =>
  switch kind {
  | SnapshotGameState => "Game State"
  | SnapshotRenderOutput => "Render"
  | SnapshotApiResponse => "API Response"
  | SnapshotTestOutput => "Test Output"
  | SnapshotCustom(name) => name
  }

/// CSS colour class for a snapshot kind.
let kindColor = (kind: snapshotKind): string =>
  switch kind {
  | SnapshotGameState => "text-blue-400"
  | SnapshotRenderOutput => "text-pink-400"
  | SnapshotApiResponse => "text-green-400"
  | SnapshotTestOutput => "text-yellow-400"
  | SnapshotCustom(_) => "text-purple-400"
  }

/// Filter snapshots by a case-insensitive search string on name.
let filterSnapshots = (snapshots: array<regressionSnapshot>, filter: string): array<regressionSnapshot> =>
  if filter == "" {
    snapshots
  } else {
    let q = filter->String.toLowerCase
    snapshots->Array.filter(s => s.name->String.toLowerCase->String.includes(q))
  }

/// Compute the overall pass rate across all snapshots as a percentage.
/// Returns 100.0 when there are no snapshots.
let passRate = (snapshots: array<regressionSnapshot>): float => {
  let total = Array.length(snapshots)
  if total == 0 {
    100.0
  } else {
    let matched = matchCount(snapshots)
    Int.toFloat(matched) /. Int.toFloat(total) *. 100.0
  }
}

/// Get the most recent regression result (or None if no results yet).
let latestResult = (results: array<regressionResult>): option<regressionResult> => {
  let count = Array.length(results)
  if count == 0 {
    None
  } else {
    Some(results->Array.getUnsafe(count - 1))
  }
}

/// Whether the latest regression check introduced new failures.
let hasNewRegressions = (results: array<regressionResult>): bool =>
  switch latestResult(results) {
  | Some(r) => r.mismatched > 0
  | None => false
  }
