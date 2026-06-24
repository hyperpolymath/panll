// SPDX-License-Identifier: MPL-2.0

/// PanLL SpecBrowser Module — capability registration for the language spec browser.
///
/// Declares what the SpecBrowser panel can do. Follows the same pattern as
/// LanguageForgeModule and FarmModule.

/// Capabilities that the SpecBrowser panel exposes.
type specBrowserCapability =
  /// Overview grid of all 16 language specs with taxonomy completeness.
  | TaxonomyOverview
  /// Side-by-side comparison of grammar/spec/typing rules.
  | SpecComparison
  /// Grammar viewer with syntax highlighting.
  | GrammarViewer
  /// Typing rules viewer with notation.
  | TypingRulesViewer
  /// Verification status dashboard (tests, proofs, fuzzing).
  | VerificationStatus

/// Module configuration for the SpecBrowser panel.
type specBrowserModuleConfig = {
  /// Unique module identifier.
  id: string,
  /// Human-readable name.
  name: string,
  /// Semantic version.
  version: string,
  /// Short description for tooltips.
  description: string,
  /// Declared capabilities.
  capabilities: array<specBrowserCapability>,
  /// Panel bar icon name.
  icon: option<string>,
}

/// The canonical module configuration. SpecBrowser uses hardcoded spec data
/// from the nextgen-languages assessment — no HTTP service required.
let config: specBrowserModuleConfig = {
  id: "spec-browser",
  name: "Spec Browser",
  version: "0.1.0",
  description: "Browse all 16 language specs, grammars, typing rules — side-by-side comparison and taxonomy completeness",
  capabilities: [
    TaxonomyOverview,
    SpecComparison,
    GrammarViewer,
    TypingRulesViewer,
    VerificationStatus,
  ],
  icon: Some("book-open"),
}

/// Check if a capability is declared.
let hasCapability = (cap: specBrowserCapability): bool => {
  config.capabilities->Array.includes(cap)
}

/// Human-readable label for a capability.
let capabilityLabel = (cap: specBrowserCapability): string => {
  switch cap {
  | TaxonomyOverview => "Taxonomy Overview"
  | SpecComparison => "Spec Comparison"
  | GrammarViewer => "Grammar Viewer"
  | TypingRulesViewer => "Typing Rules Viewer"
  | VerificationStatus => "Verification Status"
  }
}
