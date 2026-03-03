// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Mass Panic module — capability declarations for the organisation-scale
/// batch scanning panel.
///
/// Mass-panic is a deployment mode of panic-attack: assemblyline batch scanning
/// with rayon parallelism, incremental BLAKE3 fingerprinting, verisimdb hexad
/// persistence, delta reporting, and notification pipeline. This panel provides
/// a GUI for operations that would otherwise require complex CLI orchestration.

type massPanicCapability =
  | AssemblylineScanning
  | IncrementalBlake3
  | VerisimDBPersistence
  | DeltaReporting
  | NotificationPipeline
  | RepoDiscovery
  | CacheManagement

type massPanicModuleConfig = {
  id: string,
  name: string,
  version: string,
  description: string,
  binaryName: string,
  capabilities: array<massPanicCapability>,
  icon: option<string>,
}

let config: massPanicModuleConfig = {
  id: "mass-panic",
  name: "Mass Panic",
  version: "2.1.0",
  description: "Organisation-scale batch scanning — assemblyline + BLAKE3 + verisimdb + delta",
  binaryName: "panic-attack",
  icon: Some("zap-off"), // differentiate from single-repo "zap"
  capabilities: [
    AssemblylineScanning,
    IncrementalBlake3,
    VerisimDBPersistence,
    DeltaReporting,
    NotificationPipeline,
    RepoDiscovery,
    CacheManagement,
  ],
}

let hasCapability = (cap: massPanicCapability): bool =>
  config.capabilities->Array.includes(cap)

let capabilityLabel = (cap: massPanicCapability): string =>
  switch cap {
  | AssemblylineScanning => "Assemblyline Scanning (rayon parallelism)"
  | IncrementalBlake3 => "Incremental BLAKE3 Fingerprinting"
  | VerisimDBPersistence => "VerisimDB Hexad Persistence"
  | DeltaReporting => "Delta Reporting (diff between runs)"
  | NotificationPipeline => "Notification Pipeline (markdown + GitHub)"
  | RepoDiscovery => "Repository Discovery (.git detection)"
  | CacheManagement => "Fingerprint Cache Management"
  }
