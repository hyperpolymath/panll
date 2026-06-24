// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// BurbleEngine — Pure computation for PanLL's Burble voice integration.
//
// Manages workspace huddle voice chat using the Burble Workspace profile
// (always-on VAD, noise suppression, echo cancellation, no spatial audio).
// All functions are pure — side effects (WebSocket, Gossamer invoke) happen
// in BurbleCmd.
//
// TEA integration:
//   Model:   BurbleModel.burbleState (the state)
//   Update:  BurbleEngine.update (pure state transitions)
//   Cmd:     BurbleCmd (side-effectful commands)
//   View:    consumes burbleState for rendering
//
// The Burble server runs on ws://localhost:6473/voice.

open BurbleModel

// ============================================================================
// Default state
// ============================================================================

/// Initial Burble state — disconnected, no huddle, unmuted.
let defaultState: burbleState = {
  connection: Disconnected,
  participants: Dict.make(),
  isMuted: false,
  isDeafened: false,
  currentHuddle: None,
  error: None,
}

// ============================================================================
// Pure update — TEA state transitions
// ============================================================================

/// Process a Burble message and return the updated state.
/// This is the pure core of the TEA update loop for voice huddles.
let update = (state: burbleState, msg: burbleMsg): burbleState => {
  switch msg {
  | ConnectionChanged(newConnection) => {
      ...state,
      connection: newConnection,
      // Clear error on successful connection.
      error: switch newConnection {
      | Connected => None
      | Failed(reason) => Some(reason)
      | _ => state.error
      },
    }

  | JoinedHuddle(huddleId) => {
      ...state,
      currentHuddle: Some(huddleId),
      participants: Dict.make(),
      error: None,
    }

  | LeftHuddle => {
      ...state,
      currentHuddle: None,
      participants: Dict.make(),
    }

  | ParticipantUpdated(participant) =>
    let newParticipants = Dict.fromArray(Dict.toArray(state.participants))
    Dict.set(newParticipants, participant.id, participant)
    {
      ...state,
      participants: newParticipants,
    }

  | ParticipantLeft(participantId) =>
    let newParticipants = Dict.fromArray(
      Dict.toArray(state.participants)->Array.filter(((key, _)) => key !== participantId),
    )
    {
      ...state,
      participants: newParticipants,
    }

  | MuteToggled(isMuted) => {
      ...state,
      isMuted,
    }

  | DeafenToggled(isDeafened) => {
      ...state,
      isDeafened,
      // Deafening also mutes.
      isMuted: isDeafened ? true : state.isMuted,
    }

  | ErrorOccurred(errorMsg) => {
      ...state,
      error: Some(errorMsg),
    }

  | ErrorCleared => {
      ...state,
      error: None,
    }
  }
}

// ============================================================================
// Query helpers — pure functions for reading state
// ============================================================================

/// Whether the user is connected to the Burble server.
let isConnected = (state: burbleState): bool => state.connection == Connected

/// Whether the user is currently in a huddle.
let isInHuddle = (state: burbleState): bool => Option.isSome(state.currentHuddle)

/// Get the list of participants in the current huddle.
let getParticipants = (state: burbleState): array<participant> =>
  Dict.valuesToArray(state.participants)

/// Get the count of participants in the current huddle.
let participantCount = (state: burbleState): int =>
  Array.length(Dict.keysToArray(state.participants))

/// Get participants who are currently speaking (VAD-detected).
let speakingParticipants = (state: burbleState): array<participant> =>
  Dict.valuesToArray(state.participants)->Array.filter(p => p.isSpeaking)

/// Get a specific participant by ID.
let getParticipant = (state: burbleState, participantId: string): option<participant> =>
  Dict.get(state.participants, participantId)

/// Human-readable label for the connection state (for status bar).
let connectionLabel = (state: burbleState): string =>
  switch state.connection {
  | Disconnected => "Disconnected"
  | Connecting => "Connecting..."
  | Connected =>
    switch state.currentHuddle {
    | Some(huddle) =>
      let count = participantCount(state)
      `In huddle: ${huddle} (${Int.toString(count)} participants)`
    | None => "Connected (no huddle)"
    }
  | Reconnecting => "Reconnecting..."
  | Failed(reason) => `Failed: ${reason}`
  }

/// Voice state label for the local user (muted/deafened/active).
let localVoiceLabel = (state: burbleState): string =>
  if state.isDeafened {
    "Deafened"
  } else if state.isMuted {
    "Muted"
  } else {
    "Active"
  }

/// Whether the Burble state has an active error to display.
let hasError = (state: burbleState): bool => Option.isSome(state.error)
