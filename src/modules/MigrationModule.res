// SPDX-License-Identifier: PMPL-1.0-or-later

/// MigrationModule — PanLL module registration for the ReScript Migration Observatory.
///
/// Maps the migration observatory to PanLL's three-panel model:
///
///   Panel-L (Symbolic):  Migration constraints — deprecated APIs, version
///                        requirements, proof obligations, merge conflicts
///   Panel-N (Neural):    Hypatia reasoning — migration order, API replacement
///                        strategies, merge decisions, agentic actions taken
///   Panel-W (World):     Results dashboard — health scores, build times,
///                        bundle sizes, submission queue, timeline, rollback
///
/// Data sources:
///   - panic-attack migration-snapshot (via CLI or JSON files)
///   - feedback-o-tron MCP tools (begin/end observation, review queue)
///   - merge-resolver session logs (decision log JSON)
///   - Hypatia migration_rules.lgt (proof obligations, migration readiness)
///   - VeriSimDB octads (session persistence, cross-repo aggregation)

/// Capabilities supported by the Migration Observatory.
type migrationCapability =
  /// Capture before/after snapshots via panic-attack.
  | HealthSnapshots
  /// Observe migration sessions via feedback-o-tron MCP.
  | SessionObservation
  /// Queue and review issues for ReScript team submission.
  | SubmissionQueue
  /// Safe, reversible merge conflict resolution via merge-resolver.
  | MergeResolution
  /// Cross-repo aggregation reports from VeriSimDB.
  | AggregateReports
  /// Neurosymbolic reasoning from Hypatia migration rules.
  | ProofObligations

/// Panel-L constraint categories for the migration observatory.
type constraintCategory =
  /// Deprecated API usage constraints (Js.*, Belt.*).
  | DeprecatedApi
  /// Configuration format constraints (bsconfig.json).
  | ConfigFormat
  /// Version bracket requirements (JSX v4, uncurried mode).
  | VersionRequirement
  /// Proof obligations from Hypatia (all deprecated calls removed, etc.).
  | ProofObligation
  /// Merge conflict constraints (unresolved conflicts block migration).
  | MergeConflict

/// Panel-N reasoning categories for the migration observatory.
type reasoningCategory =
  /// Recommended migration order from Hypatia's dependency graph analysis.
  | MigrationOrder
  /// API replacement strategy (search_replace vs module_replace).
  | ReplacementStrategy
  /// Merge conflict resolution reasoning (why chose ours/theirs/ai).
  | MergeReasoning
  /// Safety triangle routing decisions.
  | SafetyRouting

/// Panel-W result categories for the migration observatory.
type resultCategory =
  /// Health score dashboard with sparklines.
  | HealthDashboard
  /// Before/after comparison cards.
  | ComparisonCards
  /// Build time and bundle size metrics.
  | PerformanceMetrics
  /// Submission review queue with approve/reject.
  | ReviewQueue
  /// Merge conflict timeline with rollback points.
  | MergeTimeline
  /// Cross-repo aggregation charts.
  | AggregationCharts

/// Module configuration for the Migration Observatory.
let moduleConfig = {
  "name": "Migration Observatory",
  "version": "1.0.0",
  "description": "ReScript migration health tracking, session observation, issue submission, and merge conflict resolution",
  "capabilities": [
    "health_snapshots",
    "session_observation",
    "submission_queue",
    "merge_resolution",
    "aggregate_reports",
    "proof_obligations",
  ],
  "backends": [
    {"name": "panic-attack", "type": "cli", "target": "panic-attack migration-snapshot"},
    {"name": "feedback-o-tron", "type": "mcp", "target": "feedback-a-tron"},
    {"name": "merge-resolver", "type": "cli", "target": "merge-resolver"},
    {"name": "verisimdb", "type": "api", "target": "http://localhost:8080/api/v1"},
  ],
  "panelMapping": {
    "panelL": ["deprecated_apis", "config_format", "version_requirements", "proof_obligations", "merge_conflicts"],
    "panelN": ["migration_order", "replacement_strategy", "merge_reasoning", "safety_routing"],
    "panelW": ["health_dashboard", "comparison_cards", "performance_metrics", "review_queue", "merge_timeline", "aggregation_charts"],
  },
}
