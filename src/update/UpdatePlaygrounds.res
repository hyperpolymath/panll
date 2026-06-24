// SPDX-License-Identifier: MPL-2.0
open Model
open Msg

let updatePlaygrounds = (model: model, msg: playgroundsMsg): (model, Tea_Cmd.t<msg>) => {
  let pg = model.playgrounds
  switch msg {
  | SetPlayCategory(cat) => ({...model, playgrounds: {...pg, activeCategory: cat}}, Tea_Cmd.none)
  | SetLanguage(lang) => ({...model, playgrounds: {...pg, activeLanguage: lang}}, Tea_Cmd.none)
  | UpdateCode(code) => ({...model, playgrounds: {...pg, editorContent: code}}, Tea_Cmd.none)
  | Execute => (
      {...model, playgrounds: {...pg, executing: true, error: None}},
      Tea_Cmd.batch(list{
        PlaygroundsCmd.executeQuery(
          PlaygroundsEngine.languageLabel(pg.activeLanguage),
          pg.editorContent,
          result => Playgrounds(ExecuteResult(result)),
        ),
        TypeLLService.checkCodeTypes(
          pg.editorContent,
          PlaygroundsEngine.languageLabel(pg.activeLanguage),
          result => Playgrounds(TypeCheckResult(result)),
        ),
      }),
    )
  | ExecuteResult(result) =>
    switch result {
    | Ok(_jsonStr) => (
        {
          ...model,
          playgrounds: {
            ...pg,
            executing: false,
            lastResult: Some({
              success: true,
              data: Some(_jsonStr),
              error: None,
              durationMs: 0.0,
              rowCount: 0,
            }),
          },
        },
        Tea_Cmd.none,
      )
    | Error(e) => (
        {
          ...model,
          playgrounds: {
            ...pg,
            executing: false,
            lastResult: Some({
              success: false,
              data: None,
              error: Some(e),
              durationMs: 0.0,
              rowCount: 0,
            }),
          },
        },
        Tea_Cmd.none,
      )
    }
  | LoadSnippet(snippetId) => {
      let snippet = pg.snippets->Array.find(s => s.id === snippetId)
      switch snippet {
      | Some(s) => (
          {...model, playgrounds: {...pg, editorContent: s.code, activeLanguage: s.language}},
          Tea_Cmd.none,
        )
      | None => (model, Tea_Cmd.none)
      }
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "playgrounds", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | SetNqcInput(text) => ({...model, playgrounds: {...pg, nqcInput: text}}, Tea_Cmd.none)
  | SetNqcLanguage(lang) => ({...model, playgrounds: {...pg, nqcLanguage: lang}}, Tea_Cmd.none)
  | ExecuteNqc => (
      {...model, playgrounds: {...pg, executing: true, error: None}},
      PlaygroundsCmd.executeQuery(
        PlaygroundsEngine.languageLabel(pg.nqcLanguage),
        pg.nqcInput,
        result => Playgrounds(NqcResult(result)),
      ),
    )
  | NqcResult(result) => {
      let qr = switch result {
      | Ok(data) => {success: true, data: Some(data), error: None, durationMs: 0.0, rowCount: 0}
      | Error(e) => {success: false, data: None, error: Some(e), durationMs: 0.0, rowCount: 0}
      }
      let entry = (pg.nqcInput, pg.nqcLanguage, Some(qr))
      let history = [entry]->Array.concat(pg.nqcHistory)
      (
        {
          ...model,
          playgrounds: {...pg, executing: false, nqcHistory: history, lastResult: Some(qr)},
        },
        Tea_Cmd.none,
      )
    }
  | ClearNqcHistory => ({...model, playgrounds: {...pg, nqcHistory: []}}, Tea_Cmd.none)
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
