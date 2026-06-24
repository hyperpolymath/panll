// SPDX-License-Identifier: MPL-2.0

/// Proofs Bridge messages -- proven repo formal verification integration.

open Model

type proofsBridgeMsg =
  | SetPrBTab(proofsBridgeTab)
  | PrBStarted
  | PrBCompleted(result<string, string>)
  | DismissPrBError
