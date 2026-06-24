// SPDX-License-Identifier: MPL-2.0

/// PanLL Governance Types — Cognitive governance and system coherence.
///
/// These types implement the "elastic state contracts" that maintain the
/// Binary Star co-orbit between Operator and Machine. Anti-Crash is the
/// circuit breaker that validates neural tokens. The Vexometer tracks
/// operator frustration. Orbital metrics measure pane synchronisation.
/// Contractiles enforce adaptive boundaries. Sync events track cross-pane
/// change propagation.
///
/// Depends on PaneModel for neuralToken (used in antiCrashState.pendingReview).

/// Constraint violation types (Anti-Crash)
type violationType =
  /// Type mismatch between expected and actual types.
  | TypeMismatch(string, string)
  /// A value exceeded its declared boundary or range.
  | BoundaryViolation(string)
  /// A logical contradiction was detected in the constraint set.
  | LogicContradiction(string)
  /// A reference to an undefined identifier or resource.
  | UndefinedReference(string)
  /// A security policy violation was detected.
  | SecurityViolation(string)

/// Anti-Crash validation state
type antiCrashState = {
  /// Whether the Anti-Crash circuit breaker is enabled.
  enabled: bool,
  /// When true, any violation halts neural output immediately.
  strictMode: bool,
  /// Accumulated constraint violations from the current session.
  violations: array<violationType>,
  /// Whether output is currently halted due to a violation.
  halted: bool,
  /// A neural token awaiting operator review before being accepted.
  pendingReview: option<PaneModel.neuralToken>,
}

/// Vexometer state
type vexometerState = {
  /// Frustration index from 0.0 (calm) to 1.0 (maximum vexation).
  index: float,
  /// Count of recent operator cancellations (contributes to vexation).
  recentCancellations: int,
  /// Count of recent operator corrections (contributes to vexation).
  recentCorrections: int,
  /// Whether the anti-inflammatory response is active (reducing UI noise).
  antiInflammatoryActive: bool,
  /// Whether task inertia has been detected (operator stuck on same task).
  inertiaDetected: bool,
}

/// Orbital stability metrics
type orbitalState = {
  /// Orbital stability sigma value (higher = more stable).
  stability: float,
  /// Current divergence level between symbolic and neural panes.
  divergenceLevel: float,
  /// Drift aura colour indicator: "indigo" (stable) or "amber" (drifting).
  driftAuraColour: string,
  /// Symbolic mass: weight of Panel-L content (token density, constraint count).
  /// Range 0.0–1.0 where higher means more substantial symbolic content.
  symbolicMass: float,
  /// Neural stream: throughput of Panel-N content (inference rate, monologue density).
  /// Range 0.0–1.0 where higher means more active neural processing.
  neuralStream: float,
  /// Barycentre position on the symbolic–neural axis.
  /// -1.0 = fully symbolic, 0.0 = balanced, +1.0 = fully neural.
  barycentrePosition: float,
  /// Sync health: overall cross-pane synchronisation quality.
  /// Range 0.0–1.0 derived from latency, event throughput, hash freshness.
  syncHealth: float,
}

/// Barycentre tour step for the guided walkthrough
type tourStep =
  | TourIntro
  | TourBinaryStar
  | TourBarycentrePosition
  | TourOrbitalMetrics
  | TourContractiles
  | TourSyncHealth
  | TourComplete

/// State for the interactive barycentre tour
type tourState = {
  /// Whether the tour is currently active.
  active: bool,
  /// Current step in the tour sequence.
  currentStep: tourStep,
  /// Whether the user has completed the tour at least once.
  completed: bool,
}

/// Information Humidity level — defined in PaneModel to avoid circular dependency.
/// Re-exported via Model.res include chain. Use humidityLevel directly when
/// Model is open; use PaneModel.humidityLevel for standalone references.

/// View mode for the environment
type viewMode =
  /// Normal operating mode with all panels visible.
  | Standard
  /// Light background with dark text for high-ambient-light environments.
  | LightMode
  /// Memory Foam grid only, minimal chrome.
  | Ambient
  /// No sidebars or status bars, maximum content focus.
  | Zen
  /// Architecture Manifold displayed on idle.
  | DarkStart

/// Synchronisation event types (for OrbitalSync)
type syncEvent =
  | SymbolicUpdate(string) // Change in Pane-L
  | NeuralUpdate(string) // Change in Pane-N
  | WorldUpdate(string) // Change in Pane-W
  | CrossPaneLink(string, string) // Link between panes

/// Synchronisation state (for OrbitalSync)
type syncState = {
  /// Hash of the last synchronised Pane-L (symbolic) state.
  lastSymbolicHash: string,
  /// Hash of the last synchronised Pane-N (neural) state.
  lastNeuralHash: string,
  /// Hash of the last synchronised Pane-W (world) state.
  lastWorldHash: string,
  /// Queue of sync events waiting to be propagated.
  pendingSync: array<syncEvent>,
  /// Current cross-pane synchronisation latency in milliseconds.
  syncLatency: float,
}

/// Contract enforcement level (for Contractiles)
type enforcementLevel =
  | Strict // Halt on violation
  | Warn // Log warning, continue
  | Adaptive // Adjust contract based on context

/// Contract status (for Contractiles)
type contractStatus =
  | Satisfied
  | Violated(string)
  | Pending
  | Suspended

/// A contractile definition (for Contractiles)
type contractile = {
  /// Unique contract identifier.
  id: string,
  /// Human-readable contract name.
  name: string,
  /// Explanation of what this contract enforces.
  description: string,
  /// How strictly this contract is enforced.
  enforcement: enforcementLevel,
  /// Current evaluation status of this contract.
  status: contractStatus,
  /// Elasticity: 0.0 = rigid (no flex), 1.0 = fully elastic (adapts freely).
  elasticity: float,
  /// Timestamp of the last evaluation pass.
  lastEvaluated: float,
}

/// Contractile evaluation result (for Contractiles)
type evaluationResult = {
  /// ID of the contract that was evaluated.
  contractId: string,
  /// Resulting status after evaluation.
  status: contractStatus,
  /// Human-readable evaluation message.
  message: string,
  /// Suggested adjustment if the contract is elastic and could adapt.
  adjustmentSuggestion: option<string>,
}
