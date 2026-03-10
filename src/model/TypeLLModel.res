// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL TypeLL Model — Unified type system kernel.
///
/// TypeLL is to PanLL what LLVM is to Clang — the formal verification backbone.
/// It merges linear, affine, and dependent types into a single cohesive framework:
///
/// ## Unified Type System Design
///
/// **Core idea:** Dependent types describe *properties* of values while
/// linear/affine types track *usage* of values. The unified system lets you
/// combine both: `linear Vec (n + m) a` is a dependent-linear type that
/// tracks both length *and* consumption.
///
/// **Gradual linearity:** Affine by default (like Rust). Opt-in to linear
/// (exactly once) or unrestricted (unlimited). QTT quantifiers (0, 1, ω)
/// make this formal.
///
/// **Type discipline modes:** Modules declare their default discipline:
///   `#![affine]`     — Rust-like: use at most once (default)
///   `#![linear]`     — Strict: use exactly once
///   `#![dependent]`  — Full dependent types (Idris-like)
///   `#![refined]`    — Refinement types (Liquid-like)
///   `#![unrestricted]` — Standard types, no usage tracking
///
/// **Inference strategy:**
///   1. Aggressively infer linearity/affinity from usage patterns
///   2. Infer simple dependent types (array lengths from literals)
///   3. Explicit annotations only for complex constraints
///   4. IDE tactics for interactive dependent type construction
///
/// **Effect polymorphism:** Effects (IO, State, Except) tracked as part
/// of the type: `fn id {e} (x : a @ e) -> a @ e`
///
/// ## View Layers (from rescript-evangeliser)
///
///   RAW     — Full type signatures, unmodified. For experts.
///   FOLDED  — Categorised and collapsible. For working developers.
///   GLYPHED — Visual symbols annotating semantic meaning. For learning.
///   WYSIWYG — Interactive type construction. For exploration.
///
/// ## Type System Coverage
///
///   Tier 1 (Core):     Dependent, Linear, Session, Proof-Carrying
///   Tier 2 (Advanced): QTT, Effects, Modal, Affine
///   Tier 3 (Research): HoTT, Equality Saturation, Category-Theoretic
///
/// ## Inspirations
///
///   Idris 2   — Linear types via QTT + dependent types natively
///   ATS       — Dependent types with linear logic for systems programming
///   Rust      — Affine types in practice (borrow checker)
///   Linear Haskell — Linear types in a non-dependent setting
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// View Layer — progressive disclosure from rescript-evangeliser
// ============================================================================

/// Progressive disclosure level for type information.
/// Adapted from rescript-evangeliser's four-layer pedagogy system.
type viewLayer =
  /// Full type signatures, unmodified. Expert mode.
  | Raw
  /// Categorised sections with collapsible regions. Working developer mode.
  | Folded
  /// Symbol-annotated types showing semantic meaning. Learning mode.
  | Glyphed
  /// Interactive type construction UI. Exploration mode.
  | Wysiwyg

// ============================================================================
// Type System Tiers
// ============================================================================

/// Type system tier — categorises type features by sophistication.
type typeTier =
  /// Core type features: dependent, linear, session, proof-carrying.
  | TierCore
  /// Advanced features: QTT, effects, modal, affine.
  | TierAdvanced
  /// Research features: HoTT, equality saturation, category-theoretic.
  | TierResearch

/// Individual type system feature.
type typeFeature =
  // Tier 1: Core
  | DependentTypes
  | LinearTypes
  | SessionTypes
  | ProofCarryingCode
  // Tier 2: Advanced
  | QuantitativeTypeTheory
  | EffectSystems
  | ModalTypes
  | AffineTypes
  // Tier 3: Research
  | HomotopyTypeTheory
  | EqualitySaturation
  | CategoryTheoreticTypes

// ============================================================================
// Unified Type System — Gradual Linearity & Type Discipline Modes
// ============================================================================

/// Usage quantifier from Quantitative Type Theory (QTT).
/// Tracks how many times a value may be used — the core of gradual linearity.
type usageQuantifier =
  /// Zero uses: the value is erased at runtime (proof-only, compile-time witness).
  | UsageZero
  /// Exactly one use: strict linear consumption (no dup, no drop).
  | UsageOne
  /// Unrestricted: unlimited uses (standard functional programming).
  | UsageOmega

/// Type discipline mode — declared per module/file to set the default type
/// system behaviour. Inspired by Rust's edition system and Idris' quantity annotations.
type typeDiscipline =
  /// Affine by default: values used at most once, may be discarded. Like Rust.
  | DisciplineAffine
  /// Linear: values used exactly once. Strict resource tracking.
  | DisciplineLinear
  /// Dependent: full dependent types with value-level computation in types.
  | DisciplineDependent
  /// Refined: base types narrowed by predicate constraints (Liquid types).
  | DisciplineRefined
  /// Unrestricted: no usage tracking, standard types. Escape hatch.
  | DisciplineUnrestricted

/// A unified type expression in the combined system.
/// Represents "dependent linear types" — types that carry both value
/// properties (dependent) and usage discipline (linear/affine/QTT).
type unifiedTypeExpr = {
  /// The base type expression (e.g., "Vec n a", "IO String", "Nat -> Nat").
  baseExpr: string,
  /// Usage quantifier for this type (0, 1, or omega).
  usage: usageQuantifier,
  /// Type discipline in effect for this expression.
  discipline: typeDiscipline,
  /// Dependent indices — value-level terms that appear in the type.
  /// e.g., for `Vec n a`, indices would be ["n"].
  dependentIndices: array<string>,
  /// Effect annotations — which effects this type may perform.
  /// e.g., ["IO", "State s", "Except e"].
  effects: array<string>,
  /// Refinement predicates — constraints narrowing the type.
  /// e.g., for `{x : Nat | x > 0}`, predicates would be ["x > 0"].
  refinements: array<string>,
}

/// Inference hint — what TypeLL inferred vs what was annotated.
type inferenceSource =
  /// Fully inferred from usage patterns (no annotation needed).
  | Inferred
  /// Explicitly annotated by the programmer.
  | Annotated
  /// Partially inferred, partially annotated.
  | Mixed
  /// Inferred from a tactic suggestion (IDE-assisted).
  | TacticAssisted

/// Result of unified type analysis — richer than a simple typeCheckResult,
/// this captures the full combined type system picture.
type unifiedTypeAnalysis = {
  /// The unified type expression.
  typeExpr: unifiedTypeExpr,
  /// How the type was determined.
  source: inferenceSource,
  /// Whether linearity constraints are satisfied.
  linearitySatisfied: bool,
  /// Whether dependent indices are well-founded.
  indicesWellFounded: bool,
  /// Whether refinement predicates are satisfiable.
  refinementsSatisfiable: bool,
  /// Proof obligations arising from dependent types.
  proofObligations: array<string>,
  /// Usage violations: where the quantifier was breached.
  usageViolations: array<string>,
  /// Effect leaks: effects not declared in the type signature.
  effectLeaks: array<string>,
}

/// A type discipline declaration for a module or file scope.
type disciplineDeclaration = {
  /// The scope this discipline applies to (module name or file path).
  scope: string,
  /// The declared discipline.
  discipline: typeDiscipline,
  /// Whether inference is permitted to relax the discipline.
  inferenceAllowed: bool,
  /// Override features enabled beyond the discipline default.
  enabledFeatures: array<typeFeature>,
}

// ============================================================================
// Evangeliser Glyphs — visual symbols for type concepts
// ============================================================================

/// Visual glyph representing a type concept. Makaton-inspired symbols
/// from rescript-evangeliser, extended for the full type system spectrum.
type typeGlyph = {
  /// Unicode symbol.
  symbol: string,
  /// Short label.
  label: string,
  /// What this glyph means in type theory.
  meaning: string,
}

// ============================================================================
// TypeLL Results
// ============================================================================

/// Result of type-checking an expression.
type typeCheckResult = {
  /// Whether the expression type-checks.
  valid: bool,
  /// Inferred or checked type signature.
  typeSignature: string,
  /// Human-readable explanation of the type.
  explanation: string,
  /// Proof obligations generated (if dependent types involved).
  proofObligations: array<string>,
  /// Effects detected (reads, writes, allocations).
  effects: array<string>,
  /// Linearity violations (if linear/affine types involved).
  linearityIssues: array<string>,
  /// Session protocol compliance notes.
  sessionNotes: array<string>,
  /// Which type features are active in this result.
  activeFeatures: array<typeFeature>,
  /// Type tier of the highest feature used.
  maxTier: typeTier,
  /// Usage quantifier determined for this expression (QTT).
  usage: usageQuantifier,
  /// Which type discipline was in effect during checking.
  discipline: typeDiscipline,
  /// How the result was inferred/annotated.
  inferenceSource: inferenceSource,
  /// Unified type analysis (full combined system picture), if available.
  unifiedAnalysis: option<unifiedTypeAnalysis>,
}

/// A type signature entry from the server.
type typeSignatureEntry = {
  /// Name of the binding/function.
  name: string,
  /// Full type signature.
  signature: string,
  /// Which module/namespace it belongs to.
  module_: string,
  /// Type tier.
  tier: typeTier,
}

/// Universe hierarchy entry.
type universeEntry = {
  /// Universe level (0 = Type, 1 = Type₁, etc.).
  level: int,
  /// Universe name.
  name: string,
  /// Description.
  description: string,
}

/// A refinement constraint applied to a type.
type refinementConstraint = {
  /// The constraint expression (e.g., "x > 0", "len(s) < 256").
  expression: string,
  /// Whether this constraint is satisfiable.
  satisfiable: bool,
  /// Counterexample if not satisfiable.
  counterexample: option<string>,
}

/// Result of applying refinement types.
type refinementResult = {
  /// Original type.
  baseType: string,
  /// Refined type.
  refinedType: string,
  /// Applied constraints.
  constraints: array<refinementConstraint>,
  /// Whether all constraints are satisfiable together.
  consistent: bool,
}

/// Evangeliser-style narrative for a type result. Progressive, encouraging.
type typeNarrative = {
  /// What the developer got right (celebrate).
  celebrate: string,
  /// What could be improved (minimize).
  minimize: string,
  /// How types make it better (show better).
  showBetter: string,
  /// Type-level safety guarantees (safety).
  safety: string,
}

// ============================================================================
// Panel State
// ============================================================================

/// Category tabs for the TypeLL panel.
type typellCategory =
  /// Type checker — paste code, get type analysis.
  | TlChecker
  /// Type explorer — browse universes and signatures.
  | TlExplorer
  /// Refinement lab — apply refinement types interactively.
  | TlRefinement
  /// Discipline — configure module type disciplines and view unified analysis.
  | TlDiscipline
  /// Type guide — educational reference for type system tiers.
  | TlGuide

/// Root state for the TypeLL panel.
type typellState = {
  /// Whether the TypeLL server is reachable.
  serverConnected: bool,
  /// Whether an operation is in progress.
  loading: bool,
  /// Error from the last operation.
  error: option<string>,
  /// Active category tab.
  activeCategory: typellCategory,
  /// Active view layer (progressive disclosure level).
  activeViewLayer: viewLayer,

  // Checker state
  /// Expression input for type checking.
  checkerInput: string,
  /// Optional context for type checking (JSON).
  checkerContext: string,
  /// Most recent type check result.
  lastCheckResult: option<typeCheckResult>,
  /// Evangeliser narrative for last result.
  lastNarrative: option<typeNarrative>,

  // Explorer state
  /// Available type signatures from server.
  signatures: array<typeSignatureEntry>,
  /// Universe hierarchy.
  universes: array<universeEntry>,
  /// Search filter for signatures.
  signatureFilter: string,
  /// Which tier to filter by (None = all).
  tierFilter: option<typeTier>,

  // Refinement state
  /// Base type specification for refinement.
  refinementSpec: string,
  /// Constraints input (one per line).
  refinementConstraints: string,
  /// Most recent refinement result.
  lastRefinement: option<refinementResult>,

  // Discipline state
  /// Active type discipline declarations for known modules.
  disciplineDeclarations: array<disciplineDeclaration>,
  /// Default discipline for new/unconfigured modules.
  defaultDiscipline: typeDiscipline,
  /// Most recent unified type analysis result.
  lastUnifiedAnalysis: option<unifiedTypeAnalysis>,

  // Cross-panel state
  /// Whether TypeLL is providing type intelligence to other panels.
  serviceActive: bool,
  /// How many cross-panel type queries have been served this session.
  queriesServed: int,
  /// When true, TypeLL operations route through BoJ nesy-mcp cartridge instead of direct HTTP.
  bojRouting: bool,
  /// Cross-panel TypeLL results keyed by panel name. Panels without their own
  /// lastTypeCheck field store results here via TypeCheckResult handlers.
  panelTypeChecks: Dict.t<string>,
}
