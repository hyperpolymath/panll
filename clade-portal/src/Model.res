// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

/// Model — Application state for the Clade Portal.
///
/// Holds the complete UI state for browsing PanLL's 100+ panel clades.
/// The portal provides three view modes (tree, list, graph), a search
/// facility, and live health indicators for each clade's panels.
///
/// Capability tokens are the central security mechanism: filesystem access
/// is required to read clade metadata, and network access is required to
/// check panel health.

// ---------------------------------------------------------------------------
// View mode
// ---------------------------------------------------------------------------

/// How the clade taxonomy is displayed in the main content area.
type viewMode =
  | /// Hierarchical tree with expandable nodes grouped by kind.
    Tree
  | /// Flat alphabetical list with sortable columns.
    List
  | /// Force-directed graph showing relationships between clades.
    Graph

// ---------------------------------------------------------------------------
// Health status
// ---------------------------------------------------------------------------

/// Health status of a clade's panels.
type healthStatus =
  | /// All panels in the clade are responding normally.
    Healthy
  | /// Some panels are slow or partially available.
    Degraded
  | /// No panels are responding or all have errors.
    Unhealthy
  | /// Health has not been checked yet (no network token, or not loaded).
    Unknown

// ---------------------------------------------------------------------------
// Clade types
// ---------------------------------------------------------------------------

/// Summary information for a single clade, displayed in lists and trees.
type cladeSummary = {
  /// Clade identifier (directory name, e.g. "ai", "databases").
  id: string,
  /// Human-readable display name.
  name: string,
  /// Clade kind (directive, scanner, builder, database, network, etc.).
  kind: string,
  /// Icon identifier (maps to Lucide icon set).
  icon: string,
  /// Short description of what the clade does.
  description: string,
  /// Number of panels registered in this clade.
  panelCount: int,
  /// Current health status of the clade's panels.
  health: healthStatus,
}

/// Trait flags from the clade's [clade-traits] section.
type cladeTraits = {
  /// Whether the clade connects to a backend service.
  hasBackend: bool,
  /// Whether the clade performs scanning/analysis.
  hasScanning: bool,
  /// Whether the clade persists data across sessions.
  hasPersistence: bool,
  /// Whether the clade generates work items.
  hasWorkItems: bool,
  /// Whether the clade defines priority ordering for other panels.
  hasPriorityOrdering: bool,
  /// Whether the clade supports user customisation.
  hasCustomisation: bool,
  /// Whether the clade is a directive (controls other panels).
  isDirective: bool,
  /// Whether the clade is read-only (reports but does not modify).
  isReadonly: bool,
}

/// Relationship data between clades.
type cladeRelationships = {
  /// Parent clade ID, if this clade is part of a hierarchy.
  parent: option<string>,
  /// Child clade IDs that inherit from this clade.
  children: array<string>,
  /// Sibling clades of the same kind.
  siblings: array<string>,
  /// Clades that this one depends on.
  dependencies: array<string>,
  /// Clades that depend on this one.
  dependents: array<string>,
}

/// Full detail for a single clade, shown in the detail panel.
type cladeDetail = {
  /// Core metadata from [clade-metadata].
  id: string,
  /// Human-readable display name.
  name: string,
  /// Short name for compact UI elements.
  shortName: string,
  /// Semantic version of the clade definition.
  version: string,
  /// Clade kind (directive, scanner, builder, etc.).
  kind: string,
  /// Icon identifier.
  icon: string,
  /// Full description.
  description: string,
  /// Trait flags from [clade-traits].
  traits: cladeTraits,
  /// Capability strings from [clade-capabilities].
  capabilities: array<string>,
  /// Panel integration identifiers from [clade-panel-integration].
  panelId: option<string>,
  /// Model module name.
  modelModule: option<string>,
  /// Component module name.
  componentModule: option<string>,
  /// Command module name.
  commandModule: option<string>,
  /// Relationships to other clades.
  relationships: cladeRelationships,
  /// Whether a config.k9.ncl file exists for this clade.
  hasK9Config: bool,
  /// Whether a README.adoc file exists for this clade.
  hasReadme: bool,
  /// Current health status.
  health: healthStatus,
}

/// A search result entry returned by full-text clade search.
type searchResult = {
  /// Matching clade ID.
  cladeId: string,
  /// Clade display name.
  name: string,
  /// Clade kind.
  kind: string,
  /// Which field matched the query.
  matchField: string,
  /// Context snippet around the match.
  matchSnippet: string,
  /// Relevance score (higher = better match).
  score: float,
}

// ---------------------------------------------------------------------------
// Capability status
// ---------------------------------------------------------------------------

/// Capability token status for Gossamer security.
/// Each capability must be explicitly granted by the runtime before use.
type capabilityStatus =
  | /// Not yet requested from the runtime.
    NotRequested
  | /// Request sent, awaiting runtime grant.
    Pending
  | /// Granted with a token. The float is the token value.
    Granted(float)
  | /// Runtime denied the capability request.
    Denied

// ---------------------------------------------------------------------------
// Application model
// ---------------------------------------------------------------------------

/// Complete application state for the Clade Portal.
type model = {
  /// All clade summaries loaded from disk.
  clades: array<cladeSummary>,
  /// Currently selected clade with full detail, if any.
  selectedClade: option<cladeDetail>,
  /// Current search query string (empty = no active search).
  searchQuery: string,
  /// Search results from the last query.
  searchResults: array<searchResult>,
  /// Current view mode for the main content area.
  viewMode: viewMode,
  /// Set of clade IDs whose tree nodes are expanded.
  expandedNodes: array<string>,
  /// Whether the initial clade list has been loaded.
  isLoading: bool,
  /// Filesystem capability token — required to read clade files.
  filesystemCap: capabilityStatus,
  /// Network capability token — required for health checks.
  networkCap: capabilityStatus,
  /// Error message to display in the UI, if any.
  error: option<string>,
  /// Whether the capability grant panel is visible.
  showCapPanel: bool,
  /// Health status map: clade ID -> health status (from batch check).
  healthMap: array<(string, healthStatus)>,
}

/// Initial application state. Starts with no capabilities granted,
/// forcing the user to explicitly authorise filesystem and network
/// access through the Gossamer capability token system.
let initial: model = {
  clades: [],
  selectedClade: None,
  searchQuery: "",
  searchResults: [],
  viewMode: Tree,
  expandedNodes: [],
  isLoading: false,
  filesystemCap: NotRequested,
  networkCap: NotRequested,
  error: None,
  showCapPanel: true,
  healthMap: [],
}
