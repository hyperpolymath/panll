// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Agentic Bridge Model — connects AI agent orchestration to IDApTIK
/// game development. Bridges PanLL's agentic testing framework with game
/// exploration, OODA-loop agent execution, and automated quality assurance.
///
/// Three-panel model (L/N/W):
///   L: Test agent parameters (speed, thoroughness, random seed)
///   N: AI agent OODA loop — Observe, Orient, Decide, Act phase tracking
///   W: Agent execution results, findings, and coverage reports
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Tab Navigation
// ============================================================================

/// Category tabs for the Agentic Bridge panel.
type agenticBridgeTab =
  /// Agents — browse and manage test agents.
  | Agents
  /// Config — configure agent parameters and strategies.
  | Config
  /// Execution — monitor running agent OODA loops.
  | Execution
  /// Results — view findings, coverage, and quality reports.
  | Results

// ============================================================================
// OODA Loop
// ============================================================================

/// Phase in the OODA (Observe-Orient-Decide-Act) decision loop.
/// Each test agent cycles through these phases during game exploration.
/// Alias for PaneModel.oodaPhase (shared type, included first in Model.res).
type agenticOodaPhase = PaneModel.oodaPhase

// ============================================================================
// Agent Status and Actions
// ============================================================================

/// Operational status of a test agent.
type agentStatus =
  /// Idle — agent is configured but not running.
  | AgentIdle
  /// Running — agent is actively exploring the game.
  | AgentRunning
  /// Paused — agent execution is suspended.
  | AgentPaused
  /// Completed — agent finished its exploration run.
  | AgentCompleted
  /// Failed — agent encountered a fatal error.
  | AgentFailed

/// Severity of a finding discovered by a test agent.
type findingSeverity =
  /// Critical — game-breaking issue (crash, data loss).
  | FindingCritical
  /// Major — significant gameplay issue.
  | FindingMajor
  /// Minor — cosmetic or low-impact issue.
  | FindingMinor
  /// Observation — informational note, not necessarily a bug.
  | FindingObservation

/// An action performed by a test agent during execution.
type agentAction = {
  /// Action timestamp (milliseconds since agent start).
  timestampMs: float,
  /// OODA phase during which this action occurred.
  phase: agenticOodaPhase,
  /// Description of the action taken.
  description: string,
  /// Game state path affected by this action.
  targetPath: string,
}

/// A finding discovered by a test agent during exploration.
type agentFinding = {
  /// Unique finding identifier.
  id: string,
  /// Severity of this finding.
  severity: findingSeverity,
  /// Short summary of the finding.
  summary: string,
  /// Detailed description of the issue.
  detail: string,
  /// Game state path where the finding was observed.
  location: string,
  /// Steps to reproduce (action descriptions).
  reproSteps: array<string>,
}

/// A test agent instance with its execution state and results.
type testAgent = {
  /// Unique agent identifier.
  id: string,
  /// Human-readable agent name (e.g., "ExplorerBot", "StressTester").
  name: string,
  /// Current operational status.
  status: agentStatus,
  /// Current OODA phase.
  oodaPhase: agenticOodaPhase,
  /// Actions performed during execution.
  actions: array<agentAction>,
  /// Findings discovered during execution.
  findings: array<agentFinding>,
}

// ============================================================================
// Agent Configuration
// ============================================================================

/// Exploration strategy for a test agent.
type explorationStrategy =
  /// Random — agent makes random choices weighted by heuristics.
  | StrategyRandom
  /// Exhaustive — agent systematically explores all reachable states.
  | StrategyExhaustive
  /// Adversarial — agent deliberately tries to break the game.
  | StrategyAdversarial
  /// Replay — agent replays a recorded action sequence.
  | StrategyReplay

/// Configuration parameters for a test agent.
type agentConfig = {
  /// Unique config identifier matching an agent id.
  agentId: string,
  /// Execution speed multiplier (1.0 = real-time).
  speed: float,
  /// Thoroughness level (0.0 = quick scan, 1.0 = exhaustive).
  thoroughness: float,
  /// Random seed for reproducible exploration runs.
  randomSeed: int,
  /// Maximum number of OODA cycles before the agent stops.
  maxCycles: int,
  /// Exploration strategy.
  strategy: explorationStrategy,
}

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Agentic Bridge panel.
type agenticBridgeState = {
  /// Active tab within the Agentic Bridge panel.
  activeTab: agenticBridgeTab,
  /// All registered test agents with their execution state.
  agents: array<testAgent>,
  /// Configuration for each agent.
  agentConfigs: array<agentConfig>,
  /// Whether any agent is currently running.
  running: bool,
  /// Currently selected agent identifier for detail view.
  selectedAgent: option<string>,
  /// Error from the last operation.
  error: option<string>,
}
