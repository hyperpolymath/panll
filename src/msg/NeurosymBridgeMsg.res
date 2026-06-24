// SPDX-License-Identifier: MPL-2.0

/// Neurosymbolic Bridge messages -- guard AI behaviour reasoning via ECHIDNA.

open Model

type neurosymBridgeMsg =
  | SetNbTab(neurosymBridgeTab)
  | NbStarted
  | NbCompleted(result<string, string>)
  | DismissNbError
