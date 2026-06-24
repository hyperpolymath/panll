// SPDX-License-Identifier: MPL-2.0

/// PanLL Palimpsest Plaza Model — leaf types for the PMPL licensing panel.
///
/// The Plaza is the adoption, compliance, and governance hub for the
/// Palimpsest-MPL license ecosystem. It helps projects adopt PMPL,
/// validates compliance (SPDX headers, exhibits, provenance signatures),
/// and provides governance visibility (Stewardship Council, ethical use).
///
/// Three-panel mapping:
///   Panel-L: License rules, SPDX requirements, exhibit obligations
///   Panel-N: Compliance reasoning, ethical use interpretation
///   Panel-W: Adoption dashboard, audit results, signature verification
///
/// Dependency: none (leaf module in the type DAG).

/// PMPL compliance level for a single repository.
type complianceLevel =
  /// All checks pass: SPDX headers, LICENSE file, exhibits, provenance.
  | FullCompliance
  /// Core requirements met (SPDX + LICENSE) but optional elements missing.
  | PartialCompliance
  /// Critical requirements missing (no LICENSE or wrong SPDX identifier).
  | NonCompliant
  /// Not yet scanned.
  | Unknown

/// A single compliance check result.
type complianceCheck = {
  /// Check identifier (e.g. "spdx-headers", "license-file", "exhibit-a").
  id: string,
  /// Human-readable check name.
  name: string,
  /// Description of what this check validates.
  description: string,
  /// Whether this check passed.
  passed: bool,
  /// Severity if failed: "critical", "warning", "info".
  severity: string,
  /// Details about what was found or missing.
  detail: string,
}

/// Compliance audit result for a repository.
type complianceAudit = {
  /// Repository name.
  repoName: string,
  /// Overall compliance level.
  level: complianceLevel,
  /// Individual check results.
  checks: array<complianceCheck>,
  /// Number of files scanned.
  filesScanned: int,
  /// Number of files with correct SPDX headers.
  filesWithHeaders: int,
  /// Timestamp of last audit.
  lastAudit: string,
}

/// Quantum-safe provenance signature status.
type signatureStatus =
  /// Valid signature verified successfully.
  | SignatureValid
  /// Signature present but verification failed.
  | SignatureInvalid(string)
  /// No signature found.
  | NoSignature
  /// Signature uses classical (non-quantum-safe) algorithm.
  | ClassicalOnly

/// A provenance signature record.
type provenanceRecord = {
  /// File or commit that was signed.
  target: string,
  /// Signer identity.
  signer: string,
  /// Algorithm used (ML-DSA-65, SLH-DSA-128s, etc.).
  algorithm: string,
  /// Timestamp of signature.
  timestamp: string,
  /// Verification status.
  status: signatureStatus,
}

/// License compatibility result — can PMPL coexist with another license?
type compatibilityResult = {
  /// The other license identifier (e.g. "MIT", "Apache-2.0", "GPL-3.0").
  license: string,
  /// Whether combination is compatible.
  compatible: bool,
  /// Notes about conditions or caveats.
  notes: string,
}

/// Exhibit status for a repository.
type exhibitStatus = {
  /// Exhibit A (Ethical Use Guidelines) present.
  exhibitA: bool,
  /// Exhibit B (Quantum-Safe Provenance) present.
  exhibitB: bool,
  /// Custom exhibits present.
  customExhibits: array<string>,
}

/// Adoption statistics for the ecosystem.
type adoptionStats = {
  /// Total repos in the ecosystem.
  totalRepos: int,
  /// Repos using PMPL-1.0-or-later.
  pmplRepos: int,
  /// Repos using MPL-2.0 fallback.
  mplFallbackRepos: int,
  /// Repos with no SPDX header.
  unlicensedRepos: int,
  /// Repos with quantum-safe signatures.
  quantumSignedRepos: int,
  /// Breakdown by license.
  byLicense: array<(string, int)>,
}

/// Category tabs for the Plaza panel.
type plazaCategory =
  /// Overview dashboard with adoption stats and quick actions.
  | Dashboard
  /// Compliance audit results across repos.
  | Compliance
  /// Quantum-safe provenance signature management.
  | Provenance
  /// License compatibility checker.
  | Compatibility
  /// Ethical use guidelines and AI training disclosure.
  | EthicalUse
  /// Governance: Stewardship Council, decisions, amendments.
  | Governance
  /// Quick-start adoption wizard for new projects.
  | Adopt

/// Root state for the Palimpsest Plaza panel.
type plazaState = {
  /// Whether data has been loaded.
  loaded: bool,
  /// Loading indicator.
  loading: bool,
  /// Last error.
  error: option<string>,
  /// Adoption statistics.
  stats: option<adoptionStats>,
  /// Compliance audit results for scanned repos.
  audits: array<complianceAudit>,
  /// Provenance signatures found.
  signatures: array<provenanceRecord>,
  /// Compatibility check results.
  compatibilityResults: array<compatibilityResult>,
  /// Active category tab.
  activeCategory: plazaCategory,
  /// Text filter for search.
  filterText: string,
  /// Selected repo for detailed view.
  selectedRepo: option<string>,
}
