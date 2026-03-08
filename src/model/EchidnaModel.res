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
  /// TypeLL-generated proof obligations JSON for the last proof input (cross-panel intelligence).
  lastProofObligations: option<string>,
}
