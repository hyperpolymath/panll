// SPDX-License-Identifier: MPL-2.0
open Model
open Msg

let updateAerie = (model: model, msg: aerieMsg): (model, Tea_Cmd.t<msg>) => {
  let aer = model.aerie
  switch msg {
  | LoadAerie => {
      let fetchCmd = if aer.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "observe-mcp",
          "metrics",
          `{"type": "latency"}`,
          result => Aerie(LatencyLoaded(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        AerieCmd.fetchLatency(result => Aerie(LatencyLoaded(result)))
      }
      let typellCmd = TypeLLService.checkConfigTypes("aerie-config", "aerie", result => Aerie(
        TypeCheckResult(result),
      ))
      (
        {...model, aerie: {...aer, loading: true, error: None}},
        Tea_Cmd.batch(list{fetchCmd, typellCmd}),
      )
    }
  | LatencyLoaded(result) =>
    switch result {
    | Ok(_jsonStr) => ({...model, aerie: {...aer, loaded: true, loading: false}}, Tea_Cmd.none)
    | Error(e) => ({...model, aerie: {...aer, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SpeedTestLoaded(result) =>
    switch result {
    | Ok(_jsonStr) => ({...model, aerie: {...aer, loaded: true, loading: false}}, Tea_Cmd.none)
    | Error(e) => ({...model, aerie: {...aer, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetAerieCategory(cat) => ({...model, aerie: {...aer, activeCategory: cat}}, Tea_Cmd.none)
  | ToggleAerieBojRouting => (
      {...model, aerie: {...aer, bojRouting: !aer.bojRouting}},
      Tea_Cmd.none,
    )
  | ToggleProbe(endpoint) => {
      let probes = aer.probes->Array.map(p =>
        if p.endpoint === endpoint {
          {...p, active: !p.active}
        } else {
          p
        }
      )
      ({...model, aerie: {...aer, probes}}, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "aerie", json)
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
