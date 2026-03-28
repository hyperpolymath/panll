// SPDX-License-Identifier: PMPL-1.0-or-later

/// Proofs Bridge messages -- proven repo formal verification integration.

open Model

type proofsBridgeMsg =
  | SetPrBTab(proofsBridgeTab)
  | PrBStarted
  | PrBCompleted(result<string, string>)
  | DismissPrBError
