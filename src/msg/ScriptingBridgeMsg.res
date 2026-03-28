// SPDX-License-Identifier: PMPL-1.0-or-later

/// Scripting Bridge messages -- VM instruction scripting REPL.

open Model

type scriptingBridgeMsg =
  | SetScBTab(scriptingBridgeTab)
  | ScBStarted
  | ScBCompleted(result<string, string>)
  | DismissScBError
