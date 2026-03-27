// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL TangleViz Module — capability registration for the Tangle topology panel.
///
/// Declares what the TangleViz panel can do. The UI renders controls only for
/// capabilities that are declared here. This follows the same pattern as
/// FarmModule and CloudGuardModule.

/// Capabilities that the TangleViz panel exposes.
type tangleVizCapability =
  /// Interactive SVG braid diagram with over/under crossings.
  | BraidVisualization
  /// Compute knot/link invariants (Jones, Alexander, HOMFLY, etc.).
  | InvariantComputation
  /// Parse Tangle source code into braid words.
  | SourceParsing

/// Module configuration for the TangleViz panel.
type tangleVizModuleConfig = {
  /// Unique module identifier.
  id: string,
  /// Human-readable name.
  name: string,
  /// Semantic version.
  version: string,
  /// Short description for tooltips.
  description: string,
  /// Declared capabilities.
  capabilities: array<tangleVizCapability>,
  /// Panel bar icon name.
  icon: option<string>,
}

/// The canonical module configuration. TangleViz is a pure client-side
/// visualizer — no backend service required.
let config: tangleVizModuleConfig = {
  id: "tangle-viz",
  name: "Tangle Viz",
  version: "0.1.0",
  description: "Topological programming visualizer — braid diagrams, knot invariants, Tangle source parsing",
  capabilities: [BraidVisualization, InvariantComputation, SourceParsing],
  icon: Some("knot"),
}

/// Check if a capability is declared.
let hasCapability = (cap: tangleVizCapability): bool => {
  config.capabilities->Array.includes(cap)
}

/// Human-readable label for a capability.
let capabilityLabel = (cap: tangleVizCapability): string => {
  switch cap {
  | BraidVisualization => "Braid Visualization"
  | InvariantComputation => "Invariant Computation"
  | SourceParsing => "Source Parsing"
  }
}
