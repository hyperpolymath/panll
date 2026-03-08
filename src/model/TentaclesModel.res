// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Tentacles Model — leaf types for the 7-Tentacles compiler agent panel.
///
/// Seven colour-coded agents each represent a compiler subsystem, progressing
/// through 4 cephalopod stages (Cuttle → Squidlet → Duet → Octopus).
/// Each agent maps to the three-panel model:
///   Panel-L (constraints)  → symbolic obligations from the agent's domain
///   Panel-N (OODA stream)  → agent reasoning via Observe/Orient/Decide/Act
///   Panel-W (results)      → validated outputs and task completions
///
/// Dependency: PaneModel (reuses oodaPhase type).

open PaneModel

/// Unique identifier for each of the 7 compiler agents.
/// Order matches the visible colour spectrum.
type tentacleId =
  /// Red — Parser agent. Reads source, produces token streams, reports syntax errors.
  | Red
  /// Orange — Concurrency agent. Schedules parallel tasks, detects deadlocks.
  | Orange
  /// Yellow — Type System agent. Infers types, checks constraints, resolves generics.
  | Yellow
  /// Green — AST Architect agent. Transforms syntax trees, applies optimisations.
  | Green
  /// Blue — Auditor agent. Measures coverage, flags anti-patterns, enforces standards.
  | Blue
  /// Indigo — Metaprogrammer agent. Manages macros, code generation, template expansion.
  | Indigo
  /// Violet — Governance agent. Enforces policy, license compliance, security rules.
  | Violet

/// Progressive reveal stages modelled on cephalopod growth.
/// Each stage unlocks deeper compiler concepts.
type tentacleStage =
  /// Cuttle (ages 8-12) — introductory, game-like interactions.
  | Cuttle
  /// Squidlet (ages 13-14) — intermediate, pattern-matching challenges.
  | Squidlet
  /// Duet (age 15) — paired reasoning with a second agent.
  | Duet
  /// Octopus (ages 16+) — full compiler subsystem access.
  | Octopus

/// OODA loop phase for agent reasoning in Panel-N.
/// NOTE: oodaPhase is already defined in PaneModel (Observe | Orient | Decide | Act).
/// TentaclesModel reuses it via Model.res include — no redefinition needed.

/// A symbolic constraint surfaced by an agent for Panel-L display.
type tentacleConstraint = {
  /// Which agent produced this constraint.
  source: tentacleId,
  /// Human-readable constraint label (e.g. "Type unification: α → β").
  label: string,
  /// Machine-readable constraint expression.
  expression: string,
  /// Whether the constraint is currently satisfied.
  satisfied: bool,
  /// Unix timestamp in milliseconds when the constraint was generated.
  timestamp: float,
}

/// A single reasoning step in the OODA stream (Panel-N).
type reasoningEntry = {
  /// Which agent produced this entry.
  agent: tentacleId,
  /// Current OODA phase of this entry.
  phase: oodaPhase,
  /// Summary text of the reasoning step.
  summary: string,
  /// Optional detailed explanation (collapsed by default).
  detail: option<string>,
  /// Unix timestamp in milliseconds.
  timestamp: float,
}

/// A validated result or output from an agent (Panel-W).
type validatedResult = {
  /// Which agent produced this result.
  agent: tentacleId,
  /// Short title for the result card.
  title: string,
  /// The output content (code, proof text, report, etc.).
  content: string,
  /// Whether this result passed verification/validation.
  verified: bool,
  /// Confidence score from the trust pipeline (0.0 to 1.0).
  confidence: float,
  /// Unix timestamp in milliseconds.
  timestamp: float,
}

/// Personality traits for an agent — drives the UI voice and interaction style.
type tentaclePersonality = {
  /// Conversational voice description.
  voice: string,
  /// Signature catchphrase shown in the agent header.
  catchphrase: string,
  /// Array of encouraging responses for correct actions.
  encouragement: array<string>,
  /// Array of gentle correction responses for mistakes.
  corrections: array<string>,
  /// Array of celebration messages for milestones.
  celebrations: array<string>,
}

/// Stage-specific display names for an agent (the cephalopod names).
type tentacleNames = {
  /// Name at the Cuttle stage.
  cuttle: string,
  /// Name at the Squidlet stage.
  squidlet: string,
  /// Name at the Duet stage.
  duet: string,
  /// Name at the Octopus stage.
  octopus: string,
}

/// Inter-agent message payload for broadcast communication.
/// Sent through the TEA update loop, not direct function calls.
type agentBroadcastPayload =
  /// A constraint was added or updated.
  | ConstraintUpdate(tentacleConstraint)
  /// An agent completed verification of a result.
  | VerificationResult(validatedResult)
  /// An agent requests help from another specific agent.
  | AssistanceRequest(tentacleId, string)
  /// An agent shares a reasoning insight.
  | ReasoningShare(reasoningEntry)
  /// Stage transition notification.
  | StageChanged(tentacleStage)

/// Common state shared by all 7 agents.
type tentacleAgentState = {
  /// Which agent this is.
  id: tentacleId,
  /// Current progressive reveal stage.
  stage: tentacleStage,
  /// Agent personality (voice, catchphrase, responses).
  personality: tentaclePersonality,
  /// Stage-specific display names.
  names: tentacleNames,
  /// Compiler subsystem role description.
  compilerRole: string,
  /// What this agent teaches (list of topic strings).
  teaches: array<string>,
  /// Constraints this agent is currently tracking (Panel-L feed).
  constraints: array<tentacleConstraint>,
  /// OODA reasoning stream (Panel-N feed).
  reasoning: array<reasoningEntry>,
  /// Validated results (Panel-W feed).
  results: array<validatedResult>,
  /// Current OODA phase for the active task.
  currentPhase: oodaPhase,
  /// Whether this agent is actively processing a task.
  busy: bool,
  /// Current task description (None if idle).
  currentTask: option<string>,
  /// Error message from the last failed operation.
  lastError: option<string>,
}

/// Category tabs for the Tentacles panel — each shows a different view.
type tentaclesCategory =
  /// Individual agent view — shows one agent's 3-panel breakdown.
  | AgentView
  /// Orchestra view — all 7 agents displayed simultaneously in a grid.
  | Orchestra
  /// Stage configuration — set the learner's current stage, affecting all agents.
  | StageConfig
  /// Progress dashboard — completion tracking, favourite agent, stats.
  | Progress

/// Root state for the Tentacles panel module.
type tentaclesState = {
  /// The 7 agent states, one per tentacle colour.
  agents: array<tentacleAgentState>,
  /// Currently selected agent for the AgentView tab.
  selectedAgent: tentacleId,
  /// Active category tab.
  activeCategory: tentaclesCategory,
  /// Global learner stage (affects all agents simultaneously).
  globalStage: tentacleStage,
  /// Whether the orchestra view is in compact mode (icons only).
  orchestraCompact: bool,
  /// Pending broadcast messages waiting to be delivered next tick.
  pendingBroadcasts: array<agentBroadcastPayload>,
  /// Whether the ECHIDNA FFI bridge is connected (for "without" mode).
  ffiConnected: bool,
  /// Last FFI health check timestamp.
  ffiLastCheck: float,
  /// FFI connection error message.
  ffiError: option<string>,
}
