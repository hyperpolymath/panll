// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL TypeLL Engine — pure computation for the verification kernel.
///
/// Provides labels, glyphs, narrative generation, parsing, and display helpers.
/// The evangeliser view layer system is implemented here: progressive disclosure
/// of type information from RAW (expert) through WYSIWYG (exploration).
///
/// No side effects — all Tauri/server interaction is in TypeLLCmd.

open TypeLLModel

// ============================================================================
// View Layer Labels & Descriptions
// ============================================================================

/// Human-readable label for a view layer.
let viewLayerLabel = (vl: viewLayer): string =>
  switch vl {
  | Raw => "Raw"
  | Folded => "Folded"
  | Glyphed => "Glyphed"
  | Wysiwyg => "WYSIWYG"
  }

/// Description of what each view layer shows.
let viewLayerDescription = (vl: viewLayer): string =>
  switch vl {
  | Raw => "Full type signatures, unmodified. Expert mode."
  | Folded => "Categorised and collapsible. Working developer mode."
  | Glyphed => "Symbol-annotated types. Learning mode."
  | Wysiwyg => "Interactive type construction. Exploration mode."
  }

/// All view layers in order of increasing abstraction.
let allViewLayers: array<viewLayer> = [Raw, Folded, Glyphed, Wysiwyg]

/// Tailwind colour for view layer badge.
let viewLayerColour = (vl: viewLayer): string =>
  switch vl {
  | Raw => "text-gray-300 bg-gray-800/50"
  | Folded => "text-sky-400 bg-sky-900/30"
  | Glyphed => "text-violet-400 bg-violet-900/30"
  | Wysiwyg => "text-amber-400 bg-amber-900/30"
  }

// ============================================================================
// Type Feature Labels & Glyphs
// ============================================================================

/// Human-readable label for a type feature.
let featureLabel = (f: typeFeature): string =>
  switch f {
  | DependentTypes => "Dependent Types"
  | LinearTypes => "Linear Types"
  | SessionTypes => "Session Types"
  | ProofCarryingCode => "Proof-Carrying Code"
  | QuantitativeTypeTheory => "Quantitative Type Theory"
  | EffectSystems => "Effect Systems"
  | ModalTypes => "Modal Types"
  | AffineTypes => "Affine Types"
  | HomotopyTypeTheory => "Homotopy Type Theory"
  | EqualitySaturation => "Equality Saturation"
  | CategoryTheoreticTypes => "Category-Theoretic Types"
  }

/// Short code for a type feature (for badges and filters).
let featureCode = (f: typeFeature): string =>
  switch f {
  | DependentTypes => "dep"
  | LinearTypes => "lin"
  | SessionTypes => "sess"
  | ProofCarryingCode => "pcc"
  | QuantitativeTypeTheory => "qtt"
  | EffectSystems => "eff"
  | ModalTypes => "mod"
  | AffineTypes => "aff"
  | HomotopyTypeTheory => "hott"
  | EqualitySaturation => "eqsat"
  | CategoryTheoreticTypes => "cat"
  }

/// Tier for a type feature.
let featureTier = (f: typeFeature): typeTier =>
  switch f {
  | DependentTypes | LinearTypes | SessionTypes | ProofCarryingCode => TierCore
  | QuantitativeTypeTheory | EffectSystems | ModalTypes | AffineTypes => TierAdvanced
  | HomotopyTypeTheory | EqualitySaturation | CategoryTheoreticTypes => TierResearch
  }

/// All features grouped by tier.
let coreFeatures: array<typeFeature> = [DependentTypes, LinearTypes, SessionTypes, ProofCarryingCode]
let advancedFeatures: array<typeFeature> = [QuantitativeTypeTheory, EffectSystems, ModalTypes, AffineTypes]
let researchFeatures: array<typeFeature> = [HomotopyTypeTheory, EqualitySaturation, CategoryTheoreticTypes]
let allFeatures: array<typeFeature> = Array.concat(coreFeatures, Array.concat(advancedFeatures, researchFeatures))

/// Tier label.
let tierLabel = (t: typeTier): string =>
  switch t {
  | TierCore => "Core"
  | TierAdvanced => "Advanced"
  | TierResearch => "Research"
  }

/// Tier colour.
let tierColour = (t: typeTier): string =>
  switch t {
  | TierCore => "text-emerald-400 bg-emerald-900/30"
  | TierAdvanced => "text-blue-400 bg-blue-900/30"
  | TierResearch => "text-purple-400 bg-purple-900/30"
  }

// ============================================================================
// Evangeliser Glyphs — Makaton-inspired visual type symbols
// ============================================================================

/// Get the glyph for a type feature. Extended from rescript-evangeliser's
/// symbol system to cover the full type system spectrum.
let featureGlyph = (f: typeFeature): typeGlyph =>
  switch f {
  | DependentTypes => { symbol: "Pi", label: "Dependent", meaning: "Value-dependent types — types that compute from values" }
  | LinearTypes => { symbol: "1", label: "Linear", meaning: "Used exactly once — no duplication, no discard" }
  | SessionTypes => { symbol: "!", label: "Session", meaning: "Protocol safety — communication follows a contract" }
  | ProofCarryingCode => { symbol: "QED", label: "Proved", meaning: "Cryptographic proof certificate attached" }
  | QuantitativeTypeTheory => { symbol: "n", label: "Quantity", meaning: "Resource quantity tracked — 0, 1, or unlimited uses" }
  | EffectSystems => { symbol: "IO", label: "Effect", meaning: "Side effects declared — reads, writes, allocations" }
  | ModalTypes => { symbol: "BOX", label: "Modal", meaning: "Contextual access — valid only in certain modes" }
  | AffineTypes => { symbol: "?1", label: "Affine", meaning: "Used at most once — may be discarded but not duplicated" }
  | HomotopyTypeTheory => { symbol: "~", label: "HoTT", meaning: "Path equality — types related by continuous transformation" }
  | EqualitySaturation => { symbol: "=", label: "EqSat", meaning: "Equivalence classes — all equal forms explored simultaneously" }
  | CategoryTheoreticTypes => { symbol: "->", label: "Functor", meaning: "Structure-preserving maps between categories" }
  }

// ============================================================================
// Category Tab Labels
// ============================================================================

/// Category tab label.
let categoryLabel = (cat: typellCategory): string =>
  switch cat {
  | TlChecker => "Checker"
  | TlExplorer => "Explorer"
  | TlRefinement => "Refinement"
  | TlGuide => "Guide"
  }

/// All category tabs.
let allCategories: array<typellCategory> = [TlChecker, TlExplorer, TlRefinement, TlGuide]

// ============================================================================
// Evangeliser Narrative Generation
// ============================================================================

/// Generate an encouraging narrative for a type check result.
/// Follows the "Celebrate good, minimize bad, show better" philosophy
/// from rescript-evangeliser, applied to type systems.
let generateNarrative = (result: typeCheckResult): typeNarrative => {
  let celebrate = if result.valid {
    if result.activeFeatures->Array.length > 0 {
      let featureNames = result.activeFeatures->Array.map(featureLabel)->Array.join(", ")
      `Your code uses ${featureNames} — that's serious type-level engineering.`
    } else {
      "Your expression type-checks cleanly. Well-typed programs don't go wrong."
    }
  } else {
    "You're engaging with the type system — that's the first step to bulletproof code."
  }

  let minimize = if !result.valid {
    "The type checker found issues, but each one is a bug caught before runtime."
  } else if result.linearityIssues->Array.length > 0 {
    "There are linearity notes — resources might not be used optimally."
  } else if result.proofObligations->Array.length > 0 {
    `There are ${Int.toString(Array.length(result.proofObligations))} proof obligations — the type system is asking you to justify your claims.`
  } else {
    ""
  }

  let showBetter = if result.effects->Array.length > 0 {
    let effectCount = Int.toString(Array.length(result.effects))
    `${effectCount} effects tracked explicitly. In most languages, these would be invisible side effects.`
  } else if result.maxTier === TierCore {
    "Core type features give you safety guarantees that no runtime test can match."
  } else if result.maxTier === TierAdvanced {
    "Advanced type features let you encode invariants that would require complex runtime checks elsewhere."
  } else {
    "Type-level computation turns categories of bugs into compilation errors."
  }

  let safety = if result.valid && result.proofObligations->Array.length === 0 {
    "Fully verified — no proof obligations outstanding."
  } else if result.valid {
    `Verified with ${Int.toString(Array.length(result.proofObligations))} proof obligations. Discharge these for full assurance.`
  } else {
    "Fix the type errors to unlock safety guarantees."
  }

  { celebrate, minimize, showBetter, safety }
}

// ============================================================================
// Rendering Helpers — View Layer Transforms
// ============================================================================

/// Format a type signature according to the active view layer.
let formatSignature = (sig: string, viewLayer: viewLayer, features: array<typeFeature>): string =>
  switch viewLayer {
  | Raw => sig
  | Folded =>
    // Group by feature category
    let tier = if features->Array.some(f => featureTier(f) === TierResearch) {
      "[Research] "
    } else if features->Array.some(f => featureTier(f) === TierAdvanced) {
      "[Advanced] "
    } else {
      "[Core] "
    }
    tier ++ sig
  | Glyphed =>
    // Prepend glyphs for active features
    let glyphStr = features->Array.map(f => {
      let g = featureGlyph(f)
      g.symbol
    })->Array.join(" ")
    if glyphStr !== "" {
      glyphStr ++ " | " ++ sig
    } else {
      sig
    }
  | Wysiwyg => sig // Interactive mode renders differently in the component
  }

/// Filter signatures by tier.
let filterByTier = (sigs: array<typeSignatureEntry>, tier: option<typeTier>): array<typeSignatureEntry> =>
  switch tier {
  | None => sigs
  | Some(t) => sigs->Array.filter(s => s.tier === t)
  }

/// Filter signatures by search text.
let filterBySearch = (sigs: array<typeSignatureEntry>, query: string): array<typeSignatureEntry> =>
  if query === "" {
    sigs
  } else {
    let q = String.toLowerCase(query)
    sigs->Array.filter(s =>
      String.includes(String.toLowerCase(s.name), q) ||
      String.includes(String.toLowerCase(s.signature), q) ||
      String.includes(String.toLowerCase(s.module_), q)
    )
  }

// ============================================================================
// JSON Parsing
// ============================================================================

/// Parse a type check result from JSON.
let parseCheckResult = (json: string): result<typeCheckResult, string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let getString = (key: string): string =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => s
            | _ => ""
            }
          | None => ""
          }
        let getBool = (key: string): bool =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Bool(b) => b
            | _ => false
            }
          | None => false
          }
        let getStringArray = (key: string): array<string> =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Array(arr) =>
              arr->Array.filterMap(item =>
                switch JSON.Classify.classify(item) {
                | String(s) => Some(s)
                | _ => None
                }
              )
            | _ => []
            }
          | None => []
          }

        Ok({
          valid: getBool("valid"),
          typeSignature: getString("type_signature"),
          explanation: getString("explanation"),
          proofObligations: getStringArray("proof_obligations"),
          effects: getStringArray("effects"),
          linearityIssues: getStringArray("linearity_issues"),
          sessionNotes: getStringArray("session_notes"),
          activeFeatures: [], // Parsed from feature codes if present
          maxTier: TierCore,
        })
      }
    | _ => Error("Expected JSON object for type check result")
    }
  } catch {
  | _ => Error("Failed to parse type check JSON")
  }
}

/// Parse a refinement result from JSON.
let parseRefinementResult = (json: string): result<refinementResult, string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let getString = (key: string): string =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => s
            | _ => ""
            }
          | None => ""
          }
        let getBool = (key: string): bool =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Bool(b) => b
            | _ => false
            }
          | None => false
          }

        Ok({
          baseType: getString("base_type"),
          refinedType: getString("refined_type"),
          constraints: [],
          consistent: getBool("consistent"),
        })
      }
    | _ => Error("Expected JSON object for refinement result")
    }
  } catch {
  | _ => Error("Failed to parse refinement JSON")
  }
}

// ============================================================================
// Default State
// ============================================================================

/// Default initial state.
let defaultState: typellState = {
  serverConnected: false,
  loading: false,
  error: None,
  activeCategory: TlChecker,
  activeViewLayer: Folded,
  checkerInput: "",
  checkerContext: "",
  lastCheckResult: None,
  lastNarrative: None,
  signatures: [],
  universes: [],
  signatureFilter: "",
  tierFilter: None,
  refinementSpec: "",
  refinementConstraints: "",
  lastRefinement: None,
  serviceActive: true,
  queriesServed: 0,
  bojRouting: false,
  panelTypeChecks: Dict.make(),
}
