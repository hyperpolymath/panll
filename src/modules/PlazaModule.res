// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Palimpsest Plaza Module — capability registration for the
/// PMPL licensing adoption and governance panel.
///
/// The Plaza gives every PanLL user free access to PMPL compliance
/// tooling, making license adoption frictionless. This is the panel
/// that makes PanLL valuable to the wider FOSS community — not just
/// hyperpolymath projects.

/// Capabilities that the Plaza panel exposes.
type plazaCapability =
  /// Adoption dashboard with ecosystem statistics.
  | AdoptionDashboard
  /// SPDX header and LICENSE file compliance checking.
  | ComplianceAudit
  /// Quantum-safe provenance signature management.
  | ProvenanceVerification
  /// License compatibility matrix (PMPL vs MIT/Apache/GPL/etc.).
  | CompatibilityChecker
  /// Ethical use guidelines and AI training disclosure.
  | EthicalUseGuide
  /// Stewardship Council governance visibility.
  | GovernanceView
  /// Quick-start adoption wizard (generate LICENSE, headers, CI config).
  | AdoptionWizard

/// Module configuration for the Plaza panel.
type plazaModuleConfig = {
  /// Unique module identifier.
  id: string,
  /// Human-readable name.
  name: string,
  /// Semantic version.
  version: string,
  /// Description for tooltips.
  description: string,
  /// Declared capabilities.
  capabilities: array<plazaCapability>,
  /// Panel bar icon name.
  icon: option<string>,
}

/// The canonical module configuration. Plaza uses the local pmpl-sign,
/// pmpl-verify, and pmpl-audit CLI tools plus filesystem scanning.
let config: plazaModuleConfig = {
  id: "plaza",
  name: "Palimpsest Plaza",
  version: "0.1.0",
  description: "PMPL license adoption, compliance, and governance hub for the FOSS community",
  capabilities: [
    AdoptionDashboard,
    ComplianceAudit,
    ProvenanceVerification,
    CompatibilityChecker,
    EthicalUseGuide,
    GovernanceView,
    AdoptionWizard,
  ],
  icon: Some("scroll"),
}

/// Check if a capability is declared.
let hasCapability = (cap: plazaCapability): bool => {
  config.capabilities->Array.includes(cap)
}

/// Human-readable label for a capability.
let capabilityLabel = (cap: plazaCapability): string => {
  switch cap {
  | AdoptionDashboard => "Adoption Dashboard"
  | ComplianceAudit => "Compliance Audit"
  | ProvenanceVerification => "Provenance Verification"
  | CompatibilityChecker => "Compatibility Checker"
  | EthicalUseGuide => "Ethical Use Guide"
  | GovernanceView => "Governance"
  | AdoptionWizard => "Adopt PMPL"
  }
}
