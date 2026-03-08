// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Multiplayer Monitor Engine — pure computation and helpers for
/// the IDApTIK multiplayer sync server monitoring panel.

open MultiplayerMonitorModel

/// Human-readable labels for category tabs.
let categoryLabel = (cat: multiplayerCategory): string =>
  switch cat {
  | MultiplayerDashboard => "Dashboard"
  | MultiplayerChannels => "Channels"
  | MultiplayerStateDiff => "State Diff"
  | MultiplayerLatency => "Latency"
  | MultiplayerDeviceLocks => "Device Locks"
  }

/// Human-readable label for WebSocket connection state.
let connectionLabel = (ws: wsConnectionState): string =>
  switch ws {
  | WsDisconnected => "Disconnected"
  | WsConnecting => "Connecting..."
  | WsConnected => "Connected"
  | WsReconnecting => "Reconnecting..."
  | WsError(err) => `Error: ${err}`
  }

/// Colour class for connection state.
let connectionColour = (ws: wsConnectionState): string =>
  switch ws {
  | WsDisconnected => "text-gray-500"
  | WsConnecting => "text-amber-400"
  | WsConnected => "text-emerald-400"
  | WsReconnecting => "text-amber-400"
  | WsError(_) => "text-red-400"
  }

/// Filter players — optionally exclude spectators.
let filterPlayers = (players: array<connectedPlayer>, showSpectators: bool): array<connectedPlayer> =>
  if showSpectators {
    players
  } else {
    players->Array.filter(p => !p.isSpectator)
  }

/// Get unresolved state diffs.
let unresolvedDiffs = (diffs: array<stateDiffEntry>): array<stateDiffEntry> =>
  diffs->Array.filter(d => !d.resolved)

/// Count contested device locks.
let contestedLocks = (locks: array<deviceLock>): int =>
  locks->Array.filter(l => Array.length(l.contestedBy) > 0)->Array.length

/// Average latency across all players.
let averageLatency = (players: array<connectedPlayer>): int => {
  let len = Array.length(players)
  if len === 0 {
    0
  } else {
    let total = players->Array.reduce(0, (acc, p) => acc + p.latencyMs)
    total / len
  }
}

/// Default state for the Multiplayer Monitor panel.
let defaultState: multiplayerMonitorState = {
  activeCategory: MultiplayerDashboard,
  wsConnection: WsDisconnected,
  serverUrl: "ws://localhost:4000/socket/websocket",
  players: [],
  channels: [],
  stateDiffs: [],
  deviceLocks: [],
  latencySamples: [],
  etsCache: [],
  selectedPlayerId: None,
  autoReconnect: true,
  showSpectators: true,
  loading: false,
  error: None,
}
