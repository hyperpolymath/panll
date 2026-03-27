// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ECHIDNA Types — Theorem prover dispatch engine state.
///
/// ECHIDNA is the multi-solver proof dispatch system that sits behind PanLL's
/// Pane-N. It manages prover catalogs, proof sessions, trust assessment,
/// axiom risk analysis, and tactic suggestions. These types mirror the
/// ECHIDNA REST API (/api/v1/) response shapes.
///
/// This module has NO dependencies on other PanLL modules.

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
  | Safe // No concerns
  | Noted // Informational (e.g., standard library axioms)
  | Warning // Potentially unsound (e.g., functional extensionality)
  | Reject // Proof-breaking (e.g., believe_me, Admitted)

/// Portfolio confidence — aggregate confidence across multiple provers.
/// Cross-checked means multiple independent solvers agree on the result.
type portfolioConfidence =
  | CrossChecked // Multiple solvers independently agree
  | SingleSolver // Only one solver produced a result
  | Inconclusive // Solvers disagree or partial results
  | AllTimedOut // Every solver timed out

/// A prover registered in the ECHIDNA prover catalog.
/// Tier indicates the solver family (e.g., SMT, ATP, ITP, tactic engine).
type echidnaProver = {
  /// Prover display name (e.g. "Z3", "CVC5", "Coq").
  name: string,
  /// Solver family tier (e.g. "SMT", "ATP", "ITP", "tactic").
  tier: string,
  /// Complexity class this prover targets (e.g. "QF_LIA", "HOL").
  complexity: string,
}

/// A single axiom usage entry from the axiom report — flags whether
/// the proof relies on dangerous assumptions.
type axiomUsage = {
  /// Name of the axiom used in the proof.
  axiomName: string,
  /// Danger classification for this axiom.
  dangerLevel: axiomDangerLevel,
  /// Human-readable explanation of the axiom's impact.
  description: string,
}

/// The structured result of an ECHIDNA dispatch (proof submission).
/// Contains verification status, trust assessment, prover telemetry,
/// axiom risk report, and optional certificate hash.
type echidnaDispatchResult = {
  /// Whether the proof obligation was verified.
  verified: bool,
  /// Trust level assigned by the multi-solver assessment.
  trustLevel: echidnaTrustLevel,
  /// Names of provers that participated in this dispatch.
  proversUsed: array<string>,
  /// Wall-clock time spent on the proof in milliseconds.
  proofTimeMs: float,
  /// Number of proof goals still remaining (0 = fully proven).
  goalsRemaining: int,
  /// Axiom risk report for this proof.
  axiomReport: array<axiomUsage>,
  /// Hash of the issued proof certificate, if verification succeeded.
  certificateHash: option<string>,
  /// Human-readable result summary message.
  message: string,
  /// Portfolio confidence level across multiple solvers.
  crossChecked: portfolioConfidence,
}

/// A tactic suggestion from the ECHIDNA ML advisor.
/// Includes tactic name, arguments, confidence score, aspect tags, and description.
/// The ML advisor (Julia :8090) or prover fallback populates these.
type echidnaTacticSuggestion = {
  /// Tactic name (e.g. "intros", "apply", "rewrite").
  tactic: string,
  /// Arguments to pass to the tactic.
  args: array<string>,
  /// ML advisor confidence in this suggestion (0.0-1.0).
  confidence: float,
  /// Aspect tags describing the tactic's purpose.
  aspectTags: array<string>,
  /// Human-readable explanation of what this tactic does.
  description: string,
}

/// ECHIDNA proof session status — maps to the ProofResponse status field
/// from the ECHIDNA REST API (/api/v1/proofs).
type echidnaProofStatus =
  | Pending // Session created, awaiting first tactic
  | InProgress // Tactics being applied, goals remaining
  | ProofSuccess // All goals discharged
  | ProofFailed // Proof attempt failed
  | ProofTimeout // Solver timed out
  | ProofError // Internal error during proof

/// Interactive proof session state — mirrors ECHIDNA's ProofResponse.
/// Tracks session identity, prover, goals, applied tactics, and timing.
type echidnaSessionState = {
  /// Unique session identifier from the ECHIDNA backend.
  sessionId: string,
  /// Name of the prover driving this session.
  prover: string,
  /// The top-level proof goal text.
  goal: string,
  /// Current status of this proof session.
  status: echidnaProofStatus,
  /// Remaining proof goals (subgoals).
  goals: array<string>,
  /// Accumulated proof script (tactic history).
  proofScript: array<string>,
  /// Whether the proof is complete (all goals discharged).
  complete: bool,
  /// Ordered list of tactics applied so far.
  tacticsApplied: array<string>,
  /// Elapsed time in milliseconds since session start.
  timeElapsed: option<float>,
  /// Error message if the session encountered a problem.
  errorMessage: option<string>,
}

// ===========================================================================
// MOF / OCL / Enterprise Architecture Modeling (OMG + The Open Group)
// ===========================================================================

/// MOF layer in the OMG four-layer metamodel hierarchy.
/// M3 is MOF itself, M2 is a metamodel (UML, ArchiMate), M1 is a user model,
/// M0 is the runtime instance.
type mofLayer =
  | M3_MetaMetaModel // MOF itself — defines how metamodels are structured
  | M2_Metamodel // UML, ArchiMate, SysML, BPMN — defines modeling languages
  | M2_Profile // UML/SysML profiles — domain-specific extensions
  | M1_Model // User's model — instances of the metamodel
  | M0_Instance // Runtime objects — instances of the model

/// Supported metamodel standards at the M2 layer.
type metamodelStandard =
  | UML // OMG Unified Modeling Language (class, sequence, state, etc.)
  | SysML // OMG Systems Modeling Language (requirements, blocks, parametrics)
  | ArchiMate // The Open Group ArchiMate (enterprise architecture)
  | BPMN // OMG Business Process Model and Notation
  | DMN // OMG Decision Model and Notation
  | CMMN // OMG Case Management Model and Notation
  | ODM // OMG Ontology Definition Metamodel
  | CustomProfile // User-defined UML/SysML profile

/// OCL constraint severity — maps to how strictly the constraint is enforced.
type oclSeverity =
  | OclInvariant // Must always hold (inv:)
  | OclPrecondition // Must hold before operation (pre:)
  | OclPostcondition // Must hold after operation (post:)
  | OclDerive // Derived value specification (derive:)
  | OclInit // Initial value specification (init:)
  | OclBody // Body of a query operation (body:)

/// A single OCL constraint to be verified by ECHIDNA.
type oclConstraint = {
  /// Context classifier (e.g. "Package::ClassName").
  context: string,
  /// Constraint name (e.g. "positiveBalance", "validState").
  name: string,
  /// OCL expression text.
  expression: string,
  /// Constraint kind.
  severity: oclSeverity,
  /// Which MOF layer this constraint operates at.
  layer: mofLayer,
  /// Which metamodel standard this constraint belongs to.
  metamodel: metamodelStandard,
}

/// Result of checking a single OCL constraint via ECHIDNA solvers.
type oclCheckResult = {
  /// The constraint that was checked.
  @as("constraint") oclRule: oclConstraint,
  /// Whether the constraint is satisfied.
  satisfied: bool,
  /// Counter-example if violated (model element path + values).
  counterExample: option<string>,
  /// Which solver verified this constraint.
  solverUsed: string,
  /// Verification time in milliseconds.
  checkTimeMs: float,
}

/// Enterprise architecture model element — a node in the MOF instance graph.
type modelElement = {
  /// Qualified name (e.g. "org.example::OrderService").
  qualifiedName: string,
  /// Metaclass (e.g. "Class", "Component", "BusinessProcess", "ApplicationService").
  metaclass: string,
  /// MOF layer.
  layer: mofLayer,
  /// Metamodel standard.
  metamodel: metamodelStandard,
  /// Attributes as key-value pairs.
  attributes: array<(string, string)>,
  /// Outgoing relationships (relationship type, target qualified name).
  relationships: array<(string, string)>,
}

/// State for enterprise architecture model checking within ECHIDNA.
type enterpriseModelState = {
  /// Loaded model elements.
  elements: array<modelElement>,
  /// OCL constraints to verify against the model.
  constraints: array<oclConstraint>,
  /// Results from the most recent constraint check batch.
  checkResults: array<oclCheckResult>,
  /// Whether a batch check is in progress.
  checking: bool,
  /// Active metamodel standard filter (None = show all).
  activeMetamodel: option<metamodelStandard>,
  /// Active MOF layer filter (None = show all).
  activeLayer: option<mofLayer>,
  /// XMI import source path (last imported file).
  lastXmiImport: option<string>,
}

/// ECHIDNA panel tabs — selects between proof workbench and enterprise model checking.
type echidnaTab =
  | EchidnaProofTab // Traditional theorem prover workbench
  | EchidnaEnterpriseTab // MOF/OCL/ArchiMate enterprise model checking

/// ECHIDNA backend state — tracks connection, prover catalog, proof lifecycle,
/// interactive session, tactic suggestions, and enterprise model checking.
type echidnaState = {
  /// Whether the ECHIDNA backend is reachable.
  connected: bool,
  /// Base URL of the ECHIDNA REST API endpoint.
  endpoint: string,
  /// Backend version string, if connected.
  version: option<string>,
  /// Available provers from the catalog.
  provers: array<echidnaProver>,
  /// Result of the most recent proof dispatch.
  lastProofResult: option<echidnaDispatchResult>,
  /// Error message from the last proof operation.
  proofError: option<string>,
  /// Whether a proof dispatch is currently in flight.
  proofLoading: bool,
  /// Active interactive proof session, if any.
  session: option<echidnaSessionState>,
  /// Current tactic suggestions from the ML advisor.
  tacticSuggestions: array<echidnaTacticSuggestion>,
  /// Currently selected prover name for the next dispatch.
  selectedProver: option<string>,
  /// Raw proof input text from the editor.
  proofInput: string,
  /// Whether the ECHIDNA menu dropdown is expanded.
  menuExpanded: bool,
  /// Active tab within the ECHIDNA panel.
  activeTab: echidnaTab,
  /// Current tactic input text for the interactive session.
  tacticInput: string,
  /// Whether a session operation is in flight.
  sessionLoading: bool,
  /// TypeLL-generated proof obligations JSON for the last proof input (cross-panel intelligence).
  lastProofObligations: option<string>,
  /// When true, proof operations route through BoJ proof-mcp cartridge instead of direct ECHIDNA HTTP.
  bojRouting: bool,
  /// Enterprise architecture model checking state (MOF/OCL/ArchiMate/UML).
  /// ECHIDNA acts as the constraint solver for OMG and The Open Group standards.
  enterpriseModel: enterpriseModelState,
}
