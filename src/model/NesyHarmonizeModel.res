// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Harmonization Monitor Model — types for live neural-symbolic
/// verdict fusion monitoring.
///
/// Tracks how neural and symbolic subsystems reach harmonized verdicts,
/// including confidence levels, symbolic override rates, and per-source
/// entry attribution.
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Verdict Types
// ============================================================================

/// Neural subsystem verdict — probabilistic assessment.
type neuralVerdict =
  /// Neural model classifies the input as probably safe.
  | ProbableSafe
  /// Neural model is uncertain — insufficient confidence.
  | Unsure
  /// Neural model classifies the input as probably unsafe.
  | ProbableUnsafe

/// Symbolic subsystem verdict — logical proof-based assessment.
type symbolicVerdict =
  /// Symbolic prover has a proof of safety.
  | ProvenSafe
  /// Symbolic prover could not construct a proof either way.
  | NoProof
  /// Symbolic prover has a proof of unsafety (counterexample found).
  | ProvenUnsafe

/// Harmonized verdict after fusing neural and symbolic outputs.
type harmonizedVerdict =
  /// Both subsystems agree on safety, or symbolic proof overrides neural.
  | CertifiedSafe
  /// Disagreement or insufficient confidence — needs human review.
  | RequiresReview
  /// Either subsystem flags critical unsafety — block immediately.
  | CriticalUnsafe

/// Confidence level of the harmonized verdict.
type confidenceLevel =
  /// Low confidence — both subsystems uncertain or in disagreement.
  | Low
  /// High confidence — strong agreement between subsystems.
  | High
  /// Absolute confidence — symbolic proof provides formal guarantee.
  | Absolute

// ============================================================================
// Harmonization Entries
// ============================================================================

/// A single harmonization entry representing one neural-symbolic verdict fusion.
type harmonizationEntry = {
  /// Unique entry identifier.
  id: string,
  /// ISO 8601 timestamp of when this harmonization occurred.
  timestamp: string,
  /// The neural subsystem's verdict.
  neural: neuralVerdict,
  /// The symbolic subsystem's verdict.
  symbolic: symbolicVerdict,
  /// The final harmonized verdict after fusion.
  verdict: harmonizedVerdict,
  /// Confidence level of the harmonized verdict.
  confidence: confidenceLevel,
  /// Whether the symbolic subsystem overrode the neural subsystem.
  symbolicWins: bool,
  /// Which agent or service requested this harmonization.
  source: string,
}

// ============================================================================
// Statistics
// ============================================================================

/// Aggregate statistics across all harmonization entries.
type harmonizeStats = {
  /// Total number of harmonization entries.
  totalCount: int,
  /// Count of CertifiedSafe verdicts.
  certifiedSafe: int,
  /// Count of RequiresReview verdicts.
  requiresReview: int,
  /// Count of CriticalUnsafe verdicts.
  criticalUnsafe: int,
  /// Rate at which symbolic subsystem overrides neural (0.0–1.0).
  symbolicWinRate: float,
}

// ============================================================================
// Panel State
// ============================================================================

/// Top-level state for the NeSy Harmonization Monitor panel.
type nesyHarmonizeState = {
  /// All harmonization entries (newest first).
  entries: array<harmonizationEntry>,
  /// Optional verdict filter — None shows all entries.
  filter: option<harmonizedVerdict>,
  /// Whether the panel auto-refreshes on an interval.
  autoRefresh: bool,
  /// Polling interval in milliseconds for auto-refresh.
  refreshIntervalMs: int,
  /// Aggregate statistics computed from entries.
  stats: harmonizeStats,
}
