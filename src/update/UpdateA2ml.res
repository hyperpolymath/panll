// SPDX-License-Identifier: PMPL-1.0-or-later

/// A2ML — manifest management sub-updater.

open Model
open Msg

let updateA2ml = (model: model, a2mlMsg: a2mlMsg): (model, Tea_Cmd.t<msg>) => {
  switch a2mlMsg {
  | LoadManifest(path) =>
    let cmd = A2mlCmd.loadManifest(path, r => A2ml(ManifestLoaded(r)))
    (model, cmd)
  | ManifestLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      let manifest = A2mlEngine.parseA2mlContent(jsonStr)
      let validation = A2mlEngine.validateManifest(manifest)
      let (_coverage, _testTypes, _notes) = A2mlEngine.extractTestCoveragePolicy(manifest)
      (
        {...model, lastA2mlManifest: Some(manifest), lastA2mlValidation: Some(validation)},
        Tea_Cmd.none,
      )
    | Error(_) => (model, Tea_Cmd.none)
    }
  | ValidateManifest(path) =>
    let cmd = A2mlCmd.validateManifestFile(path, r => A2ml(ManifestValidated(r)))
    (model, cmd)
  | ManifestValidated(result) =>
    switch result {
    | Ok(jsonStr) =>
      let manifest = A2mlEngine.parseA2mlContent(jsonStr)
      let validation = A2mlEngine.validateManifest(manifest)
      (
        {...model, lastA2mlManifest: Some(manifest), lastA2mlValidation: Some(validation)},
        Tea_Cmd.none,
      )
    | Error(_) => (model, Tea_Cmd.none)
    }
  | ListManifests =>
    let cmd = A2mlCmd.listManifests(r => A2ml(ManifestsListed(r)))
    (model, cmd)
  | ManifestsListed(result) =>
    switch result {
    | Ok(jsonStr) =>
      let paths = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(parsed) =>
        switch JSON.Classify.classify(parsed) {
        | Array(arr) =>
          arr->Array.filterMap(item =>
            switch JSON.Classify.classify(item) {
            | String(s) => Some(s)
            | _ => None
            }
          )
        | _ => []
        }

      | None => []
      }
      ({...model, a2mlManifestPaths: paths}, Tea_Cmd.none)
    | Error(_) => (model, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "a2ml", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => (model, Tea_Cmd.none)
  }
}
