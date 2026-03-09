// SPDX-License-Identifier: PMPL-1.0-or-later

/// DatabaseRegistry — manages registered database modules in PanLL.
///
/// Each database (VeriSimDB, QuandleDB, LithoGlyph) registers its module
/// configuration here. PanLL uses the registry to:
///
///   1. Discover available database backends
///   2. Render capability-appropriate UI per module
///   3. Route Tauri commands to the correct backend
///   4. Manage the playground gallery (one playground per query language)
///
/// ## Module lifecycle
///
///   1. Module config defined in this file
///   2. `allModules()` returns the list of registered modules
///   3. PanLL initialises a `moduleState` per module via `DatabaseModule.initModuleState`
///   4. Tauri commands are dispatched by module ID
///
/// ## Adding a new database
///
///   1. Define its `moduleConfig` below
///   2. Add it to the `allModules` function
///   3. Implement Tauri commands (prefixed with the module ID)

open DatabaseModule

/// VeriSimDB — octad multimodal database with drift detection, self-normalisation,
/// and formally verified queries across 8 modalities.
let verisimdb: moduleConfig = {
  id: "verisimdb",
  name: "VeriSimDB",
  version: "0.1.0-beta",
  description: "Octad multimodal database with cross-modal drift detection",
  endpoint: ServiceEndpoints.verisimdb,
  capabilities: [
    QueryExecution,
    DriftDetection,
    ProofGeneration,
    Normalisation,
    Federation,
    Telemetry,
    Playground,
  ],
  playground: Some({
    languageName: "VQL",
    languageVersion: "1.0",
    fileExtension: ".vql",
    keywords: [
      "SELECT", "FROM", "WHERE", "LIMIT", "OFFSET", "ORDER", "BY",
      "INSERT", "INTO", "UPDATE", "SET", "DELETE",
      "GRAPH", "VECTOR", "TENSOR", "SEMANTIC", "DOCUMENT", "TEMPORAL", "PROVENANCE", "SPATIAL",
      "PROOF", "EXPLAIN", "SHOW", "STATUS", "DRIFT", "SEARCH", "TEXT", "COUNT",
      "TRAVERSE", "DEPTH", "RELATED", "WITHIN", "RADIUS", "BOUNDS", "NEAREST",
      "FEDERATION", "STORE", "NORMALIZER", "THRESHOLD", "CONSISTENCY",
    ],
    exampleQueries: [
      { label: "List octads", query: "SELECT * FROM octads LIMIT 10", isDependentType: false },
      { label: "Graph query", query: "SELECT GRAPH.* FROM HEXAD 'entity-123'", isDependentType: false },
      { label: "Full-text search", query: "SEARCH TEXT 'example query' LIMIT 20", isDependentType: false },
      { label: "Show drift", query: "SHOW DRIFT", isDependentType: false },
      { label: "Existence proof", query: "SELECT SEMANTIC.* FROM HEXAD 'entity-1' PROOF EXISTENCE(entity-1)", isDependentType: true },
      { label: "Multi-proof", query: "SELECT * FROM octads PROOF EXISTENCE(e) AND INTEGRITY(e) AND FRESHNESS(e) LIMIT 5", isDependentType: true },
    ],
    hasDependentTypes: true,
    linterAvailable: true,
    formatterAvailable: true,
  }),
  icon: Some("octad"),
}

/// QuandleDB — algebraic query language for quandle-structured data.
/// (Planned — module config ready for when KQL is implemented.)
let quandledb: moduleConfig = {
  id: "quandledb",
  name: "QuandleDB",
  version: "0.0.1-alpha",
  description: "Algebraic database with quandle-structured queries",
  endpoint: ServiceEndpoints.quandledb,
  capabilities: [
    QueryExecution,
    Playground,
  ],
  playground: Some({
    languageName: "KQL",
    languageVersion: "0.1-draft",
    fileExtension: ".kql",
    keywords: [
      "QUANDLE", "RACK", "BIQUANDLE", "INVARIANT",
      "SELECT", "FROM", "WHERE", "COMPUTE",
      "COLOUR", "KNOT", "LINK", "CROSSING",
    ],
    exampleQueries: [
      { label: "List quandles", query: "SELECT * FROM quandles LIMIT 10", isDependentType: false },
      { label: "Compute invariant", query: "COMPUTE INVARIANT FOR KNOT '3_1'", isDependentType: false },
    ],
    hasDependentTypes: false,
    linterAvailable: false,
    formatterAvailable: false,
  }),
  icon: Some("quandle"),
}

/// LithoGlyph — graph query language for petroglyph pattern databases.
/// (Planned — module config ready for when GQL is implemented.)
let lithoglyph: moduleConfig = {
  id: "lithoglyph",
  name: "LithoGlyph",
  version: "0.0.1-alpha",
  description: "Graph pattern database for archaeological petroglyphs",
  endpoint: ServiceEndpoints.lithoglyph,
  capabilities: [
    QueryExecution,
    Playground,
  ],
  playground: Some({
    languageName: "GQL",
    languageVersion: "0.1-draft",
    fileExtension: ".gql",
    keywords: [
      "MATCH", "PATTERN", "GLYPH", "MOTIF", "SITE",
      "SELECT", "FROM", "WHERE", "TRAVERSE",
      "SIMILAR", "WITHIN", "REGION",
    ],
    exampleQueries: [
      { label: "List glyphs", query: "SELECT * FROM glyphs LIMIT 10", isDependentType: false },
      { label: "Pattern match", query: "MATCH PATTERN 'spiral' SIMILAR 0.8", isDependentType: false },
    ],
    hasDependentTypes: false,
    linterAvailable: false,
    formatterAvailable: false,
  }),
  icon: Some("glyph"),
}

/// Return all registered database modules. PanLL iterates this list
/// to initialise module states, render the module gallery, and populate
/// the playground gallery.
let allModules = (): array<moduleConfig> => {
  [verisimdb, quandledb, lithoglyph]
}

/// Find a module config by its ID. Returns None if not registered.
let findModule = (id: string): option<moduleConfig> => {
  allModules()->Array.find(m => m.id == id)
}

/// Return only modules that support a given capability.
let modulesWithCapability = (cap: capability): array<moduleConfig> => {
  allModules()->Array.filter(m => hasCapability(m, cap))
}

/// Return all modules that have a playground configuration — these
/// form the "playground gallery" in PanLL.
let playgroundModules = (): array<moduleConfig> => {
  modulesWithCapability(Playground)
}

/// Return all modules that expose telemetry — these get a telemetry
/// dashboard panel in Pane-W.
let telemetryModules = (): array<moduleConfig> => {
  modulesWithCapability(Telemetry)
}
