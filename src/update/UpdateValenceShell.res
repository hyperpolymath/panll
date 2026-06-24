// SPDX-License-Identifier: MPL-2.0

/// Extracted sub-updater for the Valence Shell panel.
/// Manages the embedded terminal — PTY lifecycle, input handling, session recording,
/// checkpoint management, approval gate, and Claude Code integration.

open Model
open Msg

let updateValenceShell = (model: model, msg: valenceShellMsg): (model, Tea_Cmd.t<msg>) => {
  let vs = model.valenceShell
  switch msg {
  | SetShellCategory(cat) => ({...model, valenceShell: {...vs, activeCategory: cat}}, Tea_Cmd.none)
  | UpdateInput(value) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          inputLine: value,
          completionsVisible: String.length(value) > 0,
        },
      },
      Tea_Cmd.none,
    )
  | SubmitInput => {
      let input = String.trim(vs.inputLine)
      if String.length(input) === 0 {
        (model, Tea_Cmd.none)
      } else {
        // Check approval gate
        switch vs.approvalGate {
        | GateDisabled => (
            {
              ...model,
              valenceShell: {
                ...vs,
                inputLine: "",
                commandHistory: Array.concat(vs.commandHistory, [input]),
                historyIndex: -1,
                completionsVisible: false,
                claudeCodeActive: input === "claude" || String.startsWith(input, "claude "),
              },
            },
            Tea_Cmd.batch(list{
              ValenceShellCmd.sendInput(input ++ "\n", result => ValenceShell(
                PtyOutput(
                  switch result {
                  | Ok(s) => s
                  | Error(e) => e
                  },
                  switch result {
                  | Ok(_) => true
                  | Error(_) => false
                  },
                ),
              )),
              TypeLLService.checkCodeTypes(input, "shell", result => ValenceShell(
                TypeCheckResult(result),
              )),
            }),
          )
        | GateEnabled | GateLearning => {
            // Check whitelist for learning mode
            let isWhitelisted =
              vs.approvalGate === GateLearning &&
                Array.some(vs.approvedCommands, cmd => cmd === input)
            if isWhitelisted {
              // Auto-approve whitelisted commands
              (
                {
                  ...model,
                  valenceShell: {
                    ...vs,
                    inputLine: "",
                    commandHistory: Array.concat(vs.commandHistory, [input]),
                    historyIndex: -1,
                    completionsVisible: false,
                  },
                },
                ValenceShellCmd.sendInput(input ++ "\n", result => ValenceShell(
                  PtyOutput(
                    switch result {
                    | Ok(s) => s
                    | Error(e) => e
                    },
                    switch result {
                    | Ok(_) => true
                    | Error(_) => false
                    },
                  ),
                )),
              )
            } else {
              // Queue for approval
              let pending: pendingCommand = {
                command: input,
                author: "child",
                submittedAt: 0.0,
              }
              (
                {
                  ...model,
                  valenceShell: {
                    ...vs,
                    inputLine: "",
                    pendingCommands: Array.concat(vs.pendingCommands, [pending]),
                    completionsVisible: false,
                  },
                },
                Tea_Cmd.none,
              )
            }
          }
        }
      }
    }
  | SelectCompletion(completion) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          inputLine: completion,
          completionsVisible: false,
        },
      },
      Tea_Cmd.none,
    )
  | ToggleCompletions => (
      {...model, valenceShell: {...vs, completionsVisible: !vs.completionsVisible}},
      Tea_Cmd.none,
    )
  | PtySpawned(Ok(_sessionId)) => (
      {...model, valenceShell: {...vs, ptyConnected: true, error: None}},
      Tea_Cmd.none,
    )
  | PtySpawned(Error(err)) => (
      {...model, valenceShell: {...vs, ptyConnected: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | PtyOutput(content, isStdout) => {
      let line: terminalLine = {content, isStdout, timestamp: 0.0}
      let buffer = Array.concat(vs.outputBuffer, [line])
      // Ring buffer: keep last 1000 lines
      let trimmed = if Array.length(buffer) > 1000 {
        Array.sliceToEnd(buffer, ~start=Array.length(buffer) - 1000)
      } else {
        buffer
      }
      ({...model, valenceShell: {...vs, outputBuffer: trimmed}}, Tea_Cmd.none)
    }
  | PtyExited => (
      {...model, valenceShell: {...vs, ptyConnected: false, claudeCodeActive: false}},
      Tea_Cmd.none,
    )
  | CheckValenceAvailability => (
      model,
      ValenceShellCmd.checkValenceAvailability(result => ValenceShell(
        ValenceAvailabilityResult(result),
      )),
    )
  | ValenceAvailabilityResult(Ok(_version)) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          valenceAvailable: true,
          backend: ValenceShell,
        },
      },
      Tea_Cmd.none,
    )
  | ValenceAvailabilityResult(Error(_)) => (
      {...model, valenceShell: {...vs, valenceAvailable: false}},
      Tea_Cmd.none,
    )
  | LaunchClaudeCode => (
      {
        ...model,
        valenceShell: {
          ...vs,
          inputLine: "",
          commandHistory: Array.concat(vs.commandHistory, ["claude"]),
          claudeCodeActive: true,
        },
      },
      ValenceShellCmd.sendInput("claude\n", result => ValenceShell(
        PtyOutput(
          switch result {
          | Ok(s) => s
          | Error(e) => e
          },
          switch result {
          | Ok(_) => true
          | Error(_) => false
          },
        ),
      )),
    )
  | StartRecordingSession => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.startRecording("session", result => ValenceShell(RecordingStarted(result))),
    )
  | StopRecordingSession => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.stopRecording(result => ValenceShell(RecordingStopped(result))),
    )
  | RecordingStarted(Ok(_path)) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          recording: RecordingActive(0.0),
          loading: false,
          error: None,
        },
      },
      Tea_Cmd.none,
    )
  | RecordingStarted(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RecordingStopped(Ok(_path)) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          recording: RecordingIdle,
          loading: false,
          error: None,
        },
      },
      // Reload the recordings list after stopping
      ValenceShellCmd.listRecordings(result => ValenceShell(RecordingsLoaded(result))),
    )
  | RecordingStopped(Error(err)) => (
      {
        ...model,
        valenceShell: {
          ...vs,
          recording: RecordingIdle,
          loading: false,
          error: Some(err),
        },
      },
      Tea_Cmd.none,
    )
  | LoadRecordings => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.listRecordings(result => ValenceShell(RecordingsLoaded(result))),
    )
  | RecordingsLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let path = obj->Dict.get("path")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let durationSecs =
            obj->Dict.get("durationSecs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let createdAt =
            obj->Dict.get("createdAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let sizeBytes =
            obj->Dict.get("sizeBytes")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          Some({
            ValenceShellModel.id,
            name,
            path,
            durationSecs,
            createdAt,
            sizeBytes: Float.toInt(sizeBytes),
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(recs) => (
          {...model, valenceShell: {...vs, recordings: recs, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, valenceShell: {...vs, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | RecordingsLoaded(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DeleteRecordingById(id) => (
      model,
      ValenceShellCmd.deleteRecording(id, result => ValenceShell(RecordingDeleted(result))),
    )
  | RecordingDeleted(Ok(_)) => (
      model,
      ValenceShellCmd.listRecordings(result => ValenceShell(RecordingsLoaded(result))),
    )
  | RecordingDeleted(Error(err)) => (
      {...model, valenceShell: {...vs, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ExportRecordingAs(id, format) => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.exportRecording(id, format, result => ValenceShell(
        RecordingExported(result),
      )),
    )
  | RecordingExported(Ok(_path)) => (
      {...model, valenceShell: {...vs, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | RecordingExported(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | CreateCheckpointWithLabel(label) => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.createCheckpoint(label, result => ValenceShell(CheckpointCreated(result))),
    )
  | CheckpointCreated(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let label = obj->Dict.get("label")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let createdAt =
          obj->Dict.get("createdAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let opsSince =
          obj->Dict.get("opsSinceCheckpoint")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          ValenceShellModel.id,
          label,
          createdAt,
          opsSinceCheckpoint: Float.toInt(opsSince),
        })

      | None => None
      }
      let newCheckpoints = switch parsed {
      | Some(cp) => Array.concat(vs.checkpoints, [cp])
      | None => vs.checkpoints
      }
      (
        {...model, valenceShell: {...vs, checkpoints: newCheckpoints, loading: false, error: None}},
        ValenceShellCmd.listCheckpoints(result => ValenceShell(CheckpointsLoaded(result))),
      )
    }
  | CheckpointCreated(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RestoreCheckpointById(id) => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.restoreCheckpoint(id, result => ValenceShell(CheckpointRestored(result))),
    )
  | CheckpointRestored(Ok(_)) => (
      {...model, valenceShell: {...vs, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | CheckpointRestored(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | LoadCheckpoints => (
      {...model, valenceShell: {...vs, loading: true}},
      ValenceShellCmd.listCheckpoints(result => ValenceShell(CheckpointsLoaded(result))),
    )
  | CheckpointsLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let label = obj->Dict.get("label")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let createdAt =
            obj->Dict.get("createdAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let opsSince =
            obj
            ->Dict.get("opsSinceCheckpoint")
            ->Option.flatMap(JSON.Decode.float)
            ->Option.getOr(0.0)
          Some({
            ValenceShellModel.id,
            label,
            createdAt,
            opsSinceCheckpoint: Float.toInt(opsSince),
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(cps) => (
          {...model, valenceShell: {...vs, checkpoints: cps, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, valenceShell: {...vs, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | CheckpointsLoaded(Error(err)) => (
      {...model, valenceShell: {...vs, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ScreenshotTerminal => (
      model,
      ValenceShellCmd.screenshotTerminal(result => ValenceShell(ScreenshotCaptured(result))),
    )
  | ScreenshotCaptured(Ok(_path)) => (model, Tea_Cmd.none)
  | ScreenshotCaptured(Error(err)) => (
      {...model, valenceShell: {...vs, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SetApprovalGate(gate) => ({...model, valenceShell: {...vs, approvalGate: gate}}, Tea_Cmd.none)
  | ApproveCommand(idx) => {
      let cmd = vs.pendingCommands->Array.get(idx)
      switch cmd {
      | Some(pending) => {
          let remaining = Array.filterWithIndex(vs.pendingCommands, (_c, i) => i !== idx)
          let newApproved = if vs.approvalGate === GateLearning {
            Array.concat(vs.approvedCommands, [pending.command])
          } else {
            vs.approvedCommands
          }
          (
            {
              ...model,
              valenceShell: {
                ...vs,
                pendingCommands: remaining,
                approvedCommands: newApproved,
                commandHistory: Array.concat(vs.commandHistory, [pending.command]),
              },
            },
            ValenceShellCmd.sendInput(pending.command ++ "\n", result => ValenceShell(
              PtyOutput(
                switch result {
                | Ok(s) => s
                | Error(e) => e
                },
                switch result {
                | Ok(_) => true
                | Error(_) => false
                },
              ),
            )),
          )
        }
      | None => (model, Tea_Cmd.none)
      }
    }
  | RejectCommand(idx) => {
      let remaining = Array.filterWithIndex(vs.pendingCommands, (_c, i) => i !== idx)
      ({...model, valenceShell: {...vs, pendingCommands: remaining}}, Tea_Cmd.none)
    }
  | ToggleSplitView => ({...model, valenceShell: {...vs, splitView: !vs.splitView}}, Tea_Cmd.none)
  | DismissError => ({...model, valenceShell: {...vs, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "valenceshell", json)
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
