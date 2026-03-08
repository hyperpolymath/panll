// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL TypeLL Model — types for the verification kernel panel and service layer.
///
/// TypeLL is to PanLL what LLVM is to Clang — the formal verification backbone.
/// It provides dependent, linear, affine, session, and refinement types across
/// every language and tool PanLL touches.
///
/// The panel exposes TypeLL's capabilities directly, while the service layer
/// (TypeLLService.res) lets any panel query TypeLL for type intelligence.
///
/// ## View Layers (from rescript-evangeliser)
///
/// Progressive disclosure makes advanced type systems accessible:
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

  // Cross-panel state
  /// Whether TypeLL is providing type intelligence to other panels.
  serviceActive: bool,
  /// How many cross-panel type queries have been served this session.
  queriesServed: int,
  /// When true, TypeLL operations route through BoJ nesy-mcp cartridge instead of direct HTTP.
  bojRouting: bool,
}
