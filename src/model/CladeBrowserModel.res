// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Clade Browser Model — types for exploring and customising panel clades.
///
/// A clade is a taxonomic group that defines shared traits, capabilities,
/// and inheritance for panels. The Clade Browser lets users explore all 36+
/// clades, see which panels belong to each, inspect traits, and filter
/// by kind (ai, bridge, builder, database, directive, loader, meta,
/// network, scanner, terminal, viewer).

/// The 11 clade kinds defined in the PanLL taxonomy.
type cladeKind =
  | KindAi
  | KindBridge
  | KindBuilder
  | KindDatabase
  | KindDirective
  | KindLoader
  | KindMeta
  | KindNetwork
  | KindScanner
  | KindTerminal
  | KindViewer
  | KindAll

/// Traits that a clade can confer on its panels.
type cladeTraits = {
  hasPersistence: bool,
  hasBackend: bool,
  hasWorkItems: bool,
  hasRealTime: bool,
  isAmbient: bool,
}

/// A single clade entry in the browser.
type cladeEntry = {
  id: string,
  name: string,
  kind: string,
  version: string,
  summary: string,
  longDescription: string,
  traits: cladeTraits,
  panelIds: array<string>,
  consumedBy: array<string>,
  supersedes: array<string>,
  /// Parent clade ID for trait inheritance (e.g. "bridge" for BoJ).
  parentCladeId: option<string>,
  /// Sibling clades in the taxonomy.
  siblingClades: array<string>,
}

/// Category tabs for the clade browser.
type cladeBrowserCategory =
  | CategoryOverview
  | CategoryByKind
  | CategoryTraits
  | CategoryPanelMap

/// Root state for the clade browser.
type cladeBrowserState = {
  category: cladeBrowserCategory,
  clades: array<cladeEntry>,
  selectedClade: option<string>,
  kindFilter: cladeKind,
  searchQuery: string,
  loading: bool,
  error: option<string>,
}

/// Default initial state.
let defaultState: cladeBrowserState = {
  category: CategoryOverview,
  clades: [],
  selectedClade: None,
  kindFilter: KindAll,
  searchQuery: "",
  loading: false,
  error: None,
}
