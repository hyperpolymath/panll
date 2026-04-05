// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Pane State Types — Pane-L (Symbolic), Pane-N (Neural), Pane-W (World).
///
/// These types define the three core panes of the Binary Star co-orbit model.
/// Pane-L holds formal constraints and the symbolic editor. Pane-N holds the
/// neural inference stream with its token log, monologue, and agency monitor.
/// Pane-W holds the world/task barycentre including security tools, event chain
/// analysis, and the panic-attacker integration.
///
/// This module has NO dependencies on other PanLL modules — it is the leaf
/// of the type dependency graph.
///
/// ON VARIANT TYPES: Each OODA phase below (`Observe | Orient | Decide | Act`)
/// is a ReScript variant — a tagged union the compiler understands structurally.
/// In TypeScript you'd write `type OodaPhase = "observe" | "orient" | ...` which
/// looks similar, but the compiler can't enforce exhaustive matching (you need a
/// manual `default: throw` or `satisfies never` trick that's easy to forget, and
/// which won't catch new additions at compile time across files). ReScript's
/// `switch` on variants is exhaustive by default — miss a case, get a compile
/// error. At 14 panels with dozens of variant types each, this single property
/// has prevented more bugs than any linter rule could.

/// Constraint types for the Symbolic Mass (Pane-L)
type symbolicConstraint = {
  /// Unique constraint identifier.
  id: string,
  /// The constraint expression text (e.g. a type rule or invariant).
  expression: string,
  /// Whether this constraint is currently active for validation.
  active: bool,
  /// Whether this constraint is pinned (Sticky Constraints feature).
  pinned: bool,
}

/// OODA loop phase for Thing-Agency Monitor.
/// Based on Boyd's OODA loop (1976) — the decision cycle primitive
/// underpinning autonomous systems, incident response, and multi-agent coordination.
type oodaPhase =
  /// Gathering information from the environment.
  | Observe
  /// Analysing and contextualising observations.
  | Orient
  /// Selecting a course of action.
  | Decide
  /// Executing the chosen action.
  | Act

/// Source of a neural token — which agent, prover, or subsystem emitted it.
type tokenSource =
  /// Tokens from the main neural inference engine (LLM reasoning).
  | NeuralInference
  /// Tokens from ECHIDNA theorem prover dispatch.
  | EchidnaProver
  /// Tokens from TypeLL type-checking / proof obligations.
  | TypeLLKernel
  /// Tokens from VeriSimDB VCL inference stream.
  | VeriSimInference
  /// Tokens from Anti-Crash validation feedback.
  | AntiCrashGate
  /// Tokens from the operator (human input / corrections).
  | OperatorInput
  /// Tokens from cross-panel OrbitalSync events.
  | OrbitalSync

/// Semantic category of a neural token — what kind of reasoning step it represents.
type tokenCategory =
  /// An observation or data-gathering step.
  | Observation
  /// A hypothesis or tentative conclusion.
  | Hypothesis
  /// A deductive inference step (A implies B, A holds, therefore B).
  | Deduction
  /// An abductive inference step (best explanation for observed data).
  | Abduction
  /// A proof step or formal verification result.
  | ProofStep
  /// A constraint violation or safety warning.
  | Violation
  /// A correction or retraction of a previous token.
  | Correction
  /// Synthesis / final answer / actionable output.
  | Synthesis

/// Neural token with full provenance, causality, and semantic metadata.
/// This is the atomic unit of the Neural Stream — every inference step,
/// proof result, validation event, and operator correction is a token.
type neuralToken = {
  /// Unique token identifier (monotonic within session).
  id: string,
  /// The token text content.
  content: string,
  /// When this token was produced (Unix timestamp, millisecond precision).
  timestamp: float,
  /// Neural confidence score for this token (0.0–1.0).
  confidence: float,
  /// Whether this token has passed Anti-Crash validation.
  validated: bool,
  /// Which agent/subsystem produced this token.
  source: tokenSource,
  /// What kind of reasoning step this token represents.
  category: tokenCategory,
  /// OODA phase the agent was in when this token was emitted.
  emittedDuring: oodaPhase,
  /// IDs of tokens that causally preceded this one (inference chain).
  /// Empty for root tokens (observations, operator input).
  causedBy: array<string>,
  /// Optional proof certificate hash if this token carries formal verification.
  proofHash: option<string>,
}

/// Autonomy indicator for Human-Team Interaction (HTI).
/// Tracks the agent's decision-making independence and the operator's
/// last intervention point, enabling graduated autonomy visualisation.
type agencyState = {
  /// Current phase in the OODA loop.
  phase: oodaPhase,
  /// Autonomy level: 0.0 = fully instructed, 1.0 = fully autonomous.
  autonomyLevel: float,
  /// Timestamp of the last operator input event.
  lastOperatorInput: float,
}

/// Pane-L: Symbolic Mass (Noumena)
type paneLState = {
  /// All symbolic constraints loaded in the constraint editor.
  constraints: array<symbolicConstraint>,
  /// ID of the constraint currently selected for editing, if any.
  activeConstraintId: option<string>,
  /// Raw text content of the symbolic editor textarea.
  editorContent: string,
  /// TypeLL inferred type for the current editor expression (cross-panel intelligence).
  lastInferredType: option<string>,
}

/// Filter state for the Neural Stream — controls which tokens are visible.
/// Each filter is a set of active values; if empty, all values pass.
type tokenFilters = {
  /// Active source filters — empty means show all sources.
  sources: array<tokenSource>,
  /// Active category filters — empty means show all categories.
  categories: array<tokenCategory>,
  /// Active OODA phase filters — empty means show all phases.
  phases: array<oodaPhase>,
  /// Minimum confidence threshold (0.0–1.0). Tokens below this are hidden.
  confidenceThreshold: float,
  /// Whether to show only validated tokens.
  validatedOnly: bool,
  /// Whether to show only tokens with proof hashes.
  proofOnly: bool,
}

/// Pane-N: Neural Stream (Phenomena)
type paneNState = {
  /// Accumulated neural tokens from the inference stream.
  tokens: array<neuralToken>,
  /// Whether the neural inference engine is currently producing tokens.
  inferenceActive: bool,
  /// The neural monologue text (inner reasoning trace).
  monologue: string,
  /// Thing-Agency Monitor state tracking OODA phase and autonomy level.
  agency: agencyState,
  /// Monotonic token counter for generating unique IDs within a session.
  nextTokenId: int,
  /// Active causal chain — IDs of the most recent tokens in the current
  /// reasoning thread. New tokens reference these as their `causedBy`.
  /// Reset when the agent enters a new OODA Observe phase.
  activeCausalChain: array<string>,
  /// Token stream filter state — controls which tokens are displayed.
  filters: tokenFilters,
}

/// Pane-W: World/Task Barycentre
/// Events are created from panic-attack/panll exports and feed the Time/Space
/// study view; each event carries axis/duration/intensity metadata.
type eventChainEvent = {
  /// Unique event identifier.
  id: string,
  /// Axis label (e.g. "CPU", "Memory", "I/O").
  axis: string,
  /// Start time in milliseconds from the chain origin, if known.
  startMs: option<float>,
  /// Duration of this event in milliseconds.
  durationMs: float,
  /// Intensity level (e.g. "low", "medium", "high", "critical").
  intensity: string,
  /// Event outcome status (e.g. "ok", "crash", "timeout").
  status: string,
  /// Peak memory usage in bytes during this event, if measured.
  peakMemory: option<float>,
  /// Free-form notes attached to this event.
  notes: option<string>,
}

/// Summary statistics for a panic-attacker event chain analysis.
type eventChainSummary = {
  /// Name of the program under test.
  program: string,
  /// Total number of identified weak points.
  weakPoints: int,
  /// Number of weak points classified as critical.
  criticalWeakPoints: int,
  /// Total crash events observed.
  totalCrashes: int,
  /// Overall robustness score (0.0-1.0, higher is more robust).
  robustnessScore: float,
}

/// Timeline metadata for an event chain visualization.
type eventChainTimeline = {
  /// Total duration of the timeline in milliseconds.
  durationMs: float,
  /// Number of events in the timeline.
  events: int,
}

/// The Pane-W state tracks the world view (content/topology), the imported
/// panic-attacker event-chain, and the security dialog fields that run ambush
/// tooling. Keeping these annotations clarifies how the UI state mirrors the
/// backend command lifecycle.
type paneWState = {
  /// Main content text of the world pane.
  content: string,
  /// Whether the Binary Star topology diagram mode is active.
  topologyView: bool,
  /// Last output that passed Anti-Crash validation.
  lastValidatedOutput: string,
  /// Imported panic-attacker event chain data.
  eventChain: array<eventChainEvent>,
  /// Summary statistics for the loaded event chain.
  eventChainSummary: option<eventChainSummary>,
  /// Timeline metadata for event chain visualization.
  eventChainTimeline: option<eventChainTimeline>,
  /// Raw input text for event chain import (JSON or path).
  eventChainInput: string,
  /// Error from the last event chain import attempt.
  eventChainError: option<string>,
  /// Panic-attacker integration mode: "unknown" | "full" | "fallback" | "unavailable".
  panicAttackerMode: string,
  /// Path to the panic-attacker binary, if detected.
  panicAttackerBinary: option<string>,
  /// Detailed status message from panic-attacker detection.
  panicAttackerStatusDetail: option<string>,
  /// Target program or binary for security analysis.
  securityTarget: string,
  /// Timeline specification for the security run.
  securityTimeline: string,
  /// Axes to test (e.g. "CPU,Memory,I/O").
  securityAxes: string,
  /// Intensity level for the security run.
  securityIntensity: string,
  /// Duration specification for the security run.
  securityDuration: string,
  /// Status message from the last security operation.
  securityStatus: option<string>,
  /// Error from the last security operation.
  securityError: option<string>,
  /// Whether the security tools dropdown menu is expanded.
  securityMenuExpanded: bool,
  /// Whether the security configuration dialog is open.
  securityDialogOpen: bool,
  /// Which security tool the dialog is configuring.
  securityDialogTool: option<string>,
  /// Whether the security results view is currently displayed.
  securityViewActive: bool,
}
