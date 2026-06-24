// SPDX-License-Identifier: MPL-2.0

/// PanLL Databases Model — types for the unified database management panel.
///
/// Composes DatabaseModule + DatabaseRegistry into a panel-level state that
/// manages VeriSimDB, QuandleDB, and LithoGlyph in a single view with
/// per-module connection, querying, drift detection, and telemetry.
///
/// Dependency: leaf module — imports only DatabaseModule (which has no deps).

open DatabaseModule

// ============================================================================
// Panel Tabs
// ============================================================================

/// Category tabs for the Databases panel.
type databasesCategory =
  /// Overview — connection status, health cards, capability matrix.
  | DbDashboard
  /// Query console — unified editor with per-module language switching.
  | DbQuery
  /// Schema browser — entity lists, table structure, modality details.
  | DbSchema
  /// Drift monitor — cross-modal drift heatmap and normalisation controls.
  | DbDrift
  /// Telemetry — aggregate usage metrics per module (opt-in).
  | DbTelemetry

// ============================================================================
// Query History
// ============================================================================

/// A single entry in the query history log.
type queryHistoryEntry = {
  /// Which database module ran the query.
  moduleId: string,
  /// The query text.
  query: string,
  /// Execution time in ms.
  durationMs: float,
  /// Row count returned.
  rowCount: int,
  /// Whether the query succeeded.
  success: bool,
  /// ISO timestamp.
  timestamp: string,
}

// ============================================================================
// Schema Types
// ============================================================================

/// A schema entity (table, collection, modality store).
type schemaEntity = {
  /// Entity name.
  name: string,
  /// Entity kind (e.g., "table", "modality", "collection", "graph").
  kind: string,
  /// Column/field names.
  fields: array<string>,
  /// Row/document/entry count.
  entryCount: int,
}

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Databases panel.
type databasesState = {
  /// Per-module runtime state indexed by module ID.
  modules: array<moduleState>,
  /// Currently selected module ID (e.g., "verisim").
  selectedModule: string,
  /// Active category tab.
  activeCategory: databasesCategory,
  /// Current query text in the editor.
  queryInput: string,
  /// Whether a query is currently executing.
  queryLoading: bool,
  /// Query history (most recent first, capped at 100).
  queryHistory: array<queryHistoryEntry>,
  /// Schema entities for the selected module.
  schemaEntities: array<schemaEntity>,
  /// Selected entity name for detail view.
  selectedEntity: option<string>,
  /// Entity detail JSON (loaded on selection).
  entityDetail: option<string>,
  /// Filter text for schema browser.
  filterText: string,
  /// Overall loading state.
  loading: bool,
  /// Panel-level error.
  error: option<string>,
  /// TypeLL cross-panel type-check result JSON.
  lastTypeCheck: option<string>,
  /// Route queries through BoJ's database-mcp cartridge.
  bojRouting: bool,
}
