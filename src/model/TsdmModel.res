// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL TSDM Model — Triaxial Software Development Methodology directive panel.
///
/// TSDM is a three-axis methodology: Scope → Maintenance → Audit, followed by
/// cleanup/finish-off and maintainer dialogue. Each axis has an internal priority
/// ordering that users can customise. This panel stores and exposes those
/// preferences so other panels can query the active directive when presenting
/// and sequencing work items.
///
/// The methodology originates from:
///   Zotero: SOFTWARE-DEVELOPMENT-APPROACH.a2ml (item key: UJXF97XW)
///
/// Dependency: leaf module — no imports from other PanLL models.

// =========================================================================
// Axis 1: Scope
// =========================================================================

/// Scope priority tier. Default ordering: must > intend > like.
type scopeTier =
  | Must
  | Intend
  | Like

/// Scope input source — where work items are discovered.
type scopeInput =
  | Readme
  | Roadmap
  | StatusDocs
  | CiAndSecurityDocs
  | MarkerScan // TODO, FIXME, XXX, HACK, STUB, PARTIAL
  | IdrisUnsoundScan // believe_me, assert_total

// =========================================================================
// Axis 2: Maintenance
// =========================================================================

/// Maintenance priority tier. Default ordering: corrective > adaptive > perfective.
type maintenanceTier =
  | Corrective // defect/regression/safety/security fixes
  | Adaptive // scope reconciliation, stale-reference removal, obsolete-work culling
  | Perfective // quality improvements derived from Axis 1 honest state

// =========================================================================
// Axis 3: Audit
// =========================================================================

/// Audit priority tier. Default ordering: systems > compliance > effects.
type auditTier =
  | Systems // required systems present and operating
  | Compliance // exceptions explicit, bounded, drift-resistant
  | Effects // benchmark/operational impact evidence

/// Audit tooling assignments.
type auditTooling = {
  complianceTool: string, // default: "panic-attack"
  effectsTool: string, // default: "sustainabot"
}

// =========================================================================
// Cleanup/Finish-Off Phase
// =========================================================================

/// Cleanup steps. All enabled by default; users can reorder or disable.
type cleanupStep =
  | RootCleanup
  | StaleWorkCull
  | DocsSyncHumanMachine
  | ComplianceAudit
  | EffectsAudit
  | ReleaseSummary // must / should / could
  | NextActions // corrective / adaptive / perfective

// =========================================================================
// Collaboration
// =========================================================================

/// Dialogue topics for maintainer review.
type dialogueTopic =
  | WhatChanged
  | Why
  | RemainingRisks

// =========================================================================
// Axis Execution Order
// =========================================================================

/// Which axis to execute. Default order: Scope → Maintenance → Audit.
type axisId =
  | AxisScope
  | AxisMaintenance
  | AxisAudit

// =========================================================================
// A single work item as classified by TSDM
// =========================================================================

/// A work item with its TSDM classification. Panels generate these;
/// the TSDM panel sorts, filters, and presents them according to the
/// active directive.
type tsdmWorkItem = {
  id: string,
  title: string,
  description: string,
  /// Which axis this item belongs to.
  axis: axisId,
  /// Priority tier within the axis.
  scopeTier: option<scopeTier>,
  maintenanceTier: option<maintenanceTier>,
  auditTier: option<auditTier>,
  /// Source panel that generated this item.
  sourcePanel: string,
  /// Whether the item is completed.
  done: bool,
}

// =========================================================================
// Root state
// =========================================================================

/// Root state for the TSDM directive panel.
type tsdmState = {
  /// Axis execution order (user-customisable). Default: [Scope, Maintenance, Audit].
  axisOrder: array<axisId>,
  /// Scope tier ordering (user-customisable). Default: [Must, Intend, Like].
  scopeOrder: array<scopeTier>,
  /// Maintenance tier ordering (user-customisable). Default: [Corrective, Adaptive, Perfective].
  maintenanceOrder: array<maintenanceTier>,
  /// Audit tier ordering (user-customisable). Default: [Systems, Compliance, Effects].
  auditOrder: array<auditTier>,
  /// Scope input sources (user-customisable ordering).
  scopeInputs: array<scopeInput>,
  /// Cleanup steps (user-customisable ordering, each can be toggled).
  cleanupSteps: array<cleanupStep>,
  /// Which cleanup steps are enabled.
  cleanupEnabled: array<cleanupStep>,
  /// Dialogue topics for maintainer review.
  dialogueTopics: array<dialogueTopic>,
  /// Audit tooling configuration.
  auditTooling: auditTooling,
  /// Aggregated work items from all panels, classified by TSDM axes.
  workItems: array<tsdmWorkItem>,
  /// Whether the directive is "locked" (no reordering until session ends).
  locked: bool,
  /// Active axis being worked (for progress display).
  activeAxis: option<axisId>,
  /// Filter: show only items from a specific axis (None = show all).
  axisFilter: option<axisId>,
  /// Search text across work items.
  searchText: string,
  /// Whether to show completed items.
  showCompleted: bool,
  /// Last error.
  lastError: option<string>,
}

/// Default state — canonical TSDM ordering.
let init: tsdmState = {
  axisOrder: [AxisScope, AxisMaintenance, AxisAudit],
  scopeOrder: [Must, Intend, Like],
  maintenanceOrder: [Corrective, Adaptive, Perfective],
  auditOrder: [Systems, Compliance, Effects],
  scopeInputs: [Readme, Roadmap, StatusDocs, CiAndSecurityDocs, MarkerScan, IdrisUnsoundScan],
  cleanupSteps: [
    RootCleanup,
    StaleWorkCull,
    DocsSyncHumanMachine,
    ComplianceAudit,
    EffectsAudit,
    ReleaseSummary,
    NextActions,
  ],
  cleanupEnabled: [
    RootCleanup,
    StaleWorkCull,
    DocsSyncHumanMachine,
    ComplianceAudit,
    EffectsAudit,
    ReleaseSummary,
    NextActions,
  ],
  dialogueTopics: [WhatChanged, Why, RemainingRisks],
  auditTooling: {
    complianceTool: "panic-attack",
    effectsTool: "sustainabot",
  },
  workItems: [],
  locked: false,
  activeAxis: None,
  axisFilter: None,
  searchText: "",
  showCompleted: false,
  lastError: None,
}
