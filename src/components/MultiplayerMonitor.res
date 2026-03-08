// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Multiplayer Monitor Component — view for monitoring the IDApTIK
/// Phoenix sync server. Dashboard, channels, state diffs, latency, locks.

open Model
open Msg
open Tea.Html

/// Render a category tab button.
let renderTab = (
  label: string,
  cat: multiplayerCategory,
  active: multiplayerCategory,
): Tea_Vdom.t<msg> => {
  let isActive = cat === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{Attrs.class_(cls), Events.onClick(MultiplayerMonitor(SetMultiplayerCategory(cat)))},
    list{text(label)},
  )
}

/// Render a player card.
let renderPlayerCard = (player: connectedPlayer, isSelected: bool): Tea_Vdom.t<msg> => {
  let borderCls = if isSelected { "border-cyan-400" } else { "border-gray-700" }
  let latencyCls = if player.latencyMs < 50 {
    "text-emerald-400"
  } else if player.latencyMs < 100 {
    "text-amber-400"
  } else {
    "text-red-400"
  }
  div(
    list{
      Attrs.class_(`p-3 bg-gray-800 rounded border ${borderCls} cursor-pointer hover:border-gray-500`),
      Events.onClick(MultiplayerMonitor(SelectPlayer(player.playerId))),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(list{Attrs.class_("text-sm font-medium text-gray-100")}, list{text(player.displayName)}),
              if player.isHost {
                span(list{Attrs.class_("text-xs bg-amber-700 text-amber-100 px-1.5 py-0.5 rounded")}, list{text("HOST")})
              } else if player.isSpectator {
                span(list{Attrs.class_("text-xs bg-gray-600 text-gray-300 px-1.5 py-0.5 rounded")}, list{text("SPEC")})
              } else {
                noNode
              },
            },
          ),
          span(list{Attrs.class_(`text-xs font-mono ${latencyCls}`)}, list{text(`${Int.toString(player.latencyMs)}ms`)}),
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-3 text-xs text-gray-500")},
        list{
          span(list{}, list{text(`Device: ${player.deviceId}`)}),
          span(list{}, list{text(`Clock: ${Int.toString(player.lamportClock)}`)}),
        },
      ),
    },
  )
}

/// Render dashboard view.
let renderDashboard = (state: multiplayerMonitorState): Tea_Vdom.t<msg> => {
  let connCls = MultiplayerMonitorEngine.connectionColour(state.wsConnection)
  let players = MultiplayerMonitorEngine.filterPlayers(state.players, state.showSpectators)
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Connection status card
      div(
        list{Attrs.class_("p-4 bg-gray-800 rounded border border-gray-700")},
        list{
          div(
            list{Attrs.class_("flex items-center justify-between mb-3")},
            list{
              div(
                list{Attrs.class_("flex items-center gap-2")},
                list{
                  span(list{Attrs.class_("text-sm font-medium text-gray-200")}, list{text("Sync Server")}),
                  span(
                    list{Attrs.class_(`text-xs ${connCls}`)},
                    list{text(MultiplayerMonitorEngine.connectionLabel(state.wsConnection))},
                  ),
                },
              ),
              div(
                list{Attrs.class_("flex items-center gap-2")},
                list{
                  switch state.wsConnection {
                  | WsConnected =>
                    button(
                      list{
                        Attrs.class_("px-2 py-1 text-xs bg-red-700 text-white rounded hover:bg-red-600 cursor-pointer"),
                        Events.onClick(MultiplayerMonitor(DisconnectServer)),
                      },
                      list{text("Disconnect")},
                    )
                  | WsDisconnected | WsError(_) =>
                    button(
                      list{
                        Attrs.class_("px-2 py-1 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer"),
                        Events.onClick(MultiplayerMonitor(ConnectServer)),
                      },
                      list{text("Connect")},
                    )
                  | WsConnecting | WsReconnecting => noNode
                  },
                  button(
                    list{
                      Attrs.class_("px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"),
                      Events.onClick(MultiplayerMonitor(RefreshState)),
                    },
                    list{text("Refresh")},
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("text-xs text-gray-500 font-mono")},
            list{text(state.serverUrl)},
          ),
        },
      ),
      // Stats row
      div(
        list{Attrs.class_("grid grid-cols-4 gap-3")},
        list{
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(list{Attrs.class_("text-2xl font-light text-gray-100")}, list{text(Int.toString(Array.length(players)))}),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Players")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(list{Attrs.class_("text-2xl font-light text-gray-100")}, list{text(Int.toString(Array.length(state.channels)))}),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Channels")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-gray-100")},
                list{text(Int.toString(MultiplayerMonitorEngine.averageLatency(state.players)))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Avg Latency (ms)")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{
                  Attrs.class_(
                    if MultiplayerMonitorEngine.contestedLocks(state.deviceLocks) > 0 {
                      "text-2xl font-light text-red-400"
                    } else {
                      "text-2xl font-light text-gray-100"
                    },
                  ),
                },
                list{text(Int.toString(MultiplayerMonitorEngine.contestedLocks(state.deviceLocks)))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Contested Locks")}),
            },
          ),
        },
      ),
      // Player list
      if Array.length(players) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No players connected")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-2")},
          players
          ->Array.map(p => renderPlayerCard(p, state.selectedPlayerId === Some(p.playerId)))
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render channels view.
let renderChannels = (state: multiplayerMonitorState): Tea_Vdom.t<msg> => {
  if Array.length(state.channels) === 0 {
    div(
      list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
      list{text("No channel subscriptions — connect to the sync server first")},
    )
  } else {
    div(
      list{Attrs.class_("space-y-2")},
      state.channels
      ->Array.map(ch =>
        div(
          list{Attrs.class_("p-3 bg-gray-800 rounded border border-gray-700")},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between mb-1")},
              list{
                span(list{Attrs.class_("text-sm font-mono text-cyan-400")}, list{text(ch.topic)}),
                span(
                  list{Attrs.class_("text-xs text-gray-400")},
                  list{text(`${Int.toString(ch.messageCount)} messages`)},
                ),
              },
            ),
          },
        )
      )
      ->List.fromArray,
    )
  }
}

/// Render state diffs view.
let renderStateDiffs = (state: multiplayerMonitorState): Tea_Vdom.t<msg> => {
  let unresolved = MultiplayerMonitorEngine.unresolvedDiffs(state.stateDiffs)
  div(
    list{Attrs.class_("space-y-3")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between")},
        list{
          span(
            list{Attrs.class_("text-xs text-gray-400")},
            list{text(`${Int.toString(Array.length(unresolved))} unresolved diffs`)},
          ),
          button(
            list{
              Attrs.class_("px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"),
              Events.onClick(MultiplayerMonitor(RefreshDiffs)),
            },
            list{text("Refresh")},
          ),
        },
      ),
      if Array.length(state.stateDiffs) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No state diffs detected — game state is in sync")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-1")},
          state.stateDiffs
          ->Array.map(diff =>
            div(
              list{
                Attrs.class_(
                  `p-2 rounded text-xs ${if diff.resolved {
                      "bg-gray-800 opacity-50"
                    } else {
                      "bg-red-900/20 border border-red-800"
                    }}`,
                ),
              },
              list{
                div(
                  list{Attrs.class_("flex items-center gap-3")},
                  list{
                    span(list{Attrs.class_("text-gray-400")}, list{text(diff.playerId)}),
                    span(list{Attrs.class_("text-gray-200 font-mono")}, list{text(diff.field)}),
                    span(list{Attrs.class_("text-red-400 font-mono")}, list{text(diff.localValue)}),
                    span(list{Attrs.class_("text-gray-500")}, list{text("vs")}),
                    span(list{Attrs.class_("text-emerald-400 font-mono")}, list{text(diff.remoteValue)}),
                    if diff.resolved {
                      span(list{Attrs.class_("text-emerald-500")}, list{text("Resolved")})
                    } else {
                      span(list{Attrs.class_("text-red-400")}, list{text("Unresolved")})
                    },
                  },
                ),
              },
            )
          )
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render latency view.
let renderLatency = (state: multiplayerMonitorState): Tea_Vdom.t<msg> => {
  if Array.length(state.latencySamples) === 0 {
    div(
      list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
      list{text("No latency data — connect players to see latency graph")},
    )
  } else {
    div(
      list{Attrs.class_("space-y-2")},
      list{
        div(
          list{Attrs.class_("text-xs text-gray-400 mb-2")},
          list{text(`${Int.toString(Array.length(state.latencySamples))} samples`)},
        ),
        // Simple latency bars per player
        ...state.players
        ->Array.map(player => {
          let latencyCls = if player.latencyMs < 50 {
            "bg-emerald-600"
          } else if player.latencyMs < 100 {
            "bg-amber-600"
          } else {
            "bg-red-600"
          }
          let widthPct = Int.toString(
            if player.latencyMs > 200 { 100 } else { player.latencyMs * 100 / 200 },
          )
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(list{Attrs.class_("w-24 text-xs text-gray-300 truncate")}, list{text(player.displayName)}),
              div(
                list{Attrs.class_("flex-1 bg-gray-800 rounded h-4 overflow-hidden")},
                list{
                  div(
                    list{
                      Attrs.class_(`h-full ${latencyCls} rounded`),
                      Attrs.style("width", `${widthPct}%`),
                    },
                    list{},
                  ),
                },
              ),
              span(
                list{Attrs.class_("w-12 text-xs text-gray-400 text-right font-mono")},
                list{text(`${Int.toString(player.latencyMs)}ms`)},
              ),
            },
          )
        })
        ->List.fromArray,
      },
    )
  }
}

/// Render device locks view.
let renderDeviceLocks = (state: multiplayerMonitorState): Tea_Vdom.t<msg> => {
  if Array.length(state.deviceLocks) === 0 {
    div(
      list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
      list{text("No device locks active")},
    )
  } else {
    div(
      list{Attrs.class_("space-y-2")},
      state.deviceLocks
      ->Array.map(lock => {
        let isContested = Array.length(lock.contestedBy) > 0
        let borderCls = if isContested { "border-red-700" } else { "border-gray-700" }
        div(
          list{Attrs.class_(`p-3 bg-gray-800 rounded border ${borderCls}`)},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between mb-1")},
              list{
                span(list{Attrs.class_("text-sm font-mono text-gray-200")}, list{text(lock.deviceId)}),
                switch lock.lockedBy {
                | Some(player) =>
                  span(list{Attrs.class_("text-xs text-cyan-400")}, list{text(`Locked by ${player}`)})
                | None =>
                  span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Unlocked")})
                },
              },
            ),
            if isContested {
              div(
                list{Attrs.class_("text-xs text-red-400 mt-1")},
                list{
                  text(`Contested by: ${lock.contestedBy->Array.join(", ")}`),
                },
              )
            } else {
              noNode
            },
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// Main view function.
let view = (state: multiplayerMonitorState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Multiplayer Monitor panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(list{Attrs.class_("text-lg font-semibold text-gray-100")}, list{text("Multiplayer Monitor")}),
              span(
                list{Attrs.class_(`text-xs ${MultiplayerMonitorEngine.connectionColour(state.wsConnection)}`)},
                list{text(MultiplayerMonitorEngine.connectionLabel(state.wsConnection))},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    if state.showSpectators {
                      "px-2 py-1 text-xs bg-gray-600 text-white rounded"
                    } else {
                      "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                    },
                  ),
                  Events.onClick(MultiplayerMonitor(ToggleSpectators)),
                },
                list{text("Spectators")},
              ),
              button(
                list{
                  Attrs.class_("px-2 py-1 text-xs bg-amber-700 text-white rounded hover:bg-amber-600 cursor-pointer"),
                  Events.onClick(MultiplayerMonitor(ReconnectionTest)),
                },
                list{text("Reconnection Test")},
              ),
            },
          ),
        },
      ),
      // Category tabs
      div(
        list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          renderTab("Dashboard", MultiplayerDashboard, state.activeCategory),
          renderTab("Channels", MultiplayerChannels, state.activeCategory),
          renderTab("State Diff", MultiplayerStateDiff, state.activeCategory),
          renderTab("Latency", MultiplayerLatency, state.activeCategory),
          renderTab("Device Locks", MultiplayerDeviceLocks, state.activeCategory),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("mx-4 mt-2 p-2 bg-red-900/50 border border-red-700 rounded text-xs text-red-300")},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between")},
              list{
                text(err),
                button(
                  list{
                    Attrs.class_("text-red-400 hover:text-red-200 cursor-pointer"),
                    Events.onClick(MultiplayerMonitor(DismissMultiplayerError)),
                  },
                  list{text("Dismiss")},
                ),
              },
            ),
          },
        )
      | None => noNode
      },
      // Loading
      if state.loading {
        div(
          list{Attrs.class_("px-4 py-2 text-xs text-cyan-400 animate-pulse")},
          list{text("Loading multiplayer state...")},
        )
      } else {
        noNode
      },
      // Main content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4")},
        list{
          switch state.activeCategory {
          | MultiplayerDashboard => renderDashboard(state)
          | MultiplayerChannels => renderChannels(state)
          | MultiplayerStateDiff => renderStateDiffs(state)
          | MultiplayerLatency => renderLatency(state)
          | MultiplayerDeviceLocks => renderDeviceLocks(state)
          },
        },
      ),
    },
  )
}
