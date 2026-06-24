// SPDX-License-Identifier: MPL-2.0

/// ECHIDNA theorem prover backend messages -- connection lifecycle, prover
/// catalog browsing, proof submission/verification, interactive sessions
/// (Phase 2 stub), tactic suggestions (Phase 2 stub), theorem search,
/// and UI state toggles.

open Model

type echidnaMsg =
  // Connection lifecycle
  | CheckHealth
  | HealthOk(string)
  | HealthError(string)
  // Prover catalog
  | ListProvers
  | ProversLoaded(result<string, string>)
  // Proof submission and verification
  | SubmitProof
  | ProofResult(result<string, string>)
  | SubmitVerify
  | VerifyResult(result<string, string>)
  // Theorem search
  | SearchTheorems(string)
  | SearchResult(result<string, string>)
  // Interactive sessions
  | CreateSession
  | SessionCreated(result<string, string>)
  | ApplyTactic(string, array<string>)
  | TacticApplied(result<string, string>)
  | GetSessionState
  | SessionStateLoaded(result<string, string>)
  | CancelSession
  | UpdateTacticInput(string)
  // Tactic suggestions
  | RequestTacticSuggestions
  | TacticSuggestionsLoaded(result<string, string>)
  // UI state
  | ToggleMenu
  | UpdateProofInput(string)
  | SelectProver(option<string>)
  | ClearProofResult
  /// TypeLL-generated proof obligations for the current proof input.
  | ProofObligationsGenerated(result<string, string>)
  /// Toggle BoJ routing for proof operations (proof-mcp cartridge).
  | ToggleEchidnaBojRouting
  /// Switch ECHIDNA panel tab (Proof / Enterprise).
  | SelectEchidnaTab(echidnaTab)
  // Enterprise model checking (MOF/OCL)
  /// Import model elements from XMI file.
  | ImportXmiModel
  /// XMI model loaded and parsed.
  | XmiModelLoaded(result<string, string>)
  /// Add an OCL constraint to the enterprise model.
  | AddOclConstraint(string, string, string) // context, name, expression
  /// Remove an OCL constraint by index.
  | RemoveOclConstraint(int)
  /// Run batch OCL constraint checking against loaded model.
  | RunOclCheck
  /// OCL batch check completed.
  | OclCheckResult(result<string, string>)
  /// Filter by metamodel standard.
  | SetMetamodelFilter(option<metamodelStandard>)
  /// Filter by MOF layer.
  | SetMofLayerFilter(option<mofLayer>)
  /// Clear enterprise model state.
  | ClearEnterpriseModel
