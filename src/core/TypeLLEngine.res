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
  | TlDiscipline => "Discipline"
  | TlGuide => "Guide"
  }

/// All category tabs.
let allCategories: array<typellCategory> = [TlChecker, TlExplorer, TlRefinement, TlDiscipline, TlGuide]

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
// Unified Type System — Discipline, Quantifiers, Feature Extraction
// ============================================================================

/// Label for a usage quantifier.
let usageLabel = (u: usageQuantifier): string =>
  switch u {
  | UsageZero => "0 (erased)"
  | UsageOne => "1 (linear)"
  | UsageOmega => "omega (unrestricted)"
  }

/// Short symbol for a usage quantifier.
let usageSymbol = (u: usageQuantifier): string =>
  switch u {
  | UsageZero => "0"
  | UsageOne => "1"
  | UsageOmega => "w"
  }

/// Label for a type discipline.
let disciplineLabel = (d: typeDiscipline): string =>
  switch d {
  | DisciplineAffine => "Affine (default)"
  | DisciplineLinear => "Linear"
  | DisciplineDependent => "Dependent"
  | DisciplineRefined => "Refined"
  | DisciplineUnrestricted => "Unrestricted"
  }

/// Short directive for a discipline (as it would appear in a source file).
let disciplineDirective = (d: typeDiscipline): string =>
  switch d {
  | DisciplineAffine => "#![affine]"
  | DisciplineLinear => "#![linear]"
  | DisciplineDependent => "#![dependent]"
  | DisciplineRefined => "#![refined]"
  | DisciplineUnrestricted => "#![unrestricted]"
  }

/// Colour for a discipline badge.
let disciplineColour = (d: typeDiscipline): string =>
  switch d {
  | DisciplineAffine => "text-amber-400 bg-amber-900/30"
  | DisciplineLinear => "text-red-400 bg-red-900/30"
  | DisciplineDependent => "text-purple-400 bg-purple-900/30"
  | DisciplineRefined => "text-cyan-400 bg-cyan-900/30"
  | DisciplineUnrestricted => "text-gray-400 bg-gray-800/50"
  }

/// Label for an inference source.
let inferenceSourceLabel = (s: inferenceSource): string =>
  switch s {
  | Inferred => "Inferred"
  | Annotated => "Annotated"
  | Mixed => "Mixed"
  | TacticAssisted => "Tactic-assisted"
  }

/// Which features are implied by a discipline.
let disciplineImpliedFeatures = (d: typeDiscipline): array<typeFeature> =>
  switch d {
  | DisciplineAffine => [AffineTypes]
  | DisciplineLinear => [LinearTypes, QuantitativeTypeTheory]
  | DisciplineDependent => [DependentTypes, ProofCarryingCode]
  | DisciplineRefined => [DependentTypes]
  | DisciplineUnrestricted => []
  }

/// All disciplines in order.
let allDisciplines: array<typeDiscipline> = [
  DisciplineAffine, DisciplineLinear, DisciplineDependent, DisciplineRefined, DisciplineUnrestricted,
]

/// Parse a feature code string (e.g., "dep", "lin", "aff") to a typeFeature.
let parseFeatureCode = (code: string): option<typeFeature> =>
  switch code {
  | "dep" | "dependent" => Some(DependentTypes)
  | "lin" | "linear" => Some(LinearTypes)
  | "sess" | "session" => Some(SessionTypes)
  | "pcc" | "proof-carrying" => Some(ProofCarryingCode)
  | "qtt" | "quantitative" => Some(QuantitativeTypeTheory)
  | "eff" | "effect" => Some(EffectSystems)
  | "mod" | "modal" => Some(ModalTypes)
  | "aff" | "affine" => Some(AffineTypes)
  | "hott" => Some(HomotopyTypeTheory)
  | "eqsat" => Some(EqualitySaturation)
  | "cat" | "category" => Some(CategoryTheoreticTypes)
  | _ => None
  }

/// Determine the max tier from a set of active features.
let computeMaxTier = (features: array<typeFeature>): typeTier => {
  let hasResearch = features->Array.some(f => featureTier(f) === TierResearch)
  let hasAdvanced = features->Array.some(f => featureTier(f) === TierAdvanced)
  if hasResearch { TierResearch }
  else if hasAdvanced { TierAdvanced }
  else { TierCore }
}

/// Parse a usage string to a quantifier.
let parseUsage = (s: string): usageQuantifier =>
  switch s {
  | "0" | "zero" | "erased" => UsageZero
  | "1" | "one" | "linear" => UsageOne
  | _ => UsageOmega
  }

/// Parse a discipline string.
let parseDiscipline = (s: string): typeDiscipline =>
  switch s {
  | "affine" => DisciplineAffine
  | "linear" => DisciplineLinear
  | "dependent" => DisciplineDependent
  | "refined" => DisciplineRefined
  | "unrestricted" => DisciplineUnrestricted
  | _ => DisciplineAffine // Affine by default
  }

/// Parse an inference source string.
let parseInferenceSource = (s: string): inferenceSource =>
  switch s {
  | "annotated" => Annotated
  | "mixed" => Mixed
  | "tactic" | "tactic-assisted" => TacticAssisted
  | _ => Inferred
  }

/// Build a default unified type expression.
let defaultUnifiedTypeExpr: unifiedTypeExpr = {
  baseExpr: "",
  usage: UsageOmega,
  discipline: DisciplineAffine,
  dependentIndices: [],
  effects: [],
  refinements: [],
}

/// Summarise a unified type analysis result as a single line.
let unifiedAnalysisSummary = (analysis: unifiedTypeAnalysis): string => {
  let parts = []
  let parts = if analysis.linearitySatisfied { parts } else { Array.concat(parts, ["linearity violated"]) }
  let parts = if analysis.indicesWellFounded { parts } else { Array.concat(parts, ["indices not well-founded"]) }
  let parts = if analysis.refinementsSatisfiable { parts } else { Array.concat(parts, ["refinements unsatisfiable"]) }
  let parts = if Array.length(analysis.usageViolations) > 0 {
    Array.concat(parts, [Int.toString(Array.length(analysis.usageViolations)) ++ " usage violations"])
  } else { parts }
  let parts = if Array.length(analysis.effectLeaks) > 0 {
    Array.concat(parts, [Int.toString(Array.length(analysis.effectLeaks)) ++ " effect leaks"])
  } else { parts }
  if Array.length(parts) === 0 {
    disciplineLabel(analysis.typeExpr.discipline) ++ " | " ++ usageSymbol(analysis.typeExpr.usage) ++ " | OK"
  } else {
    disciplineLabel(analysis.typeExpr.discipline) ++ " | " ++ Array.join(parts, ", ")
  }
}

// ============================================================================
// JSON Parsing — Tea_Json decoders
// ============================================================================

/// Tea_Json decoder for a type check result.
/// Extracts feature codes, computes tier, parses usage/discipline/inference.
let checkResultDecoder: Tea_Json.decoder<typeCheckResult> = {
  open Decoders
  map11(
    (valid, typeSignature, explanation, proofObligations, effects,
     linearityIssues, sessionNotes, featureCodes, usageStr,
     disciplineStr, inferSrcStr) => {
      let activeFeatures = featureCodes->Array.filterMap(parseFeatureCode)
      let maxTier = computeMaxTier(activeFeatures)
      ({
        valid,
        typeSignature,
        explanation,
        proofObligations,
        effects,
        linearityIssues,
        sessionNotes,
        activeFeatures,
        maxTier,
        usage: parseUsage(usageStr),
        discipline: parseDiscipline(disciplineStr),
        inferenceSource: parseInferenceSource(inferSrcStr),
        unifiedAnalysis: None, // Parsed separately if the server provides it
      }: typeCheckResult)
    },
    boolField("valid"),
    stringField("type_signature"),
    stringField("explanation"),
    stringArrayField("proof_obligations"),
    stringArrayField("effects"),
    stringArrayField("linearity_issues"),
    stringArrayField("session_notes"),
    stringArrayField("features"),
    stringField("usage"),
    stringField("discipline"),
    stringField("inference_source"),
  )
}

/// Parse a type check result from JSON.
let parseCheckResult = (json: string): result<typeCheckResult, string> =>
  Decoders.decode(checkResultDecoder, json)

/// Tea_Json decoder for a refinement result.
let refinementResultDecoder: Tea_Json.decoder<refinementResult> = {
  open Decoders
  open Tea_Json
  map4(
    (baseType, refinedType, _constraints, consistent) => ({
      baseType,
      refinedType,
      constraints: [],
      consistent,
    }: refinementResult),
    stringField("base_type"),
    stringField("refined_type"),
    fieldWithDefault("constraints", lenientArray(string), []),
    boolField("consistent"),
  )
}

/// Parse a refinement result from JSON.
let parseRefinementResult = (json: string): result<refinementResult, string> =>
  Decoders.decode(refinementResultDecoder, json)

// ============================================================================
// Kernel Integration — localhost:7800 routing helpers
// ============================================================================

/// Result of a kernel type check routed to localhost:7800.
type kernelTypeCheckResult = {
  /// Whether the expression is well-typed.
  valid: bool,
  /// The inferred or checked type signature.
  typeSignature: string,
  /// Active type features detected.
  activeFeatures: array<typeFeature>,
  /// Proof obligations generated.
  proofObligations: array<string>,
  /// Effects detected.
  effects: array<string>,
  /// Linearity issues detected.
  linearityIssues: array<string>,
  /// Which language the source was checked against.
  language: string,
}

/// Result of usage quantifier inference.
type usageInferenceResult = {
  /// Inferred quantifier (0, 1, omega).
  quantifier: usageQuantifier,
  /// Explanation of the inference.
  explanation: string,
  /// Variables and their inferred usages.
  bindings: array<(string, usageQuantifier)>,
}

/// Result of effect inference.
type effectInferenceResult = {
  /// List of effects detected (e.g., "IO", "State s", "Alloc").
  effects: array<string>,
  /// Whether the expression is pure (no effects).
  pure: bool,
  /// Effect row type if applicable.
  effectRow: option<string>,
}

/// Result of dimensional type checking (for Eclexia).
type dimensionalResult = {
  /// Whether dimensional consistency holds.
  consistent: bool,
  /// Inferred dimensional type (e.g., "Length / Time^2").
  dimensionalType: string,
  /// Dimensional violations found.
  violations: array<string>,
  /// Unit coercion suggestions.
  coercions: array<string>,
}

/// A proof obligation generated from dependent types.
type proofObligation = {
  /// Unique ID for this obligation.
  id: string,
  /// The proposition to prove.
  proposition: string,
  /// Which dependent indices this obligation arises from.
  indices: array<string>,
  /// Suggested tactic to discharge it.
  suggestedTactic: option<string>,
  /// Whether ECHIDNA can auto-discharge this.
  autoDischarge: bool,
}

/// Build the JSON body for a kernel type-check request.
let buildCheckBody = (source: string, language: string): string => {
  `{"source":${JSON.stringifyAny(source)->Option.getOr("\"\"")}, "language":${JSON.stringifyAny(language)->Option.getOr("\"\"")}, "mode":"check"}`
}

/// Build the JSON body for a kernel usage inference request.
let buildInferUsageBody = (source: string): string => {
  `{"source":${JSON.stringifyAny(source)->Option.getOr("\"\"")}, "mode":"infer_usage"}`
}

/// Build the JSON body for a kernel effect inference request.
let buildCheckEffectsBody = (source: string): string => {
  `{"source":${JSON.stringifyAny(source)->Option.getOr("\"\"")}, "mode":"check_effects"}`
}

/// Build the JSON body for a kernel dimensional check request (Eclexia).
let buildCheckDimensionalBody = (source: string): string => {
  `{"source":${JSON.stringifyAny(source)->Option.getOr("\"\"")}, "mode":"check_dimensional"}`
}

/// Build the JSON body for proof obligation generation.
let buildGenerateProofObligationBody = (source: string): string => {
  `{"source":${JSON.stringifyAny(source)->Option.getOr("\"\"")}, "mode":"generate_obligations"}`
}

/// Tea_Json decoder for a kernel type check result (parameterised by language).
let kernelCheckResultDecoder = (language: string): Tea_Json.decoder<kernelTypeCheckResult> => {
  open Decoders
  map6(
    (valid, typeSignature, featureCodes, proofObligations, effects, linearityIssues) => {
      let activeFeatures = featureCodes->Array.filterMap(parseFeatureCode)
      ({
        valid,
        typeSignature,
        activeFeatures,
        proofObligations,
        effects,
        linearityIssues,
        language,
      }: kernelTypeCheckResult)
    },
    boolField("valid"),
    stringField("type_signature"),
    stringArrayField("features"),
    stringArrayField("proof_obligations"),
    stringArrayField("effects"),
    stringArrayField("linearity_issues"),
  )
}

/// Parse a kernel type check result from JSON response.
let parseKernelCheckResult = (json: string, language: string): result<kernelTypeCheckResult, string> =>
  Decoders.decode(kernelCheckResultDecoder(language), json)

/// Tea_Json decoder for a usage inference result.
let usageInferenceResultDecoder: Tea_Json.decoder<usageInferenceResult> = {
  open Decoders
  open Tea_Json
  map2(
    (quantifierStr, explanation) => ({
      quantifier: parseUsage(quantifierStr),
      explanation,
      bindings: [],
    }: usageInferenceResult),
    stringField("quantifier"),
    stringField("explanation"),
  )
}

/// Parse a usage inference result from JSON.
let parseUsageInferenceResult = (json: string): result<usageInferenceResult, string> =>
  Decoders.decode(usageInferenceResultDecoder, json)

/// Tea_Json decoder for an effect inference result.
let effectInferenceResultDecoder: Tea_Json.decoder<effectInferenceResult> = {
  open Decoders
  open Tea_Json
  map3(
    (effects, pure, effectRow) => ({
      effects,
      pure,
      effectRow,
    }: effectInferenceResult),
    stringArrayField("effects"),
    boolField("pure"),
    optionalFieldDecoder("effect_row", string),
  )
}

/// Parse an effect inference result from JSON.
let parseEffectInferenceResult = (json: string): result<effectInferenceResult, string> =>
  Decoders.decode(effectInferenceResultDecoder, json)

/// Tea_Json decoder for a dimensional check result.
let dimensionalResultDecoder: Tea_Json.decoder<dimensionalResult> = {
  open Decoders
  open Tea_Json
  map4(
    (consistent, dimensionalType, violations, coercions) => ({
      consistent,
      dimensionalType,
      violations,
      coercions,
    }: dimensionalResult),
    boolField("consistent"),
    stringField("dimensional_type"),
    stringArrayField("violations"),
    stringArrayField("coercions"),
  )
}

/// Parse a dimensional check result from JSON.
let parseDimensionalResult = (json: string): result<dimensionalResult, string> =>
  Decoders.decode(dimensionalResultDecoder, json)

/// Kernel endpoint URL (default localhost:7800).
let kernelBaseUrl = "http://localhost:7800/api/v1"

/// All supported nextgen-languages that the kernel can type-check.
let supportedLanguages: array<string> = [
  "affinescript", "eclexia", "anvomidav", "ephapax", "wokelang",
  "betlang", "tangle", "my-lang", "crank", "delimit",
  "sunyata", "hexsweep", "cascade", "polytope", "coda", "strata",
]

/// Check if a language name is supported by the kernel.
let isKernelSupported = (lang: string): bool => {
  supportedLanguages->Array.includes(String.toLowerCase(lang))
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
  disciplineDeclarations: [],
  defaultDiscipline: DisciplineAffine, // Affine by default, as per unified type system design
  lastUnifiedAnalysis: None,
  serviceActive: true,
  queriesServed: 0,
  bojRouting: false,
  panelTypeChecks: Dict.make(),
}
