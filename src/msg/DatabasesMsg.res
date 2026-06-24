// SPDX-License-Identifier: MPL-2.0

/// Databases panel messages -- unified VeriSimDB/QuandleDB/LithoGlyph management.

open Model

type databasesMsg =
  /// Switch the active category tab.
  | SetCategory(databasesCategory)
  /// Select a database module by ID.
  | SelectModule(string)
  /// Connect to all database backends.
  | ConnectAll
  /// Refresh health/connection status for all modules.
  | RefreshHealth
  /// Health check result for a module.
  | HealthResult(string, result<string, string>)
  /// Set the query input text.
  | SetQueryInput(string)
  /// Execute the current query against the selected module.
  | ExecuteQuery
  /// Query execution result.
  | QueryResult(result<string, string>)
  /// Clear the query input and result.
  | ClearQuery
  /// Load an example query into the editor.
  | LoadExampleQuery(string)
  /// Set the schema filter text.
  | SetFilter(string)
  /// Select a schema entity for detail view.
  | SelectEntity(string)
  /// Load entity detail JSON.
  | LoadEntityDetail(string)
  /// Entity detail result.
  | EntityDetailResult(result<string, string>)
  /// Refresh drift scores for the selected module.
  | RefreshDrift
  /// Drift scores result.
  | DriftResult(result<string, string>)
  /// Normalise all drifted modalities.
  | NormaliseAll
  /// Normalisation result.
  | NormaliseResult(result<string, string>)
  /// Load telemetry snapshot.
  | LoadTelemetry
  /// Telemetry snapshot result.
  | TelemetryResult(result<string, string>)
  /// Toggle BoJ cartridge routing.
  | ToggleBojRouting
  /// Dismiss error banner.
  | DismissError
