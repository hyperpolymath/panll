// SPDX-License-Identifier: MPL-2.0

/// Scripting Bridge messages -- VM instruction scripting REPL.

open Model

type scriptingBridgeMsg =
  | SetScBTab(scriptingBridgeTab)
  | ScBStarted
  | ScBCompleted(result<string, string>)
  | DismissScBError
