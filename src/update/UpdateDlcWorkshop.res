// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updater for the DLC Workshop panel.
/// Manages puzzle loading, composer instructions, test execution, asset browsing,
/// DLC packaging, puzzle import/export, filtering, and TypeLL integration.

open Model
open Msg

let updateDlcWorkshop = (model: model, msg: dlcWorkshopMsg): (model, Tea_Cmd.t<msg>) => {
  let dw = model.dlcWorkshop
  switch msg {
  | SetWorkshopCategory(cat) => (
      {...model, dlcWorkshop: {...dw, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | LoadPuzzles => (
      {...model, dlcWorkshop: {...dw, loading: true}},
      DlcWorkshopCmd.loadPuzzles(result => DlcWorkshop(PuzzlesLoaded(result))),
    )
  | PuzzlesLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let description =
            obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let diffStr =
            obj->Dict.get("difficulty")->Option.flatMap(JSON.Decode.string)->Option.getOr("medium")
          let difficulty: DlcWorkshopModel.puzzleDifficulty = switch diffStr {
          | "tutorial" => DifficultyTutorial
          | "easy" => DifficultyEasy
          | "hard" => DifficultyHard
          | "expert" => DifficultyExpert
          | "nightmare" => DifficultyNightmare
          | _ => DifficultyMedium
          }
          let solutionSteps =
            obj->Dict.get("solutionSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let optimalSteps =
            obj->Dict.get("optimalSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          let hintsArr = obj->Dict.get("hints")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
          let hints = hintsArr->Array.filterMap(v => v->JSON.Decode.string)
          Some({
            DlcWorkshopModel.id,
            name,
            description,
            difficulty,
            instructions: [],
            solutionSteps: Float.toInt(solutionSteps),
            optimalSteps: Float.toInt(optimalSteps),
            testStatus: TestNotRun,
            hints,
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(puzzles) => (
          {...model, dlcWorkshop: {...dw, puzzles, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, dlcWorkshop: {...dw, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | PuzzlesLoaded(Error(err)) => (
      {...model, dlcWorkshop: {...dw, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectPuzzle(id) => ({...model, dlcWorkshop: {...dw, selectedPuzzleId: Some(id)}}, Tea_Cmd.none)
  | DeselectPuzzle => ({...model, dlcWorkshop: {...dw, selectedPuzzleId: None}}, Tea_Cmd.none)
  | AddInstruction => {
      let idx = Array.length(dw.composerInstructions)
      let instr: puzzleInstruction = {index: idx, opcode: "NOP", operand: None, comment: ""}
      (
        {
          ...model,
          dlcWorkshop: {
            ...dw,
            composerInstructions: Array.concat(dw.composerInstructions, [instr]),
          },
        },
        Tea_Cmd.none,
      )
    }
  | RemoveInstruction(idx) => {
      let newInstrs = dw.composerInstructions->Array.filter(i => i.index !== idx)
      ({...model, dlcWorkshop: {...dw, composerInstructions: newInstrs}}, Tea_Cmd.none)
    }
  | ClearComposer => ({...model, dlcWorkshop: {...dw, composerInstructions: []}}, Tea_Cmd.none)
  | SavePuzzle => (
      model,
      Tea_Cmd.batch(list{
        DlcWorkshopCmd.savePuzzle("", result => DlcWorkshop(PuzzleSaved(result))),
        TypeLLService.checkGameDataTypes("puzzle-spec", "dlc-workshop", result => DlcWorkshop(
          TypeCheckResult(result),
        )),
      }),
    )
  | PuzzleSaved(Ok(_)) => (model, Tea_Cmd.none)
  | PuzzleSaved(Error(err)) => ({...model, dlcWorkshop: {...dw, error: Some(err)}}, Tea_Cmd.none)
  | RunPuzzleTest(puzzleId) => (
      {...model, dlcWorkshop: {...dw, loading: true}},
      DlcWorkshopCmd.runTest(puzzleId, result => DlcWorkshop(PuzzleTestResult(result))),
    )
  | PuzzleTestResult(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let puzzleId =
          obj->Dict.get("puzzleId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let passed = obj->Dict.get("passed")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let errorMsg = obj->Dict.get("error")->Option.flatMap(JSON.Decode.string)
        let status: DlcWorkshopModel.testRunStatus = if passed {
          TestPassed
        } else {
          TestFailed(errorMsg->Option.getOr("Test failed"))
        }
        Some((puzzleId, status))

      | None => None
      }
      switch parsed {
      | Some((puzzleId, status)) => {
          let puzzles = dw.puzzles->Array.map(p =>
            if p.id === puzzleId {
              {...p, testStatus: status}
            } else {
              p
            }
          )
          let testResults = Array.concat(dw.testResults, [(puzzleId, status)])
          (
            {...model, dlcWorkshop: {...dw, puzzles, testResults, loading: false, error: None}},
            Tea_Cmd.none,
          )
        }
      | None => ({...model, dlcWorkshop: {...dw, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | PuzzleTestResult(Error(err)) => (
      {...model, dlcWorkshop: {...dw, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RunAllTests => (
      {...model, dlcWorkshop: {...dw, loading: true}},
      DlcWorkshopCmd.runAllTests(result => DlcWorkshop(AllTestsResult(result))),
    )
  | AllTestsResult(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let results = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let puzzleId =
            obj->Dict.get("puzzleId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let passed =
            obj->Dict.get("passed")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
          let errorMsg = obj->Dict.get("error")->Option.flatMap(JSON.Decode.string)
          let status: DlcWorkshopModel.testRunStatus = if passed {
            TestPassed
          } else {
            TestFailed(errorMsg->Option.getOr("Test failed"))
          }
          Some((puzzleId, status))
        })
        Some(results)

      | None => None
      }
      switch parsed {
      | Some(results) => {
          let puzzles = dw.puzzles->Array.map(p => {
            let matching = results->Array.find(((id, _)) => id === p.id)
            switch matching {
            | Some((_, status)) => {...p, testStatus: status}
            | None => p
            }
          })
          (
            {
              ...model,
              dlcWorkshop: {...dw, puzzles, testResults: results, loading: false, error: None},
            },
            Tea_Cmd.none,
          )
        }
      | None => ({...model, dlcWorkshop: {...dw, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | AllTestsResult(Error(err)) => (
      {...model, dlcWorkshop: {...dw, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | BrowseDlcAssets => (
      {...model, dlcWorkshop: {...dw, loading: true}},
      DlcWorkshopCmd.browseAssets(result => DlcWorkshop(DlcAssetsLoaded(result))),
    )
  | DlcAssetsLoaded(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        let items = arr->Array.filterMap(item => {
          let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
          let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let assetType =
            obj->Dict.get("assetType")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let filePath =
            obj->Dict.get("filePath")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let sizeBytes =
            obj->Dict.get("sizeBytes")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
          Some({
            DlcWorkshopModel.id,
            name,
            assetType,
            filePath,
            sizeBytes: Float.toInt(sizeBytes),
          })
        })
        Some(items)

      | None => None
      }
      switch parsed {
      | Some(assets) => (
          {...model, dlcWorkshop: {...dw, assets, loading: false, error: None}},
          Tea_Cmd.none,
        )
      | None => ({...model, dlcWorkshop: {...dw, loading: false, error: None}}, Tea_Cmd.none)
      }
    }
  | DlcAssetsLoaded(Error(err)) => (
      {...model, dlcWorkshop: {...dw, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | PackageDlc => (
      {...model, dlcWorkshop: {...dw, loading: true}},
      DlcWorkshopCmd.packageDlc("", result => DlcWorkshop(PackageResult(result))),
    )
  | PackageResult(Ok(_)) => (
      {...model, dlcWorkshop: {...dw, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | PackageResult(Error(err)) => (
      {...model, dlcWorkshop: {...dw, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | ImportPuzzle => (
      model,
      DlcWorkshopCmd.importPuzzle("", result => DlcWorkshop(PuzzleImported(result))),
    )
  | PuzzleImported(Ok(jsonStr)) => {
      let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
        let id = obj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let description =
          obj->Dict.get("description")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let diffStr =
          obj->Dict.get("difficulty")->Option.flatMap(JSON.Decode.string)->Option.getOr("medium")
        let difficulty: DlcWorkshopModel.puzzleDifficulty = switch diffStr {
        | "tutorial" => DifficultyTutorial
        | "easy" => DifficultyEasy
        | "hard" => DifficultyHard
        | "expert" => DifficultyExpert
        | "nightmare" => DifficultyNightmare
        | _ => DifficultyMedium
        }
        let solutionSteps =
          obj->Dict.get("solutionSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let optimalSteps =
          obj->Dict.get("optimalSteps")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let hintsArr = obj->Dict.get("hints")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let hints = hintsArr->Array.filterMap(v => v->JSON.Decode.string)
        Some({
          DlcWorkshopModel.id,
          name,
          description,
          difficulty,
          instructions: [],
          solutionSteps: Float.toInt(solutionSteps),
          optimalSteps: Float.toInt(optimalSteps),
          testStatus: TestNotRun,
          hints,
        })

      | None => None
      }
      switch parsed {
      | Some(puzzle) => (
          {
            ...model,
            dlcWorkshop: {...dw, puzzles: Array.concat(dw.puzzles, [puzzle]), error: None},
          },
          Tea_Cmd.none,
        )
      | None => ({...model, dlcWorkshop: {...dw, error: None}}, Tea_Cmd.none)
      }
    }
  | PuzzleImported(Error(err)) => ({...model, dlcWorkshop: {...dw, error: Some(err)}}, Tea_Cmd.none)
  | ExportPuzzle => {
      let puzzleId = switch dw.selectedPuzzleId {
      | Some(id) => id
      | None => ""
      }
      (model, DlcWorkshopCmd.exportPuzzle(puzzleId, result => DlcWorkshop(PuzzleExported(result))))
    }
  | PuzzleExported(Ok(_)) => (model, Tea_Cmd.none)
  | PuzzleExported(Error(err)) => ({...model, dlcWorkshop: {...dw, error: Some(err)}}, Tea_Cmd.none)
  | SetDlcFilter(text) => ({...model, dlcWorkshop: {...dw, filterText: text}}, Tea_Cmd.none)
  | SetDifficultyFilter(diff) => (
      {...model, dlcWorkshop: {...dw, filterDifficulty: diff}},
      Tea_Cmd.none,
    )
  | DismissWorkshopError => ({...model, dlcWorkshop: {...dw, error: None}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "dlcworkshop", json)
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
