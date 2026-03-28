// SPDX-License-Identifier: PMPL-1.0-or-later

/// My-Lang AI-native language messages.

open Model

type myLangMsg =
  /// Set the active category tab.
  | SetMlCategory(myLangCategory)
  /// Switch the active dialect.
  | SetDialect(myLangDialect)
  /// Check whether CLI binary is available.
  | CheckMlCli
  /// CLI check result.
  | MlCliResult(result<string, string>)
  /// Update editor content.
  | UpdateEditor(string)
  /// Compile the current editor content.
  | Compile
  /// Compilation result from Gossamer backend.
  | CompileResult(result<string, string>)
  /// Update REPL input.
  | UpdateReplInput(string)
  /// Evaluate the current REPL input.
  | EvalRepl
  /// REPL evaluation result from Gossamer backend.
  | ReplResult(result<string, string>)
  /// TypeLL cross-panel type check result for the last compilation.
  | MlTypeCheckResult(result<string, string>)
  /// Connect to my-lang LSP server.
  | ConnectLsp
  /// LSP connection result.
  | LspConnected(result<string, string>)
  /// LSP diagnostics received for current editor content.
  | LspDiagnosticsReceived(array<string>)
  /// Request diagnostics from LSP.
  | RequestDiagnostics
  /// Toggle BoJ routing for My-Lang operations (lsp-mcp cartridge).
  | ToggleMyLangBojRouting
