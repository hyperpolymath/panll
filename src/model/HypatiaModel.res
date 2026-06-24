// SPDX-License-Identifier: MPL-2.0

/// PanLL Hypatia Model — types for the Hypatia neurosymbolic scanner panel.
///
/// Hypatia is the intelligence hub: 5 neural networks, VCL queries against
/// verisim-data flat files, safety triangle routing, quarantine, and
/// learning cycles. This panel is the brain of the entire ecosystem — it
/// sees across all 301+ repos and feeds findings to gitbot-fleet for execution.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Neural network identity within the Hypatia ensemble.
type neuralNetId =
  /// PageRank trust over repos/bots/recipes.
  | GraphOfTrust
  /// Domain-specific confidence (7 expert domains).
  | MixtureOfExperts
  /// Temporal anomaly detection in event streams.
  | LiquidStateMachine
  /// Confidence trajectory forecasting + drift detection.
  | EchoStateNetwork
  /// Finding similarity, novelty detection, classification.
  | RadialNeuralNetwork

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
  /// Recipe inventory — confidence distribution and fix_script coverage.
  | HypatiaRecipes

/// An individual recipe in the Hypatia inventory.
type recipeEntry = {
  /// Unique recipe identifier (e.g. "hypatia-rec-001").
  id: string,
  /// Human-readable recipe name.
  name: string,
  /// Brief description of what this recipe detects/fixes.
  description: string,
  /// Confidence score (0.0–1.0).
  confidence: float,
  /// Safety triangle tier this recipe routes to (defined in FleetModel).
  tier: FleetModel.safetyTier,
  /// Whether a fix_script is available.
  hasFixScript: bool,
  /// Programming languages this recipe applies to.
  languages: array<string>,
  /// Number of times this recipe has fired across the estate.
  timesTriggered: int,
  /// Last triggered timestamp (ISO 8601) or "never".
  lastTriggered: string,
}

/// Recipe confidence distribution bucket.
type recipeConfidenceBucket = {
  /// Label for this bucket (e.g. "0.99", "0.95+", "0.90+", "<0.90").
  label: string,
  /// Number of recipes in this bucket.
  count: int,
}

/// Recipe inventory summary for the Recipes tab.
type recipeInventory = {
  /// Total number of recipes.
  totalRecipes: int,
  /// Confidence distribution buckets.
  confidenceBuckets: array<recipeConfidenceBucket>,
  /// Number of recipes with a fix_script (non-null).
  withFixScript: int,
  /// Number of recipes without a fix_script (null).
  withoutFixScript: int,
}

/// Outcome summary for the Hypatia Dashboard.
type outcomeSummary = {
  /// Total dispatch outcomes recorded.
  totalOutcomes: int,
  /// Number of successful outcomes.
  successCount: int,
  /// Success rate as a percentage (0.0–100.0).
  successRate: float,
  /// Whether the key mismatch fix has been applied.
  mismatchFixApplied: bool,
}

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
  /// Safety triangle counts: (eliminate, substitute, control).
  triangleCounts: option<(int, int, int)>,
  /// Recipe inventory summary.
  recipes: option<recipeInventory>,
  /// Individual recipe entries for drill-down.
  recipeEntries: array<recipeEntry>,
  /// Currently selected recipe for detail view (by id).
  selectedRecipe: option<string>,
  /// Recipe filter text.
  recipeFilter: string,
  /// Outcome summary for dashboard display.
  outcomes: option<outcomeSummary>,
}
