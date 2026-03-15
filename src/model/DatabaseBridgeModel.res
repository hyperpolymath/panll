// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Database Bridge Model — connects VeriSimDB verified database layer to
/// IDApTIK game development. Bridges formal schema verification with game
/// state persistence, query optimisation reasoning, and proof obligations
/// for data integrity.
///
/// Three-panel model (L/N/W):
///   L: VeriSimDB schema constraints, proof obligations for data integrity
///   N: Query optimisation reasoning via ECHIDNA analysis
///   W: Game state persistence viewer with live snapshots
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Tab Navigation
// ============================================================================

/// Category tabs for the Database Bridge panel.
type databaseBridgeTab =
  /// Schema — browse and define VeriSimDB schemas with constraints.
  | Schema
  /// Queries — query history, execution, and optimisation suggestions.
  | Queries
  /// GameState — live game state persistence viewer.
  | GameState
  /// ProofObligations — formal proof obligations for schema integrity.
  | ProofObligations

// ============================================================================
// Schema Domain
// ============================================================================

/// Data type of a schema column in VeriSimDB.
type columnDataType =
  /// Integer (signed, platform-width).
  | ColInt
  /// Floating-point number.
  | ColFloat
  /// UTF-8 string with optional max length.
  | ColString
  /// Boolean flag.
  | ColBool
  /// Timestamp (milliseconds since epoch).
  | ColTimestamp
  /// Binary blob.
  | ColBlob
  /// JSON document.
  | ColJson

/// A column definition within a VeriSimDB schema.
type schemaColumn = {
  /// Column name.
  name: string,
  /// Data type.
  dataType: columnDataType,
  /// Whether this column may be null.
  nullable: bool,
  /// Whether this column is part of the primary key.
  primaryKey: bool,
  /// Constraint expression (e.g., "value > 0", "length <= 255").
  @as("constraint") constraint_: option<string>,
}

/// A VeriSimDB schema definition for a game data table.
type schema = {
  /// Schema/table name (e.g., "player_state", "inventory_items").
  name: string,
  /// Column definitions.
  columns: array<schemaColumn>,
  /// Cross-column invariants (e.g., "health <= max_health").
  invariants: array<string>,
  /// Description of what this schema stores.
  description: string,
}

// ============================================================================
// Query History
// ============================================================================

/// Status of a query execution.
type queryStatus =
  /// Query completed successfully.
  | QuerySuccess
  /// Query failed with an error.
  | QueryFailed
  /// Query is currently executing.
  | QueryRunning
  /// Query was cancelled.
  | QueryCancelled

/// A query history entry recording an executed query and its result.
type dbQueryHistoryEntry = {
  /// Unique query identifier.
  id: string,
  /// The SQL or VeriSimDB query text.
  queryText: string,
  /// Execution status.
  status: queryStatus,
  /// Number of rows returned or affected.
  rowCount: int,
  /// Execution duration in milliseconds.
  durationMs: float,
  /// Timestamp when the query was executed (milliseconds since epoch).
  executedAt: float,
  /// Optimisation suggestions from ECHIDNA reasoning.
  optimisationHints: array<string>,
}

// ============================================================================
// Proof Obligations
// ============================================================================

/// Verification status of a proof obligation.
type proofObligationStatus =
  /// Proven — ECHIDNA verified the obligation holds.
  | ObligationProven
  /// Unproven — obligation has not been checked yet.
  | ObligationUnproven
  /// Violated — ECHIDNA found a counterexample.
  | ObligationViolated
  /// Timeout — verification timed out.
  | ObligationTimeout

/// A formal proof obligation arising from schema constraints.
type dbProofObligation = {
  /// Unique obligation identifier.
  id: string,
  /// The schema this obligation applies to.
  schemaName: string,
  /// Formal statement of the obligation.
  statement: string,
  /// Verification status.
  status: proofObligationStatus,
  /// Counterexample if violated.
  counterexample: option<string>,
  /// Human-readable description.
  description: string,
}

// ============================================================================
// Game State Snapshot
// ============================================================================

/// A snapshot of persisted game state from VeriSimDB.
type gameStateSnapshot = {
  /// Snapshot identifier.
  snapshotId: string,
  /// Timestamp when the snapshot was taken (milliseconds since epoch).
  takenAt: float,
  /// Number of tables in this snapshot.
  tableCount: int,
  /// Total number of rows across all tables.
  totalRows: int,
  /// Size in bytes.
  sizeBytes: int,
  /// Per-table row counts as (table_name, row_count) pairs.
  tableSizes: array<(string, int)>,
}

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Database Bridge panel.
type databaseBridgeState = {
  /// Active tab within the Database Bridge panel.
  activeTab: databaseBridgeTab,
  /// All registered VeriSimDB schemas.
  schemas: array<schema>,
  /// Query execution history (most recent first).
  queries: array<dbQueryHistoryEntry>,
  /// Formal proof obligations for schema integrity.
  proofObligations: array<dbProofObligation>,
  /// Most recent game state snapshot.
  gameStateSnapshot: option<gameStateSnapshot>,
  /// Whether VeriSimDB is connected.
  connected: bool,
  /// Error from the last operation.
  error: option<string>,
}
