// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

let updateInterfaces = (model: model, msg: interfacesMsg): (model, Tea_Cmd.t<msg>) => {
  let iface = model.interfaces
  switch msg {
  | ScanInterfaces => (
      {...model, interfaces: {...iface, loading: true, error: None}},
      Tea_Cmd.batch(list{
        InterfacesCmd.scanInterfaces(result => Interfaces(InterfacesLoaded(result))),
        TypeLLService.checkConfigTypes("abi-ffi-scan", "interfaces", result => Interfaces(TypeCheckResult(result))),
      }),
    )
  | InterfacesLoaded(result) =>
    switch result {
    | Ok(_jsonStr) => ({...model, interfaces: {...iface, loaded: true, loading: false}}, Tea_Cmd.none)
    | Error(e) => ({...model, interfaces: {...iface, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetIfaceCategory(cat) => ({...model, interfaces: {...iface, activeCategory: cat}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "interfaces", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
