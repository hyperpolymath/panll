// SPDX-License-Identifier: MPL-2.0

/// PanLL Database Bridge Engine — pure computation and helpers for the
/// Database Bridge panel. Provides default state, tab metadata, schema and
/// query counting, and proof obligation status formatting.

open DatabaseBridgeModel

/// Default state for the Database Bridge panel.
/// Starts on the Schema tab with empty schema, query, and obligation lists.
let defaultState: databaseBridgeState = {
  activeTab: Schema,
  schemas: [],
  queries: [],
  proofObligations: [],
  gameStateSnapshot: None,
  connected: false,
  error: None,
}

/// Human-readable label for each tab in the Database Bridge panel.
let tabLabel = (tab: databaseBridgeTab): string =>
  switch tab {
  | Schema => "Schema"
  | Queries => "Queries"
  | GameState => "Game State"
  | ProofObligations => "Proof Obligations"
  }

/// All tabs in display order.
let allTabs: array<databaseBridgeTab> = [Schema, Queries, GameState, ProofObligations]

/// Count the total number of registered schemas.
let countSchemas = (state: databaseBridgeState): int => Array.length(state.schemas)

/// Count the total number of columns across all schemas.
let countTotalColumns = (schemas: array<schema>): int =>
  schemas->Array.reduce(0, (acc, s) => acc + Array.length(s.columns))

/// Count query history entries.
let countQueries = (state: databaseBridgeState): int => Array.length(state.queries)

/// Count queries by execution status.
let countQueriesByStatus = (queries: array<dbQueryHistoryEntry>, status: queryStatus): int =>
  queries->Array.filter(q => q.status === status)->Array.length

/// Format a proof obligation status as a human-readable string.
let formatObligationStatus = (status: proofObligationStatus): string =>
  switch status {
  | ObligationProven => "Proven"
  | ObligationUnproven => "Unproven"
  | ObligationViolated => "Violated"
  | ObligationTimeout => "Timeout"
  }

/// Count proof obligations by verification status.
let countObligationsByStatus = (
  obligations: array<dbProofObligation>,
  status: proofObligationStatus,
): int => obligations->Array.filter(o => o.status === status)->Array.length

/// Compute the percentage of proven obligations (0.0 to 100.0).
/// Returns 100.0 when there are no obligations.
let proofObligationPercent = (obligations: array<dbProofObligation>): float => {
  let total = Array.length(obligations)
  if total === 0 {
    100.0
  } else {
    let proven = obligations->Array.filter(o => o.status === ObligationProven)->Array.length
    Int.toFloat(proven) /. Int.toFloat(total) *. 100.0
  }
}

/// Summarise a game state snapshot as a human-readable string.
/// Returns "No snapshot" when no snapshot is available.
let formatSnapshotSummary = (snapshot: option<gameStateSnapshot>): string =>
  switch snapshot {
  | None => "No snapshot"
  | Some(s) =>
    `${Int.toString(s.tableCount)} tables, ${Int.toString(s.totalRows)} rows, ${Int.toString(
        s.sizeBytes,
      )} bytes`
  }
