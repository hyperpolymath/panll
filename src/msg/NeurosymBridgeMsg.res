// SPDX-License-Identifier: PMPL-1.0-or-later

/// Neurosymbolic Bridge messages -- guard AI behaviour reasoning via ECHIDNA.

open Model

type neurosymBridgeMsg =
  | SetNbTab(neurosymBridgeTab)
  | NbStarted
  | NbCompleted(result<string, string>)
  | DismissNbError
