// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL panic-attack module — capability declarations for the stress testing
/// and weak point analysis panel.
///
/// panic-attack is a universal stress testing and logic-based bug signature
/// detection tool. It analyses code across 47 languages, detecting 20
/// categories of weak points. This module exposes scan, report, and
/// comparison capabilities.

type panicAttackCapability =
  | StaticAnalysis
  | StressTesting
  | BugSignatureDetection
  | ReportGeneration
  | ReportComparison
  | BatchScanning
  | SarifExport
  | EventChainExport

type panicAttackModuleConfig = {
  id: string,
  name: string,
  version: string,
  description: string,
  binaryName: string,
  capabilities: array<panicAttackCapability>,
  icon: option<string>,
}

let config: panicAttackModuleConfig = {
  id: "panic-attack",
  name: "panic-attack",
  version: "2.0.0",
  description: "Universal stress testing and logic-based bug signature detection",
  binaryName: "panic-attack",
  icon: Some("zap"),
  capabilities: [
    StaticAnalysis,
    StressTesting,
    BugSignatureDetection,
    ReportGeneration,
    ReportComparison,
    BatchScanning,
    SarifExport,
    EventChainExport,
  ],
}

let hasCapability = (cap: panicAttackCapability): bool =>
  config.capabilities->Array.includes(cap)

let capabilityLabel = (cap: panicAttackCapability): string =>
  switch cap {
  | StaticAnalysis => "Static Analysis (assail)"
  | StressTesting => "Stress Testing (attack/assault)"
  | BugSignatureDetection => "Bug Signature Detection (kanren)"
  | ReportGeneration => "Report Generation (JSON/YAML/SARIF)"
  | ReportComparison => "Report Comparison (diff)"
  | BatchScanning => "Batch Scanning (assemblyline)"
  | SarifExport => "SARIF Export (GitHub Security)"
  | EventChainExport => "Event Chain Export (PanLL)"
  }
