// SPDX-License-Identifier: PMPL-1.0-or-later

/// Protocol Bridge messages -- multiplayer sync protocol analysis.

open Model

type protocolBridgeMsg =
  | SetPbTab(protocolBridgeTab)
  | PbStarted
  | PbCompleted(result<string, string>)
  | DismissPbError
