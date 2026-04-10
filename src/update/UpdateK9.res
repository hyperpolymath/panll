// SPDX-License-Identifier: PMPL-1.0-or-later

/// K9 — contractile management sub-updater.

open Model
open Msg

let updateK9 = (model: model, k9Msg: k9Msg): (model, Tea_Cmd.t<msg>) => {
  switch k9Msg {
  | LoadContractile(path) =>
    let cmd = K9Cmd.loadContractile(path, r => K9(ContractileLoaded(r)))
    (model, cmd)
  | ContractileLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      let contractile = K9Engine.validateContractile(jsonStr, ~path="loaded")
      let kennelSchema = if contractile.securityLevel == K9Engine.Kennel {
        Some(jsonStr)
      } else {
        model.k9KennelSchema
      }
      (
        {...model, lastK9Contractile: Some(contractile), k9KennelSchema: kennelSchema},
        Tea_Cmd.none,
      )
    | Error(_) => (model, Tea_Cmd.none)
    }
  | ValidateContractile(path) =>
    let cmd = K9Cmd.validateContractileFile(path, r => K9(ContractileValidated(r)))
    (model, cmd)
  | ContractileValidated(result) =>
    switch result {
    | Ok(jsonStr) =>
      let contractile = K9Engine.validateContractile(jsonStr, ~path="validated")
      ({...model, lastK9Contractile: Some(contractile)}, Tea_Cmd.none)
    | Error(_) => (model, Tea_Cmd.none)
    }
  | ApplyLayout(name) =>
    let cmd = K9Cmd.applyLayout(name, r => K9(LayoutApplied(r)))
    (model, cmd)
  | LayoutApplied(result) =>
    switch result {
    | Ok(jsonStr) =>
      let layout = K9Engine.parseLayoutPanels(jsonStr)
      ({...model, lastK9Layout: Some(layout)}, Tea_Cmd.none)
    | Error(_) => (model, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "k9", json)
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
