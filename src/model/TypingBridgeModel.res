// SPDX-License-Identifier: MPL-2.0

/// PanLL Typing Bridge Model — connects TypeLL type system to IDApTIK game
/// development. Bridges PanLL's formal type reasoning with practical game
/// configuration, level typing, and constraint verification.
///
/// Three-panel model (L/N/W):
///   L: Type constraints for game state, typed level configurations
///   N: TypeLL reasoning about type safety across game systems
///   W: Type-safe configuration editor with live constraint feedback
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Tab Navigation
// ============================================================================

/// Category tabs for the Typing Bridge panel.
type typingBridgeTab =
  /// Constraints — define and browse type constraints on game state.
  | Constraints
  /// Inference — view TypeLL inference results for game configurations.
  | Inference
  /// Editor — type-safe configuration editor for level data.
  | Editor
  /// Diagnostics — type errors, warnings, and suggestions.
  | Diagnostics

// ============================================================================
// Type Constraint Domain
// ============================================================================

/// Severity of a type constraint violation.
type constraintSeverity =
  /// Hard error — the game will not load with this violation.
  | ConstraintError
  /// Warning — the game may behave unexpectedly.
  | ConstraintWarning
  /// Informational — suggestion for stronger typing.
  | ConstraintInfo

/// A type constraint applied to game state or level configuration.
/// These constraints are checked by TypeLL's inference engine.
type gameTypeConstraint = {
  /// Unique constraint identifier.
  id: string,
  /// Human-readable constraint name (e.g., "HealthNonNegative").
  name: string,
  /// The type expression constraining the game value.
  typeExpression: string,
  /// Target path in the game state tree (e.g., "player.health").
  targetPath: string,
  /// Severity if this constraint is violated.
  severity: constraintSeverity,
  /// Whether this constraint is currently satisfied.
  satisfied: bool,
  /// Human-readable description of what this constraint enforces.
  description: string,
}

// ============================================================================
// Inference Results
// ============================================================================

/// Status of a type inference operation.
type inferenceStatus =
  /// Inference succeeded — type is fully determined.
  | InferenceSuccess
  /// Inference produced a partial result — some ambiguity remains.
  | InferencePartial
  /// Inference failed — contradictory constraints or insufficient information.
  | InferenceFailed

/// A single inference result from TypeLL applied to a game configuration value.
type inferenceResult = {
  /// The game state path that was analysed.
  targetPath: string,
  /// The inferred type expression.
  inferredType: string,
  /// Status of this inference.
  status: inferenceStatus,
  /// Constraints that contributed to this inference.
  contributingConstraints: array<string>,
  /// Suggestions for improving type safety.
  suggestions: array<string>,
  /// Time taken for inference in milliseconds.
  inferenceTimeMs: float,
}

// ============================================================================
// Level Configuration Typing
// ============================================================================

/// A typed field within a level configuration.
type typedConfigField = {
  /// Field path within the level config (e.g., "enemies.spawn_rate").
  path: string,
  /// Expected type expression.
  expectedType: string,
  /// Current value serialised as string.
  currentValue: string,
  /// Whether the current value satisfies the type constraint.
  valid: bool,
  /// Validation message if invalid.
  validationMessage: option<string>,
}

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Typing Bridge panel.
type typingBridgeState = {
  /// Active tab within the Typing Bridge panel.
  activeTab: typingBridgeTab,
  /// All registered type constraints for the current game project.
  constraints: array<gameTypeConstraint>,
  /// Results from the most recent inference pass.
  inferenceResults: array<inferenceResult>,
  /// Currently selected constraint for detail view.
  selectedConstraint: option<string>,
  /// Typed configuration fields for the active level.
  configFields: array<typedConfigField>,
  /// Whether a type-checking or inference operation is in progress.
  running: bool,
  /// Error from the last operation.
  error: option<string>,
}
