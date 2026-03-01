// SPDX-License-Identifier: PMPL-1.0-or-later

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
  | TypeMismatch(string, string) // expected, actual
  | BoundaryViolation(string)
  | LogicContradiction(string)
  | UndefinedReference(string)
  | SecurityViolation(string)

/// Anti-Crash validation state
type antiCrashState = {
  enabled: bool,
  strictMode: bool,
  violations: array<violationType>,
  halted: bool,
  pendingReview: option<PaneModel.neuralToken>,
}

/// Vexometer state
type vexometerState = {
  index: float, // 0.0 - 1.0
  recentCancellations: int,
  recentCorrections: int,
  antiInflammatoryActive: bool,
  inertiaDetected: bool,
}

/// Orbital stability metrics
type orbitalState = {
  stability: float, // sigma value
  divergenceLevel: float,
  driftAuraColour: string, // "indigo" or "amber"
}

/// Information Humidity level
type humidityLevel =
  | High // Low stress - show more detail
  | Medium
  | Low // High stress - shed visual noise

/// View mode for the environment
type viewMode =
  | Standard
  | Ambient // Memory Foam grid only
  | Zen // No sidebars/status
  | DarkStart // Architecture Manifold on idle

/// Synchronisation event types (for OrbitalSync)
type syncEvent =
  | SymbolicUpdate(string)   // Change in Pane-L
  | NeuralUpdate(string)     // Change in Pane-N
  | WorldUpdate(string)      // Change in Pane-W
  | CrossPaneLink(string, string) // Link between panes

/// Synchronisation state (for OrbitalSync)
type syncState = {
  lastSymbolicHash: string,
  lastNeuralHash: string,
  lastWorldHash: string,
  pendingSync: array<syncEvent>,
  syncLatency: float, // milliseconds
}

/// Contract enforcement level (for Contractiles)
type enforcementLevel =
  | Strict    // Halt on violation
  | Warn      // Log warning, continue
  | Adaptive  // Adjust contract based on context

/// Contract status (for Contractiles)
type contractStatus =
  | Satisfied
  | Violated(string)
  | Pending
  | Suspended

/// A contractile definition (for Contractiles)
type contractile = {
  id: string,
  name: string,
  description: string,
  enforcement: enforcementLevel,
  status: contractStatus,
  elasticity: float, // 0.0 = rigid, 1.0 = fully elastic
  lastEvaluated: float,
}

/// Contractile evaluation result (for Contractiles)
type evaluationResult = {
  contractId: string,
  status: contractStatus,
  message: string,
  adjustmentSuggestion: option<string>,
}
