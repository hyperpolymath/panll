// SPDX-License-Identifier: PMPL-1.0-or-later
//
// BurbleEngine.res — Burble voice integration engine for PanLL.
//
// Pure computation module that bridges Burble's embeddable client
// library into PanLL's TEA architecture. Handles:
//
//   - Voice session lifecycle (start/stop huddles)
//   - PanelBus event emission on voice state changes
//   - VoiceTag integration (speech transcripts → code annotations)
//   - Panel context tracking (which panel initiated voice)
//   - Graceful degradation when Burble server is unavailable
//
// Integration path:
//   1. TauriEvents.res subscribes to "burble:*" Tauri events
//   2. Msg.res includes BurbleMsg variants
//   3. Update.res routes BurbleMsg to this engine
//   4. This engine emits PanelBus events for other panels to consume
//
// This engine does NOT own the Burble client directly — it provides
// pure state + event computation. Side effects (WebSocket, audio)
// happen in the Tauri command layer.

/// Voice session state for PanLL.
type voiceSessionState =
  | Inactive          // No voice session running
  | Connecting        // Burble connection in progress
  | Active({          // Voice session active
      roomId: string,
      context: panelContext,
      participantCount: int,
      isMuted: bool,
      isDeafened: bool,
    })
  | Error(string)     // Voice failed

/// Panel context for voice sessions.
and panelContext =
  | GlobalHuddle          // Workspace-wide voice
  | PanelSpecific(string) // Voice tied to a panel
  | PairProgramming       // Two-person session
  | CodeReview            // Review session (may record)

/// Burble engine state (part of PanLL's Model).
type state = {
  voiceSession: voiceSessionState,
  serverUrl: string,
  serverAvailable: bool,
  speechToTextEnabled: bool,
  recentTranscripts: array<transcript>,
}

/// A speech transcript for VoiceTag integration.
and transcript = {
  text: string,
  speaker: string,
  timestamp: float,
  panelId: option<string>,
}

/// Default initial state.
let init = (): state => {
  voiceSession: Inactive,
  serverUrl: "ws://localhost:4000/voice",
  serverAvailable: false,
  speechToTextEnabled: false,
  recentTranscripts: [],
}

// ---------------------------------------------------------------------------
// Messages (to be included in PanLL's Msg.res)
// ---------------------------------------------------------------------------

/// Burble-related messages for PanLL's TEA update loop.
type msg =
  | StartHuddle(panelContext)
  | StopHuddle
  | VoiceConnected(string)     // roomId
  | VoiceDisconnected
  | VoiceError(string)
  | ParticipantJoined(string, string) // userId, displayName
  | ParticipantLeft(string)           // userId
  | SpeechStarted(string, string)     // userId, displayName
  | SpeechStopped(string)             // userId
  | TranscriptReceived(string, string, string) // userId, displayName, text
  | ToggleMute
  | ToggleDeafen
  | ToggleSpeechToText
  | ServerAvailabilityChanged(bool)

// ---------------------------------------------------------------------------
// Update (pure computation — no side effects)
// ---------------------------------------------------------------------------

/// Process a Burble message, returning updated state + PanelBus events.
let update = (state: state, msg: msg): (state, array<PanelBus.panelEvent>) => {
  switch msg {
  | StartHuddle(context) =>
    let newState = {...state, voiceSession: Connecting}
    (newState, [])

  | StopHuddle =>
    let events = switch state.voiceSession {
    | Active({context}) =>
      let ctxStr = switch context {
      | GlobalHuddle => "global"
      | PanelSpecific(id) => "panel:" ++ id
      | PairProgramming => "pair"
      | CodeReview => "review"
      }
      [PanelBus.BurbleVoiceEnded(ctxStr)]
    | _ => []
    }
    ({...state, voiceSession: Inactive}, events)

  | VoiceConnected(roomId) =>
    let context = switch state.voiceSession {
    | Connecting => GlobalHuddle  // Default context if not set
    | Active({context}) => context
    | _ => GlobalHuddle
    }
    let ctxStr = switch context {
    | GlobalHuddle => "global"
    | PanelSpecific(id) => "panel:" ++ id
    | PairProgramming => "pair"
    | CodeReview => "review"
    }
    let newState = {
      ...state,
      voiceSession: Active({
        roomId,
        context,
        participantCount: 1,
        isMuted: false,
        isDeafened: false,
      }),
    }
    (newState, [PanelBus.BurbleVoiceStarted(ctxStr, roomId)])

  | VoiceDisconnected =>
    ({...state, voiceSession: Inactive}, [])

  | VoiceError(err) =>
    ({...state, voiceSession: Error(err)}, [])

  | ParticipantJoined(_, _) =>
    let newState = switch state.voiceSession {
    | Active(s) =>
      {...state, voiceSession: Active({...s, participantCount: s.participantCount + 1})}
    | _ => state
    }
    (newState, [])

  | ParticipantLeft(_) =>
    let newState = switch state.voiceSession {
    | Active(s) =>
      {...state, voiceSession: Active({...s, participantCount: max(0, s.participantCount - 1)})}
    | _ => state
    }
    (newState, [])

  | SpeechStarted(userId, displayName) =>
    (state, [PanelBus.BurbleSpeechStarted(userId, displayName)])

  | SpeechStopped(userId) =>
    (state, [PanelBus.BurbleSpeechEnded(userId)])

  | TranscriptReceived(userId, displayName, text) =>
    let transcript: transcript = {
      text,
      speaker: displayName,
      timestamp: Date.now(),
      panelId: switch state.voiceSession {
      | Active({context: PanelSpecific(id)}) => Some(id)
      | _ => None
      },
    }
    let transcripts = Array.concat([transcript], state.recentTranscripts)
    let trimmed = if Array.length(transcripts) > 50 {
      Array.slice(transcripts, ~start=0, ~end=50)
    } else {
      transcripts
    }
    let events = if state.speechToTextEnabled {
      [PanelBus.BurbleVoiceTagCreated(text, "Note")]
    } else {
      []
    }
    ({...state, recentTranscripts: trimmed}, events)

  | ToggleMute =>
    let newState = switch state.voiceSession {
    | Active(s) => {...state, voiceSession: Active({...s, isMuted: !s.isMuted})}
    | _ => state
    }
    (newState, [])

  | ToggleDeafen =>
    let newState = switch state.voiceSession {
    | Active(s) => {...state, voiceSession: Active({...s, isDeafened: !s.isDeafened})}
    | _ => state
    }
    (newState, [])

  | ToggleSpeechToText =>
    ({...state, speechToTextEnabled: !state.speechToTextEnabled}, [])

  | ServerAvailabilityChanged(available) =>
    ({...state, serverAvailable: available}, [])
  }
}

// ---------------------------------------------------------------------------
// Query helpers
// ---------------------------------------------------------------------------

/// Whether a voice session is currently active.
let isActive = (state: state): bool => {
  switch state.voiceSession {
  | Active(_) => true
  | _ => false
  }
}

/// Current participant count (0 if not in session).
let participantCount = (state: state): int => {
  switch state.voiceSession {
  | Active({participantCount}) => participantCount
  | _ => 0
  }
}

/// Whether the local user is muted.
let isMuted = (state: state): bool => {
  switch state.voiceSession {
  | Active({isMuted}) => isMuted
  | _ => false
  }
}

/// Status string for display in the workspace UI.
let statusLabel = (state: state): string => {
  switch state.voiceSession {
  | Inactive => "Voice: Off"
  | Connecting => "Voice: Connecting..."
  | Active({participantCount, context}) =>
    let ctxLabel = switch context {
    | GlobalHuddle => "Huddle"
    | PanelSpecific(id) => "Panel " ++ id
    | PairProgramming => "Pair"
    | CodeReview => "Review"
    }
    `Voice: ${ctxLabel} (${Int.toString(participantCount)})`
  | Error(err) => "Voice: Error — " ++ err
  }
}
