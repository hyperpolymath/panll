// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

/// Msg — Message type for the Clade Portal TEA architecture.
///
/// Every user interaction and async result flows through this type.
/// Messages are dispatched by the view and processed by the update
/// function in App.res.

/// All messages that can occur in the Clade Portal.
type msg =
  // --- Clade loading ---
  | /// Load all clade summaries from disk (initial load).
    LoadClades
  | /// All clade summaries arrived from the filesystem.
    CladesLoaded(result<string, string>)

  // --- Clade selection ---
  | /// User clicked a clade in the tree/list/graph to see its detail.
    SelectClade(string)
  | /// Clade detail response arrived from the filesystem.
    CladeDetailLoaded(result<string, string>)
  | /// User closed the detail panel.
    DeselectClade

  // --- Relationships ---
  | /// Load relationship data for the selected clade.
    LoadRelationships(string)
  | /// Relationship data arrived.
    RelationshipsLoaded(result<string, string>)

  // --- Search ---
  | /// User typed in the search bar.
    UpdateSearchQuery(string)
  | /// User submitted the search (pressed Enter or clicked Search).
    PerformSearch
  | /// Search results arrived.
    SearchResultsLoaded(result<string, string>)
  | /// User cleared the search bar.
    ClearSearch

  // --- View mode ---
  | /// User switched to a different view mode (Tree, List, Graph).
    SetViewMode(Model.viewMode)

  // --- Tree expansion ---
  | /// User expanded a node in the tree view.
    ExpandNode(string)
  | /// User collapsed a node in the tree view.
    CollapseNode(string)

  // --- Health ---
  | /// Check health for a single clade.
    CheckCladeHealth(string)
  | /// Health check result for a single clade.
    CladeHealthLoaded(string, result<string, string>)
  | /// Batch health check for all clades.
    CheckAllHealth
  | /// Batch health results arrived.
    AllHealthLoaded(result<string, string>)

  // --- Gossamer capability tokens ---
  | /// User clicked "Grant" on a capability in the cap panel.
    RequestCapability(string)
  | /// Gossamer runtime granted a capability token.
    CapGranted(string, float)
  | /// Gossamer runtime revoked a capability token.
    CapRevoked(string)
  | /// User dismissed the capability panel.
    DismissCapPanel
  | /// User reopened the capability panel.
    ShowCapPanel

  // --- UI ---
  | /// Clear the current error message.
    ClearError
  | /// No-op message (used for commands that have no followup).
    NoOp
