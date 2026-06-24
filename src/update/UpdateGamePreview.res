// SPDX-License-Identifier: MPL-2.0

/// Extracted sub-updater for the Game Preview panel.
/// Manages the live IDApTIK game preview — dev server connection, game loop control
/// (pause/resume/step), overlay toggles, gameplay recording, clips, render stats,
/// and device interaction logging.

open Model
open Msg

let updateGamePreview = (model: model, msg: gamePreviewMsg): (model, Tea_Cmd.t<msg>) => {
  let gp = model.gamePreview
  switch msg {
  | SetPreviewCategory(cat) => ({...model, gamePreview: {...gp, activeCategory: cat}}, Tea_Cmd.none)
  | CheckDevServer => (
      {...model, gamePreview: {...gp, loading: true}},
      Tea_Cmd.batch(list{
        GamePreviewCmd.checkDevServer(gp.devServerUrl, result => GamePreview(
          DevServerResult(result),
        )),
        TypeLLService.checkGameDataTypes(gp.devServerUrl, "game-preview", result => GamePreview(
          TypeCheckResult(result),
        )),
      }),
    )
  | DevServerResult(Ok(_)) => (
      {...model, gamePreview: {...gp, devServerConnected: true, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | DevServerResult(Error(err)) => (
      {...model, gamePreview: {...gp, devServerConnected: false, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | PauseGame => (
      {...model, gamePreview: {...gp, execution: GamePaused}},
      GamePreviewCmd.controlGameLoop("pause", result => GamePreview(GameControlResult(result))),
    )
  | ResumeGame => (
      {...model, gamePreview: {...gp, execution: GameRunning}},
      GamePreviewCmd.controlGameLoop("resume", result => GamePreview(GameControlResult(result))),
    )
  | StepFrame => (
      {...model, gamePreview: {...gp, execution: GameStepping}},
      GamePreviewCmd.controlGameLoop("step", result => GamePreview(GameControlResult(result))),
    )
  | GameControlResult(Ok(_)) => (model, Tea_Cmd.none)
  | GameControlResult(Error(err)) => (
      {...model, gamePreview: {...gp, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ToggleOverlay(overlay) => (
      {
        ...model,
        gamePreview: {
          ...gp,
          activeOverlays: GamePreviewEngine.toggleOverlay(gp.activeOverlays, overlay),
        },
      },
      Tea_Cmd.none,
    )
  | StartGameRecording => (
      {...model, gamePreview: {...gp, loading: true}},
      GamePreviewCmd.startGameRecording("gameplay", result => GamePreview(
        GameRecordingStarted(result),
      )),
    )
  | StopGameRecording => (
      {...model, gamePreview: {...gp, loading: true}},
      GamePreviewCmd.stopGameRecording(result => GamePreview(GameRecordingStopped(result))),
    )
  | GameRecordingStarted(Ok(_)) => (
      {
        ...model,
        gamePreview: {...gp, gameRecording: GameRecordingActive(0.0), loading: false, error: None},
      },
      Tea_Cmd.none,
    )
  | GameRecordingStarted(Error(err)) => (
      {...model, gamePreview: {...gp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | GameRecordingStopped(Ok(_)) => (
      {
        ...model,
        gamePreview: {...gp, gameRecording: GameRecordingIdle, loading: false, error: None},
      },
      GamePreviewCmd.listClips(result => GamePreview(ClipsLoaded(result))),
    )
  | GameRecordingStopped(Error(err)) => (
      {
        ...model,
        gamePreview: {...gp, gameRecording: GameRecordingIdle, loading: false, error: Some(err)},
      },
      Tea_Cmd.none,
    )
  | ScreenshotGame => (
      model,
      GamePreviewCmd.screenshotGameFrame(result => GamePreview(GameScreenshotCaptured(result))),
    )
  | GameScreenshotCaptured(Ok(_)) => (model, Tea_Cmd.none)
  | GameScreenshotCaptured(Error(err)) => (
      {...model, gamePreview: {...gp, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SetZoom(level) => {
      let clamped = if level < 0.25 {
        0.25
      } else if level > 4.0 {
        4.0
      } else {
        level
      }
      ({...model, gamePreview: {...gp, zoomLevel: clamped}}, Tea_Cmd.none)
    }
  | ToggleMultiplayerView => (
      {...model, gamePreview: {...gp, multiplayerView: !gp.multiplayerView}},
      Tea_Cmd.none,
    )
  | LoadClips => (
      {...model, gamePreview: {...gp, loading: true}},
      GamePreviewCmd.listClips(result => GamePreview(ClipsLoaded(result))),
    )
  | ClipsLoaded(Ok(jsonStr)) => {
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
          let sizeBytes =
            obj->Dict.get("sizeBytes")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let createdAt =
            obj->Dict.get("createdAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          Some({
            GamePreviewModel.id,
            name,
            path,
            durationSecs,
            sizeBytes: Float.toInt(sizeBytes),
            createdAt,
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(clips) => (
          {...model, gamePreview: {...gp, clips, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, gamePreview: {...gp, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | ClipsLoaded(Error(err)) => (
      {...model, gamePreview: {...gp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DeleteClip(id) => (
      model,
      GamePreviewCmd.deleteClip(id, result => GamePreview(ClipDeleted(result))),
    )
  | ClipDeleted(Ok(_)) => (
      model,
      GamePreviewCmd.listClips(result => GamePreview(ClipsLoaded(result))),
    )
  | ClipDeleted(Error(err)) => ({...model, gamePreview: {...gp, error: Some(err)}}, Tea_Cmd.none)
  | RefreshStats => (
      model,
      GamePreviewCmd.fetchRenderStats(result => GamePreview(StatsReceived(result))),
    )
  | StatsReceived(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let fps = obj->Dict.get("fps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let drawCalls =
          obj->Dict.get("drawCalls")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let textureMemory =
          obj->Dict.get("textureMemory")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let spriteCount =
          obj->Dict.get("spriteCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          GamePreviewModel.fps,
          drawCalls: Float.toInt(drawCalls),
          textureMemory: Float.toInt(textureMemory),
          spriteCount: Float.toInt(spriteCount),
        })

      | None => None
      }
      switch parsed {
      | Some(stats) => ({...model, gamePreview: {...gp, stats: Some(stats)}}, Tea_Cmd.none)
      | None => (model, Tea_Cmd.none)
      }
    }
  | StatsReceived(Error(err)) => ({...model, gamePreview: {...gp, error: Some(err)}}, Tea_Cmd.none)
  | ClearDeviceLog => ({...model, gamePreview: {...gp, deviceLog: []}}, Tea_Cmd.none)
  | DeviceInteractionEvent(entry) => {
      let log = Array.concat(gp.deviceLog, [entry])
      let trimmed = if Array.length(log) > 200 {
        Array.sliceToEnd(log, ~start=Array.length(log) - 200)
      } else {
        log
      }
      ({...model, gamePreview: {...gp, deviceLog: trimmed}}, Tea_Cmd.none)
    }
  | DismissGameError => ({...model, gamePreview: {...gp, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "gamepreview", json)
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
