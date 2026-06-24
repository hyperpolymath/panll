// SPDX-License-Identifier: MPL-2.0

/// SystemUpdate — component update management sub-updater.

open Model
open Msg
open SystemUpdateMsg

let updateSystemUpdate = (model: model, subMsg: systemUpdateMsg): (model, Tea_Cmd.t<msg>) => {
  let su = model.systemUpdate
  switch subMsg {
  | ListComponents => (
      {...model, systemUpdate: {...su, loading: true}},
      SystemUpdateCmd.listComponents(r => SystemUpdate(ComponentsLoaded(r))),
    )
  | ComponentsLoaded(Ok(json)) => {
      let _ = json
      ({...model, systemUpdate: {...su, loading: false}}, Tea_Cmd.none)
    }
  | ComponentsLoaded(Error(e)) => (
      {...model, systemUpdate: {...su, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | CheckAll => (
      {...model, systemUpdate: {...su, loading: true}},
      SystemUpdateCmd.checkAll(r => SystemUpdate(CheckAllResult(r))),
    )
  | CheckAllResult(Ok(_json)) => ({...model, systemUpdate: {...su, loading: false}}, Tea_Cmd.none)
  | CheckAllResult(Error(e)) => (
      {...model, systemUpdate: {...su, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | CheckComponent(id) => (
      {...model, systemUpdate: {...su, loading: true}},
      SystemUpdateCmd.checkComponent(id, r => SystemUpdate(CheckComponentResult(r))),
    )
  | CheckComponentResult(Ok(_json)) => ({...model, systemUpdate: {...su, loading: false}}, Tea_Cmd.none)
  | CheckComponentResult(Error(e)) => (
      {...model, systemUpdate: {...su, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | ApplyComponent(id) => (
      {...model, systemUpdate: {...su, loading: true}},
      SystemUpdateCmd.applyComponent(id, r => SystemUpdate(ApplyComponentResult(r))),
    )
  | ApplyComponentResult(Ok(_json)) => ({...model, systemUpdate: {...su, loading: false}}, Tea_Cmd.none)
  | ApplyComponentResult(Error(e)) => (
      {...model, systemUpdate: {...su, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | ApplyAll => (
      {...model, systemUpdate: {...su, loading: true}},
      SystemUpdateCmd.applyAll(r => SystemUpdate(ApplyAllResult(r))),
    )
  | ApplyAllResult(Ok(_json)) => ({...model, systemUpdate: {...su, loading: false}}, Tea_Cmd.none)
  | ApplyAllResult(Error(e)) => (
      {...model, systemUpdate: {...su, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | AsdfStatus => (
      {...model, systemUpdate: {...su, loading: true}},
      SystemUpdateCmd.asdfStatus(r => SystemUpdate(AsdfStatusResult(r))),
    )
  | AsdfStatusResult(Ok(_json)) => ({...model, systemUpdate: {...su, loading: false}}, Tea_Cmd.none)
  | AsdfStatusResult(Error(e)) => (
      {...model, systemUpdate: {...su, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | ViewLogs => (
      {...model, systemUpdate: {...su, loading: true}},
      SystemUpdateCmd.logs(r => SystemUpdate(LogsLoaded(r))),
    )
  | LogsLoaded(Ok(_json)) => ({...model, systemUpdate: {...su, loading: false}}, Tea_Cmd.none)
  | LogsLoaded(Error(e)) => (
      {...model, systemUpdate: {...su, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | LastSummary => (
      {...model, systemUpdate: {...su, loading: true}},
      SystemUpdateCmd.lastSummary(r => SystemUpdate(LastSummaryResult(r))),
    )
  | LastSummaryResult(Ok(_json)) => ({...model, systemUpdate: {...su, loading: false}}, Tea_Cmd.none)
  | LastSummaryResult(Error(e)) => (
      {...model, systemUpdate: {...su, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | ToggleShowLogs => (
      {...model, systemUpdate: {...su, showLogs: !su.showLogs}},
      Tea_Cmd.none,
    )
  }
}
