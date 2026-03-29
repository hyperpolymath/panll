// SPDX-License-Identifier: PMPL-1.0-or-later

/// Sub-updater for Capture — screenshots, recordings, demos, cloning, comparison.

open Model
open Msg

let updateCapture = (model: model, msg: captureMsg): (model, Tea_Cmd.t<msg>) => {
  let cap = model.capture
  switch msg {
  | CaptureScreenshot(panelId) => {
      // Invoke html2canvas capture via JS interop, then save the result through Gossamer.
      let captureId = "cap-" ++ Float.toString(Date.now())
      let format = "png"
      // The actual html2canvas call happens in JS; here we wire the save command
      // with a placeholder base64 string that the frontend JS bridge will populate.
      (
        model,
        Tea_Cmd.batch(list{
          CaptureCmd.saveScreenshot(captureId, panelId, "", format),
          TypeLLService.checkConfigTypes(panelId, "capture", result => Capture(
            TypeCheckResult(result),
          )),
        }),
      )
    }
  | ScreenshotSaved(result) =>
    switch result {
    | Ok(jsonStr) => {
        let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>
          let o = json->JSON.Decode.object->Option.getOr(Dict.make())
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let fmt = switch gs(o, "format") {
          | "pdf" => Pdf
          | "svg" => Svg
          | _ => Png
          }
          Some(
            (
              {
                id: gs(o, "id"),
                panelId: gs(o, "panelId"),
                label: gs(o, "panelId") ++ " capture",
                filePath: gs(o, "filePath"),
                format: fmt,
                timestamp: Date.now(),
                width: 0,
                height: 0,
                isRecording: false,
                durationSeconds: 0.0,
              }: captureEntry
            ),
          )

        | None => None
        }
        switch parsed {
        | Some(entry) => (
            {...model, capture: {...cap, captures: Array.concat(cap.captures, [entry])}},
            Tea_Cmd.none,
          )
        | None => (model, Tea_Cmd.none)
        }
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | StartRecording(panelId) => (
      {...model, capture: CaptureEngine.startRecording(cap, panelId, 0.0)},
      Tea_Cmd.none,
    )
  | StopRecording => ({...model, capture: CaptureEngine.stopRecording(cap)}, Tea_Cmd.none)
  | TogglePauseRecording => (
      {
        ...model,
        capture: switch cap.recording {
        | Recording(_, _) => CaptureEngine.pauseRecording(cap, 0.0)
        | Paused(_, _) => CaptureEngine.resumeRecording(cap, 0.0)
        | NotRecording => cap
        },
      },
      Tea_Cmd.none,
    )
  | PrintPanel(panelId) => (model, CaptureCmd.printPanel(panelId))
  | PrintResult(_result) => (model, Tea_Cmd.none)
  | ToggleCaptureSelection(panelId) => (
      {...model, capture: CaptureEngine.toggleCaptureSelection(cap, panelId)},
      Tea_Cmd.none,
    )
  | ClearCaptureSelection => ({...model, capture: CaptureEngine.clearSelection(cap)}, Tea_Cmd.none)
  | CaptureSelected => {
      // Capture all selected panels as a composite screenshot.
      // Triggers individual captures for each selected panel; composite assembly happens in the backend.
      let captureId = "composite-" ++ Float.toString(Date.now())
      let panelsJson = cap.selectedForCapture->Array.map(p => `"${p}"`)->Array.join(",")
      (model, CaptureCmd.saveScreenshot(captureId, "[" ++ panelsJson ++ "]", "", "png"))
    }
  | CaptureFullEnvironment => {
      // Capture the entire PanLL window as a single screenshot.
      let captureId = "full-env-" ++ Float.toString(Date.now())
      (
        {...model, capture: {...cap, fullEnvironmentCapture: true}},
        CaptureCmd.saveScreenshot(captureId, "__full_environment__", "", "png"),
      )
    }
  | ToggleCaptureBar => (
      {...model, capture: {...cap, captureBarVisible: !cap.captureBarVisible}},
      Tea_Cmd.none,
    )
  | ClonePanel(panelId) => {
      // Snapshot the panel's current state and create a panelClone entry.
      let cloneId = "clone-" ++ Float.toString(Date.now())
      let clone: CaptureModel.panelClone = {
        id: cloneId,
        sourcePanelId: panelId,
        label: panelId ++ " (Clone)",
        stateSnapshot: "", // State serialisation deferred to JS interop layer.
        created: Date.now(),
      }
      ({...model, capture: {...cap, clones: Array.concat(cap.clones, [clone])}}, Tea_Cmd.none)
    }
  | RemoveClone(cloneId) => (
      {...model, capture: CaptureEngine.removeClone(cap, cloneId)},
      Tea_Cmd.none,
    )
  | SetComparison(mode) => ({...model, capture: {...cap, comparison: mode}}, Tea_Cmd.none)
  | ExitComparison => ({...model, capture: CaptureEngine.exitComparison(cap)}, Tea_Cmd.none)
  | StartDemo(demoId) => ({...model, capture: CaptureEngine.startDemo(cap, demoId)}, Tea_Cmd.none)
  | StopDemo => ({...model, capture: CaptureEngine.stopDemo(cap)}, Tea_Cmd.none)
  | NextDemoStep => ({...model, capture: CaptureEngine.nextDemoStep(cap)}, Tea_Cmd.none)
  | PrevDemoStep => ({...model, capture: CaptureEngine.prevDemoStep(cap)}, Tea_Cmd.none)
  | SaveDemo => {
      // Serialise the active demo and persist via Gossamer.
      let demoJson = switch cap.activeDemo {
      | Some(demoId) =>
        switch cap.demos->Array.find(d => d.id === demoId) {
        | Some(demo) =>
          `{"id":"${demo.id}","title":"${demo.title}","author":"${demo.author}","description":"${demo.description}","panelId":"${demo.panelId}","steps":[],"created":${Float.toString(
              demo.created,
            )}}`
        | None => "{}"
        }
      | None => "{}"
      }
      (model, CaptureCmd.saveDemo(demoJson))
    }
  | DemoSaved(_result) => (model, Tea_Cmd.none)
  | LoadDemos => (model, CaptureCmd.loadDemos())
  | DemosLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        let demos = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
        | Some(json) =>
          json
          ->JSON.Decode.array
          ->Option.getOr([])
          ->Array.filterMap(item => {
            let o = item->JSON.Decode.object->Option.getOr(Dict.make())
            let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
            let gf = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
            let id = gs(o, "id")
            if id !== "" {
              Some(
                (
                  {
                    id,
                    title: gs(o, "title"),
                    author: gs(o, "author"),
                    description: gs(o, "description"),
                    panelId: gs(o, "panelId"),
                    steps: [],
                    created: gf(o, "created"),
                    filePath: o->Dict.get("filePath")->Option.flatMap(JSON.Decode.string),
                  }: demoPackage
                ),
              )
            } else {
              None
            }
          })

        | None => []
        }
        ({...model, capture: {...cap, demos}}, Tea_Cmd.none)
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | SetCaptureCategory(cat) => ({...model, capture: {...cap, activeCategory: cat}}, Tea_Cmd.none)
  | RemoveCapture(captureId) => (
      {...model, capture: CaptureEngine.removeCapture(cap, captureId)},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "capture", json)
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
