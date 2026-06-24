// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Mass Panic Model — types for the organisation-scale batch scanning
/// panel (assemblyline + incremental BLAKE3 + verisim + delta reporting).
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
  | VerisimDB(string) // verisim data directory

// ---------------------------------------------------------------------------
// Imaging — fNIRS-style spatial health map (panll.system-image.v0)
// ---------------------------------------------------------------------------

/// Risk distribution histogram — how many nodes at each risk level.
type riskDistribution = {
  healthy: int,
  low: int,
  moderate: int,
  high: int,
  critical: int,
}

/// A single node in the system image — one repo's health reading.
type imageNode = {
  id: string,
  name: string,
  healthScore: float,
  riskIntensity: float,
  weakPointDensity: float,
  weakPointCount: int,
  criticalCount: int,
  highCount: int,
  fingerprint: option<string>,
  skipped: bool,
  topCategories: array<string>,
}

/// An edge connecting two nodes by risk proximity or shared pattern.
type imageEdge = {
  fromNode: string,
  toNode: string,
  edgeType: string,
  weight: float,
}

/// A point-in-time system health image (fNIRS-style functional scan).
type systemImage = {
  scanSurface: string,
  generatedAt: string,
  globalHealth: float,
  globalRisk: float,
  nodeCount: int,
  edgeCount: int,
  totalWeakPoints: int,
  totalCritical: int,
  riskDistribution: riskDistribution,
  nodes: array<imageNode>,
  edges: array<imageEdge>,
}

// ---------------------------------------------------------------------------
// Temporal — time-series navigation (panll.temporal-diff.v0)
// ---------------------------------------------------------------------------

/// A temporal snapshot entry (lightweight manifest row).
type snapshotEntry = {
  sequence: int,
  timestamp: string,
  label: string,
  nodeCount: int,
  globalHealth: float,
  globalRisk: float,
  totalWeakPoints: int,
}

/// Per-node health change between two snapshots.
type nodeDelta = {
  name: string,
  healthBefore: float,
  healthAfter: float,
  healthDelta: float,
  riskBefore: float,
  riskAfter: float,
  riskDelta: float,
  weakPointDelta: int,
}

/// Diff between two system image snapshots.
type temporalDiff = {
  fromLabel: string,
  toLabel: string,
  fromTimestamp: string,
  toTimestamp: string,
  healthDelta: float,
  riskDelta: float,
  weakPointDelta: int,
  criticalDelta: int,
  newNodes: array<string>,
  removedNodes: array<string>,
  improvedNodes: array<nodeDelta>,
  degradedNodes: array<nodeDelta>,
  unchangedCount: int,
  trend: string,
}

/// Which sub-view is active in the mass-panic panel.
type massPanicView =
  | ScanView
  | ImagingView
  | TemporalView

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
  // -- Imaging (fNIRS-style spatial health map) --
  /// Current system image (latest scan).
  currentImage: option<systemImage>,
  /// Whether imaging view is loading.
  imagingLoading: bool,
  // -- Temporal navigation --
  /// Snapshot timeline entries.
  snapshots: array<snapshotEntry>,
  /// Current temporal diff (between two selected snapshots).
  currentDiff: option<temporalDiff>,
  /// Selected snapshot indices for comparison.
  selectedSnapshots: (option<int>, option<int>),
  /// Whether temporal view is loading.
  temporalLoading: bool,
  // -- Sub-view selection --
  /// Which sub-view is active.
  activeView: massPanicView,
}

/// Default initial state for the mass-panic panel.
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
  currentImage: None,
  imagingLoading: false,
  snapshots: [],
  currentDiff: None,
  selectedSnapshots: (None, None),
  temporalLoading: false,
  activeView: ScanView,
}
