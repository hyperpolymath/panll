// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// BurbleModel — Types for PanLL's Burble voice integration.
//
// Manages workspace huddle voice chat. Unlike IDApTIK's gaming profile
// (spatial audio, PTT), PanLL uses the Workspace profile:
//   - Always-on voice activity detection (hands-free)
//   - Noise suppression ON (office/home noise)
//   - Echo cancellation ON (speaker+mic setups)
//   - No spatial audio (flat conference style)
//   - E2EE ON (workspace conversations are sensitive)
//
// The Burble server runs on ws://localhost:6473/voice.

// ============================================================================
// Voice types (mirroring BurbleClient's type surface for PanLL's context)
// ============================================================================

/// Voice state of a participant in a huddle.
type voiceState =
  | Connected
  | Muted
  | Deafened

/// A participant in a workspace huddle.
type participant = {
  /// Unique user ID from Burble.
  id: string,
  /// Display name shown in the huddle UI.
  displayName: string,
  /// Current voice state (connected, muted, deafened).
  voiceState: voiceState,
  /// Whether the participant is currently speaking (VAD-detected).
  isSpeaking: bool,
  /// Volume level (0.0 to 1.0).
  volume: float,
}

/// Connection state for the Burble voice server.
type connectionState =
  | Disconnected
  | Connecting
  | Connected
  | Reconnecting
  | Failed(string)

// ============================================================================
// PanLL Burble state — the TEA model for voice huddles
// ============================================================================

/// Complete Burble state for PanLL's TEA architecture.
/// This is the model that BurbleEngine's pure functions operate on,
/// and that BurbleCmd's side-effectful commands produce updates for.
type burbleState = {
  /// Current connection state to the Burble server.
  connection: connectionState,
  /// Participants in the current huddle, keyed by user ID.
  participants: Dict.t<participant>,
  /// Whether the local user is muted.
  isMuted: bool,
  /// Whether the local user is deafened.
  isDeafened: bool,
  /// Current huddle room ID (None if not in a huddle).
  currentHuddle: option<string>,
  /// Error message to display in the UI.
  error: option<string>,
}

// ============================================================================
// Messages — TEA messages for the Burble subsystem
// ============================================================================

/// Messages that update the Burble state in PanLL's TEA loop.
type burbleMsg =
  | ConnectionChanged(connectionState)
  | JoinedHuddle(string)
  | LeftHuddle
  | ParticipantUpdated(participant)
  | ParticipantLeft(string)
  | MuteToggled(bool)
  | DeafenToggled(bool)
  | ErrorOccurred(string)
  | ErrorCleared
