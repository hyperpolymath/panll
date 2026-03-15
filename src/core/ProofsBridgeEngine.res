// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Proofs Bridge Engine — pure computation and helpers for the
/// Proofs Bridge panel. Provides default state, tab metadata, proof coverage
/// computation, module verification counting, and pending proof tracking.

open ProofsBridgeModel

/// Default state for the Proofs Bridge panel.
/// Starts on the Modules tab with empty module and result lists.
let defaultState: proofsBridgeState = {
  activeTab: Modules,
  provenModules: [],
  verificationResults: [],
  coveragePercent: 0.0,
  verifying: false,
  error: None,
}

/// Human-readable label for each tab in the Proofs Bridge panel.
let tabLabel = (tab: proofsBridgeTab): string =>
  switch tab {
  | Modules => "Modules"
  | Proofs => "Proofs"
  | Coverage => "Coverage"
  | Verification => "Verification"
  }

/// All tabs in display order.
let allTabs: array<proofsBridgeTab> = [Modules, Proofs, Coverage, Verification]

/// Compute the overall proof coverage percentage across all modules (0.0 to 100.0).
/// This is the ratio of proved functions to total functions across all modules.
/// Returns 100.0 when there are no functions to verify.
let overallProofCoverage = (modules: array<provenModule>): float => {
  let totalFunctions = modules->Array.reduce(0, (acc, m) => acc + m.functionCount)
  if totalFunctions === 0 {
    100.0
  } else {
    let totalProved = modules->Array.reduce(0, (acc, m) => acc + m.provedCount)
    Int.toFloat(totalProved) /. Int.toFloat(totalFunctions) *. 100.0
  }
}

/// Count modules that are fully verified (all functions proved).
let countVerifiedModules = (modules: array<provenModule>): int =>
  modules->Array.filter(m => m.status === FullyProven)->Array.length

/// Count modules that still have pending (unverified or stale) proofs.
let countPendingModules = (modules: array<provenModule>): int =>
  modules->Array.filter(m =>
    switch m.status {
    | Unverified | Stale | PartiallyProven => true
    | FullyProven => false
    }
  )->Array.length

/// Count modules matching a given verification status.
let countModulesByStatus = (modules: array<provenModule>, status: moduleVerificationStatus): int =>
  modules->Array.filter(m => m.status === status)->Array.length

/// Human-readable label for a module verification status.
let verificationStatusLabel = (status: moduleVerificationStatus): string =>
  switch status {
  | FullyProven => "Fully Proven"
  | PartiallyProven => "Partially Proven"
  | Unverified => "Unverified"
  | Stale => "Stale"
  }

/// Human-readable label for a verification result kind.
let resultKindLabel = (kind: verificationResultKind): string =>
  switch kind {
  | VerificationProved => "Proved"
  | VerificationCounterexample => "Counterexample"
  | VerificationTimeout => "Timeout"
  | VerificationError => "Error"
  }

/// Count verification results by outcome kind.
let countResultsByKind = (results: array<verificationResult>, kind: verificationResultKind): int =>
  results->Array.filter(r => r.kind === kind)->Array.length

/// Count the total number of functions across all modules that lack proofs.
let countUnprovedFunctions = (modules: array<provenModule>): int =>
  modules->Array.reduce(0, (acc, m) => acc + (m.functionCount - m.provedCount))
