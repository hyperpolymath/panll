// SPDX-License-Identifier: MPL-2.0

/// DatabaseModule — standard protocol for database backends in PanLL.
///
/// Every database (VeriSimDB, QuandleDB, LithoGlyph, etc.) implements this
/// protocol to plug into PanLL's three-pane model:
///
///   Pane-L (Symbolic):  grammar rules, type system, constraints
///   Pane-N (Neural):    query engine, inference, reasoning
///   Pane-W (World):     results, drift status, telemetry dashboard
///
/// The protocol is intentionally minimal — each database declares its
/// capabilities, and PanLL only renders UI for what the database supports.
///
/// ## Adding a new database module
///
/// 1. Define a `moduleConfig` with the database's identity and capabilities
/// 2. Register it in `DatabaseRegistry.res`
/// 3. Implement Gossamer commands for each supported capability
/// 4. The PanLL UI automatically adapts to the declared capabilities

/// Capabilities that a database module may support. PanLL only renders UI
/// for capabilities the module declares.
type capability =
  | QueryExecution // Can run queries in a native language (VCL, KQL, GQL)
  | DriftDetection // Can detect cross-modal consistency drift
  | ProofGeneration // Can generate verifiable proof certificates
  | Normalisation // Can self-repair drifted modalities
  | Federation // Can federate queries across heterogeneous backends
  | Telemetry // Exposes operational metrics for product insights
  | Playground // Provides an interactive query editor/playground

/// Connection status for a database backend.
type connectionStatus =
  | Disconnected
  | Connecting
  | Connected(string) // endpoint URL
  | Error(string) // error message

/// A telemetry snapshot — aggregate product development metrics.
/// No query content, entity data, or PII — only counters and rates.
type telemetrySnapshot = {
  generatedAt: string,
  modalityHeatmap: array<(string, float)>,
  queryPatterns: array<(string, int)>,
  avgQueryDurationMs: float,
  driftDetectedCount: int,
  normaliseSuccessRate: float,
  proofTypeUsage: array<(string, int)>,
  entityCount: int,
}

/// Query result from any database module — uniform shape for PanLL rendering.
type queryResult = {
  columns: array<string>,
  rows: array<array<string>>,
  rowCount: int,
  timingMs: float,
  statementType: string,
  message: option<string>,
}

/// Drift scores for octad modalities (VeriSimDB) or similar per-dimension
/// scores for other databases. The key is the modality/dimension name.
type driftScore = {
  dimension: string,
  score: float, // 0.0 = no drift, 1.0 = maximum drift
}

/// Proof obligation from a query with dependent types.
type proofObligation = {
  proofType: string,
  contractName: string,
  status: string, // "verified" | "failed" | "pending"
  proofHash: string,
}

/// An example query for the playground.
type exampleQuery = {
  label: string,
  query: string,
  isDependentType: bool,
}

/// The query language configuration for the playground.
type playgroundConfig = {
  languageName: string, // "VCL", "KQL", "GQL"
  languageVersion: string, // "1.0", "0.5-alpha"
  fileExtension: string, // ".vcl", ".kql", ".gql"
  keywords: array<string>, // syntax keywords for highlighting
  exampleQueries: array<exampleQuery>,
  hasDependentTypes: bool, // supports a -DT variant
  linterAvailable: bool,
  formatterAvailable: bool,
}

/// Configuration for registering a database module with PanLL.
type moduleConfig = {
  id: string, // unique module identifier (e.g., "verisim")
  name: string, // display name (e.g., "VeriSimDB")
  version: string, // module version
  description: string, // one-line description
  endpoint: string, // default connection endpoint
  capabilities: array<capability>,
  playground: option<playgroundConfig>,
  icon: option<string>, // CSS class or emoji for the module
}

/// The runtime state for a connected database module in PanLL.
type moduleState = {
  config: moduleConfig,
  connection: connectionStatus,
  lastQuery: string,
  queryResult: option<queryResult>,
  queryError: option<string>,
  driftScores: option<array<driftScore>>,
  proofObligations: array<proofObligation>,
  telemetry: option<telemetrySnapshot>,
  menuExpanded: bool,
}

/// Initialise a module state from its configuration.
let initModuleState = (config: moduleConfig): moduleState => {
  config,
  connection: Disconnected,
  lastQuery: "",
  queryResult: None,
  queryError: None,
  driftScores: None,
  proofObligations: [],
  telemetry: None,
  menuExpanded: false,
}

/// Check whether a module supports a given capability.
let hasCapability = (config: moduleConfig, cap: capability): bool => {
  config.capabilities->Array.includes(cap)
}

/// Capability display name for UI rendering.
let capabilityLabel = (cap: capability): string => {
  switch cap {
  | QueryExecution => "Query Execution"
  | DriftDetection => "Drift Detection"
  | ProofGeneration => "Proof Generation"
  | Normalisation => "Normalisation"
  | Federation => "Federation"
  | Telemetry => "Telemetry"
  | Playground => "Playground"
  }
}
