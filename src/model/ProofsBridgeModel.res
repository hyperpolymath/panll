// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Proofs Bridge Model — connects the proven repo's formally verified
/// libraries to IDApTIK game development. Bridges ECHIDNA verification with
/// SafeMath, SafeString, SafeCrypto, SafeInput, and SafeJson modules used
/// in game code.
///
/// Three-panel model (L/N/W):
///   L: Proven repo interface specs (SafeMath/SafeString/SafeCrypto/SafeInput/SafeJson)
///   N: ECHIDNA verification reasoning about proof coverage and soundness
///   W: Proof status badges per module with coverage metrics
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Tab Navigation
// ============================================================================

/// Category tabs for the Proofs Bridge panel.
type proofsBridgeTab =
  /// Modules — browse proven library modules and their functions.
  | Modules
  /// Proofs — view individual proof results and details.
  | Proofs
  /// Coverage — proof coverage metrics across all modules.
  | Coverage
  /// Verification — run and monitor ECHIDNA verification sessions.
  | Verification

// ============================================================================
// Proven Module Domain
// ============================================================================

/// Verification status of a proven module.
type moduleVerificationStatus =
  /// FullyProven — all functions in this module have formal proofs.
  | FullyProven
  /// PartiallyProven — some functions are proven, others pending.
  | PartiallyProven
  /// Unverified — no proofs have been completed for this module.
  | Unverified
  /// Stale — proofs exist but the code has changed since last verification.
  | Stale

/// A proven library module with its verification status.
type provenModule = {
  /// Module name (e.g., "SafeMath", "SafeString", "SafeCrypto").
  name: string,
  /// Verification status.
  status: moduleVerificationStatus,
  /// Total number of exported functions in this module.
  functionCount: int,
  /// Number of functions with completed proofs.
  provedCount: int,
  /// Timestamp of last successful verification (milliseconds since epoch).
  lastVerified: option<float>,
  /// Module description.
  description: string,
}

// ============================================================================
// Verification Results
// ============================================================================

/// Result of verifying a single function within a proven module.
type verificationResultKind =
  /// Proved — the function's specification is formally verified.
  | VerificationProved
  /// Counterexample — a counterexample was found violating the spec.
  | VerificationCounterexample
  /// Timeout — the prover timed out.
  | VerificationTimeout
  /// Error — an error occurred during verification.
  | VerificationError

/// A single verification result from ECHIDNA.
type verificationResult = {
  /// Unique result identifier.
  id: string,
  /// Module containing the verified function.
  moduleName: string,
  /// Function name that was verified.
  functionName: string,
  /// Specification that was checked.
  specification: string,
  /// Verification outcome.
  kind: verificationResultKind,
  /// Prover used (e.g., "Z3", "CVC5", "Coq").
  proverUsed: string,
  /// Verification duration in milliseconds.
  durationMs: float,
  /// Counterexample if the spec was violated.
  counterexample: option<string>,
  /// Error message if verification errored.
  errorMessage: option<string>,
}

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Proofs Bridge panel.
type proofsBridgeState = {
  /// Active tab within the Proofs Bridge panel.
  activeTab: proofsBridgeTab,
  /// All registered proven library modules.
  provenModules: array<provenModule>,
  /// Verification results from ECHIDNA (most recent first).
  verificationResults: array<verificationResult>,
  /// Overall proof coverage percentage across all modules (0.0 to 100.0).
  coveragePercent: float,
  /// Whether an ECHIDNA verification session is in progress.
  verifying: bool,
  /// Error from the last operation.
  error: option<string>,
}
