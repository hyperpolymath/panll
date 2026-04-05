// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL TSDM module — capability declarations for the Triaxial Software
/// Development Methodology directive panel.
///
/// TSDM is a directive panel: it controls how other panels present and
/// sequence work items. Users customise axis ordering, tier priorities,
/// and cleanup steps. All consumer panels read the active directive.

type tsdmCapability =
  | AxisReordering
  | TierCustomisation
  | CleanupConfiguration
  | WorkItemAggregation
  | DirectivePersistence
  | DirectiveLocking
  | ConsumerBroadcast

type tsdmModuleConfig = {
  id: string,
  name: string,
  version: string,
  description: string,
  capabilities: array<tsdmCapability>,
  icon: option<string>,
}

let config: tsdmModuleConfig = {
  id: "tsdm",
  name: "TSDM",
  version: "1.0.0",
  description: "Triaxial Software Development Methodology — directive panel for priority ordering across all panels",
  icon: Some("compass"),
  capabilities: [
    AxisReordering,
    TierCustomisation,
    CleanupConfiguration,
    WorkItemAggregation,
    DirectivePersistence,
    DirectiveLocking,
    ConsumerBroadcast,
  ],
}

let hasCapability = (cap: tsdmCapability): bool => config.capabilities->Array.includes(cap)

let capabilityLabel = (cap: tsdmCapability): string =>
  switch cap {
  | AxisReordering => "Axis Reordering (Scope, Maintenance, Audit)"
  | TierCustomisation => "Tier Customisation (priority within each axis)"
  | CleanupConfiguration => "Cleanup/Finish-Off Configuration"
  | WorkItemAggregation => "Work Item Aggregation (from consumer panels)"
  | DirectivePersistence => "Directive Persistence (localStorage + verisim)"
  | DirectiveLocking => "Directive Locking (prevent mid-session changes)"
  | ConsumerBroadcast => "Consumer Broadcast (notify panels of ordering changes)"
  }
