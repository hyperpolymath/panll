// SPDX-License-Identifier: PMPL-1.0-or-later

/// Aerie network diagnostics messages.

open Model

type aerieMsg =
  | LoadAerie
  | LatencyLoaded(result<string, string>)
  | SpeedTestLoaded(result<string, string>)
  | SetAerieCategory(aerieCategory)
  /// Toggle BoJ routing for overlay operations (observe-mcp cartridge).
  | ToggleAerieBojRouting
  /// Toggle a probe target on/off by endpoint.
  | ToggleProbe(string)
  /// TypeLL cross-panel type check result for network config types.
  | TypeCheckResult(result<string, string>)
