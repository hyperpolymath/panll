// SPDX-License-Identifier: MPL-2.0

/// Gitbot-Fleet panel messages -- bot status, findings queue, dispatch,
/// and safety triangle navigation.

open Model

type fleetMsg =
  /// Load all fleet data (bots + findings).
  | LoadFleet
  /// Bot status loaded from fleet API.
  | BotsLoaded(result<string, string>)
  /// Findings loaded from fleet API.
  | FindingsLoaded(result<string, string>)
  /// Change the active category tab.
  | SetFleetCategory(fleetCategory)
  /// Update the findings text filter.
  | SetFleetFilter(string)
  /// TypeLL cross-panel type check result for bot dispatch types.
  | TypeCheckResult(result<string, string>)
