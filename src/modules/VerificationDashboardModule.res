// SPDX-License-Identifier: MPL-2.0

/// PanLL VerificationDashboard Module — capability registration for the verification panel.
///
/// Declares what the VerificationDashboard panel can do. Follows the same
/// pattern as LanguageForgeModule and SpecBrowserModule.

/// Capabilities that the VerificationDashboard panel exposes.
type verificationDashboardCapability =
  /// Summary view with aggregated counts.
  | VerificationSummary
  /// Per-language test/proof breakdown.
  | LanguageBreakdown
  /// Proof status tracking (admitted/sorry debt).
  | ProofTracking
  /// Benchmark results viewer.
  | BenchmarkResults
  /// Fuzzing coverage report.
  | FuzzingReport

/// Module configuration for the VerificationDashboard panel.
type verificationDashboardModuleConfig = {
  /// Unique module identifier.
  id: string,
  /// Human-readable name.
  name: string,
  /// Semantic version.
  version: string,
  /// Short description for tooltips.
  description: string,
  /// Declared capabilities.
  capabilities: array<verificationDashboardCapability>,
  /// Panel bar icon name.
  icon: option<string>,
}

/// The canonical module configuration.
let config: verificationDashboardModuleConfig = {
  id: "verification-dashboard",
  name: "Verification Dashboard",
  version: "0.1.0",
  description: "Proof, test, benchmark, and fuzzing status across all nextgen-languages repos",
  capabilities: [
    VerificationSummary,
    LanguageBreakdown,
    ProofTracking,
    BenchmarkResults,
    FuzzingReport,
  ],
  icon: Some("check-circle"),
}

/// Check if a capability is declared.
let hasCapability = (cap: verificationDashboardCapability): bool => {
  config.capabilities->Array.includes(cap)
}

/// Human-readable label for a capability.
let capabilityLabel = (cap: verificationDashboardCapability): string => {
  switch cap {
  | VerificationSummary => "Verification Summary"
  | LanguageBreakdown => "Language Breakdown"
  | ProofTracking => "Proof Tracking"
  | BenchmarkResults => "Benchmark Results"
  | FuzzingReport => "Fuzzing Report"
  }
}
