// SPDX-License-Identifier: MPL-2.0

/// PanLL Multiplayer Monitor Model — types for monitoring the IDApTIK
/// Elixir/Phoenix sync server. WebSocket status, channel subscriptions,
/// player state diffs, Lamport clocks, device locks, and latency.

/// WebSocket connection state.
type wsConnectionState =
  | WsDisconnected
  | WsConnecting
  | WsConnected
  | WsReconnecting
  | WsError(string)

/// A connected player in the multiplayer session.
type connectedPlayer = {
  playerId: string,
  displayName: string,
  deviceId: string,
  latencyMs: int,
  lamportClock: int,
  lastHeartbeat: float,
  isHost: bool,
  isSpectator: bool,
}

/// A Phoenix channel subscription.
type channelSubscription = {
  topic: string,
  joinedAt: float,
  messageCount: int,
  lastMessageAt: float,
}

/// A player state diff entry (for debugging sync issues).
type stateDiffEntry = {
  timestamp: float,
  playerId: string,
  field: string,
  localValue: string,
  remoteValue: string,
  resolved: bool,
}

/// Device lock status (which player controls which device).
type deviceLock = {
  deviceId: string,
  lockedBy: option<string>,
  lockedAt: float,
  contestedBy: array<string>,
}

/// Latency sample for graphing.
type latencySample = {
  timestamp: float,
  playerId: string,
  latencyMs: int,
}

/// ETS cache entry for inspection.
type etsCacheEntry = {
  table: string,
  key: string,
  value: string,
  size: int,
}

/// Category tabs for the Multiplayer Monitor panel.
type multiplayerCategory =
  | MultiplayerDashboard
  | MultiplayerChannels
  | MultiplayerStateDiff
  | MultiplayerLatency
  | MultiplayerDeviceLocks

/// Root state for the Multiplayer Monitor panel.
type multiplayerMonitorState = {
  activeCategory: multiplayerCategory,
  wsConnection: wsConnectionState,
  serverUrl: string,
  players: array<connectedPlayer>,
  channels: array<channelSubscription>,
  stateDiffs: array<stateDiffEntry>,
  deviceLocks: array<deviceLock>,
  latencySamples: array<latencySample>,
  etsCache: array<etsCacheEntry>,
  selectedPlayerId: option<string>,
  autoReconnect: bool,
  showSpectators: bool,
  loading: bool,
  error: option<string>,
}
