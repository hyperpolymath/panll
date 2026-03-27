// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

let updateReposystem = (model: model, msg: reposystemMsg): (model, Tea_Cmd.t<msg>) => {
  let rsr = model.reposystem
  switch msg {
  | ScanAll => (
      {...model, reposystem: {...rsr, loading: true, error: None}},
      Tea_Cmd.batch(list{
        ReposystemCmd.scanAll(result => Reposystem(ScanAllLoaded(result))),
        TypeLLService.checkConfigTypes("rsr-scan", "reposystem", result => Reposystem(
          TypeCheckResult(result),
        )),
      }),
    )
  | ScanAllLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch ReposystemEngine.parseAudits(jsonStr) {
      | Ok(audits) => {
          let stats = ReposystemEngine.computeStats(audits)
          (
            {
              ...model,
              reposystem: {...rsr, loaded: true, loading: false, audits, stats: Some(stats)},
            },
            Tea_Cmd.none,
          )
        }
      | Error(e) => ({...model, reposystem: {...rsr, loading: false, error: Some(e)}}, Tea_Cmd.none)
      }
    | Error(e) => ({...model, reposystem: {...rsr, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetRsrCategory(cat) => ({...model, reposystem: {...rsr, activeCategory: cat}}, Tea_Cmd.none)
  | SetRsrFilter(text) => ({...model, reposystem: {...rsr, filterText: text}}, Tea_Cmd.none)
  | SelectRequirement(req) => (
      {...model, reposystem: {...rsr, selectedRequirement: req}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "reposystem", json)
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
