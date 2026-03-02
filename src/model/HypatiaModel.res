// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Hypatia Model — types for the Hypatia neurosymbolic scanner panel.
///
/// Hypatia is the intelligence hub: 5 neural networks, VQL queries against
/// ArangoDB, safety triangle routing, quarantine, and learning cycles.
/// This panel is the brain of the entire ecosystem — it sees across all
/// 298+ repos and feeds findings to gitbot-fleet for execution.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Neural network identity within the Hypatia ensemble.
type neuralNetId =
  /// Vulnerability pattern recognition.
  | VulnNet
  /// Dependency graph analysis.
  | DepNet
  /// Code quality scoring.
  | QualNet
  /// Novelty detection (unseen patterns).
  | NoveltyNet
  /// Confidence calibration meta-network.
  | CalibNet

/// Status of an individual neural network.
type neuralNetStatus =
  /// Network is loaded and producing inferences.
  | NetActive
  /// Network is training/updating weights.
  | NetTraining
  /// Network is not loaded.
  | NetOffline
  /// Network encountered an error.
  | NetError(string)

/// A single neural network's state snapshot.
type neuralNetState = {
  /// Which network this is.
  id: neuralNetId,
  /// Current status.
  status: neuralNetStatus,
  /// Current confidence score (0.0–1.0).
  confidence: float,
  /// Number of inferences produced in current cycle.
  inferenceCount: int,
  /// Model version string.
  version: string,
}

/// A scan result from the Hypatia pipeline — one per repo.
type scanResult = {
  /// Repository name.
  repoName: string,
  /// Overall risk score (0.0–1.0, higher = riskier).
  riskScore: float,
  /// Number of findings in this repo.
  findingCount: int,
  /// Number of quarantined items.
  quarantineCount: int,
  /// Timestamp of last scan (ISO 8601).
  lastScanned: string,
  /// Whether the repo passed all checks.
  passed: bool,
}

/// Pipeline stage in the Hypatia processing flow.
type pipelineStage =
  /// Ingestion — reading source code and metadata.
  | Ingestion
  /// Analysis — running neural networks.
  | Analysis
  /// Routing — safety triangle classification.
  | Routing
  /// Dispatch — sending to gitbot-fleet.
  | Dispatch
  /// Complete — cycle finished.
  | Complete

/// Learning cycle status — Hypatia's continuous improvement loop.
type learningCycle = {
  /// Current pipeline stage.
  stage: pipelineStage,
  /// Number of repos scanned in this cycle.
  reposScanned: int,
  /// Total repos to scan.
  reposTotal: int,
  /// Cycle start time.
  startedAt: string,
  /// Whether novelty gating triggered (new patterns detected).
  noveltyTriggered: bool,
}

/// Category tabs for the Hypatia panel.
type hypatiaCategory =
  /// Overview — neural network gauges, pipeline status, learning cycle.
  | HypatiaDashboard
  /// Scan results — per-repo findings table.
  | HypatiaScans
  /// Quarantine — items held for human review.
  | HypatiaQuarantine
  /// Neural confidence — detailed network performance.
  | HypatiaNeural

/// Root state for the Hypatia panel.
type hypatiaState = {
  /// Whether data has been loaded from the Elixir backend.
  loaded: bool,
  /// Whether a loading operation is in progress.
  loading: bool,
  /// Error from the last operation.
  error: option<string>,
  /// The 5 neural networks and their current state.
  networks: array<neuralNetState>,
  /// Scan results per repo.
  scans: array<scanResult>,
  /// Current learning cycle status.
  learningCycle: option<learningCycle>,
  /// Active category tab.
  activeCategory: hypatiaCategory,
  /// Text filter for scan results search.
  filterText: string,
  /// Total repos in the scanning universe.
  totalRepos: int,
  /// Number of repos currently quarantined.
  quarantinedCount: int,
}
