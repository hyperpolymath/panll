// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Editor Bridge Engine — pure computation and helpers for
/// federating with external code editors.

open EditorBridgeModel

/// Human-readable labels for category tabs.
let categoryLabel = (cat: editorBridgeCategory): string =>
  switch cat {
  | BridgeOverview => "Overview"
  | BridgeDiagnostics => "Diagnostics"
  | BridgeSymbols => "Symbols"
  | BridgeActivity => "Activity"
  | BridgeSettings => "Settings"
  }

/// Human-readable editor name.
let editorLabel = (editor: editorKind): string =>
  switch editor {
  | EditorVSCodium => "VSCodium"
  | EditorVSCode => "VS Code"
  | EditorZed => "Zed"
  | EditorHelix => "Helix"
  | EditorNeovim => "Neovim"
  | EditorEmacs => "Emacs"
  | EditorKakoune => "Kakoune"
  | EditorCustom(name) => name
  }

/// All supported editors.
let allEditors: array<editorKind> = [
  EditorVSCodium,
  EditorVSCode,
  EditorZed,
  EditorHelix,
  EditorNeovim,
  EditorEmacs,
  EditorKakoune,
]

/// Connection state label.
let connectionLabel = (conn: editorConnection): string =>
  switch conn {
  | EditorDisconnected => "Disconnected"
  | EditorConnecting => "Connecting..."
  | EditorConnected(version) => `Connected (${version})`
  | EditorError(err) => `Error: ${err}`
  }

/// Connection colour.
let connectionColour = (conn: editorConnection): string =>
  switch conn {
  | EditorDisconnected => "text-gray-500"
  | EditorConnecting => "text-amber-400"
  | EditorConnected(_) => "text-emerald-400"
  | EditorError(_) => "text-red-400"
  }

/// Severity colour for diagnostics.
let severityColour = (severity: string): string =>
  switch severity {
  | "error" => "text-red-400"
  | "warning" => "text-amber-400"
  | "info" => "text-blue-400"
  | "hint" => "text-gray-400"
  | _ => "text-gray-400"
  }

/// Filter diagnostics by severity flags.
let filterDiagnostics = (
  diagnostics: array<editorDiagnostic>,
  showErrors: bool,
  showWarnings: bool,
  showInfo: bool,
  filterText: string,
): array<editorDiagnostic> => {
  let bySeverity = diagnostics->Array.filter(d =>
    switch d.severity {
    | "error" => showErrors
    | "warning" => showWarnings
    | "info" | "hint" => showInfo
    | _ => true
    }
  )
  if filterText === "" {
    bySeverity
  } else {
    let lower = String.toLowerCase(filterText)
    bySeverity->Array.filter(d =>
      String.includes(String.toLowerCase(d.message), lower) ||
      String.includes(String.toLowerCase(d.filePath), lower)
    )
  }
}

/// Filter symbols by text.
let filterSymbols = (symbols: array<workspaceSymbol>, filterText: string): array<workspaceSymbol> => {
  if filterText === "" {
    symbols
  } else {
    let lower = String.toLowerCase(filterText)
    symbols->Array.filter(s =>
      String.includes(String.toLowerCase(s.name), lower) ||
      String.includes(String.toLowerCase(s.containerName), lower)
    )
  }
}

/// Count diagnostics by severity.
let countBySeverity = (diagnostics: array<editorDiagnostic>, severity: string): int =>
  diagnostics->Array.filter(d => d.severity === severity)->Array.length

/// Default state for the Editor Bridge panel.
let defaultState: editorBridgeState = {
  activeCategory: BridgeOverview,
  editorKind: EditorVSCodium,
  connection: EditorDisconnected,
  openFiles: [],
  diagnostics: [],
  symbols: [],
  activity: [],
  selectedFilePath: None,
  diagnosticFilter: "",
  symbolFilter: "",
  showWarnings: true,
  showErrors: true,
  showInfo: false,
  autoSync: true,
  lspPort: 6008,
  loading: false,
  error: None,
}
