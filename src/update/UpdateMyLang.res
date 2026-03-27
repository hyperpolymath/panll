// SPDX-License-Identifier: PMPL-1.0-or-later
// UpdateMyLang.res — MyLang (nextgen language playground) sub-updater extracted from Update.res

open Model
open Msg

let updateMyLang = (model: model, msg: myLangMsg): (model, Tea_Cmd.t<msg>) => {
  let ml = model.myLang
  switch msg {
  | SetMlCategory(cat) => ({...model, myLang: {...ml, activeCategory: cat}}, Tea_Cmd.none)
  | SetDialect(d) => {
      // #9: Save current REPL session before switching dialect.
      let savedSessions =
        ml.replSessions->Array.filter(((dialect, _)) => dialect !== ml.activeDialect)
      let sessionId = `session-${MyLangEngine.dialectLabel(ml.activeDialect)}`
      let savedSessions = Array.concat(savedSessions, [(ml.activeDialect, sessionId)])
      // Restore REPL history for the new dialect (or start fresh).
      (
        {
          ...model,
          myLang: {
            ...ml,
            activeDialect: d,
            editorContent: MyLangEngine.dialectExample(d),
            replSessions: savedSessions,
            lspDiagnostics: [], // Clear diagnostics on dialect switch
          },
        },
        Tea_Cmd.none,
      )
    }
  | CheckMlCli => (
      {...model, myLang: {...ml, loading: true}},
      MyLangCmd.checkCli(result => MyLang(MlCliResult(result))),
    )
  | MlCliResult(Ok(_)) => (
      {...model, myLang: {...ml, cliAvailable: true, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | MlCliResult(Error(e)) => (
      {...model, myLang: {...ml, cliAvailable: false, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | UpdateEditor(v) => ({...model, myLang: {...ml, editorContent: v}}, Tea_Cmd.none)
  | Compile => {
      let dialectStr = MyLangEngine.dialectLabel(ml.activeDialect)
      let compileCmd = if ml.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "lsp-mcp",
          "compile",
          `{"code": "${ml.editorContent}", "dialect": "${dialectStr}"}`,
          result => MyLang(CompileResult(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        MyLangCmd.compile(ml.editorContent, dialectStr, result => MyLang(CompileResult(result)))
      }
      (
        {...model, myLang: {...ml, loading: true, error: None, lastTypeCheck: None}},
        Tea_Cmd.batch(list{
          compileCmd,
          TypeLLService.checkMyLangTypes(ml.editorContent, dialectStr, result => MyLang(
            MlTypeCheckResult(result),
          )),
        }),
      )
    }
  | CompileResult(Ok(json)) =>
    switch MyLangEngine.parseCompilation(json) {
    | Ok(result) => (
        {...model, myLang: {...ml, loading: false, lastCompilation: Some(result), error: None}},
        Tea_Cmd.none,
      )
    | Error(e) => ({...model, myLang: {...ml, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | CompileResult(Error(e)) => (
      {...model, myLang: {...ml, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | UpdateReplInput(v) => ({...model, myLang: {...ml, replInput: v}}, Tea_Cmd.none)
  | EvalRepl =>
    if ml.replInput === "" {
      (model, Tea_Cmd.none)
    } else {
      let dialectStr = MyLangEngine.dialectLabel(ml.activeDialect)
      let evalCmd = if ml.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "lsp-mcp",
          "repl",
          `{"input": "${ml.replInput}", "dialect": "${dialectStr}"}`,
          result => MyLang(ReplResult(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        MyLangCmd.replEval(ml.replInput, dialectStr, result => MyLang(ReplResult(result)))
      }
      ({...model, myLang: {...ml, loading: true, replInput: ""}}, evalCmd)
    }
  | ReplResult(Ok(output)) => {
      let entry: replEntry = {
        input: ml.replInput !== "" ? ml.replInput : "(previous input)",
        output,
        isError: false,
      }
      (
        {
          ...model,
          myLang: {...ml, loading: false, replHistory: Array.concat(ml.replHistory, [entry])},
        },
        Tea_Cmd.none,
      )
    }
  | ReplResult(Error(e)) => {
      let entry: replEntry = {
        input: ml.replInput !== "" ? ml.replInput : "(previous input)",
        output: e,
        isError: true,
      }
      (
        {
          ...model,
          myLang: {...ml, loading: false, replHistory: Array.concat(ml.replHistory, [entry])},
        },
        Tea_Cmd.none,
      )
    }
  | MlTypeCheckResult(Ok(json)) => {
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, myLang: {...ml, lastTypeCheck: Some(json)}, typell: newTypell}, Tea_Cmd.none)
    }
  | MlTypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  // #8: LSP integration for syntax highlighting and diagnostics.
  | ConnectLsp => (
      {...model, myLang: {...ml, loading: true}},
      MyLangCmd.connectLsp(result => MyLang(LspConnected(result))),
    )
  | LspConnected(Ok(_)) => (
      {...model, myLang: {...ml, lspConnected: true, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | LspConnected(Error(e)) => (
      {...model, myLang: {...ml, lspConnected: false, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | LspDiagnosticsReceived(diagnostics) => (
      {...model, myLang: {...ml, lspDiagnostics: diagnostics}},
      Tea_Cmd.none,
    )
  | RequestDiagnostics =>
    if ml.lspConnected {
      let filePath = "panll://mylang/" ++ MyLangEngine.dialectLabel(ml.activeDialect) ++ "/input"
      (
        model,
        MyLangCmd.requestDiagnostics(filePath, ml.editorContent, result =>
          switch result {
          | Ok(json) => MyLang(LspDiagnosticsReceived([json]))
          | Error(e) => MyLang(LspDiagnosticsReceived([e]))
          }
        ),
      )
    } else {
      (model, Tea_Cmd.none)
    }
  | ToggleMyLangBojRouting => (
      {...model, myLang: {...ml, bojRouting: !ml.bojRouting}},
      Tea_Cmd.none,
    )
  }
}
