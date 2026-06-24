// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Drift Dashboard Model — types for neural model drift detection
/// and alerting.
///
/// Monitors 6 categories of drift across neural models, with severity-based
/// alerting, corrective action recommendations, and per-model status tracking.
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Drift Classification
// ============================================================================

/// Category of drift detected in a neural model.
type driftKind =
  /// Concept drift — the relationship between input and output has shifted.
  | ConceptDrift
  /// Data drift — the input data distribution has changed.
  | DataDrift
  /// Prior drift — the base rate of classes has shifted.
  | PriorDrift
  /// Architecture drift — model architecture no longer suits the problem.
  | ArchitectureDrift
  /// Distribution drift — output distribution diverges from expected.
  | DistributionDrift
  /// Feedback drift — feedback loop has introduced systematic bias.
  | FeedbackDrift

/// Recommended corrective action for detected drift.
type driftAction =
  /// Retrain the model on updated data.
  | Retrain
  /// Calibrate model confidence thresholds.
  | Calibrate
  /// Fall back to symbolic-only reasoning.
  | Fallback
  /// Halt model inference immediately.
  | Halt
  /// Escalate to human review.
  | Review
  /// Informational only — no action needed.
  | Ignore

// ============================================================================
// Urgency and Severity
// ============================================================================

/// Urgency level for a drift alert.
type driftUrgency =
  /// Immediate — act now, model may produce dangerous outputs.
  | Immediate
  /// Soon — address within hours, degradation is measurable.
  | Soon
  /// Scheduled — address in next maintenance window.
  | Scheduled
  /// FYI — informational, no action needed.
  | FYI

/// Severity of the detected drift.
type driftSeverity =
  /// Critical — model is producing incorrect outputs.
  | DriftCritical
  /// Warning — model accuracy is degrading.
  | DriftWarning
  /// Info — minor drift detected, within tolerance.
  | DriftInfo

// ============================================================================
// Drift Alerts
// ============================================================================

/// A single drift alert for a monitored model.
type driftAlert = {
  /// Unique alert identifier.
  id: string,
  /// ISO 8601 timestamp of when drift was detected.
  timestamp: string,
  /// Name of the model exhibiting drift.
  modelName: string,
  /// Category of drift detected.
  kind: driftKind,
  /// Severity of the drift.
  severity: driftSeverity,
  /// Urgency of required response.
  urgency: driftUrgency,
  /// Recommended corrective action.
  recommendedAction: driftAction,
  /// Drift magnitude as a normalised score (0.0–1.0).
  magnitude: float,
  /// Human-readable description of the drift.
  description: string,
}

// ============================================================================
// Per-Model Status
// ============================================================================

/// Current drift status for a single monitored model.
type modelDriftStatus = {
  /// Name of the monitored model.
  modelName: string,
  /// Whether the model is currently exhibiting drift.
  isDrifting: bool,
  /// Most recent drift kind, if any.
  lastDriftKind: option<driftKind>,
  /// Most recent drift magnitude (0.0–1.0).
  lastMagnitude: float,
  /// ISO 8601 timestamp of last drift check.
  lastChecked: string,
  /// Number of alerts triggered for this model.
  alertCount: int,
}

// ============================================================================
// Panel State
// ============================================================================

/// Top-level state for the NeSy Drift Dashboard panel.
type nesyDriftState = {
  /// All drift alerts (newest first).
  alerts: array<driftAlert>,
  /// Per-model drift status overview.
  modelStatuses: array<modelDriftStatus>,
  /// Optional urgency filter — None shows all alerts.
  urgencyFilter: option<driftUrgency>,
  /// Whether the dashboard is actively polling for drift checks.
  polling: bool,
  /// Poll interval in milliseconds.
  pollIntervalMs: int,
}
