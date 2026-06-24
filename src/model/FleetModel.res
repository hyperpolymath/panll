// SPDX-License-Identifier: MPL-2.0

/// PanLL Fleet Model — types for the Gitbot-Fleet panel.
///
/// The Fleet panel shows the 6-bot gitbot-fleet orchestration system:
/// rhodibot, echidnabot, sustainabot, glambot, seambot, finishbot.
/// Each bot has a status, findings queue, and dispatch history.
/// The safety triangle (Eliminate/Substitute/Control) visualises
/// how findings are routed through the fleet.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Individual bot identity within the fleet.
type botId =
  /// Rhodibot — code quality and style enforcement.
  | Rhodibot
  /// Echidnabot — security vulnerability detection.
  | Echidnabot
  /// Sustainabot — dependency health and sustainability.
  | Sustainabot
  /// Glambot — documentation and presentation quality.
  | Glambot
  /// Seambot — integration and API compatibility.
  | Seambot
  /// Finishbot — completion verification and release readiness.
  | Finishbot

/// Operational status of an individual bot.
type botStatus =
  /// Bot is running and processing findings.
  | BotActive
  /// Bot is idle, waiting for work.
  | BotIdle
  /// Bot is offline or unreachable.
  | BotOffline
  /// Bot encountered an error.
  | BotError(string)

/// A single bot's state snapshot from the fleet dashboard API.
type botState = {
  /// Which bot this is.
  id: botId,
  /// Current operational status.
  status: botStatus,
  /// Number of findings currently queued for this bot.
  queuedFindings: int,
  /// Number of findings processed in the current cycle.
  processedFindings: int,
  /// Confidence threshold for autonomous action (0.0–1.0).
  confidenceThreshold: float,
  /// Last activity timestamp (ISO 8601 string).
  lastActivity: string,
}

/// Safety triangle tier — how findings are categorised for routing.
/// Based on the hierarchy of controls: Eliminate > Substitute > Control.
type safetyTier =
  /// Eliminate — remove the hazard entirely (e.g. delete vulnerable dependency).
  | Eliminate
  /// Substitute — replace with a safer alternative (e.g. swap library).
  | Substitute
  /// Control — mitigate the risk (e.g. add input validation, pin version).
  | Control

/// A finding from the Hypatia scanner, routed through the fleet.
type fleetFinding = {
  /// Unique finding identifier.
  id: string,
  /// Which repo this finding came from.
  repoName: string,
  /// Short description of the finding.
  summary: string,
  /// Safety triangle tier for routing.
  tier: safetyTier,
  /// Neural confidence score from Hypatia (0.0–1.0).
  confidence: float,
  /// Which bot is assigned to handle this finding (None = unassigned).
  assignedBot: option<botId>,
  /// Whether the finding has been resolved.
  resolved: bool,
}

/// Fleet health summary — aggregate metrics.
type fleetHealth = {
  /// Number of bots currently active.
  activeBots: int,
  /// Total findings in all queues.
  totalQueued: int,
  /// Total findings processed in current cycle.
  totalProcessed: int,
  /// Average confidence across all queued findings.
  avgConfidence: float,
  /// Safety triangle counts: (eliminate, substitute, control).
  triangleCounts: (int, int, int),
}

/// Category tabs for the Fleet panel.
type fleetCategory =
  /// Overview dashboard with bot grid and safety triangle.
  | FleetDashboard
  /// Findings queue with filtering and assignment.
  | FleetFindings
  /// Dispatch history and audit log.
  | FleetDispatch

/// Root state for the Gitbot-Fleet panel.
type fleetState = {
  /// Whether fleet data has been loaded.
  loaded: bool,
  /// Whether a loading operation is in progress.
  loading: bool,
  /// Error from the last operation.
  error: option<string>,
  /// The 6 bots and their current state.
  bots: array<botState>,
  /// Current findings in the queue.
  findings: array<fleetFinding>,
  /// Aggregate health metrics.
  health: option<fleetHealth>,
  /// Active category tab.
  activeCategory: fleetCategory,
  /// Text filter for findings search.
  filterText: string,
}
