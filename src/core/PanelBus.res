// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Panel Bus — cross-panel event types for inter-module communication.
///
/// When one panel's state change should trigger updates in another panel,
/// the Update loop emits bus events after the sub-updater runs. The main
/// update function inspects these events and dispatches follow-up messages.
///
/// This is a pure data layer — no side effects. Events are value types
/// that describe what happened, not what should happen next.

/// Cross-panel event that one module emits for others to consume.
type panelEvent =
  /// Hypatia completed a scan and routed findings to the fleet.
  | HypatiaFindingsRouted(string) // JSON payload of routed findings
  /// Hypatia updated neural confidence for a repo.
  | HypatiaConfidenceUpdated(string, float) // (repo, confidence)
  /// Git-private-farm repo list was refreshed.
  | FarmRepoListUpdated(int) // count of repos
  /// A repo's health status changed.
  | RepoHealthChanged(string, float) // (repo, healthScore)
  /// Gitbot-fleet dispatched a fix.
  | FleetFixDispatched(string, string) // (repo, fixRecipeId)
  /// Reposystem detected an RSR compliance change.
  | RsrComplianceChanged(string, float) // (repo, newScore)
  /// Database connection status changed.
  | DatabaseConnectionChanged(string, bool) // (dbName, connected)

/// Collect bus events from a sub-updater's state transition.
/// Returns an empty array if no cross-panel effects are needed.
/// The main update loop calls this after each sub-updater and
/// dispatches follow-up messages for any events produced.
///
/// Currently a placeholder — each panel's sub-updater will return
/// events as a second element of its return tuple once implemented.
let noEvents: array<panelEvent> = []
