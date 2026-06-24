// SPDX-License-Identifier: MPL-2.0

/// Protocol Bridge messages -- multiplayer sync protocol analysis.

open Model

type protocolBridgeMsg =
  | SetPbTab(protocolBridgeTab)
  | PbStarted
  | PbCompleted(result<string, string>)
  | DismissPbError
