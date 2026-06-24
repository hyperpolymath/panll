// SPDX-License-Identifier: MPL-2.0

/// PanLL Editor Bridge Commands — backend invoke wrappers for connecting
/// to external editors via LSP, extension protocols, or file watchers.

let invoke = RuntimeBridge.invoke

/// Detect which editor is running and attempt to connect.
let detectEditor = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("editor_bridge_detect", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("No supported editor detected")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Connect to an editor via LSP on a given port.
let connectLsp = (port: int, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("editor_bridge_connect_lsp", {"port": port})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to connect to LSP")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read diagnostics from the connected editor.
let readDiagnostics = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("editor_bridge_diagnostics", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read diagnostics")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read open files from the connected editor.
let readOpenFiles = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("editor_bridge_open_files", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read open files")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Read workspace symbols.
let readSymbols = (query: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("editor_bridge_symbols", {"query": query})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to read symbols")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Tell the external editor to open a file at a specific line.
let openFileAtLine = (
  filePath: string,
  line: int,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("editor_bridge_open_file", {"filePath": filePath, "line": line})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to open file in editor")))
      Promise.resolve()
    })
    ->ignore
  })
}
