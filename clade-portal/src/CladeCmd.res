// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

/// CladeCmd — Backend command dispatch for the Clade Portal.
///
/// Each function wraps a Gossamer IPC call to read clade metadata from the
/// filesystem or check panel health over the network. Filesystem commands
/// require a valid filesystem capability token; health commands require a
/// network capability token.
///
/// The commands operate on the PanLL panel-clades directory structure:
///   panel-clades/clades/{clade-id}/
///     *.a2ml        — Clade metadata (A2ML format)
///     config.k9.ncl — K9 kennel configuration (Nickel)
///     README.adoc   — Human-readable documentation
///
/// Gossamer acts as the filesystem proxy — the webview never makes direct
/// file I/O calls. Instead, each command goes through IPC to the Gossamer
/// Zig runtime, which holds the filesystem capability and reads from disk.

/// The base path to the panel-clades directory on disk.
/// This is the canonical location in the PanLL monorepo.
let _cladesBasePath = "/var/mnt/eclipse/repos/panll/panel-clades/clades"

// ---------------------------------------------------------------------------
// Directory listing
// ---------------------------------------------------------------------------

/// List all clade directories under the panel-clades path.
///
/// Returns a JSON array of directory entry objects, each containing:
///   - name: string — the directory name (clade ID)
///   - isDirectory: bool — always true for valid clades
///
/// Excludes hidden files and the _basics template directory.
/// Requires a filesystem capability token.
let listClades = (token: float): promise<string> => {
  RuntimeBridge.invokeWithToken(
    "clade_list_directories",
    {"path": _cladesBasePath, "excludePatterns": ["_basics", "README.adoc"]},
    token,
  )
}

// ---------------------------------------------------------------------------
// Clade detail
// ---------------------------------------------------------------------------

/// Read the full detail of a specific clade.
///
/// Reads and parses all A2ML files in the clade directory, returning
/// the combined metadata as a JSON string. The response includes:
///   - id, name, shortName, version, kind, icon, description
///   - traits: hasBackend, hasScanning, hasPersistence, etc.
///   - capabilities: array of capability strings
///   - panelIntegration: panelId, modelModule, componentModule, etc.
///   - hasK9Config: whether a config.k9.ncl file exists
///   - hasReadme: whether a README.adoc file exists
///
/// @param cladeId - The clade directory name (e.g. "ai", "databases")
let getCladeDetail = (cladeId: string, token: float): promise<string> => {
  RuntimeBridge.invokeWithToken(
    "clade_read_detail",
    {"path": `${_cladesBasePath}/${cladeId}`, "cladeId": cladeId},
    token,
  )
}

// ---------------------------------------------------------------------------
// Relationships
// ---------------------------------------------------------------------------

/// Get parent/child/sibling relationships for a clade.
///
/// Analyses the clade's kind, capabilities, and connections sections to
/// determine its position in the taxonomy. Returns a JSON object with:
///   - parent: option<string> — parent clade ID if hierarchical
///   - children: array<string> — child clade IDs
///   - siblings: array<string> — clades of the same kind
///   - dependencies: array<string> — clades this one depends on
///   - dependents: array<string> — clades that depend on this one
///
/// @param cladeId - The clade directory name
let getCladeRelationships = (cladeId: string, token: float): promise<string> => {
  RuntimeBridge.invokeWithToken(
    "clade_get_relationships",
    {"path": _cladesBasePath, "cladeId": cladeId},
    token,
  )
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

/// Full-text search across all clade metadata.
///
/// Searches clade names, descriptions, capability lists, and kind fields
/// for the given query string. Returns a JSON array of match objects:
///   - cladeId: string — the matching clade
///   - name: string — clade display name
///   - kind: string — clade kind
///   - matchField: string — which field matched (name, description, etc.)
///   - matchSnippet: string — context around the match
///   - score: float — relevance score (higher = better match)
///
/// @param query - The search query string (case-insensitive substring match)
let searchClades = (query: string, token: float): promise<string> => {
  RuntimeBridge.invokeWithToken(
    "clade_search",
    {"path": _cladesBasePath, "query": query},
    token,
  )
}

// ---------------------------------------------------------------------------
// Health
// ---------------------------------------------------------------------------

/// Check the health of panels belonging to a clade.
///
/// For each panel registered in the clade's panel-integration section,
/// this command attempts to contact the panel's health endpoint (if the
/// panel has a backend). Returns a JSON object with:
///   - cladeId: string — the clade checked
///   - panelHealth: array of { panelId, status, latencyMs, lastCheck }
///   - overallStatus: "healthy" | "degraded" | "unhealthy" | "unknown"
///
/// Requires a network capability token (panels may run on localhost or
/// remote services).
///
/// @param cladeId - The clade to check health for
let getCladeHealth = (cladeId: string, token: float): promise<string> => {
  RuntimeBridge.invokeWithToken(
    "clade_check_health",
    {"cladeId": cladeId},
    token,
  )
}

// ---------------------------------------------------------------------------
// Batch operations
// ---------------------------------------------------------------------------

/// Load summary data for all clades in a single IPC call.
///
/// This is an optimised path for the initial portal load. Instead of
/// calling listClades + getCladeDetail for each clade (100+ IPC calls),
/// this command reads all clade directories and extracts summary fields
/// (id, name, kind, icon, description, panelCount) in one pass.
///
/// Returns a JSON array of clade summary objects.
let loadAllCladeSummaries = (token: float): promise<string> => {
  RuntimeBridge.invokeWithToken(
    "clade_load_all_summaries",
    {"path": _cladesBasePath},
    token,
  )
}

/// Batch health check for all clades with backends.
///
/// Checks health of all clades that have hasBackend = true in their
/// traits. Returns a JSON object mapping clade IDs to health status.
///
/// Requires a network capability token.
let checkAllCladeHealth = (token: float): promise<string> => {
  RuntimeBridge.invokeWithToken(
    "clade_check_all_health",
    {"path": _cladesBasePath},
    token,
  )
}
