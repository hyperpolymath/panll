// SPDX-License-Identifier: MPL-2.0

/// PanLL Floor Raise Model — floor-raising campaign dashboard state.
///
/// Tracks foundational tool adoption across the hyperpolymath ecosystem.
/// Aggregates proven, contractile, manifest, verisim, feedback-o-tron,
/// and vexometer adoption metrics.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Adoption status for a single foundational tool across the ecosystem.
type toolAdoption = {
  /// Tool name (e.g. "proven", "contractiles", "panic-attacker").
  name: string,
  /// Number of repos that have adopted this tool.
  adoptedCount: int,
  /// Total number of repos that should adopt this tool.
  targetCount: int,
  /// Adoption percentage (0.0 to 100.0).
  percentage: float,
  /// Whether a dispatch campaign is currently active for this tool.
  campaignActive: bool,
}

/// Dispatch outcome from a gitbot-fleet campaign.
type dispatchOutcome = {
  /// Timestamp (ISO 8601).
  timestamp: string,
  /// Repository name.
  repo: string,
  /// Fix script that was applied.
  fixScript: string,
  /// Whether the fix succeeded.
  success: bool,
  /// Category (e.g. "MissingTrustfile").
  category: string,
}

/// Floor Raise dashboard tabs.
type floorRaiseTab =
  | TabOverview
  | TabCampaigns
  | TabOutcomes
  | TabGaps

/// Root state for the Floor Raise panel.
type floorRaiseState = {
  /// Active tab.
  activeTab: floorRaiseTab,
  /// Adoption metrics for each foundational tool.
  adoptions: array<toolAdoption>,
  /// Recent dispatch outcomes.
  outcomes: array<dispatchOutcome>,
  /// Whether a scan is in progress.
  scanning: bool,
  /// Error from last scan.
  error: option<string>,
  /// Total repos in ecosystem.
  totalRepos: int,
}
