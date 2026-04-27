// SPDX-License-Identifier: PMPL-1.0-or-later

/// Bus — cross-panel messaging sub-updater.

open Model
open Msg
open PanelBusMsg

let updateBus = (model: model, busMsg: panelBusMsg): (model, Tea_Cmd.t<msg>) => {
  switch busMsg {
  | BusSubscribe(cladeId, topics) =>
    let busRegistry = PanelBus.subscribe(model.busRegistry, cladeId, topics)
    ({...model, busRegistry}, Tea_Cmd.none)
  | BusUnsubscribe(cladeId) =>
    let busRegistry = PanelBus.unsubscribe(model.busRegistry, cladeId)
    ({...model, busRegistry}, Tea_Cmd.none)
  | BusClearHistory =>
    let busRegistry = {...model.busRegistry, recentEvents: [], nextEventId: 1}
    ({...model, busRegistry}, Tea_Cmd.none)
  }
}
