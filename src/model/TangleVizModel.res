// SPDX-License-Identifier: MPL-2.0

/// PanLL TangleViz Model — leaf types for the topological programming visualizer.
///
/// State for visualizing knot/braid topology from the Tangle programming language.
/// Supports braid word manipulation, knot invariant computation, and SVG rendering
/// of braid diagrams with over/under crossings.
///
/// Dependency: none (leaf module in the type DAG).

/// A single generator in a braid word — σᵢ or σᵢ⁻¹.
/// Positive exponent = over-crossing, negative = under-crossing.
type braidGenerator = {
  /// Generator index (1-based: σ₁, σ₂, etc.).
  index: int,
  /// Exponent (+1 for positive crossing, -1 for inverse).
  exponent: int,
}

/// View mode for the topology visualizer.
type tangleViewMode =
  /// Horizontal braid diagram with strand crossings.
  | BraidDiagram
  /// Closed knot/link diagram (braid closure).
  | KnotDiagram
  /// Algebraic braid word notation.
  | AlgebraicView

/// Knot/link invariant that can be computed.
type knotInvariant =
  /// Jones polynomial V(t).
  | Jones
  /// Alexander polynomial Delta(t).
  | Alexander
  /// HOMFLY-PT polynomial P(a,z).
  | Homfly
  /// Kauffman bracket polynomial.
  | Kauffman
  /// Writhe number (sum of crossing signs).
  | Writhe
  /// Linking number (for multi-component links).
  | Linking

/// Parsed status for Tangle source code.
type parsedStatus =
  /// Successfully parsed with the braid word extracted.
  | ParsedOk
  /// Parse failed with an error message.
  | ParseFailed(string)

/// Root state for the TangleViz panel module.
type tangleVizState = {
  /// The braid word as an array of generators.
  braidWord: array<braidGenerator>,
  /// Number of strands (auto-detected from max generator index + 1).
  strandCount: int,
  /// Current visualization mode.
  viewMode: tangleViewMode,
  /// Currently selected invariant for computation.
  selectedInvariant: option<knotInvariant>,
  /// Result of the last invariant computation.
  invariantResult: option<string>,
  /// Raw Tangle source code input.
  inputText: string,
  /// Whether the input text has been parsed.
  parsedProgram: option<parsedStatus>,
  /// Whether the braid diagram is animating.
  animating: bool,
  /// Last error message, if any.
  error: option<string>,
}
