// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Agentic Bridge Engine — pure computation and helpers for the
/// Agentic Bridge panel. Provides default state, tab metadata, agent
/// status counting, finding aggregation, and OODA phase formatting.

open AgenticBridgeModel

/// Default state for the Agentic Bridge panel.
/// Starts on the Agents tab with empty agent and config lists.
let defaultState: agenticBridgeState = {
  activeTab: Agents,
  agents: [],
  agentConfigs: [],
  running: false,
  selectedAgent: None,
  error: None,
}

/// Human-readable label for each tab in the Agentic Bridge panel.
let tabLabel = (tab: agenticBridgeTab): string =>
  switch tab {
  | Agents => "Agents"
  | Config => "Config"
  | Execution => "Execution"
  | Results => "Results"
  }

/// All tabs in display order.
let allTabs: array<agenticBridgeTab> = [Agents, Config, Execution, Results]

/// Count agents matching a given operational status.
let countAgentsByStatus = (agents: array<testAgent>, status: agentStatus): int =>
  agents->Array.filter(a => a.status === status)->Array.length

/// Count the total number of findings across all agents.
let countFindings = (agents: array<testAgent>): int =>
  agents->Array.reduce(0, (acc, agent) => acc + Array.length(agent.findings))

/// Count findings by severity across all agents.
let countFindingsBySeverity = (agents: array<testAgent>, severity: findingSeverity): int =>
  agents->Array.reduce(0, (acc, agent) =>
    acc + agent.findings->Array.filter(f => f.severity === severity)->Array.length
  )

/// Human-readable label for an agent operational status.
let agentStatusLabel = (status: agentStatus): string =>
  switch status {
  | AgentIdle => "Idle"
  | AgentRunning => "Running"
  | AgentPaused => "Paused"
  | AgentCompleted => "Completed"
  | AgentFailed => "Failed"
  }

/// Human-readable label for a finding severity.
let findingSeverityLabel = (severity: findingSeverity): string =>
  switch severity {
  | FindingCritical => "Critical"
  | FindingMajor => "Major"
  | FindingMinor => "Minor"
  | FindingObservation => "Observation"
  }

/// Format an OODA phase as a human-readable string with description.
let formatOodaPhase = (phase: agenticOodaPhase): string =>
  switch phase {
  | Observe => "Observe — gathering game state information"
  | Orient => "Orient — analysing observations against patterns"
  | Decide => "Decide — selecting next action"
  | Act => "Act — executing chosen action"
  }

/// Short label for an OODA phase (single word).
let oodaPhaseLabel = (phase: agenticOodaPhase): string =>
  switch phase {
  | Observe => "Observe"
  | Orient => "Orient"
  | Decide => "Decide"
  | Act => "Act"
  }

/// Count total actions performed across all agents.
let countTotalActions = (agents: array<testAgent>): int =>
  agents->Array.reduce(0, (acc, agent) => acc + Array.length(agent.actions))
