// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

/// PanLL Fleet-AgenticBridge Wiring — dispatches Fleet bot actions to
/// AgenticBridge OODA phases and updates agent status on bot task completion.
///
/// When a Fleet bot completes a finding (e.g., echidnabot resolves a security
/// finding), this module maps the bot action into the AgenticBridge's OODA
/// loop so automated playtesting agents can react to fleet-driven changes.
///
/// The mapping is:
///   - Bot finding assigned   -> AgenticBridge agent enters Observe phase
///   - Bot processing finding -> AgenticBridge agent enters Orient phase
///   - Bot applying fix       -> AgenticBridge agent enters Decide phase
///   - Bot resolving finding  -> AgenticBridge agent enters Act + Completed

open Model

/// Map a Fleet bot ID to an AgenticBridge OODA phase based on the bot's
/// current processing stage. Returns the OODA phase and a descriptive action.
let botActionToOodaPhase = (botId: FleetModel.botId, resolved: bool): (oodaPhase, string) => {
  let botName = switch botId {
  | Rhodibot => "rhodibot"
  | Echidnabot => "echidnabot"
  | Sustainabot => "sustainabot"
  | Glambot => "glambot"
  | Seambot => "seambot"
  | Finishbot => "finishbot"
  }
  if resolved {
    (Act, botName ++ " resolved finding — applying changes")
  } else {
    (Observe, botName ++ " assigned finding — observing impact")
  }
}

/// Derive an updated AgenticBridge agent status from a Fleet bot's state.
/// When a bot completes all queued findings, its corresponding agent is
/// marked as Completed. Active bots map to Running agents.
let botStatusToAgentStatus = (botStatus: FleetModel.botStatus): agentStatus => {
  switch botStatus {
  | BotActive => AgentRunning
  | BotIdle => AgentIdle
  | BotOffline => AgentPaused
  | BotError(_) => AgentFailed
  }
}

/// Build a bridge action record from a Fleet finding resolution event.
/// This creates an AgenticBridge action entry that appears in the Execution
/// tab, linking Fleet findings to OODA-phase tracking.
let buildBridgeAction = (finding: FleetModel.fleetFinding, phase: oodaPhase): agentAction => {
  {
    phase,
    description: "Fleet: " ++ finding.summary,
    targetPath: finding.repoName,
    timestampMs: 0.0, // Caller should set actual timestamp
  }
}
