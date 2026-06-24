// SPDX-License-Identifier: MPL-2.0

/// PanLL Editor Bridge Model — types for federating with external code
/// editors (VSCodium, Zed, Helix, Neovim, Emacs) via LSP, editor
/// extensions, or file watchers. PanLL is mission control, not a text
/// editor — this panel shows development context without duplicating
/// the editing surface.

/// Supported editor and modeling tool integrations.
/// Includes code editors (LSP), enterprise architecture tools (XMI/ArchiMate),
/// and diagram/design tools (model exchange protocols).
type editorKind =
  // Code editors (LSP protocol)
  | EditorVSCodium
  | EditorVSCode
  | EditorZed
  | EditorHelix
  | EditorNeovim
  | EditorEmacs
  | EditorKakoune
  // Enterprise architecture & modeling tools (XMI/model exchange)
  | EditorVisualParadigm // Visual Paradigm Enterprise (UML, ArchiMate, BPMN, SysML)
  | EditorSparxEA // Sparx Enterprise Architect (UML, SysML, ArchiMate)
  | EditorArchi // Archi (open-source ArchiMate modeling tool)
  | EditorCamundaModeler // Camunda Modeler (BPMN/DMN process modeling)
  | EditorMagicDraw // Dassault MagicDraw / Cameo (UML/SysML)
  // Custom
  | EditorCustom(string)

/// Editor connection state.
type editorConnection =
  | EditorDisconnected
  | EditorConnecting
  | EditorConnected(string)
  | EditorError(string)

/// A file currently open in the external editor.
type openEditorFile = {
  path: string,
  language: string,
  modified: bool,
  cursorLine: int,
  cursorCol: int,
  selections: int,
}

/// An LSP diagnostic from the editor.
type editorDiagnostic = {
  filePath: string,
  line: int,
  col: int,
  endLine: int,
  endCol: int,
  severity: string,
  message: string,
  source: string,
  code: string,
}

/// A symbol from the workspace (function, type, module).
type workspaceSymbol = {
  name: string,
  kind: string,
  filePath: string,
  line: int,
  containerName: string,
}

/// A recent editor action (for activity feed).
type editorAction = {
  timestamp: float,
  action: string,
  filePath: string,
  detail: string,
}

/// Category tabs for the Editor Bridge panel.
type editorBridgeCategory =
  | BridgeOverview
  | BridgeDiagnostics
  | BridgeSymbols
  | BridgeActivity
  | BridgeSettings

/// Root state for the Editor Bridge panel.
type editorBridgeState = {
  activeCategory: editorBridgeCategory,
  editorKind: editorKind,
  connection: editorConnection,
  openFiles: array<openEditorFile>,
  diagnostics: array<editorDiagnostic>,
  symbols: array<workspaceSymbol>,
  activity: array<editorAction>,
  selectedFilePath: option<string>,
  diagnosticFilter: string,
  symbolFilter: string,
  showWarnings: bool,
  showErrors: bool,
  showInfo: bool,
  autoSync: bool,
  lspPort: int,
  loading: bool,
  error: option<string>,
  /// Route LSP operations through BoJ's lsp-mcp cartridge instead of direct Gossamer.
  bojRouting: bool,
}
