// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Regression Guard Model — snapshot comparison and golden-file testing state.
/// This module has NO dependencies on other PanLL modules.

/// Type of snapshot.
type snapshotKind =
  | SnapshotGameState
  | SnapshotRenderOutput
  | SnapshotApiResponse
  | SnapshotTestOutput
  | SnapshotCustom(string)

/// A snapshot entry.
type regressionSnapshot = {
  id: string,
  name: string,
  kind: snapshotKind,
  goldenPath: string,
  currentPath: option<string>,
  matched: option<bool>,
  diffSummary: option<string>,
  updatedAt: string,
}

/// Regression check result.
type regressionResult = {
  totalSnapshots: int,
  matched: int,
  mismatched: int,
  missing: int,
  newSnapshots: int,
  durationMs: float,
  timestamp: string,
}

/// Active tab.
type regressionTab =
  | TabSnapshots
  | TabDiffs
  | TabHistory
  | TabSettings

/// Regression guard state.
type regressionGuardState = {
  activeTab: regressionTab,
  snapshots: array<regressionSnapshot>,
  results: array<regressionResult>,
  running: bool,
  autoUpdate: bool,
  filter: string,
  error: option<string>,
}
