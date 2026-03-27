// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updater for the Multiplayer Monitor panel.
/// Manages WebSocket connection lifecycle, player/channel/device-lock state,
/// state diff inspection, reconnection testing, and TypeLL integration.

open Model
open Msg

let updateMultiplayerMonitor = (model: model, msg: multiplayerMonitorMsg): (model, Tea_Cmd.t<msg>) => {
  let mp = model.multiplayerMonitor
  switch msg {
  | SetMultiplayerCategory(cat) => (
      {...model, multiplayerMonitor: {...mp, activeCategory: cat}},
      Tea_Cmd.none,
    )
  | ConnectServer => (
      {...model, multiplayerMonitor: {...mp, wsConnection: WsConnecting, loading: true}},
      Tea_Cmd.batch(list{
        MultiplayerMonitorCmd.connectToServer(
          mp.serverUrl,
          result => MultiplayerMonitor(ConnectionResult(result)),
        ),
        TypeLLService.checkGameDataTypes(mp.serverUrl, "multiplayer", result => MultiplayerMonitor(TypeCheckResult(result))),
      }),
    )
  | DisconnectServer => (
      {...model, multiplayerMonitor: {...mp, loading: true}},
      MultiplayerMonitorCmd.disconnectFromServer(
        result => MultiplayerMonitor(DisconnectionResult(result)),
      ),
    )
  | ConnectionResult(Ok(_)) => (
      {...model, multiplayerMonitor: {...mp, wsConnection: WsConnected, loading: false, error: None}},
      MultiplayerMonitorCmd.readMultiplayerState(result => MultiplayerMonitor(StateReceived(result))),
    )
  | ConnectionResult(Error(err)) => (
      {...model, multiplayerMonitor: {...mp, wsConnection: WsError(err), loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DisconnectionResult(Ok(_)) => (
      {
        ...model,
        multiplayerMonitor: {
          ...mp,
          wsConnection: WsDisconnected,
          loading: false,
          players: [],
          channels: [],
          error: None,
        },
      },
      Tea_Cmd.none,
    )
  | DisconnectionResult(Error(err)) => (
      {...model, multiplayerMonitor: {...mp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshState => (
      {...model, multiplayerMonitor: {...mp, loading: true}},
      MultiplayerMonitorCmd.readMultiplayerState(result => MultiplayerMonitor(StateReceived(result))),
    )
  | StateReceived(Ok(jsonStr)) => {
    let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
    | Some(json) =>

      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let playersArr = obj->Dict.get("players")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let players = playersArr->Array.filterMap(item => {
        let p = item->JSON.Decode.object->Option.getOr(Dict.make())
        let playerId = p->Dict.get("playerId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let displayName = p->Dict.get("displayName")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let deviceId = p->Dict.get("deviceId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let latencyMs = p->Dict.get("latencyMs")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let lamportClock = p->Dict.get("lamportClock")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let lastHeartbeat = p->Dict.get("lastHeartbeat")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let isHost = p->Dict.get("isHost")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        let isSpectator = p->Dict.get("isSpectator")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        Some({
          MultiplayerMonitorModel.playerId,
          displayName,
          deviceId,
          latencyMs: Float.toInt(latencyMs),
          lamportClock: Float.toInt(lamportClock),
          lastHeartbeat,
          isHost,
          isSpectator,
        })
      })
      let channelsArr = obj->Dict.get("channels")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let channels = channelsArr->Array.filterMap(item => {
        let c = item->JSON.Decode.object->Option.getOr(Dict.make())
        let topic = c->Dict.get("topic")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let joinedAt = c->Dict.get("joinedAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let messageCount = c->Dict.get("messageCount")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let lastMessageAt = c->Dict.get("lastMessageAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        Some({
          MultiplayerMonitorModel.topic,
          joinedAt,
          messageCount: Float.toInt(messageCount),
          lastMessageAt,
        })
      })
      let locksArr = obj->Dict.get("deviceLocks")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let deviceLocks = locksArr->Array.filterMap(item => {
        let l = item->JSON.Decode.object->Option.getOr(Dict.make())
        let deviceId = l->Dict.get("deviceId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let lockedBy = l->Dict.get("lockedBy")->Option.flatMap(JSON.Decode.string)
        let lockedAt = l->Dict.get("lockedAt")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let contestedArr = l->Dict.get("contestedBy")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
        let contestedBy = contestedArr->Array.filterMap(v => v->JSON.Decode.string)
        Some({
          MultiplayerMonitorModel.deviceId,
          lockedBy,
          lockedAt,
          contestedBy,
        })
      })
      Some((players, channels, deviceLocks))

    | None => None
    }
    switch parsed {
    | Some((players, channels, deviceLocks)) => (
        {...model, multiplayerMonitor: {...mp, players, channels, deviceLocks, loading: false, error: None}},
        Tea_Cmd.none,
      )
    | None => ({...model, multiplayerMonitor: {...mp, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | StateReceived(Error(err)) => (
      {...model, multiplayerMonitor: {...mp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | RefreshDiffs => (
      {...model, multiplayerMonitor: {...mp, loading: true}},
      MultiplayerMonitorCmd.readStateDiffs(result => MultiplayerMonitor(DiffsReceived(result))),
    )
  | DiffsReceived(Ok(jsonStr)) => {
    let parsed = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
    | Some(json) =>

      let arr = json->JSON.Decode.array->Option.getOr([])
      let diffs = arr->Array.filterMap(item => {
        let obj = item->JSON.Decode.object->Option.getOr(Dict.make())
        let timestamp = obj->Dict.get("timestamp")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)
        let playerId = obj->Dict.get("playerId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let field = obj->Dict.get("field")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let localValue = obj->Dict.get("localValue")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let remoteValue = obj->Dict.get("remoteValue")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
        let resolved = obj->Dict.get("resolved")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
        Some({
          MultiplayerMonitorModel.timestamp,
          playerId,
          field,
          localValue,
          remoteValue,
          resolved,
        })
      })
      Some(diffs)

    | None => None
    }
    switch parsed {
    | Some(stateDiffs) => ({...model, multiplayerMonitor: {...mp, stateDiffs, loading: false, error: None}}, Tea_Cmd.none)
    | None => ({...model, multiplayerMonitor: {...mp, loading: false, error: None}}, Tea_Cmd.none)
    }
  }
  | DiffsReceived(Error(err)) => (
      {...model, multiplayerMonitor: {...mp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | SelectPlayer(id) => (
      {...model, multiplayerMonitor: {...mp, selectedPlayerId: Some(id)}},
      Tea_Cmd.none,
    )
  | DeselectPlayer => (
      {...model, multiplayerMonitor: {...mp, selectedPlayerId: None}},
      Tea_Cmd.none,
    )
  | ToggleSpectators => (
      {...model, multiplayerMonitor: {...mp, showSpectators: !mp.showSpectators}},
      Tea_Cmd.none,
    )
  | ToggleAutoReconnect => (
      {...model, multiplayerMonitor: {...mp, autoReconnect: !mp.autoReconnect}},
      Tea_Cmd.none,
    )
  | ReconnectionTest => (
      {...model, multiplayerMonitor: {...mp, loading: true}},
      MultiplayerMonitorCmd.reconnectionTest(
        result => MultiplayerMonitor(ReconnectionTestResult(result)),
      ),
    )
  | ReconnectionTestResult(Ok(_)) => (
      {...model, multiplayerMonitor: {...mp, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | ReconnectionTestResult(Error(err)) => (
      {...model, multiplayerMonitor: {...mp, loading: false, error: Some(err)}},
      Tea_Cmd.none,
    )
  | DismissMultiplayerError => (
      {...model, multiplayerMonitor: {...mp, error: None}},
      Tea_Cmd.none,
    )
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "multiplayermonitor", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
