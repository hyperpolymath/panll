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

/// Empty event array for sub-updaters with no cross-panel effects.
let noEvents: array<panelEvent> = []

/// Governance-originated events — emitted by the post-update governance
/// pass when contractile compliance, orbital stability, or database
/// connection state changes. These allow consumer panels (Hypatia, Fleet,
/// Reposystem) to react to cross-cutting state transitions.

/// Anti-Crash violation spike detected — governance tightened constraints.
type governanceEvent =
  /// Contractile compliance score changed (0.0–1.0).
  | ComplianceChanged(float)
  /// Orbital stability changed significantly.
  | StabilityChanged(float)
  /// Inference was halted by governance.
  | InferenceHalted(string) // reason
  /// Inference was resumed by governance.
  | InferenceResumed
  /// Humidity level was adjusted.
  | HumidityAdjusted(Model.humidityLevel)

/// Convert a governance event to a panel event for bus routing.
let governanceToPanel = (evt: governanceEvent): panelEvent => {
  switch evt {
  | ComplianceChanged(score) => RsrComplianceChanged("contractiles", score)
  | StabilityChanged(score) => RepoHealthChanged("panll-orbit", score)
  | InferenceHalted(_) => RepoHealthChanged("panll-inference", 0.0)
  | InferenceResumed => RepoHealthChanged("panll-inference", 1.0)
  | HumidityAdjusted(_) => RepoHealthChanged("panll-humidity", 1.0)
  }
}
