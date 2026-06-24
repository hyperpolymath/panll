// SPDX-License-Identifier: MPL-2.0

/// Editor Bridge messages -- editor detection, LSP lifecycle, diagnostics,
/// symbols, open files, jump-to-line, and settings for the external code
/// editor federation panel.

open Model

type editorBridgeMsg =
  /// Switch the active category tab.
  | SetBridgeCategory(editorBridgeCategory)
  /// Detect which editor is running.
  | DetectEditor
  /// Editor detection result.
  | EditorDetected(result<string, string>)
  /// Connect to the editor's LSP server.
  | ConnectLsp
  /// LSP connection result.
  | LspConnected(result<string, string>)
  /// Refresh diagnostics from LSP.
  | RefreshDiagnostics
  /// Diagnostics received.
  | DiagnosticsReceived(result<string, string>)
  /// Refresh open files list.
  | RefreshOpenFiles
  /// Open files received.
  | OpenFilesReceived(result<string, string>)
  /// Refresh workspace symbols.
  | RefreshSymbols
  /// Symbols received.
  | SymbolsReceived(result<string, string>)
  /// Open a file at a specific line in the external editor.
  | OpenFileInEditor(string, int)
  /// File opened (or failed).
  | FileOpened(result<string, string>)
  /// Refresh the bridge status.
  | RefreshBridge
  /// Set the diagnostic filter text.
  | SetDiagnosticFilter(string)
  /// Toggle BoJ routing -- route LSP through lsp-mcp cartridge.
  | ToggleBojRouting
  /// Toggle error visibility.
  | ToggleShowErrors
  /// Toggle warning visibility.
  | ToggleShowWarnings
  /// Toggle info visibility.
  | ToggleShowInfo
  /// Set the symbol search filter.
  | SetSymbolFilter(string)
  /// Set the preferred editor kind.
  | SetEditorKind(editorKind)
  /// Toggle auto-sync with the editor.
  | ToggleAutoSync
  /// Dismiss the error banner.
  | DismissBridgeError
  /// TypeLL cross-panel type check result for LSP diagnostics types.
  | TypeCheckResult(result<string, string>)
