// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for the 7-Tentacles compiler agent panel.

open Model

type tentaclesMsg =
  /// Switch the active category tab.
  | SetTentaclesCategory(tentaclesCategory)
  /// Select an agent for the AgentView tab.
  | SelectAgent(tentacleId)
  /// Change the global learner stage.
  | SetGlobalStage(tentacleStage)
  /// Toggle orchestra compact mode.
  | ToggleOrchestraCompact
  /// An agent broadcasts a message to the orchestra.
  | BroadcastFromAgent(tentacleId, agentBroadcastPayload)
  /// Deliver pending broadcasts to all agents.
  | DeliverBroadcasts
  /// Start a task on a specific agent.
  | StartAgentTask(tentacleId, string)
  /// An agent's OODA phase advanced.
  | AgentPhaseAdvanced(tentacleId, oodaPhase)
  /// An agent produced a constraint (Panel-L feed).
  | AgentConstraintAdded(tentacleId, tentacleConstraint)
  /// An agent produced a reasoning entry (Panel-N feed).
  | AgentReasoningAdded(tentacleId, reasoningEntry)
  /// An agent produced a validated result (Panel-W feed).
  | AgentResultAdded(tentacleId, validatedResult)
  /// An agent finished its current task.
  | AgentTaskCompleted(tentacleId)
  /// An agent encountered an error.
  | AgentError(tentacleId, string)
  /// Clear an agent's error state.
  | ClearAgentError(tentacleId)
  /// Check FFI bridge health (ECHIDNA "without" mode).
  | CheckFfiBridge
  /// FFI bridge health check result.
  | FfiBridgeResult(bool, option<string>)
  /// TypeLL cross-panel type check result for agent task types.
  | TypeCheckResult(result<string, string>)
