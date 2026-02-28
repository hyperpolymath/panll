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

/// ECHIDNA trust level — maps to the prover dispatch's multi-solver confidence.
/// Level 1 (lowest) is a single unverified solver; Level 5 is cross-checked
/// formal proof with no axiom risks.
type echidnaTrustLevel =
  | TrustLevel1 // Unverified / single solver, high axiom risk
  | TrustLevel2 // Single solver, no dangerous axioms
  | TrustLevel3 // Multiple solvers agree
  | TrustLevel4 // Cross-checked, no axiom issues
  | TrustLevel5 // Full formal proof, cross-checked, certificate issued

/// Axiom danger classification — used by the axiom report to flag risky
/// assumptions in proof obligations (e.g., believe_me, Admitted, sorry).
type axiomDangerLevel =
  | Safe    // No concerns
  | Noted   // Informational (e.g., standard library axioms)
  | Warning // Potentially unsound (e.g., functional extensionality)
  | Reject  // Proof-breaking (e.g., believe_me, Admitted)

/// Portfolio confidence — aggregate confidence across multiple provers.
/// Cross-checked means multiple independent solvers agree on the result.
type portfolioConfidence =
  | CrossChecked   // Multiple solvers independently agree
  | SingleSolver   // Only one solver produced a result
  | Inconclusive   // Solvers disagree or partial results
  | AllTimedOut     // Every solver timed out

/// A prover registered in the ECHIDNA prover catalog.
/// Tier indicates the solver family (e.g., SMT, ATP, ITP, tactic engine).
type echidnaProver = {
  name: string,
  tier: string,
  complexity: string,
}

/// A single axiom usage entry from the axiom report — flags whether
/// the proof relies on dangerous assumptions.
type axiomUsage = {
  axiomName: string,
  dangerLevel: axiomDangerLevel,
  description: string,
}

/// The structured result of an ECHIDNA dispatch (proof submission).
/// Contains verification status, trust assessment, prover telemetry,
/// axiom risk report, and optional certificate hash.
type echidnaDispatchResult = {
  verified: bool,
  trustLevel: echidnaTrustLevel,
  proversUsed: array<string>,
  proofTimeMs: float,
  goalsRemaining: int,
  axiomReport: array<axiomUsage>,
  certificateHash: option<string>,
  message: string,
  crossChecked: portfolioConfidence,
}

/// A tactic suggestion from the ECHIDNA ML advisor.
/// Includes tactic name, arguments, confidence score, aspect tags, and description.
/// The ML advisor (Julia :8090) or prover fallback populates these.
type echidnaTacticSuggestion = {
  tactic: string,
  args: array<string>,
  confidence: float,
  aspectTags: array<string>,
  description: string,
}

/// ECHIDNA proof session status — maps to the ProofResponse status field
/// from the ECHIDNA REST API (/api/v1/proofs).
type echidnaProofStatus =
  | Pending       // Session created, awaiting first tactic
  | InProgress    // Tactics being applied, goals remaining
  | ProofSuccess  // All goals discharged
  | ProofFailed   // Proof attempt failed
  | ProofTimeout  // Solver timed out
  | ProofError    // Internal error during proof

/// Interactive proof session state — mirrors ECHIDNA's ProofResponse.
/// Tracks session identity, prover, goals, applied tactics, and timing.
type echidnaSessionState = {
  sessionId: string,
  prover: string,
  goal: string,
  status: echidnaProofStatus,
  goals: array<string>,
  proofScript: array<string>,
  complete: bool,
  tacticsApplied: array<string>,
  timeElapsed: option<float>,
  errorMessage: option<string>,
}

/// ECHIDNA backend state — tracks connection, prover catalog, proof lifecycle,
/// interactive session, and tactic suggestions.
type echidnaState = {
  connected: bool,
  endpoint: string,
  version: option<string>,
  provers: array<echidnaProver>,
  lastProofResult: option<echidnaDispatchResult>,
  proofError: option<string>,
  proofLoading: bool,
  session: option<echidnaSessionState>,
  tacticSuggestions: array<echidnaTacticSuggestion>,
  selectedProver: option<string>,
  proofInput: string,
  menuExpanded: bool,
  tacticInput: string,
  sessionLoading: bool,
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

  // Theorem prover backend
  echidna: echidnaState,

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
  echidna: {
    connected: false,
    endpoint: "http://localhost:8000/api/v1",
    version: None,
    provers: [],
    lastProofResult: None,
    proofError: None,
    proofLoading: false,
    session: None,
    tacticSuggestions: [],
    selectedProver: None,
    proofInput: "",
    menuExpanded: false,
    tacticInput: "",
    sessionLoading: false,
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
