// SPDX-License-Identifier: MPL-2.0

/// PanLL Regression Guard Model — snapshot comparison and golden-file testing
/// for IDApTIK game state, render output, and API responses.
///
/// Captures baseline "golden" snapshots and compares subsequent runs against
/// them, reporting visual diffs, structural differences, and blame analysis.
///
/// Clade: Scanner. This module has NO dependencies on other PanLL modules.

// ============================================================================
// Snapshot Classification
// ============================================================================

/// Category of snapshot being tracked. Determines the comparison algorithm
/// used (text diff, image diff, JSON structural diff, etc.).
type snapshotKind =
  /// Game state serialised as JSON — uses structural JSON diff.
  | SnapshotGameState
  /// Rendered frame output — uses pixel-by-pixel image diff.
  | SnapshotRenderOutput
  /// API response body — uses JSON path diff.
  | SnapshotApiResponse
  /// Test output log — uses line-by-line text diff.
  | SnapshotTestOutput
  /// Custom snapshot with user-defined label.
  | SnapshotCustom(string)

// ============================================================================
// Snapshot Entries
// ============================================================================

/// A single tracked snapshot entry with golden baseline and optional current.
type regressionSnapshot = {
  /// Unique snapshot identifier.
  id: string,
  /// Human-readable name (e.g., "Level 3 completion state").
  name: string,
  /// Classification determining the diff algorithm.
  kind: snapshotKind,
  /// Filesystem path to the golden baseline file.
  goldenPath: string,
  /// Filesystem path to the current (latest) snapshot (None if not yet captured).
  currentPath: option<string>,
  /// Whether the current snapshot matches the golden baseline (None = not yet compared).
  matched: option<bool>,
  /// Human-readable diff summary if mismatched.
  diffSummary: option<string>,
  /// ISO 8601 timestamp of last update.
  updatedAt: string,
}

// ============================================================================
// Regression Results
// ============================================================================

/// Summary of a regression check run across all tracked snapshots.
type regressionResult = {
  /// Total number of snapshots checked.
  totalSnapshots: int,
  /// Count of snapshots matching their golden baselines.
  matched: int,
  /// Count of snapshots diverging from their golden baselines.
  mismatched: int,
  /// Count of golden baselines with no current snapshot available.
  missing: int,
  /// Count of new snapshots with no golden baseline yet.
  newSnapshots: int,
  /// Total time taken for the regression check in milliseconds.
  durationMs: float,
  /// ISO 8601 timestamp of this result.
  timestamp: string,
}

/// Blame attribution for a regression — identifies the commit that caused drift.
type regressionBlame = {
  /// The snapshot that regressed.
  snapshotId: string,
  /// Git commit hash that introduced the regression.
  commitHash: string,
  /// Author of the regressing commit.
  author: string,
  /// Commit message excerpt.
  commitMessage: string,
  /// Files changed in the regressing commit.
  filesChanged: array<string>,
}

// ============================================================================
// Tab Navigation
// ============================================================================

/// Active tab within the Regression Guard panel.
type regressionTab =
  /// Snapshots — inventory of tracked snapshots with match/mismatch badges.
  | TabSnapshots
  /// Diffs — inline visual diff viewer for mismatched snapshots.
  | TabDiffs
  /// History — timeline of regression check results with trend.
  | TabHistory
  /// Settings — auto-update policy, threshold configuration, blame settings.
  | TabSettings

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Regression Guard panel.
type regressionGuardState = {
  /// Active tab within the panel.
  activeTab: regressionTab,
  /// All tracked snapshot entries.
  snapshots: array<regressionSnapshot>,
  /// Historical regression check results.
  results: array<regressionResult>,
  /// Blame attributions for recent regressions.
  blameEntries: array<regressionBlame>,
  /// Whether a regression check is currently running.
  running: bool,
  /// Whether to auto-update golden baselines when snapshots pass review.
  autoUpdate: bool,
  /// Search filter for snapshot names.
  filter: string,
  /// Error from the last operation.
  error: option<string>,
}
