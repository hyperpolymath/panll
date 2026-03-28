// SPDX-License-Identifier: PMPL-1.0-or-later

/// Multiplayer Monitor messages -- WebSocket lifecycle, player state,
/// channel subscriptions, state diffs, device locks, latency, and
/// reconnection testing for the IDApTIK Phoenix sync server.

open Model

type multiplayerMonitorMsg =
  /// Switch the active category tab.
  | SetMultiplayerCategory(multiplayerCategory)
  /// Connect to the Phoenix sync server.
  | ConnectServer
  /// Disconnect from the sync server.
  | DisconnectServer
  /// Connection result.
  | ConnectionResult(result<string, string>)
  /// Disconnection result.
  | DisconnectionResult(result<string, string>)
  /// Refresh the full multiplayer state.
  | RefreshState
  /// Multiplayer state received.
  | StateReceived(result<string, string>)
  /// Refresh state diffs.
  | RefreshDiffs
  /// State diffs received.
  | DiffsReceived(result<string, string>)
  /// Select a player by ID.
  | SelectPlayer(string)
  /// Deselect the current player.
  | DeselectPlayer
  /// Toggle spectator visibility.
  | ToggleSpectators
  /// Toggle auto-reconnect.
  | ToggleAutoReconnect
  /// Run a reconnection test.
  | ReconnectionTest
  /// Reconnection test result.
  | ReconnectionTestResult(result<string, string>)
  /// Dismiss the error banner.
  | DismissMultiplayerError
  /// TypeLL cross-panel type check result for Phoenix types.
  | TypeCheckResult(result<string, string>)
