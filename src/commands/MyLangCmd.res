// SPDX-License-Identifier: MPL-2.0

/// PanLL My-Lang Commands — Backend wrappers for the AI-native language tools.
///
/// Invokes the my-lang CLI through backend commands.
/// The Rust backend shells out to `my compile`, `my repl`, etc.

let invoke = RuntimeBridge.invoke

/// Check whether the my-lang CLI binary is available.
let checkCli = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("mylang_check", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("my-lang CLI not found")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Compile source code in a given dialect. Returns JSON compilation result.
let compile = (source: string, dialect: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("mylang_compile", {"source": source, "dialect": dialect})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Compilation failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Connect to the my-lang LSP server. Returns connection status JSON.
let connectLsp = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("mylang_lsp_connect", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("LSP connection failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Request diagnostics from the my-lang LSP for a file.
/// Sends content to the LSP and returns diagnostic JSON.
let requestDiagnostics = (
  filePath: string,
  content: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("mylang_lsp_diagnostics", {"file_path": filePath, "content": content})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("LSP diagnostics request failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Send a line to the REPL. Returns the REPL output.
let replEval = (input: string, dialect: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<
  'msg,
> => {
  Tea_Cmd.call(callbacks => {
    invoke("mylang_repl", {"input": input, "dialect": dialect})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("REPL evaluation failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
