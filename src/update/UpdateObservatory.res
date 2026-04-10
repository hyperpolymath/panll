// SPDX-License-Identifier: PMPL-1.0-or-later

/// Observatory — integrative dashboard sub-updater.

open Model
open Msg

let updateObservatory = (model: model, subMsg: observatoryMsg): (model, Tea_Cmd.t<msg>) => {
  switch subMsg {
  | SetObsTab(tab) => (
      {...model, observatory: {...model.observatory, activeTab: tab}},
      Tea_Cmd.none,
    )
  | RunHealthCheck => (
      {...model, observatory: {...model.observatory, checking: true}},
      Tea_Cmd.none,
    )
  | HealthCheckComplete(result) =>
    switch result {
    | Ok(snapshots) => (
        {...model, observatory: {...model.observatory, snapshots, checking: false, error: None}},
        Tea_Cmd.none,
      )
    | Error(err) => (
        {...model, observatory: {...model.observatory, checking: false, error: Some(err)}},
        Tea_Cmd.none,
      )
    }
  | DismissObsError => (
      {...model, observatory: {...model.observatory, error: None}},
      Tea_Cmd.none,
    )
  }
}
