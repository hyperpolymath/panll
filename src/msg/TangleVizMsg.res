// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for TangleViz topological programming visualizer.

open Model

type tangleVizMsg =
  /// Switch view mode (braid diagram / knot diagram / algebraic).
  | SetViewMode(tangleViewMode)
  /// Update Tangle source code input text.
  | SetInputText(string)
  /// Parse the current input text into a braid word.
  | ParseInput
  /// Clear all input and state.
  | ClearAll
  /// Load an example braid word (array of generators).
  | LoadExample(array<braidGenerator>)
  /// Select a knot invariant for computation.
  | SelectInvariant(knotInvariant)
  /// Compute the currently selected invariant.
  | ComputeInvariant
  /// Dismiss the error banner.
  | DismissError
