// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL TangleViz Engine — pure functions for braid/knot topology computation.
///
/// Provides Unicode-formatted generator labels, braid word stringification,
/// strand count detection, and a library of well-known example braids.
/// All functions are pure — no side effects, no backend calls.

open TangleVizModel

// ════════════════════════════════════════════════════════════════════════
// Unicode Subscript/Superscript Helpers
// ════════════════════════════════════════════════════════════════════════

/// Convert a digit (0-9) to its Unicode subscript character.
let subscriptDigit = (d: int): string => {
  switch d {
  | 0 => "\xe2\x82\x80" // ₀
  | 1 => "\xe2\x82\x81" // ₁
  | 2 => "\xe2\x82\x82" // ₂
  | 3 => "\xe2\x82\x83" // ₃
  | 4 => "\xe2\x82\x84" // ₄
  | 5 => "\xe2\x82\x85" // ₅
  | 6 => "\xe2\x82\x86" // ₆
  | 7 => "\xe2\x82\x87" // ₇
  | 8 => "\xe2\x82\x88" // ₈
  | 9 => "\xe2\x82\x89" // ₉
  | _ => Int.toString(d)
  }
}

/// Convert a positive integer to Unicode subscript string.
let toSubscript = (n: int): string => {
  if n < 10 {
    subscriptDigit(n)
  } else {
    let tens = n / 10
    let ones = mod(n, 10)
    subscriptDigit(tens) ++ subscriptDigit(ones)
  }
}

// ════════════════════════════════════════════════════════════════════════
// Generator and Braid Word Formatting
// ════════════════════════════════════════════════════════════════════════

/// Format a single generator as a Unicode string.
/// Positive: "σ₁", "σ₂", etc.
/// Negative: "σ₁⁻¹", "σ₂⁻¹", etc.
let generatorLabel = (gen: braidGenerator): string => {
  let base = "\xcf\x83" ++ toSubscript(gen.index) // σ + subscript
  if gen.exponent < 0 {
    base ++ "\xe2\x81\xbb\xc2\xb9" // ⁻¹
  } else {
    base
  }
}

/// Convert a braid word (array of generators) to a readable string.
/// Empty braid → "e" (identity element).
/// Otherwise joins generators with spaces: "σ₁ σ₂⁻¹ σ₁".
let braidWordToString = (generators: array<braidGenerator>): string => {
  if Array.length(generators) === 0 {
    "e"
  } else {
    generators
    ->Array.map(generatorLabel)
    ->Array.join(" ")
  }
}

/// Compute the strand count from a braid word.
/// The number of strands is max(generator index) + 1.
/// An empty braid word defaults to 2 strands.
let strandCountFromWord = (generators: array<braidGenerator>): int => {
  if Array.length(generators) === 0 {
    2
  } else {
    let maxIndex = generators->Array.reduce(0, (acc, gen) => {
      if gen.index > acc { gen.index } else { acc }
    })
    maxIndex + 1
  }
}

// ════════════════════════════════════════════════════════════════════════
// Example Braids
// ════════════════════════════════════════════════════════════════════════

/// A named example braid with its generators and description.
type exampleBraid = {
  /// Display name.
  name: string,
  /// The braid word.
  generators: array<braidGenerator>,
  /// Brief description of the knot/link.
  description: string,
}

/// Library of well-known braids for quick selection.
let exampleBraids = (): array<exampleBraid> => [
  {
    name: "Trefoil",
    generators: [
      {index: 1, exponent: 1},
      {index: 2, exponent: -1},
      {index: 1, exponent: 1},
    ],
    description: "Simplest non-trivial knot (3₁)",
  },
  {
    name: "Figure-Eight",
    generators: [
      {index: 1, exponent: 1},
      {index: 2, exponent: -1},
      {index: 1, exponent: 1},
      {index: 2, exponent: -1},
    ],
    description: "First alternating knot (4₁)",
  },
  {
    name: "Hopf Link",
    generators: [
      {index: 1, exponent: 1},
      {index: 1, exponent: 1},
    ],
    description: "Simplest non-trivial link (2²₁)",
  },
  {
    name: "Borromean Rings",
    generators: [
      {index: 1, exponent: 1},
      {index: 2, exponent: -1},
      {index: 1, exponent: 1},
      {index: 2, exponent: -1},
      {index: 1, exponent: 1},
      {index: 2, exponent: -1},
    ],
    description: "Three mutually linked rings (6³₂)",
  },
  {
    name: "Identity",
    generators: [],
    description: "Trivial braid (unknot closure)",
  },
]

// ════════════════════════════════════════════════════════════════════════
// View Mode and Invariant Labels
// ════════════════════════════════════════════════════════════════════════

/// Human-readable label for a view mode tab.
let viewModeLabel = (mode: tangleViewMode): string => {
  switch mode {
  | BraidDiagram => "Braid"
  | KnotDiagram => "Knot"
  | AlgebraicView => "Algebraic"
  }
}

/// All view modes for tab iteration.
let allViewModes: array<tangleViewMode> = [BraidDiagram, KnotDiagram, AlgebraicView]

/// Human-readable label for a knot invariant.
let invariantLabel = (inv: knotInvariant): string => {
  switch inv {
  | Jones => "Jones Polynomial"
  | Alexander => "Alexander Polynomial"
  | Homfly => "HOMFLY-PT Polynomial"
  | Kauffman => "Kauffman Bracket"
  | Writhe => "Writhe Number"
  | Linking => "Linking Number"
  }
}

/// All available invariants for selector iteration.
let allInvariants: array<knotInvariant> = [Jones, Alexander, Homfly, Kauffman, Writhe, Linking]

// ════════════════════════════════════════════════════════════════════════
// Writhe Computation (the one invariant we can compute purely)
// ════════════════════════════════════════════════════════════════════════

/// Compute the writhe of a braid word — the sum of all crossing signs.
/// Positive crossing = +1, negative crossing = -1.
let computeWrithe = (generators: array<braidGenerator>): int => {
  generators->Array.reduce(0, (acc, gen) => acc + gen.exponent)
}

/// Compute a simple invariant result string.
/// Only writhe is computed purely; others show placeholder formulae.
let computeInvariant = (inv: knotInvariant, generators: array<braidGenerator>): string => {
  switch inv {
  | Writhe => {
      let w = computeWrithe(generators)
      `w = ${Int.toString(w)}`
    }
  | Linking => {
      let w = computeWrithe(generators)
      `lk = ${Int.toString(w / 2)} (from writhe/2)`
    }
  | Jones => {
      let w = computeWrithe(generators)
      let n = Array.length(generators)
      `V(t) ~ (-1)^${Int.toString(n)} t^${Int.toString(w)} (simplified)`
    }
  | Alexander => {
      let n = Array.length(generators)
      `\xce\x94(t) ~ ${Int.toString(n)}-crossing (requires Seifert matrix)`
    }
  | Homfly => {
      let n = Array.length(generators)
      `P(a,z) ~ ${Int.toString(n)}-crossing (requires skein relations)`
    }
  | Kauffman => {
      let n = Array.length(generators)
      `<K> ~ ${Int.toString(n)}-crossing (requires state sum)`
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// SVG Rendering Constants
// ════════════════════════════════════════════════════════════════════════

/// Horizontal spacing between crossing columns in the SVG.
let crossingWidth = 80.0

/// Vertical spacing between strands in the SVG.
let strandSpacing = 40.0

/// Left margin for the SVG diagram.
let svgLeftMargin = 40.0

/// Top margin for the SVG diagram.
let svgTopMargin = 30.0

/// Strand colours for up to 8 strands.
let strandColours: array<string> = [
  "#818cf8", // indigo-400
  "#34d399", // emerald-400
  "#f472b6", // pink-400
  "#fbbf24", // amber-400
  "#60a5fa", // blue-400
  "#a78bfa", // violet-400
  "#fb923c", // orange-400
  "#2dd4bf", // teal-400
]

/// Get the colour for a strand by index (wraps around).
let strandColour = (strandIndex: int): string => {
  let idx = mod(strandIndex, Array.length(strandColours))
  strandColours->Array.getUnsafe(idx)
}

// ════════════════════════════════════════════════════════════════════════
// Default State
// ════════════════════════════════════════════════════════════════════════

/// Default initial state for the TangleViz panel.
let defaultState: tangleVizState = {
  braidWord: [],
  strandCount: 2,
  viewMode: BraidDiagram,
  selectedInvariant: None,
  invariantResult: None,
  inputText: "",
  parsedProgram: None,
  animating: false,
  error: None,
}
