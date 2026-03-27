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
      if gen.index > acc {
        gen.index
      } else {
        acc
      }
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
    generators: [{index: 1, exponent: 1}, {index: 2, exponent: -1}, {index: 1, exponent: 1}],
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
    generators: [{index: 1, exponent: 1}, {index: 1, exponent: 1}],
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
// Invariant Computations
// ════════════════════════════════════════════════════════════════════════

/// Compute the writhe of a braid word — the sum of all crossing signs.
/// Positive crossing = +1, negative crossing = -1.
let computeWrithe = (generators: array<braidGenerator>): int => {
  generators->Array.reduce(0, (acc, gen) => acc + gen.exponent)
}

/// Compute the linking number by counting signed crossings between
/// distinct components. For a braid closure, we trace which strands
/// form which components, then count only inter-component crossings.
///
/// For a simple 2-strand braid, linking number = (sum of signs) / 2.
/// For n-strand braids, we trace the permutation closure to identify
/// components, then count signed crossings between distinct components.
let computeLinkingNumber = (generators: array<braidGenerator>, strandCount: int): int => {
  // First, compute the permutation induced by the braid
  let perm = Array.fromInitializer(~length=strandCount, i => i)
  generators->Array.forEach(gen => {
    let i = gen.index - 1
    if i >= 0 && i + 1 < strandCount {
      let tmp = perm->Array.getUnsafe(i)
      let _ = perm->Array.set(i, perm->Array.getUnsafe(i + 1))
      let _ = perm->Array.set(i + 1, tmp)
    }
  })

  // Find which component each strand belongs to by following the
  // permutation cycles (each cycle = one component in the closure)
  let component = Array.fromInitializer(~length=strandCount, _ => -1)
  let compIdx = ref(0)
  for s in 0 to strandCount - 1 {
    if component->Array.getUnsafe(s) === -1 {
      let current = ref(s)
      while component->Array.getUnsafe(current.contents) === -1 {
        let _ = component->Array.set(current.contents, compIdx.contents)
        current := perm->Array.getUnsafe(current.contents)
      }
      compIdx := compIdx.contents + 1
    }
  }

  // Count signed crossings between distinct components
  // Re-trace the strand positions through each crossing
  let positions = Array.fromInitializer(~length=strandCount, i => i)
  let linkingSum = ref(0)
  generators->Array.forEach(gen => {
    let i = gen.index - 1
    if i >= 0 && i + 1 < strandCount {
      let strandTop = positions->Array.getUnsafe(i)
      let strandBot = positions->Array.getUnsafe(i + 1)
      let compTop = component->Array.getUnsafe(strandTop)
      let compBot = component->Array.getUnsafe(strandBot)
      if compTop !== compBot {
        linkingSum := linkingSum.contents + gen.exponent
      }
      // Swap positions
      let tmp = positions->Array.getUnsafe(i)
      let _ = positions->Array.set(i, positions->Array.getUnsafe(i + 1))
      let _ = positions->Array.set(i + 1, tmp)
    }
  })

  // Linking number = half the signed inter-component crossing count
  linkingSum.contents / 2
}

/// Count the number of components in the braid closure.
/// Each cycle in the braid permutation corresponds to one component.
let countComponents = (generators: array<braidGenerator>, strandCount: int): int => {
  let perm = Array.fromInitializer(~length=strandCount, i => i)
  generators->Array.forEach(gen => {
    let i = gen.index - 1
    if i >= 0 && i + 1 < strandCount {
      let tmp = perm->Array.getUnsafe(i)
      let _ = perm->Array.set(i, perm->Array.getUnsafe(i + 1))
      let _ = perm->Array.set(i + 1, tmp)
    }
  })
  let visited = Array.fromInitializer(~length=strandCount, _ => false)
  let count = ref(0)
  for s in 0 to strandCount - 1 {
    if !(visited->Array.getUnsafe(s)) {
      count := count.contents + 1
      let current = ref(s)
      while !(visited->Array.getUnsafe(current.contents)) {
        let _ = visited->Array.set(current.contents, true)
        current := perm->Array.getUnsafe(current.contents)
      }
    }
  }
  count.contents
}

/// Compute a knot invariant result string.
///
/// Writhe and linking number are computed exactly from the braid word.
/// Jones, Alexander, HOMFLY-PT, and Kauffman bracket show the defining
/// skein relation with the braid's computed values substituted in,
/// giving a mathematical characterisation rather than a numeric result
/// (full polynomial computation requires state-sum expansion).
let computeInvariant = (inv: knotInvariant, generators: array<braidGenerator>): string => {
  let strandCount = strandCountFromWord(generators)
  let w = computeWrithe(generators)
  let n = Array.length(generators)
  let numComponents = countComponents(generators, strandCount)

  switch inv {
  | Writhe => {
      let sign = if w > 0 {
        "+"
      } else if w < 0 {
        "-"
      } else {
        ""
      }
      `w(K) = ${sign}${Int.toString(Math.Int.abs(w))} (sum of ${Int.toString(n)} crossing signs)`
    }
  | Linking => if numComponents < 2 {
      `lk = 0 (knot has 1 component; linking number is defined for links with >= 2 components)`
    } else {
      let lk = computeLinkingNumber(generators, strandCount)
      `lk(L) = ${Int.toString(lk)} (${Int.toString(
          numComponents,
        )}-component link, half the signed inter-component crossings)`
    }
  | Jones => {
      // V(t) satisfies: t^{-1} V(L+) - t V(L-) = (t^{1/2} - t^{-1/2}) V(L0)
      // For the unknot, V(t) = 1.
      // Writhe factor: V(K) includes (-t)^{-3w/4} normalisation.
      let wStr = Int.toString(w)
      let compStr = Int.toString(numComponents)
      if n === 0 {
        `V(t) = 1 (unknot/unlink with ${compStr} component(s))`
      } else {
        let normExp = -3 * w
        let normStr = if normExp >= 0 {
          `(-t)^{${Int.toString(normExp)}/4}`
        } else {
          `(-t)^{${Int.toString(normExp)}/4}`
        }
        `V(t) = ${normStr} * <K>(t) | w=${wStr}, n=${Int.toString(
            n,
          )}, components=${compStr} | Skein: t^{-1}V(L+) - tV(L-) = (t^{1/2} - t^{-1/2})V(L0)`
      }
    }
  | Alexander => // Delta(t) satisfies: Delta(L+) - Delta(L-) = (t^{1/2} - t^{-1/2}) Delta(L0)
    // For the unknot, Delta(t) = 1.
    if n === 0 {
      `\xce\x94(t) = 1 (unknot)`
    } else {
      let wStr = Int.toString(w)
      `\xce\x94(t) via Burau matrix: ${Int.toString(strandCount)}x${Int.toString(
          strandCount,
        )} reduced Burau rep, w=${wStr} | Skein: \xce\x94(L+) - \xce\x94(L-) = (t^{1/2} - t^{-1/2})\xce\x94(L0)`
    }
  | Homfly => // P(a,z) satisfies: a P(L+) - a^{-1} P(L-) = z P(L0)
    // For the unknot, P(a,z) = 1.
    if n === 0 {
      `P(a,z) = 1 (unknot)`
    } else {
      let posCount = generators->Array.filter(g => g.exponent > 0)->Array.length
      let negCount = n - posCount
      `P(a,z): ${Int.toString(n)} crossings (${Int.toString(posCount)}+, ${Int.toString(
          negCount,
        )}-), ${Int.toString(numComponents)} components | Skein: aP(L+) - a^{-1}P(L-) = zP(L0)`
    }
  | Kauffman => // <K> = A<K_0> + A^{-1}<K_inf> for each crossing, where A = t^{-1/4}
    // States: 2^n resolutions, each contributing A^{sigma} * (-A^2 - A^{-2})^{loops-1}
    if n === 0 {
      `<K> = 1 (unknot)`
    } else {
      let states = Math.Int.pow(2, ~exp=n)
      `<K> = sum over ${Int.toString(
          states,
        )} states of A^{sigma(s)}(-A^2 - A^{-2})^{|s|-1} | w=${Int.toString(
          w,
        )}, normalize: f(K) = (-A^3)^{-w}<K>`
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
