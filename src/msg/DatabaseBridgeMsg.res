// SPDX-License-Identifier: MPL-2.0

/// Database Bridge messages -- VeriSimDB game state persistence.

open Model

type databaseBridgeMsg =
  | SetDbBTab(databaseBridgeTab)
  | DbBStarted
  | DbBCompleted(result<string, string>)
  | DismissDbBError
