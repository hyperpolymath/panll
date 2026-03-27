// SPDX-License-Identifier: PMPL-1.0-or-later
// UpdateEditorBridge.res — Editor Bridge (external editor federation) sub-updater extracted from Update.res

open Model
open Msg

/// Handles all Editor Bridge (external editor federation) messages.
let updateEditorBridge = (model: model, msg: editorBridgeMsg): (model, Tea_Cmd.t<msg>) => {
  let eb = model.editorBridge
  switch msg {
  | SetBridgeCategory(cat) => ({...model, editorBridge: {...eb, activeCategory: cat}}, Tea_Cmd.none)
  | DetectEditor => (
      {...model, editorBridge: {...eb, loading: true}},
      EditorBridgeCmd.detectEditor(result => EditorBridge(EditorDetected(result))),
    )
  | EditorDetected(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let editorStr =
          obj->Dict.get("editorKind")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let editorKind: EditorBridgeModel.editorKind = switch editorStr {
        | "vscodium" => EditorVSCodium
        | "vscode" => EditorVSCode
        | "zed" => EditorZed
        | "helix" => EditorHelix
        | "neovim" => EditorNeovim
        | "emacs" => EditorEmacs
        | "kakoune" => EditorKakoune
        | other => EditorCustom(other)
        }
        let connStr =
          obj
          ->Dict.get("connection")
          ->Option.flatMap(JSON.Decode.string)
          ->Option.getOr("disconnected")
        let connection: EditorBridgeModel.editorConnection = switch connStr {
        | "connected" => EditorConnected(editorStr)
        | "connecting" => EditorConnecting
        | _ => EditorDisconnected
        }
        Some((editorKind, connection))

      | None => None
      }
      switch parsed {
      | Some((editorKind, connection)) => (
          {...model, editorBridge: {...eb, editorKind, connection, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, editorBridge: {...eb, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | EditorDetected(Error(err)) => (
      {...model, editorBridge: {...eb, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ConnectLsp => (
      {...model, editorBridge: {...eb, connection: EditorConnecting}},
      if eb.bojRouting {
        // Route through BoJ's lsp-mcp cartridge.
        let args = `{"port": ${Int.toString(eb.lspPort)}}`
        Tea_Cmd.batch(list{
          BojCmd.invokeCartridgeWithLatency(
            "lsp-mcp",
            "connect",
            args,
            result => EditorBridge(LspConnected(result)),
            (c, t, e) => RecordBojLatency(c, t, e),
          ),
          Tea_Cmd.msg(Vexometer(RecordVqlQuery)),
          TypeLLService.checkConfigTypes(args, "editor-bridge", result => EditorBridge(
            TypeCheckResult(result),
          )),
        })
      } else {
        Tea_Cmd.batch(list{
          EditorBridgeCmd.connectLsp(eb.lspPort, result => EditorBridge(LspConnected(result))),
          TypeLLService.checkConfigTypes(
            Int.toString(eb.lspPort),
            "editor-bridge",
            result => EditorBridge(TypeCheckResult(result)),
          ),
        })
      },
    )
  | LspConnected(Ok(info)) => (
      {...model, editorBridge: {...eb, connection: EditorConnected(info), error: None}},
      Tea_Cmd.none,
    )
  | LspConnected(Error(err)) => (
      {...model, editorBridge: {...eb, connection: EditorError(err), error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshDiagnostics => (
      {...model, editorBridge: {...eb, loading: true}},
      if eb.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "lsp-mcp",
          "diagnostics",
          "{}",
          result => EditorBridge(DiagnosticsReceived(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        EditorBridgeCmd.readDiagnostics(result => EditorBridge(DiagnosticsReceived(result)))
      },
    )
  | DiagnosticsReceived(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let filePath =
            obj->Dict.get("filePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let line = obj->Dict.get("line")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let col = obj->Dict.get("col")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let endLine =
            obj->Dict.get("endLine")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let endCol = obj->Dict.get("endCol")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let severity =
            obj->Dict.get("severity")->Option.flatMap(JSON.Decode.string)->Option.getOr("warning")
          let message =
            obj->Dict.get("message")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let source = obj->Dict.get("source")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let code = obj->Dict.get("code")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          Some({
            EditorBridgeModel.filePath,
            line: Float.toInt(line),
            col: Float.toInt(col),
            endLine: Float.toInt(endLine),
            endCol: Float.toInt(endCol),
            severity,
            message,
            source,
            code,
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(diagnostics) => (
          {...model, editorBridge: {...eb, diagnostics, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, editorBridge: {...eb, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | DiagnosticsReceived(Error(err)) => (
      {...model, editorBridge: {...eb, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshOpenFiles => (
      {...model, editorBridge: {...eb, loading: true}},
      EditorBridgeCmd.readOpenFiles(result => EditorBridge(OpenFilesReceived(result))),
    )
  | OpenFilesReceived(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let path = obj->Dict.get("path")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let language =
            obj->Dict.get("language")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let modified =
            obj->Dict.get("modified")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let cursorLine =
            obj->Dict.get("cursorLine")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let cursorCol =
            obj->Dict.get("cursorCol")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let selections =
            obj->Dict.get("selections")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          Some({
            EditorBridgeModel.path,
            language,
            modified,
            cursorLine: Float.toInt(cursorLine),
            cursorCol: Float.toInt(cursorCol),
            selections: Float.toInt(selections),
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(openFiles) => (
          {...model, editorBridge: {...eb, openFiles, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, editorBridge: {...eb, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | OpenFilesReceived(Error(err)) => (
      {...model, editorBridge: {...eb, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshSymbols => (
      {...model, editorBridge: {...eb, loading: true}},
      if eb.bojRouting {
        let args = `{"query": "${eb.symbolFilter}"}`
        BojCmd.invokeCartridgeWithLatency(
          "lsp-mcp",
          "symbols",
          args,
          result => EditorBridge(SymbolsReceived(result)),
          (c, t, e) => RecordBojLatency(c, t, e),
        )
      } else {
        EditorBridgeCmd.readSymbols(eb.symbolFilter, result => EditorBridge(
          SymbolsReceived(result),
        ))
      },
    )
  | SymbolsReceived(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let kind = obj->Dict.get("kind")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let filePath =
            obj->Dict.get("filePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let line = obj->Dict.get("line")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let containerName =
            obj->Dict.get("containerName")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          Some({
            EditorBridgeModel.name,
            kind,
            filePath,
            line: Float.toInt(line),
            containerName,
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(symbols) => (
          {...model, editorBridge: {...eb, symbols, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, editorBridge: {...eb, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | SymbolsReceived(Error(err)) => (
      {...model, editorBridge: {...eb, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | OpenFileInEditor(path, line) => (
      model,
      EditorBridgeCmd.openFileAtLine(path, line, result => EditorBridge(FileOpened(result))),
    )
  | FileOpened(Ok(_)) => (model, Tea_Cmd.none)
  | FileOpened(Error(err)) => ({...model, editorBridge: {...eb, error: Some(err)}}, Tea_Cmd.none)
  | RefreshBridge => (
      {...model, editorBridge: {...eb, loading: true}},
      EditorBridgeCmd.detectEditor(result => EditorBridge(EditorDetected(result))),
    )
  | SetDiagnosticFilter(text) => (
      {...model, editorBridge: {...eb, diagnosticFilter: text}},
      Tea_Cmd.none,
    )
  | ToggleShowErrors => (
      {...model, editorBridge: {...eb, showErrors: !eb.showErrors}},
      Tea_Cmd.none,
    )
  | ToggleShowWarnings => (
      {...model, editorBridge: {...eb, showWarnings: !eb.showWarnings}},
      Tea_Cmd.none,
    )
  | ToggleShowInfo => ({...model, editorBridge: {...eb, showInfo: !eb.showInfo}}, Tea_Cmd.none)
  | SetSymbolFilter(text) => ({...model, editorBridge: {...eb, symbolFilter: text}}, Tea_Cmd.none)
  | SetEditorKind(editor) => ({...model, editorBridge: {...eb, editorKind: editor}}, Tea_Cmd.none)
  | ToggleAutoSync => ({...model, editorBridge: {...eb, autoSync: !eb.autoSync}}, Tea_Cmd.none)
  | ToggleBojRouting => (
      {...model, editorBridge: {...eb, bojRouting: !eb.bojRouting}},
      Tea_Cmd.none,
    )
  | DismissBridgeError => ({...model, editorBridge: {...eb, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "editorbridge", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
