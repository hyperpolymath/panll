// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

/// STATE TRANSITION: Git-Private-Farm (repo inventory)
///
/// Handles loading the manifest, parsing the inventory, and UI state changes
/// (category, filter, sort). The backend reads local JSON — no HTTP service.
let updateFarm = (model: model, msg: farmMsg): (model, Tea_Cmd.t<msg>) => {
  let farm = model.farm
  switch msg {
  | LoadRepos => (
      {...model, farm: {...farm, loading: true, error: None}},
      FarmCmd.listRepos(result => Farm(ReposLoaded(result))),
    )
  | ReposLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch FarmEngine.parseInventory(jsonStr) {
      | Ok(repos) => (
          {
            ...model,
            farm: {
              ...farm,
              loaded: true,
              loading: false,
              error: None,
              repos,
              totalRepos: Array.length(repos),
              unhealthyCount: repos
              ->Array.filter(r =>
                switch r.healthScore {
                | Some(s) => s < 0.5
                | None => false
                }
              )
              ->Array.length,
            },
          },
          TypeLLService.checkConfigTypes(jsonStr, "farm", result => Farm(TypeCheckResult(result))),
        )
      | Error(e) => ({...model, farm: {...farm, loading: false, error: Some(e)}}, Tea_Cmd.none)
      }
    | Error(e) => ({...model, farm: {...farm, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetFarmCategory(cat) => ({...model, farm: {...farm, activeCategory: cat}}, Tea_Cmd.none)
  | SetFarmFilter(text) => ({...model, farm: {...farm, filterText: text}}, Tea_Cmd.none)
  | SetFarmSort(sort) => ({...model, farm: {...farm, sortBy: sort}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "farm", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => {
      UpdateHelpers.logDegradedService("TypeLL", "cross-panel type check failed")
      (model, Tea_Cmd.none)
    }
  }
}
