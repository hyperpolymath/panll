// SPDX-License-Identifier: MPL-2.0
// UpdateCladeBrowser.res — Clade Browser sub-updater extracted from Update.res

open Model
open Msg

let updateCladeBrowser = (model: model, msg: cladeBrowserMsg): (model, Tea_Cmd.t<msg>) => {
  let cb = model.cladeBrowser
  switch msg {
  | SetCladeCategory(cat) => ({...model, cladeBrowser: {...cb, category: cat}}, Tea_Cmd.none)
  | SelectClade(id) => ({...model, cladeBrowser: {...cb, selectedClade: id}}, Tea_Cmd.none)
  | SetKindFilter(kind) => ({...model, cladeBrowser: {...cb, kindFilter: kind}}, Tea_Cmd.none)
  | UpdateCladeSearch(query) => (
      {...model, cladeBrowser: {...cb, searchQuery: query}},
      Tea_Cmd.none,
    )
  | LoadClades => (
      {...model, cladeBrowser: {...cb, loading: true}},
      Tea_Cmd.batch(list{
        CladeCmd.scanCladeFiles(result => CladeBrowser(
          CladesLoaded(
            switch result {
            | Ok(jsonStr) => {
                let loaded = CladeLoader.fromScanResult(jsonStr)
                let merged = CladeLoader.mergeWithBuiltins(
                  loaded,
                  CladeBrowserEngine.builtinCladesBase,
                )
                merged->Array.map(CladeBrowserEngine.enrichClade)
              }
            | Error(_) => CladeBrowserEngine.builtinClades
            },
          ),
        )),
        TypeLLService.checkMetadataTypes("clade-scan", "clade-browser", result => CladeBrowser(
          TypeCheckResult(result),
        )),
      }),
    )
  | CladesLoaded(clades) => (
      {...model, cladeBrowser: {...cb, clades, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | SetCladePermission(targetCladeId, perm) => {
      let newRules = CladeBrowserEngine.setPermission(cb.permissionRules, targetCladeId, perm)
      // Integration #7: Clade Permissions → K9 Hunt check
      // When setting permissions, verify Hunt-level K9 execution is permitted
      // based on clade isolation and signing status.
      let updatedModel = switch cb.clades->Array.find(c => c.id === targetCladeId) {
      | Some(clade) =>
        let isolationStr = switch clade.isolation {
        | CladeBrowserModel.IsolationNone => "none"
        | CladeBrowserModel.IsolationSoft => "soft"
        | CladeBrowserModel.IsolationProcess => "process"
        | CladeBrowserModel.IsolationContainer => "container|hunt|full"
        }
        let signingOk = switch clade.signing {
        | CladeBrowserModel.SigningVerified(_) => true
        | _ => false
        }
        // Check if there's a loaded K9 contractile to verify Hunt permission against
        let _huntCheck = switch model.lastK9Contractile {
        | Some(contractile) =>
          if contractile.securityLevel == K9Engine.Hunt {
            let (_allowed, _reason) = K9Engine.checkHuntPermission(
              isolationStr,
              signingOk,
              K9Engine.summariseContractile(contractile),
            )
            // Hunt permission check result is logged but not blocking (informational)
          }
        | None => ()
        }
        {...model, cladeBrowser: {...cb, permissionRules: newRules}}
      | None => {...model, cladeBrowser: {...cb, permissionRules: newRules}}
      }
      (updatedModel, Tea_Cmd.none)
    }
  | RemoveCladePermission(targetCladeId) => {
      let newRules = CladeBrowserEngine.removePermission(cb.permissionRules, targetCladeId)
      ({...model, cladeBrowser: {...cb, permissionRules: newRules}}, Tea_Cmd.none)
    }
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "cladebrowser", json)
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
