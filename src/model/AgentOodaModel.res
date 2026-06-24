// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL OODA Session Monitor Model — types for tracking agent OODA loop
/// lifecycles.
///
/// Tracks Observe/Orient/Decide/Act/Halted states for multiple concurrent
/// agent sessions, with loop counting, health indicators, and manual
/// advance/halt controls.
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Agent State Machine
// ============================================================================

/// State of an agent within its OODA decision loop.
type agentState =
  /// Observe — agent is gathering information from the environment.
  | Observing
  /// Orient — agent is interpreting observations and building context.
  | Orienting
  /// Decide — agent is selecting the next action.
  | Deciding
  /// Act — agent is executing the chosen action.
  | Acting
  /// Halted — agent has been manually stopped or encountered an error.
  | Halted

// ============================================================================
// Session Types
// ============================================================================

/// A single OODA session representing one agent's lifecycle.
type oodaSession = {
  /// Unique session identifier.
  id: string,
  /// Human-readable agent name (e.g., "rhodibot", "echidnabot").
  agentName: string,
  /// Current state in the OODA loop.
  state: agentState,
  /// Number of complete OODA loops executed so far.
  loopCount: int,
  /// Whether this session was halted (manually or by error).
  wasHalted: bool,
  /// ISO 8601 timestamp of session creation.
  startedAt: string,
  /// ISO 8601 timestamp of last state transition.
  lastTransition: string,
  /// Optional error message if the session was halted due to an error.
  haltReason: option<string>,
}

/// A single state transition in a session's history.
type stateTransition = {
  /// State before the transition.
  fromState: agentState,
  /// State after the transition.
  toState: agentState,
  /// ISO 8601 timestamp of the transition.
  timestamp: string,
  /// Duration in milliseconds from the previous transition.
  durationMs: float,
}

/// Detailed view of a single session, including transition history.
type sessionDetail = {
  /// The session itself.
  session: oodaSession,
  /// Chronological list of state transitions.
  transitions: array<stateTransition>,
  /// Average time per OODA loop in milliseconds.
  avgLoopMs: float,
  /// Total elapsed time in milliseconds.
  totalElapsedMs: float,
}

// ============================================================================
// Panel State
// ============================================================================

/// Top-level state for the OODA Session Monitor panel.
type agentOodaState = {
  /// All active OODA sessions.
  sessions: array<oodaSession>,
  /// Currently selected session for detail view (by id).
  selectedSessionId: option<string>,
  /// Detail data for the selected session.
  selectedDetail: option<sessionDetail>,
  /// Whether a refresh is in progress.
  loading: bool,
}
