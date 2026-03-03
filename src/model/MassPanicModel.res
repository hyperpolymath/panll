// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Mass Panic Model — types for the organisation-scale batch scanning
/// panel (assemblyline + incremental BLAKE3 + verisimdb + delta reporting).
///
/// This is the "mass-panic" deployment mode of panic-attack: scan hundreds or
/// thousands of repos in parallel, persist results, compare runs, and generate
/// notifications for critical findings.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Status of an individual repo in the scan queue.
type repoScanStatus =
  | Queued
  | Scanning
  | Complete
  | Skipped // unchanged (incremental BLAKE3 match)
  | Failed(string)

/// Per-repo scan result summary.
type repoResult = {
  repoPath: string,
  repoName: string,
  status: repoScanStatus,
  totalFindings: int,
  critical: int,
  high: int,
  medium: int,
  low: int,
  filesScanned: int,
  blake3Hash: option<string>,
  scanDuration: option<float>, // seconds
}

/// Overall assemblyline run summary.
type assemblylineSummary = {
  totalRepos: int,
  scannedRepos: int,
  skippedRepos: int,
  failedRepos: int,
  totalFindings: int,
  totalCritical: int,
  totalHigh: int,
  scanDuration: float, // seconds
  timestamp: string,
}

/// Delta between two runs (what's new/fixed).
type deltaEntry = {
  repoName: string,
  newFindings: int,
  fixedFindings: int,
  changeDirection: string, // "improved", "regressed", "unchanged", "new"
}

/// Sort mode for the repo list.
type repoSortMode =
  | ByRisk // riskiest first (default)
  | ByName
  | ByFindings
  | ByDuration

/// Filter mode for the repo list.
type repoFilterMode =
  | AllRepos
  | FindingsOnly // repos with >= 1 finding
  | CriticalOnly // repos with critical findings
  | FailedOnly // repos that errored

/// Storage target for persisting results.
type storageTarget =
  | NoStorage
  | Filesystem(string) // base directory
  | VerisimDB(string) // verisimdb data directory

/// Root state for the mass-panic panel.
type massPanicState = {
  /// Directory containing repos to scan.
  reposDirectory: string,
  /// Whether a scan is in progress.
  scanning: bool,
  /// Current scan progress (0.0 to 1.0).
  progress: float,
  /// Currently scanning repo name (for progress display).
  currentRepo: option<string>,
  /// Use incremental scanning (skip unchanged repos via BLAKE3).
  incremental: bool,
  /// Cache file path for BLAKE3 fingerprints.
  cachePath: option<string>,
  /// Storage target for persisting results.
  storage: storageTarget,
  /// Minimum findings threshold for display.
  minFindings: int,
  /// Per-repo results.
  repoResults: array<repoResult>,
  /// Aggregate summary of the current/last run.
  summary: option<assemblylineSummary>,
  /// Delta entries (comparison with previous run).
  delta: array<deltaEntry>,
  /// Whether delta comparison is active.
  showDelta: bool,
  /// Previous run summary for comparison.
  previousSummary: option<assemblylineSummary>,
  /// Sort mode.
  sortMode: repoSortMode,
  /// Filter mode.
  filterMode: repoFilterMode,
  /// Text search within repo names/results.
  searchText: string,
  /// Selected repo indices for batch operations.
  selectedRepos: array<int>,
  /// Whether all repos are selected.
  selectAll: bool,
  /// Whether notification generation is enabled.
  notifyEnabled: bool,
  /// Only notify for critical findings.
  notifyCriticalOnly: bool,
  /// Loading state.
  loading: bool,
  /// Last error message.
  lastError: option<string>,
}

/// Initial state for the mass-panic panel.
let init: massPanicState = {
  reposDirectory: "",
  scanning: false,
  progress: 0.0,
  currentRepo: None,
  incremental: true, // on by default — sensible for repeat scans
  cachePath: None,
  storage: NoStorage,
  minFindings: 0,
  repoResults: [],
  summary: None,
  delta: [],
  showDelta: false,
  previousSummary: None,
  sortMode: ByRisk,
  filterMode: AllRepos,
  searchText: "",
  selectedRepos: [],
  selectAll: false,
  notifyEnabled: false,
  notifyCriticalOnly: true,
  loading: false,
  lastError: None,
}
