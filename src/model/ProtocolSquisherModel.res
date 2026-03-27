// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Protocol-Squisher Model — types for the format analysis panel.
///
/// Protocol-squisher analyses serialisation schemas across 13 formats (Protobuf,
/// Avro, FlatBuffers, Cap'n Proto, Thrift, MessagePack, Bebop, JSON Schema,
/// GraphQL, TOML, Rust, ReScript, Python) and classifies their transport
/// compatibility into 4 tiers: Concorde, Business, Economy, Wheelbarrow.
///
/// The panel imports IR analysis results as Pane-L constraints and displays
/// transport class compatibility between formats.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Serialisation format that protocol-squisher can analyse.
/// Includes both wire-protocol formats and enterprise architecture model interchange.
type schemaFormat =
  | Protobuf
  | Avro
  | FlatBuffers
  | CapnProto
  | Thrift
  | MessagePack
  | Bebop
  | JsonSchema
  | GraphQL
  | Toml
  | RustFormat
  | ReScriptFormat
  | PythonFormat
  // Enterprise architecture model interchange formats
  | XMI // OMG XML Metadata Interchange (MOF/UML/SysML serialisation)
  | ArchiMateExchange // The Open Group ArchiMate Model Exchange File Format
  | BPMN_XML // OMG BPMN 2.0 XML serialisation
  | SBVR // OMG Semantics of Business Vocabulary and Rules

/// Transport class — higher tier means more efficient wire representation.
type transportClass =
  | Concorde
  | Business
  | Economy
  | Wheelbarrow

/// A single format analysis result from the protocol-squisher CLI.
type analysisResult = {
  /// Path to the schema file that was analysed.
  filePath: string,
  /// Detected format.
  format: schemaFormat,
  /// Transport class classification.
  transportClass: transportClass,
  /// Human-readable summary of the analysis.
  summary: string,
  /// Estimated wire overhead ratio (1.0 = no overhead).
  overheadRatio: float,
  /// Number of fields/types found in the schema.
  fieldCount: int,
  /// Whether the schema uses nested/recursive types.
  hasRecursion: bool,
}

/// Compatibility comparison between two schemas.
type schemaCompatibilityResult = {
  /// Left schema path.
  leftPath: string,
  /// Right schema path.
  rightPath: string,
  /// Left format.
  leftFormat: schemaFormat,
  /// Right format.
  rightFormat: schemaFormat,
  /// Whether the schemas are structurally compatible.
  compatible: bool,
  /// Adapter complexity cost (0 = trivial, 10 = impossible).
  adapterCost: int,
  /// Human-readable compatibility notes.
  notes: string,
}

/// Category tabs for the Protocol-Squisher panel.
type protocolSquisherCategory =
  /// Analyse a schema file.
  | PsAnalyse
  /// Compare two schemas for compatibility.
  | PsCompare
  /// View recent analysis results.
  | PsResults
  /// Transport class reference guide.
  | PsGuide

/// Root state for the Protocol-Squisher panel.
type protocolSquisherState = {
  /// Whether the CLI binary is available.
  cliAvailable: bool,
  /// Whether an operation is in progress.
  loading: bool,
  /// Error from the last operation.
  error: option<string>,
  /// Active category tab.
  activeCategory: protocolSquisherCategory,
  /// Path input for schema analysis.
  analyseInput: string,
  /// Path inputs for comparison (left, right).
  compareLeftInput: string,
  compareRightInput: string,
  /// Most recent analysis result.
  lastAnalysis: option<analysisResult>,
  /// Most recent comparison result.
  lastComparison: option<schemaCompatibilityResult>,
  /// History of analysis results (most recent first).
  analysisHistory: array<analysisResult>,
  /// TypeLL type-check result JSON for the last schema analysis (cross-panel intelligence).
  /// Parsed via TypeLLEngine.parseCheckResult when rendering.
  lastTypeCheck: option<string>,
  /// IR constraints extracted from the latest analysis and pushed to Panel-L.
  /// Each string is a constraint expression derived from the schema structure.
  irConstraints: array<string>,
  /// Whether transport compatibility data should be shown in Panel-W.
  transportDisplayActive: bool,
}
