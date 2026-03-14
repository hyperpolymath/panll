// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Wiring Inspector Model — types for the Panel Contract Compiler UI.
///
/// Surfaces PCC constraint state inside PanLL: obligation status, failure
/// classification, repairability, bottleneck analysis. Each obligation maps
/// to a slot in the DD-004 8-file panel wiring pattern.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Obligation status from the constraint propagation engine.
type obligationStatus = Satisfied | Unsatisfied | Blocked

/// Failure classification — root failures cause derived failures.
type failureClass = Root | Derived | NotFailed

/// How safely this obligation can be repaired.
type repairability = Safe | Unsafe | Manual

/// A single obligation from the PCC constraint graph.
type obligation = {
  /// Unique obligation identifier (e.g. "registry:MyLang").
  id: string,
  /// Obligation kind (e.g. "registry_entry", "model_slice", "msg_namespace").
  kind: string,
  /// Panel this obligation belongs to.
  panelId: string,
  /// Current status from constraint propagation.
  status: obligationStatus,
  /// Whether this is a root failure or derived from another.
  failureClass: failureClass,
  /// How safely auto-repair could fix this obligation.
  repairability: repairability,
  /// Human-readable diagnostic message.
  message: string,
  /// Source file where the obligation is checked.
  file: option<string>,
  /// Expected value or pattern (for unsatisfied obligations).
  expected: option<string>,
  /// IDs of obligations this one depends on.
  dependsOn: array<string>,
  /// Number of downstream obligations blocked by this one.
  blockedDownstreamCount: int,
}

/// Verification result for a single panel.
type panelVerification = {
  /// Panel identifier (e.g. "MyLang").
  panelId: string,
  /// Overall verification status ("complete" or "incomplete").
  status: string,
  /// Total number of obligations checked.
  total: int,
  /// Number of satisfied obligations.
  satisfied: int,
  /// Number of unsatisfied obligations.
  unsatisfied: int,
  /// Number of blocked obligations.
  blocked: int,
  /// Primary bottleneck obligation ID (highest downstream impact).
  primaryBottleneck: option<string>,
  /// All obligations for this panel.
  obligations: array<obligation>,
}

/// Overall inspector state.
type wiringInspectorState = {
  /// Whether a verification run is in progress.
  loading: bool,
  /// ISO timestamp of the last verification run.
  lastRunAt: option<string>,
  /// Verification results for all panels.
  results: array<panelVerification>,
  /// Currently selected panel for detail view.
  selectedPanel: option<string>,
  /// Filter obligations by status string ("Satisfied", "Unsatisfied", "Blocked").
  filterStatus: option<string>,
  /// Error message from the last failed verification run.
  error: option<string>,
}
