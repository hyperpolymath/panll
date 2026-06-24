// SPDX-License-Identifier: MPL-2.0

/// VeriSimDB database backend messages -- connection lifecycle, VCL query
/// execution, entity browsing, drift status retrieval, normalisation,
/// entity detail loading, and opt-in telemetry retrieval for product
/// development insights.

type verisimdbMsg =
  | CheckHealth
  | HealthResult(result<string, string>)
  | SubmitQuery(string)
  | UpdateQueryInput(string)
  | QueryResult(result<string, string>)
  | ListEntities
  | EntitiesLoaded(result<string, string>)
  | SelectEntity(string)
  | DriftLoaded(result<string, string>)
  | ToggleDbMenu
  | ClearQueryResult
  | TriggerNormalise(string)
  | NormaliseResult(result<string, string>)
  | LoadEntityDetail(string)
  | EntityDetailLoaded(result<string, string>)
  | FetchTelemetry
  | TelemetryLoaded(result<string, string>)
  | ToggleTelemetryPanel
  | FetchOrchStatus
  | OrchStatusLoaded(result<string, string>)
  /// TypeLL cross-panel type check result for the last VCL query.
  | VclTypeCheckResult(result<string, string>)
  /// Toggle VCL-total proof obligation display in Panel-L.
  | ToggleProofDisplay
  /// Neural advisor suggestion for the current VCL query.
  | InferenceSuggestion(string)
  /// Clear inference suggestions.
  | ClearInferenceSuggestions
  /// Toggle Anti-Crash VCL validation.
  | ToggleAntiCrashValidation
  /// Toggle BoJ routing for VCL queries (database-mcp cartridge).
  | ToggleVeriSimBojRouting
