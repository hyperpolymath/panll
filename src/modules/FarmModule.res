// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Farm Module — capability registration for the Git-Private-Farm panel.
///
/// Declares what the Farm panel can do. The UI renders controls only for
/// capabilities that are declared here. This follows the same pattern as
/// CloudGuardModule and DatabaseModule.

/// Capabilities that the Farm panel exposes.
type farmCapability =
  /// Read-only repo inventory from farm-manifest.json.
  | RepoInventory
  /// Three-tier enrollment status (farm/hypatia/fleet).
  | EnrollmentDashboard
  /// Health score aggregation across repos.
  | HealthDashboard
  /// Repo group and language breakdown.
  | GroupAnalysis
  /// Forge coverage matrix (which repos mirror where).
  | ForgeCoverage

/// Module configuration for the Farm panel.
type farmModuleConfig = {
  /// Unique module identifier.
  id: string,
  /// Human-readable name.
  name: string,
  /// Semantic version.
  version: string,
  /// Short description for tooltips.
  description: string,
  /// Data source path (not an HTTP endpoint — reads local JSON).
  manifestPath: string,
  /// Declared capabilities.
  capabilities: array<farmCapability>,
  /// Panel bar icon name.
  icon: option<string>,
}

/// The canonical module configuration. Farm reads a local JSON file,
/// not an HTTP service, so the "endpoint" is a filesystem path.
let config: farmModuleConfig = {
  id: "farm",
  name: "Git-Private-Farm",
  version: "0.1.0",
  description: "Repository admin registry and maintenance hub for ~265 repos across 6 forges",
  manifestPath: "~/.git-private-farm/farm-manifest.json",
  capabilities: [
    RepoInventory,
    EnrollmentDashboard,
    HealthDashboard,
    GroupAnalysis,
    ForgeCoverage,
  ],
  icon: Some("barn"),
}

/// Check if a capability is declared.
let hasCapability = (cap: farmCapability): bool => {
  config.capabilities->Array.includes(cap)
}

/// Human-readable label for a capability.
let capabilityLabel = (cap: farmCapability): string => {
  switch cap {
  | RepoInventory => "Repo Inventory"
  | EnrollmentDashboard => "Enrollment Dashboard"
  | HealthDashboard => "Health Dashboard"
  | GroupAnalysis => "Group Analysis"
  | ForgeCoverage => "Forge Coverage"
  }
}
