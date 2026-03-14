// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Language Forge Module — capability registration for the nextgen-languages panel.
///
/// Declares what the Language Forge panel can do. The UI renders controls only
/// for capabilities that are declared here. Follows the same pattern as
/// FarmModule and CloudGuardModule.

/// Capabilities that the Language Forge panel exposes.
type languageForgeCapability =
  /// Dashboard view of all 14 nextgen-languages with scores and phases.
  | LanguageDashboard
  /// Compilation pipeline status (lexer, parser, type checker, backends).
  | CompilationStatus
  /// MoSCoW prioritisation breakdown for selected language.
  | MoscowView
  /// WASM target readiness tracking across the portfolio.
  | WasmTargetTracker

/// Module configuration for the Language Forge panel.
type languageForgeModuleConfig = {
  /// Unique module identifier.
  id: string,
  /// Human-readable name.
  name: string,
  /// Semantic version.
  version: string,
  /// Short description for tooltips.
  description: string,
  /// Declared capabilities.
  capabilities: array<languageForgeCapability>,
  /// Panel bar icon name.
  icon: option<string>,
}

/// The canonical module configuration. Language Forge uses hardcoded data
/// from the nextgen-languages assessment — no HTTP service required.
let config: languageForgeModuleConfig = {
  id: "language-forge",
  name: "Language Forge",
  version: "0.1.0",
  description: "Monitor and develop the 14 nextgen-languages portfolio — scores, phases, WASM readiness",
  capabilities: [
    LanguageDashboard,
    CompilationStatus,
    MoscowView,
    WasmTargetTracker,
  ],
  icon: Some("hammer"),
}

/// Check if a capability is declared.
let hasCapability = (cap: languageForgeCapability): bool => {
  config.capabilities->Array.includes(cap)
}

/// Human-readable label for a capability.
let capabilityLabel = (cap: languageForgeCapability): string => {
  switch cap {
  | LanguageDashboard => "Language Dashboard"
  | CompilationStatus => "Compilation Status"
  | MoscowView => "MoSCoW View"
  | WasmTargetTracker => "WASM Target Tracker"
  }
}
