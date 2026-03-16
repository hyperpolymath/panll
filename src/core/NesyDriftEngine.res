// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Drift Engine — pure helpers for the drift dashboard panel.
///
/// All functions are pure (no side effects). Provides drift classification,
/// action recommendations, urgency-based colour mappings, and filtering.

open NesyDriftModel

// ============================================================================
// Drift Classification
// ============================================================================

/// Classify a drift magnitude into a severity level.
/// Thresholds: >= 0.7 critical, >= 0.4 warning, else info.
let classifyDrift = (magnitude: float): driftSeverity => {
  if magnitude >= 0.7 {
    DriftCritical
  } else if magnitude >= 0.4 {
    DriftWarning
  } else {
    DriftInfo
  }
}

/// Recommend a corrective action based on drift kind and magnitude.
let recommendAction = (kind: driftKind, magnitude: float): driftAction => {
  switch (kind, magnitude >= 0.7) {
  | (ConceptDrift, true) => Retrain
  | (ConceptDrift, false) => Review
  | (DataDrift, true) => Retrain
  | (DataDrift, false) => Calibrate
  | (PriorDrift, _) => Calibrate
  | (ArchitectureDrift, true) => Halt
  | (ArchitectureDrift, false) => Review
  | (DistributionDrift, true) => Fallback
  | (DistributionDrift, false) => Calibrate
  | (FeedbackDrift, true) => Halt
  | (FeedbackDrift, false) => Review
  }
}

/// Determine urgency level from severity.
let urgencyLevel = (severity: driftSeverity): driftUrgency => {
  switch severity {
  | DriftCritical => Immediate
  | DriftWarning => Soon
  | DriftInfo => FYI
  }
}

// ============================================================================
// Colour Mappings
// ============================================================================

/// Tailwind background colour class for an alert based on urgency.
let alertColor = (urgency: driftUrgency): string => {
  switch urgency {
  | Immediate => "bg-red-600 text-white"
  | Soon => "bg-amber-500 text-white"
  | Scheduled => "bg-blue-500 text-white"
  | FYI => "bg-gray-600 text-gray-200"
  }
}

/// Tailwind text colour class for a drift severity.
let severityTextColor = (severity: driftSeverity): string => {
  switch severity {
  | DriftCritical => "text-red-400"
  | DriftWarning => "text-amber-400"
  | DriftInfo => "text-gray-400"
  }
}

/// Tailwind border colour class for a model drift indicator.
let driftBorderColor = (isDrifting: bool): string => {
  if isDrifting {
    "border-red-500"
  } else {
    "border-emerald-500"
  }
}

// ============================================================================
// Filtering
// ============================================================================

/// Filter alerts by urgency level. Returns all alerts if filter is None.
let filterByUrgency = (
  alerts: array<driftAlert>,
  filter: option<driftUrgency>,
): array<driftAlert> => {
  switch filter {
  | None => alerts
  | Some(urgency) => alerts->Array.filter(a => a.urgency == urgency)
  }
}

/// Filter alerts by model name.
let filterByModel = (
  alerts: array<driftAlert>,
  modelName: string,
): array<driftAlert> => {
  alerts->Array.filter(a => a.modelName == modelName)
}

// ============================================================================
// Display Labels
// ============================================================================

/// Human-readable label for a drift kind.
let driftKindLabel = (kind: driftKind): string => {
  switch kind {
  | ConceptDrift => "Concept Drift"
  | DataDrift => "Data Drift"
  | PriorDrift => "Prior Drift"
  | ArchitectureDrift => "Architecture Drift"
  | DistributionDrift => "Distribution Drift"
  | FeedbackDrift => "Feedback Drift"
  }
}

/// Human-readable label for a drift action.
let actionLabel = (action: driftAction): string => {
  switch action {
  | Retrain => "Retrain"
  | Calibrate => "Calibrate"
  | Fallback => "Fallback to Symbolic"
  | Halt => "Halt Inference"
  | Review => "Human Review"
  | Ignore => "Ignore"
  }
}

/// Human-readable label for urgency.
let urgencyLabel = (urgency: driftUrgency): string => {
  switch urgency {
  | Immediate => "IMMEDIATE"
  | Soon => "SOON"
  | Scheduled => "SCHEDULED"
  | FYI => "FYI"
  }
}

/// Human-readable label for severity.
let severityLabel = (severity: driftSeverity): string => {
  switch severity {
  | DriftCritical => "CRITICAL"
  | DriftWarning => "WARNING"
  | DriftInfo => "INFO"
  }
}

// ============================================================================
// Initial State
// ============================================================================

/// Default initial state for the NeSy Drift Dashboard.
let init: nesyDriftState = {
  alerts: [],
  modelStatuses: [],
  urgencyFilter: None,
  polling: true,
  pollIntervalMs: 10000,
}
