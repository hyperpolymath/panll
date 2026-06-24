// SPDX-License-Identifier: MPL-2.0

/// AmbientOps — hospital-model sysadmin sub-updater.

open Model
open Msg

let updateAmbientOps = (model: model, subMsg: ambientOpsMsg): (model, Tea_Cmd.t<msg>) => {
  switch subMsg {
  | SetOpsTab(tab) => (
      {...model, ambientOps: {...model.ambientOps, activeTab: tab}},
      Tea_Cmd.none,
    )
  | RunDiagnostics => (
      {...model, ambientOps: {...model.ambientOps, scanning: true}},
      Tea_Cmd.none,
    )
  | DiagnosticsComplete(result) =>
    switch result {
    | Ok(findings) => (
        {...model, ambientOps: {...model.ambientOps, findings, scanning: false, error: None}},
        Tea_Cmd.none,
      )
    | Error(err) => (
        {...model, ambientOps: {...model.ambientOps, scanning: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissOpsError => ({...model, ambientOps: {...model.ambientOps, error: None}}, Tea_Cmd.none)
  }
}
