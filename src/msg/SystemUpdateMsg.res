// SPDX-License-Identifier: PMPL-1.0-or-later

/// System Update panel messages — component listing, update checking,
/// update application, asdf details, log viewing.

type systemUpdateMsg =
  // Component listing
  | ListComponents
  | ComponentsLoaded(result<string, string>)
  // Check for updates
  | CheckAll
  | CheckAllResult(result<string, string>)
  | CheckComponent(string)
  | CheckComponentResult(result<string, string>)
  // Apply updates
  | ApplyComponent(string)
  | ApplyComponentResult(result<string, string>)
  | ApplyAll
  | ApplyAllResult(result<string, string>)
  // asdf details
  | AsdfStatus
  | AsdfStatusResult(result<string, string>)
  // Logs
  | ViewLogs
  | LogsLoaded(result<string, string>)
  // Summary
  | LastSummary
  | LastSummaryResult(result<string, string>)
  // UI state
  | ToggleShowLogs
