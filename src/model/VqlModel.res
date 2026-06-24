// SPDX-License-Identifier: MPL-2.0
// VCL-total Panel Model — The flagship PanLL panel for type-safe query authoring.
//
// This model defines the complete state for the VCL panel, including:
// - 10-level progressive type safety (the core VCL-total innovation)
// - A dedicated linter with 30+ rules across 6 categories
// - A dedicated formatter with configurable style presets
// - Cross-prover query construction and dispatch
// - VeriSimDB octad-aware schema browsing
// - Query plan visualization and cost estimation
// - Session management with proof obligation tracking
//
// The VCL panel is the primary interface through which PanLL users
// interact with the entire VeriSimDB + ECHIDNA proof ecosystem.

// ============================================================
// SECTION 1: Type Safety Levels (the 10-level VCL-total ratchet)
// ============================================================

/// The 10 progressive type safety levels of VCL-total.
/// Each level strictly subsumes the previous — once you ratchet up,
/// the linter enforces the new minimum.
type typeSafetyLevel =
  | L0_Unsafe // Raw string queries, no checking
  | L1_Parsed // Syntactically valid VCL
  | L2_SchemaBound // All tables/columns resolve against schema
  | L3_TypeCompat // Expression types are compatible (no int = string)
  | L4_NullSafe // Nullable columns handled explicitly
  | L5_InjectionProof // No string interpolation in query positions
  | L6_ResultTyped // Return type fully determined at compile time
  | L7_CardinalitySafe // Cardinality bounds proven (no unbounded scans)
  | L8_EffectTracked // Side effects (writes, locks) declared and tracked
  | L9_TemporalSafe // Temporal consistency (no future reads, no stale joins)
  | L10_LinearSafe // Linear resource usage (exactly-once consumption proven)

/// Metadata about a safety level — used for UI display and narratives.
type levelMeta = {
  level: typeSafetyLevel,
  name: string,
  shortName: string,
  description: string,
  glyph: string,
  colour: string, // Tailwind colour class
  bgColour: string, // Tailwind bg class
  proverRequired: bool, // Whether this level needs ECHIDNA prover dispatch
}

// ============================================================
// SECTION 2: Linter System
// ============================================================

/// Lint rule severity — determines how the linter treats violations.
type lintSeverity =
  | LintError // Query will not execute
  | LintWarning // Query may produce unexpected results
  | LintInfo // Suggestion for improvement
  | LintHint // Style/convention recommendation

/// Lint rule categories — each category maps to a VCL-total concern.
type lintCategory =
  | CatSyntax // Parse-level issues (L1)
  | CatSchema // Schema binding issues (L2)
  | CatType // Type compatibility (L3-L4)
  | CatSecurity // Injection, access control (L5)
  | CatPerformance // Cardinality, indexing, scans (L7)
  | CatCorrectness // Effects, temporality, linearity (L8-L10)

/// A single lint diagnostic emitted by the VCL linter.
type lintDiagnostic = {
  ruleId: string, // e.g. "VCL-S001" (Syntax), "VCL-T003" (Type)
  category: lintCategory,
  severity: lintSeverity,
  line: int,
  column: int,
  endLine: int,
  endColumn: int,
  message: string,
  suggestion: option<string>, // Auto-fix suggestion
  relatedLevel: typeSafetyLevel, // Which level this rule enforces
}

/// Linter configuration — which rules are active and at what severity.
type lintProfile =
  | ProfileStrict // All rules at maximum severity
  | ProfileRecommended // Default — errors + warnings, no hints
  | ProfileRelaxed // Errors only
  | ProfileCustom // User-configured rule set

/// Full linter state.
type linterState = {
  profile: lintProfile,
  minimumLevel: typeSafetyLevel, // Floor — violations below this level are errors
  diagnostics: array<lintDiagnostic>,
  suppressions: array<string>, // Rule IDs the user has suppressed
  autoFixEnabled: bool,
  lintOnType: bool, // Lint as user types (debounced)
  lintDebounceMs: int,
}

// ============================================================
// SECTION 3: Formatter System
// ============================================================

/// Formatter style presets — opinionated formatting for VCL queries.
type formatStyle =
  | StyleStandard // VCL-total official style (keywords uppercase, 2-space indent)
  | StyleCompact // Minimal whitespace, single-line where possible
  | StyleExpanded // One clause per line, generous whitespace
  | StyleProof // Annotated with type obligations and proof markers
  | StyleCustom // User-configured

/// Formatter options — fine-grained control over output.
type formatOptions = {
  style: formatStyle,
  indentWidth: int, // Spaces per indent level (default: 2)
  uppercaseKeywords: bool, // SELECT vs select
  alignClauses: bool, // Vertically align FROM, WHERE, etc.
  trailingComma: bool, // Comma after last SELECT column
  maxLineWidth: int, // Wrap threshold (default: 100)
  insertBlankLines: bool, // Between major clauses
  annotateTypes: bool, // Inline type annotations as comments
  showLevelMarkers: bool, // [L3] markers on type-checked expressions
  colourOutput: bool, // Syntax highlighting in formatted output
}

/// Formatter state.
type formatterState = {
  options: formatOptions,
  lastFormatted: option<string>, // Formatted output (for diff view)
  showDiff: bool, // Side-by-side original vs formatted
  formatOnSave: bool,
}

// ============================================================
// SECTION 4: Query Editor
// ============================================================

/// Query operation types — what the user is trying to do.
type queryOperation =
  | OpFindProof // Search for proofs matching criteria
  | OpFindSimilar // Vector similarity search on proof embeddings
  | OpCrossProverSearch // Federated search across multiple provers
  | OpProvenanceTrace // Track proof lineage through VeriSimDB
  | OpTemporalHistory // View proof evolution over time
  | OpDependencyGraph // Map theorem dependencies
  | OpAxiomUsage // Which axioms does this proof rely on?
  | OpTacticStats // Tactic frequency and success rates
  | OpCustom // Raw VCL-total query

/// A template parameter with type and validation.
type templateParameter = {
  name: string,
  paramType: string, // "string" | "int" | "prover" | "tactic" | etc.
  description: string,
  defaultValue: option<string>,
  validation: option<string>, // Regex or VCL-total type expression
}

/// A saved query template — reusable parameterised queries.
type queryTemplate = {
  id: string,
  name: string,
  description: string,
  operation: queryOperation,
  template: string, // VCL-total with {{param}} placeholders
  parameters: array<templateParameter>,
  requiredLevel: typeSafetyLevel,
}

/// Editor state — the main query editing surface.
type editorState = {
  content: string,
  cursorLine: int,
  cursorColumn: int,
  selectionStart: option<(int, int)>,
  selectionEnd: option<(int, int)>,
  undoStack: array<string>,
  redoStack: array<string>,
  activeOperation: queryOperation,
  activeTemplate: option<queryTemplate>,
  parameterValues: array<(string, string)>, // Filled-in template params
  isDirty: bool,
  lastSaved: option<float>, // Timestamp
}

// ============================================================
// SECTION 5: Query Execution & Results
// ============================================================

/// Execution target — where the query runs.
type executionTarget =
  | TargetVeriSimDB // Direct VeriSimDB HTTP API
  | TargetEchidna // Via ECHIDNA cross-prover engine
  | TargetBoJ // Via BoJ server cartridge routing
  | TargetTypeLL // Type-check only (no execution)
  | TargetDryRun // Parse + plan, don't execute

/// Query execution status.
type executionStatus =
  | Idle
  | Parsing
  | TypeChecking(typeSafetyLevel) // Currently at this level
  | Planning
  | Executing
  | Streaming(int) // Rows received so far
  | Complete(float) // Duration in ms
  | Failed(string) // Error message

/// A single result row — generic key-value pairs.
type resultCell =
  | CellString(string)
  | CellInt(int)
  | CellFloat(float)
  | CellBool(bool)
  | CellNull
  | CellProver(string) // Prover name with icon
  | CellProof(string) // Proof ID (clickable)
  | CellTactic(string) // Tactic name (clickable)
  | CellLevel(typeSafetyLevel) // Safety level badge
  | CellOctad(string) // VeriSimDB octad reference

/// Column definition for result display.
type resultColumn = {
  name: string,
  columnType: string,
  width: option<int>,
  sortable: bool,
  filterable: bool,
}

/// A single step in the query execution plan.
type rec planStep = {
  operation: string, // "scan", "filter", "join", "sort", "aggregate", "prove"
  target: string, // Table/index/prover name
  estimatedRows: int,
  estimatedCostPct: float,
  children: array<planStep>,
}

/// Query plan — how VeriSimDB/ECHIDNA will execute the query.
type queryPlan = {
  steps: array<planStep>,
  estimatedCost: float,
  estimatedRows: int,
  proversInvolved: array<string>,
  octadModalities: array<string>, // Which of the 8 modalities are touched
}

/// The 4-part evangeliser narrative from TypeLL integration.
type typeNarrative = {
  celebrate: string, // What's good about this query
  minimize: string, // Why issues aren't catastrophic
  showBetter: string, // How to improve
  safety: string, // What safety guarantees you get
}

/// Type checking report from TypeLL.
type typeReport = {
  achievedLevel: typeSafetyLevel,
  requestedLevel: typeSafetyLevel,
  passed: bool,
  issues: array<lintDiagnostic>,
  inferredTypes: array<(string, string)>, // (expression, inferred_type) pairs
  narrative: option<typeNarrative>,
}

/// Proof obligation status.
type obligationStatus =
  | Pending
  | Discharged(string) // Evidence/certificate
  | Refuted(string) // Counter-example
  | Timeout

/// Proof obligation generated by type checking.
type proofObligation = {
  id: string,
  description: string,
  status: obligationStatus,
  prover: option<string>,
  evidence: option<string>,
}

/// Query result set.
type queryResult = {
  columns: array<resultColumn>,
  rows: array<array<resultCell>>,
  totalRows: int,
  fetchedRows: int,
  truncated: bool,
  executionTimeMs: float,
  queryPlan: option<queryPlan>,
  typeReport: option<typeReport>,
  proofObligations: array<proofObligation>,
}

/// Query history entry.
type historyEntry = {
  id: string,
  query: string,
  operation: queryOperation,
  target: executionTarget,
  achievedLevel: typeSafetyLevel,
  timestamp: float,
  durationMs: float,
  rowCount: int,
  success: bool,
  favourite: bool,
}

/// Execution state.
type executionState = {
  target: executionTarget,
  status: executionStatus,
  lastResult: option<queryResult>,
  history: array<historyEntry>,
  maxHistorySize: int,
  streamingEnabled: bool,
  timeoutMs: int,
}

// ============================================================
// SECTION 6: Schema Browser
// ============================================================

/// VeriSimDB octad modality — the 8 dimensions of proof storage.
type octadModality =
  | ModSemantic // Meaning/content (CBOR-encoded proof states)
  | ModTemporal // Time/versioning (proof evolution chains)
  | ModProvenance // Origin/attribution (who proved what, when)
  | ModDocument // Full-text (searchable proof text)
  | ModGraph // Relationships (theorem dependency DAGs)
  | ModVector // Embeddings (similarity search on goals)
  | ModTensor // Multi-dimensional metrics (performance data)
  | ModSpatial // Origin metadata (prover location, cluster topology)

/// Schema column definition.
type schemaColumn = {
  name: string,
  dataType: string,
  nullable: bool,
  indexed: bool,
  description: string,
  foreignKey: option<(string, string)>, // (table, column)
}

/// Schema entity — a table, view, or virtual collection in VeriSimDB.
type schemaEntity = {
  name: string,
  entityType: string, // "table" | "view" | "virtual" | "octad"
  modalities: array<octadModality>,
  columns: array<schemaColumn>,
  rowEstimate: int,
  description: string,
}

/// Schema browser state.
type schemaState = {
  entities: array<schemaEntity>,
  expandedEntities: array<string>,
  searchFilter: string,
  modalityFilter: option<octadModality>,
  lastRefreshed: option<float>,
  loading: bool,
}

// ============================================================
// SECTION 7: Cross-Prover Dispatch
// ============================================================

/// Prover selection strategy for cross-prover queries.
type proverStrategy =
  | StrategyAuto // ECHIDNA chooses based on goal structure
  | StrategyPortfolio // Run on all applicable provers, take first success
  | StrategySingle(string) // Specific prover by name
  | StrategyTiered // Try fast provers first, escalate to slow ones
  | StrategyConsensus // Require N provers to agree

/// Prover status in the dispatch panel.
type proverStatus = {
  name: string,
  kind: string, // "interactive" | "smt" | "atp" | "declarative" | "constraint"
  available: bool,
  lastLatencyMs: option<float>,
  successRate: option<float>,
  proofCount: int,
}

/// Cross-prover dispatch state.
type dispatchState = {
  strategy: proverStrategy,
  availableProvers: array<proverStatus>,
  selectedProvers: array<string>,
  consensusThreshold: int, // For StrategyConsensus
  timeoutPerProverMs: int,
  showProverDetails: bool,
}

// ============================================================
// SECTION 8: View Layers (Progressive Disclosure)
// ============================================================

/// View layer for progressive disclosure of query complexity.
type viewLayer =
  | Raw // Full VCL-total syntax with all annotations
  | Folded // Collapsed sub-expressions, summary types
  | Glyphed // Mathematical symbols replace keywords (forall, exists, etc.)
  | Wysiwyg // Interactive visual query builder

// ============================================================
// SECTION 9: Panel Tabs
// ============================================================

/// The 7 tabs of the VCL panel — each a distinct workflow.
type vclTab =
  | TabEditor // Query editor with linting and formatting
  | TabResults // Result table with sorting/filtering
  | TabPlan // Query plan visualization (tree diagram)
  | TabSchema // VeriSimDB octad schema browser
  | TabProvers // Cross-prover dispatch configuration
  | TabHistory // Query history with favourites
  | TabLintConfig // Linter and formatter configuration

// ============================================================
// SECTION 10: Top-Level Panel State
// ============================================================

/// Connection status to VeriSimDB.
type connectionStatus =
  | VclDisconnected
  | VclConnecting
  | VclConnected(string) // Endpoint URL
  | VclError(string) // Error message

/// The complete VCL panel state — assembled from all subsystems.
type vclState = {
  // Panel chrome
  activeTab: vclTab,
  viewLayer: viewLayer,
  panelOpen: bool,
  fullscreen: bool,
  // Connection
  connection: connectionStatus,
  verisimEndpoint: string,
  echidnaEndpoint: string,
  typellEndpoint: string,
  bojRouting: bool,
  // Subsystems
  editor: editorState,
  linter: linterState,
  formatter: formatterState,
  execution: executionState,
  schema: schemaState,
  dispatch: dispatchState,
  // Cross-panel
  typeCheckResult: option<typeReport>,
  pendingObligations: array<proofObligation>,
}

// ============================================================
// SECTION 11: Messages
// ============================================================

/// All messages the VCL panel can receive — each maps to a state transition.
type vclMsg =
  // Tab navigation
  | SetTab(vclTab)
  | SetViewLayer(viewLayer)
  | ToggleFullscreen
  // Editor
  | SetContent(string)
  | SetCursorPosition(int, int)
  | SetSelection(option<(int, int)>, option<(int, int)>)
  | Undo
  | Redo
  | SetOperation(queryOperation)
  | ApplyTemplate(queryTemplate)
  | SetParameterValue(string, string)
  | InsertSnippet(string)
  | ClearEditor
  // Linter
  | RunLint
  | LintComplete(array<lintDiagnostic>)
  | SetLintProfile(lintProfile)
  | SetMinimumLevel(typeSafetyLevel)
  | ToggleLintOnType
  | SuppressRule(string)
  | UnsuppressRule(string)
  | ApplyAutoFix(lintDiagnostic)
  | ApplyAllFixes
  // Formatter
  | RunFormat
  | FormatComplete(string)
  | SetFormatStyle(formatStyle)
  | SetFormatOption(string, string) // (key, value) for custom options
  | ToggleFormatDiff
  | ToggleFormatOnSave
  // Execution
  | ExecuteQuery
  | CancelQuery
  | SetExecutionTarget(executionTarget)
  | ExecutionProgress(executionStatus)
  | QueryComplete(queryResult)
  | QueryFailed(string)
  | SetStreamingEnabled(bool)
  | SetTimeout(int)
  // Results
  | SortResults(string, bool) // (column, ascending)
  | FilterResults(string, string) // (column, filter_text)
  | PageResults(int) // Page number
  | ExportResults(string) // Format: "csv" | "json" | "a2ml"
  // Schema
  | RefreshSchema
  | SchemaLoaded(array<schemaEntity>)
  | ToggleEntity(string)
  | SetSchemaFilter(string)
  | SetModalityFilter(option<octadModality>)
  // Provers
  | SetProverStrategy(proverStrategy)
  | ToggleProver(string)
  | RefreshProverStatus
  | ProverStatusUpdated(array<proverStatus>)
  // History
  | SaveToHistory
  | LoadFromHistory(historyEntry)
  | ToggleFavourite(string)
  | ClearHistory
  // Connection
  | Connect
  | Disconnect
  | ConnectionChanged(connectionStatus)
  | SetVeriSimEndpoint(string)
  | SetEchidnaEndpoint(string)
  | ToggleBojRouting
  // TypeLL integration
  | RequestTypeCheck
  | TypeCheckReceived(typeReport)
  | DischargeObligation(string, string) // (obligation_id, evidence)
  // Keyboard shortcuts
  | KeyboardShortcut(string) // "ctrl+enter", "ctrl+shift+f", etc.
