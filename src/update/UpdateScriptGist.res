// SPDX-License-Identifier: PMPL-1.0-or-later
// UpdateScriptGist.res — ScriptGist (portable computation gists / Minskian cardfiles) sub-updater extracted from Update.res

open Model
open Msg

let updateScriptGist = (model: model, msg: scriptGistMsg): (model, Tea_Cmd.t<msg>) => {
  let sg = model.scriptGist
  switch msg {
  | SetGistCategory(cat) => ({...model, scriptGist: {...sg, activeCategory: cat}}, Tea_Cmd.none)
  | SelectGist(id) => ({...model, scriptGist: {...sg, selectedGistId: id}}, Tea_Cmd.none)
  | CreateGist => {
      let id = "gist-" ++ Float.toString(Date.now())
      let gist = ScriptGistEngine.newGist(id, "Untitled Gist", GistReScript)
      (
        {
          ...model,
          scriptGist: {
            ...sg,
            gists: Array.concat(sg.gists, [gist]),
            selectedGistId: Some(id),
            editorOpen: true,
          },
        },
        Tea_Cmd.none,
      )
    }
  | CreateFromTemplate(tplId) => {
      let id = "gist-" ++ Float.toString(Date.now())
      switch sg.templates->Array.find(t => t.id === tplId) {
      | Some(tpl) => {
          let gist: scriptGist = {
            ...ScriptGistEngine.newGist(id, tpl.name, tpl.language),
            code: tpl.templateCode,
            target: tpl.target,
            tags: ["from-template"],
          }
          (
            {
              ...model,
              scriptGist: {
                ...sg,
                gists: Array.concat(sg.gists, [gist]),
                selectedGistId: Some(id),
                editorOpen: true,
              },
            },
            Tea_Cmd.none,
          )
        }
      | None => (
          {...model, scriptGist: {...sg, error: Some("Template not found: " ++ tplId)}},
          Tea_Cmd.none,
        )
      }
    }
  | UpdateGistCode(code) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId {
          {...g, code, modifiedAt: Date.now(), version: g.version + 1}
        } else {
          g
        }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | UpdateGistTitle(title) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId {
          {...g, title, modifiedAt: Date.now()}
        } else {
          g
        }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | UpdateGistLanguage(lang) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId {
          {
            ...g,
            language: lang,
            target: ScriptGistEngine.defaultTarget(lang),
            modifiedAt: Date.now(),
          }
        } else {
          g
        }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | UpdateGistTarget(target) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId {
          {...g, target, modifiedAt: Date.now()}
        } else {
          g
        }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | UpdateGistVisibility(vis) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId {
          {...g, visibility: vis, modifiedAt: Date.now()}
        } else {
          g
        }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | ToggleGistPin(id) => {
      let gists = sg.gists->Array.map(g =>
        if g.id === id {
          {...g, pinned: !g.pinned}
        } else {
          g
        }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | DeleteGist(id) => {
      let gists = sg.gists->Array.filter(g => g.id !== id)
      let selectedGistId = if sg.selectedGistId === Some(id) {
        None
      } else {
        sg.selectedGistId
      }
      ({...model, scriptGist: {...sg, gists, selectedGistId}}, Tea_Cmd.none)
    }
  | SaveGist => // Persist the currently selected gist to ~/.panll/gists/<id>.json via Tauri.
    switch sg.selectedGistId {
    | Some(gistId) =>
      switch sg.gists->Array.find(g => g.id === gistId) {
      | Some(gist) => {
          let gistJson = JSON.stringifyAny(gist)->Option.getOr("{}")
          (
            model,
            ScriptGistCmd.saveGist(gistJson, result =>
              switch result {
              | Ok(_) =>
                ScriptGist(
                  GistExecutionResult(
                    Ok({
                      success: true,
                      output: "Gist saved successfully",
                      error: None,
                      durationMs: 0.0,
                      executedAt: Date.now(),
                      invoker: "user",
                    }),
                  ),
                )
              | Error(err) => ScriptGist(GistExecutionResult(Error(err)))
              }
            ),
          )
        }
      | None => (
          {...model, scriptGist: {...sg, error: Some("No gist found with id: " ++ gistId)}},
          Tea_Cmd.none,
        )
      }
    | None => (
        {...model, scriptGist: {...sg, error: Some("No gist selected to save")}},
        Tea_Cmd.none,
      )
    }
  | ExecuteGist => // Dispatch the currently selected gist to its execution target via BoJ/Tauri.
    switch sg.selectedGistId {
    | Some(gistId) =>
      switch sg.gists->Array.find(g => g.id === gistId) {
      | Some(gist) => {
          let gistJson = JSON.stringifyAny(gist)->Option.getOr("{}")
          (
            {...model, scriptGist: {...sg, executing: true}},
            ScriptGistCmd.executeGist(gistJson, result =>
              switch result {
              | Ok(resultJson) => {
                  // Parse the execution result from the backend.
                  let parsed = switch Tea_Json.decodeString(Tea_Json.value, resultJson) {
                  | Ok(json) => json
                  | Error(_) => JSON.Encode.null
                  }
                  let obj = parsed->JSON.Decode.object->Option.getOr(Dict.make())
                  let success =
                    obj->Dict.get("success")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
                  let output =
                    obj->Dict.get("output")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
                  let errorStr = obj->Dict.get("error")->Option.flatMap(JSON.Decode.string)
                  let durationMs =
                    obj
                    ->Dict.get("durationMs")
                    ->Option.flatMap(JSON.Decode.float)
                    ->Option.getOr(0.0)
                  let executedAt =
                    obj
                    ->Dict.get("executedAt")
                    ->Option.flatMap(JSON.Decode.float)
                    ->Option.getOr(Date.now())
                  let invoker =
                    obj
                    ->Dict.get("invoker")
                    ->Option.flatMap(JSON.Decode.string)
                    ->Option.getOr("user")
                  ScriptGist(
                    GistExecutionResult(
                      Ok({
                        success,
                        output,
                        error: errorStr,
                        durationMs,
                        executedAt,
                        invoker,
                      }),
                    ),
                  )
                }
              | Error(err) => ScriptGist(GistExecutionResult(Error(err)))
              }
            ),
          )
        }
      | None => (
          {...model, scriptGist: {...sg, error: Some("No gist found with id: " ++ gistId)}},
          Tea_Cmd.none,
        )
      }
    | None => (
        {...model, scriptGist: {...sg, error: Some("No gist selected to execute")}},
        Tea_Cmd.none,
      )
    }
  | GistExecutionResult(result) => switch result {
    | Ok(gistResult) => (
        {...model, scriptGist: {...sg, executing: false, lastResult: Some(gistResult)}},
        Tea_Cmd.none,
      )
    | Error(err) => (
        {...model, scriptGist: {...sg, executing: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | SetGistFilter(text) => ({...model, scriptGist: {...sg, filterText: text}}, Tea_Cmd.none)
  | SetGistSort(sortBy) => ({...model, scriptGist: {...sg, sortBy}}, Tea_Cmd.none)
  | ToggleGistEditor => ({...model, scriptGist: {...sg, editorOpen: !sg.editorOpen}}, Tea_Cmd.none)
  | ToggleMcpTools => (
      {...model, scriptGist: {...sg, mcpToolsActive: !sg.mcpToolsActive}},
      Tea_Cmd.none,
    )
  | DismissGistError => ({...model, scriptGist: {...sg, error: None}}, Tea_Cmd.none)
  | UpdateGistSchemaName(name) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId {
          {...g, schema: {...g.schema, toolName: name}}
        } else {
          g
        }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | UpdateGistSchemaSummary(summary) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId {
          {...g, schema: {...g.schema, summary}}
        } else {
          g
        }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | AddGistSchemaParam => {
      let param: gistParam = {
        name: "param",
        description: "",
        schemaType: "string",
        required: false,
        defaultValue: None,
      }
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId {
          {...g, schema: {...g.schema, inputs: Array.concat(g.schema.inputs, [param])}}
        } else {
          g
        }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | RemoveGistSchemaParam(idx) => {
      let gists = sg.gists->Array.map(g =>
        if Some(g.id) === sg.selectedGistId {
          let inputs = g.schema.inputs->Array.filterWithIndex((_p, i) => i !== idx)
          {...g, schema: {...g.schema, inputs}}
        } else {
          g
        }
      )
      ({...model, scriptGist: {...sg, gists}}, Tea_Cmd.none)
    }
  | SnapshotDiachronic => {
      // Serialise the current scriptGistState into the checkpoint snapshot.
      let snapshotStr = switch JSON.stringifyAny(sg) {
      | Some(s) => s
      | None => "{}"
      }
      let checkpoint: diachronicCheckpoint = {
        index: Array.length(sg.diachronicHistory),
        timestamp: Date.now(),
        label: "Checkpoint #" ++ Int.toString(Array.length(sg.diachronicHistory) + 1),
        snapshot: snapshotStr,
      }
      (
        {
          ...model,
          scriptGist: {...sg, diachronicHistory: Array.concat(sg.diachronicHistory, [checkpoint])},
        },
        Tea_Cmd.none,
      )
    }
  | RestoreDiachronic(idx) => // Restore a diachronic checkpoint by deserialising the snapshot JSON
    // back into a scriptGistState. Preserves the diachronic history itself
    // so the user can still navigate between checkpoints after restoring.
    switch sg.diachronicHistory->Array.get(idx) {
    | Some(checkpoint) => if checkpoint.snapshot === "" {
        // Empty snapshot (legacy checkpoint before serialisation was wired).
        (
          {...model, scriptGist: {...sg, error: Some("Checkpoint has no snapshot data")}},
          Tea_Cmd.none,
        )
      } else {
        // Deserialise the snapshot directly — it was serialised with JSON.stringify
        // in SnapshotDiachronic above, so it is a valid scriptGistState shape.
        // Self-serialized data — identity cast is safe for data roundtripped
        // through JSON.stringify/parse of the same ReScript record type.
        let jsonToGistState: JSON.t => scriptGistState = %raw(`function(j) { return j; }`)
        let restored: scriptGistState = switch Tea_Json.decodeString(
          Tea_Json.value,
          checkpoint.snapshot,
        ) {
        | Ok(json) => jsonToGistState(json)
        | Error(_) => sg // On parse failure, keep current state.
        }
        // Replace gist state but preserve the full checkpoint history
        // and clear any error from previous operations.
        let restoredWithHistory = {
          ...restored,
          diachronicHistory: sg.diachronicHistory,
          error: None,
        }
        ({...model, scriptGist: restoredWithHistory}, Tea_Cmd.none)
      }
    | None => (
        {...model, scriptGist: {...sg, error: Some("Checkpoint index out of bounds")}},
        Tea_Cmd.none,
      )
    }
  | InsertIntoCardfile(cardfileId) => switch sg.selectedGistId {
    | Some(gistId) => {
        let cardfiles = sg.cardfiles->Array.map(cf =>
          if cf.id === cardfileId {
            ScriptGistEngine.addGistToCardfile(cf, gistId)
          } else {
            cf
          }
        )
        ({...model, scriptGist: {...sg, cardfiles}}, Tea_Cmd.none)
      }
    | None => (model, Tea_Cmd.none)
    }
  | RemoveFromCardfile(cardfileId) => switch sg.selectedGistId {
    | Some(gistId) => {
        let cardfiles = sg.cardfiles->Array.map(cf =>
          if cf.id === cardfileId {
            ScriptGistEngine.removeGistFromCardfile(cf, gistId)
          } else {
            cf
          }
        )
        ({...model, scriptGist: {...sg, cardfiles}}, Tea_Cmd.none)
      }
    | None => (model, Tea_Cmd.none)
    }
  }
}
