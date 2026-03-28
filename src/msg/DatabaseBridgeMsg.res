// SPDX-License-Identifier: PMPL-1.0-or-later

/// Database Bridge messages -- VeriSimDB game state persistence.

open Model

type databaseBridgeMsg =
  | SetDbBTab(databaseBridgeTab)
  | DbBStarted
  | DbBCompleted(result<string, string>)
  | DismissDbBError
