// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

/// STATE TRANSITION: Gitbot-Fleet (6-bot orchestration)
///
/// Handles fleet loading, bot status parsing, findings parsing, category
/// navigation, and text filtering. The fleet backend is an Axum API at :8080.
let updateFleet = (model: model, msg: fleetMsg): (model, Tea_Cmd.t<msg>) => {
  let fleet = model.fleet
  switch msg {
  | LoadFleet => (
      {...model, fleet: {...fleet, loading: true, error: None}},
      Tea_Cmd.batch(list{
        FleetCmd.fetchBots(result => Fleet(BotsLoaded(result))),
        FleetCmd.fetchFindings(result => Fleet(FindingsLoaded(result))),
        TypeLLService.checkConfigTypes("fleet-dispatch", "fleet", result => Fleet(
          TypeCheckResult(result),
        )),
      }),
    )
  | BotsLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch FleetEngine.parseBots(jsonStr) {
      | Ok(bots) => {
          let health = FleetEngine.computeHealth(bots, fleet.findings)
          (
            {
              ...model,
              fleet: {
                ...fleet,
                loaded: true,
                loading: false,
                error: None,
                bots,
                health: Some(health),
              },
            },
            Tea_Cmd.none,
          )
        }
      | Error(e) => ({...model, fleet: {...fleet, loading: false, error: Some(e)}}, Tea_Cmd.none)
      }
    | Error(e) => ({...model, fleet: {...fleet, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | FindingsLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch FleetEngine.parseFindings(jsonStr) {
      | Ok(findings) => {
          let health = FleetEngine.computeHealth(fleet.bots, findings)
          (
            {
              ...model,
              fleet: {
                ...fleet,
                loaded: true,
                loading: false,
                findings,
                health: Some(health),
              },
            },
            Tea_Cmd.none,
          )
        }
      | Error(e) => ({...model, fleet: {...fleet, loading: false, error: Some(e)}}, Tea_Cmd.none)
      }
    | Error(e) => ({...model, fleet: {...fleet, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetFleetCategory(cat) => ({...model, fleet: {...fleet, activeCategory: cat}}, Tea_Cmd.none)
  | SetFleetFilter(text) => ({...model, fleet: {...fleet, filterText: text}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "fleet", json)
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
