// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Model - the unified state of the eNSAID environment.
///
/// This module documents the "Gravitational Centre" of the Binary Star system.
/// Adding annotations here keeps the Pane-L (symbolic), Pane-N (neural), and
/// Pane-W (world) slices of state easy to understand for newcomers.

/// Constraint types for the Symbolic Mass (Pane-L)
type symbolicConstraint = {
  id: string,
  expression: string,
  active: bool,
  pinned: bool, // Sticky Constraints feature
}

/// Neural token with metadata
type neuralToken = {
  content: string,
  timestamp: float,
  confidence: float,
  validated: bool, // Has passed Anti-Crash validation
}

/// Constraint violation types (Anti-Crash)
type violationType =
  | TypeMismatch(string, string) // expected, actual
  | BoundaryViolation(string)
  | LogicContradiction(string)
  | UndefinedReference(string)
  | SecurityViolation(string)

/// Anti-Crash validation state
type antiCrashState = {
  enabled: bool,
  strictMode: bool,
  violations: array<violationType>,
  halted: bool,
  pendingReview: option<neuralToken>,
}

/// OODA loop phase for Thing-Agency Monitor
type oodaPhase =
  | Observe
  | Orient
  | Decide
  | Act

/// Autonomy indicator for HTI
type agencyState = {
  phase: oodaPhase,
  autonomyLevel: float, // 0.0 = fully instructed, 1.0 = fully autonomous
  lastOperatorInput: float, // timestamp
}

/// Pane-L: Symbolic Mass (Noumena)
type paneLState = {
  constraints: array<symbolicConstraint>,
  activeConstraintId: option<string>,
  editorContent: string,
}

/// Pane-N: Neural Stream (Phenomena)
type paneNState = {
  tokens: array<neuralToken>,
  inferenceActive: bool,
  monologue: string,
  agency: agencyState,
}

/// Pane-W: World/Task Barycentre
/// Events are created from panic-attack/panll exports and feed the Time/Space
/// study view; each event carries axis/duration/intensity metadata.
type eventChainEvent = {
  id: string,
  axis: string,
  startMs: option<float>,
  durationMs: float,
  intensity: string,
  status: string,
  peakMemory: option<float>,
  notes: option<string>,
}

type eventChainSummary = {
  program: string,
  weakPoints: int,
  criticalWeakPoints: int,
  totalCrashes: int,
  robustnessScore: float,
}

type eventChainTimeline = {
  durationMs: float,
  events: int,
}

/// The Pane-W state tracks the world view (content/topology), the imported
/// panic-attacker event-chain, and the security dialog fields that run ambush
/// tooling. Keeping these annotations clarifies how the UI state mirrors the
/// backend command lifecycle.
type paneWState = {
  content: string,
  topologyView: bool, // Binary Star diagram mode
  lastValidatedOutput: string,
  eventChain: array<eventChainEvent>,
  eventChainSummary: option<eventChainSummary>,
  eventChainTimeline: option<eventChainTimeline>,
  eventChainInput: string,
  eventChainError: option<string>,
  panicAttackerMode: string, // unknown | full | fallback | unavailable
  panicAttackerBinary: option<string>,
  panicAttackerStatusDetail: option<string>,
  securityTarget: string,
  securityTimeline: string,
  securityAxes: string,
  securityIntensity: string,
  securityDuration: string,
  securityStatus: option<string>,
  securityError: option<string>,
  securityMenuExpanded: bool,
  securityDialogOpen: bool,
  securityDialogTool: option<string>,
  securityViewActive: bool,
}

/// Vexometer state
type vexometerState = {
  index: float, // 0.0 - 1.0
  recentCancellations: int,
  recentCorrections: int,
  antiInflammatoryActive: bool,
  inertiaDetected: bool,
}

/// Orbital stability metrics
type orbitalState = {
  stability: float, // sigma value
  divergenceLevel: float,
  driftAuraColour: string, // "indigo" or "amber"
}

/// Information Humidity level
type humidityLevel =
  | High // Low stress - show more detail
  | Medium
  | Low // High stress - shed visual noise

/// View mode for the environment
type viewMode =
  | Standard
  | Ambient // Memory Foam grid only
  | Zen // No sidebars/status
  | DarkStart // Architecture Manifold on idle

/// Synchronisation event types (for OrbitalSync)
type syncEvent =
  | SymbolicUpdate(string)   // Change in Pane-L
  | NeuralUpdate(string)     // Change in Pane-N
  | WorldUpdate(string)      // Change in Pane-W
  | CrossPaneLink(string, string) // Link between panes

/// Synchronisation state (for OrbitalSync)
type syncState = {
  lastSymbolicHash: string,
  lastNeuralHash: string,
  lastWorldHash: string,
  pendingSync: array<syncEvent>,
  syncLatency: float, // milliseconds
}

/// Contract enforcement level (for Contractiles)
type enforcementLevel =
  | Strict    // Halt on violation
  | Warn      // Log warning, continue
  | Adaptive  // Adjust contract based on context

/// Contract status (for Contractiles)
type contractStatus =
  | Satisfied
  | Violated(string)
  | Pending
  | Suspended

/// A contractile definition (for Contractiles)
type contractile = {
  id: string,
  name: string,
  description: string,
  enforcement: enforcementLevel,
  status: contractStatus,
  elasticity: float, // 0.0 = rigid, 1.0 = fully elastic
  lastEvaluated: float,
}

/// Contractile evaluation result (for Contractiles)
type evaluationResult = {
  contractId: string,
  status: contractStatus,
  message: string,
  adjustmentSuggestion: option<string>,
}

/// Proof obligation from a VQL-DT query result certificate
type proofObligation = {
  proofType: string,
  contractName: string,
  status: string, // "verified" | "failed" | "pending"
  proofHash: string,
}

/// Parsed drift scores for each modality — used by the drift heatmap.
/// Each score is 0.0 (no drift) to 1.0 (maximum drift).
type driftScores = {
  graph: float,
  vector: float,
  tensor: float,
  semantic: float,
  document: float,
  temporal: float,
  provenance: float,
  spatial: float,
}

/// Telemetry snapshot — aggregate product development metrics from a database
/// backend. No query content, entity data, or PII — only counters and rates.
/// This data helps understand how the database is used and where to focus
/// development effort. Users can also see this to understand their own workload.
type telemetrySnapshot = {
  generatedAt: string,
  modalityHeatmap: array<(string, float)>,
  queryPatterns: array<(string, int)>,
  avgQueryDurationMs: float,
  driftDetectedCount: int,
  normaliseSuccessRate: float,
  proofTypeUsage: array<(string, int)>,
  entityCount: int,
  privacyNotice: string,
}

/// VeriSimDB backend state — tracks connection, query results, entity browsing,
/// drift detection, normalisation, and telemetry for the VeriSimDB database
/// integration. The telemetry field is opt-in and shows aggregate-only metrics.
type verisimdbState = {
  connected: bool,
  endpoint: string,
  lastQuery: string,
  queryResult: option<string>,
  queryError: option<string>,
  entities: array<string>,
  selectedEntity: option<string>,
  driftStatus: option<string>,
  driftScores: option<driftScores>,
  proofObligations: array<proofObligation>,
  dbMenuExpanded: bool,
  normalisingEntity: option<string>,
  entityDetail: option<string>,
  telemetry: option<telemetrySnapshot>,
  telemetryVisible: bool,
  orchStatus: option<string>,
}

/// The complete Model
type model = {
  // Core panes
  paneL: paneLState,
  paneN: paneNState,
  paneW: paneWState,

  // Cognitive governance
  antiCrash: antiCrashState,
  vexometer: vexometerState,
  orbital: orbitalState,
  syncState: syncState,
  contractiles: array<contractile>,
  humidity: humidityLevel,

  // View state
  viewMode: viewMode,
  paneLVisible: bool,
  paneNVisible: bool,
  paneWVisible: bool,
  protocolAnalysisVisible: bool,

  // Database backends
  verisimdb: verisimdbState,

  // Feedback-O-Tron
  feedbackPending: option<string>,
  feedbackError: option<string>,
  feedbackReportType: option<string>,
}

/// Initial model state - "Dark Start" mode
let init = (): model => {
  paneL: {
    constraints: [],
    activeConstraintId: None,
    editorContent: "",
  },
  paneN: {
    tokens: [],
    inferenceActive: false,
    monologue: "",
    agency: {
      phase: Observe,
      autonomyLevel: 0.0,
      lastOperatorInput: 0.0,
    },
  },
  paneW: {
    content: "",
    topologyView: true, // Start with Binary Star diagram
    lastValidatedOutput: "",
    eventChain: [],
    eventChainSummary: None,
    eventChainTimeline: None,
    eventChainInput: "",
    eventChainError: None,
    panicAttackerMode: "unknown",
    panicAttackerBinary: None,
    panicAttackerStatusDetail: None,
    securityTarget: "",
    securityTimeline: "",
    securityAxes: "cpu,memory,concurrency",
    securityIntensity: "medium",
    securityDuration: "30",
    securityStatus: None,
    securityError: None,
    securityMenuExpanded: false,
    securityDialogOpen: false,
    securityDialogTool: None,
    securityViewActive: false,
  },
  antiCrash: {
    enabled: true,
    strictMode: true,
    violations: [],
    halted: false,
    pendingReview: None,
  },
  vexometer: {
    index: 0.0,
    recentCancellations: 0,
    recentCorrections: 0,
    antiInflammatoryActive: false,
    inertiaDetected: false,
  },
  orbital: {
    stability: 1.0,
    divergenceLevel: 0.0,
    driftAuraColour: "indigo",
  },
  syncState: {
    lastSymbolicHash: "",
    lastNeuralHash: "",
    lastWorldHash: "",
    pendingSync: [],
    syncLatency: 0.0,
  },
  contractiles: [
    {
      id: "orbital-stability",
      name: "Orbital Stability Bound",
      description: "Ensures the Binary Star co-orbit remains stable",
      enforcement: Strict,
      status: Pending,
      elasticity: 0.2,
      lastEvaluated: 0.0,
    },
    {
      id: "vexation-ceiling",
      name: "Vexation Ceiling",
      description: "Prevents operator friction from exceeding acceptable levels",
      enforcement: Adaptive,
      status: Pending,
      elasticity: 0.5,
      lastEvaluated: 0.0,
    },
    {
      id: "divergence-limit",
      name: "Divergence Limit",
      description: "Limits drift between symbolic and neural subsystems",
      enforcement: Warn,
      status: Pending,
      elasticity: 0.3,
      lastEvaluated: 0.0,
    },
    {
      id: "autonomy-bound",
      name: "Autonomy Bound",
      description: "Constrains the machine's autonomous action level",
      enforcement: Strict,
      status: Pending,
      elasticity: 0.4,
      lastEvaluated: 0.0,
    },
  ],
  verisimdb: {
    connected: false,
    endpoint: "http://localhost:8080/api/v1",
    lastQuery: "",
    queryResult: None,
    queryError: None,
    entities: [],
    selectedEntity: None,
    driftStatus: None,
    driftScores: None,
    proofObligations: [],
    dbMenuExpanded: false,
    normalisingEntity: None,
    entityDetail: None,
    telemetry: None,
    telemetryVisible: false,
    orchStatus: None,
  },
  humidity: Medium,
  viewMode: DarkStart,
  paneLVisible: true,
  paneNVisible: true,
  paneWVisible: true,
  protocolAnalysisVisible: false,
  feedbackPending: None,
  feedbackError: None,
  feedbackReportType: Some("FeatureRequest"),
}
