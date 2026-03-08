// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL My-Lang Commands — Tauri wrappers for the AI-native language tools.
///
/// Invokes the my-lang CLI through Tauri backend commands.
/// The Rust backend shells out to `my compile`, `my repl`, etc.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Check whether the my-lang CLI binary is available.
let checkCli = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
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
let compile = (
  source: string,
  dialect: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
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

/// Send a line to the REPL. Returns the REPL output.
let replEval = (
  input: string,
  dialect: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
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
