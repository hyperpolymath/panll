// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// BurbleCmd — TEA command wrappers for PanLL's Burble voice integration.
//
// All commands use the invoke bridge to communicate with the Rust
// backend, which manages the WebSocket connection to the Burble voice
// server at ws://localhost:6473/voice.
//
// Pattern: same as LlmCodingCmd.res — Tea_Cmd.call wrapping backend invokes
// with Promise-based async flow and result tagging.
//
// The Workspace profile is always used:
//   - Always-on VAD (hands-free)
//   - Noise suppression ON
//   - Echo cancellation ON
//   - No spatial audio
//   - E2EE ON

let invoke = RuntimeBridge.invoke

// ============================================================================
// Connection lifecycle
// ============================================================================

/// Connect to the Burble voice server.
/// The backend establishes a Phoenix WebSocket to ws://localhost:6473/voice
/// with the Workspace profile applied.
let connect = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "burble_connect",
      {
        "server_url": "ws://localhost:6473/voice",
        "profile": "workspace",
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to connect to Burble")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Disconnect from the Burble voice server.
let disconnect = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("burble_disconnect", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to disconnect from Burble")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Huddle lifecycle
// ============================================================================

/// Join a workspace huddle by huddle ID.
/// Creates/joins the voice room on the Burble server.
let joinHuddle = (huddleId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("burble_join_huddle", {"huddle_id": huddleId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to join huddle")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Leave the current workspace huddle.
let leaveHuddle = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("burble_leave_huddle", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to leave huddle")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Voice controls
// ============================================================================

/// Toggle the local user's mute state.
let toggleMute = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("burble_toggle_mute", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to toggle mute")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Toggle the local user's deafen state.
/// Deafening also mutes the user.
let toggleDeafen = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("burble_toggle_deafen", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to toggle deafen")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Participant queries
// ============================================================================

/// Fetch the current list of participants in the huddle.
/// Returns a JSON string that the update function can parse.
let getParticipants = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("burble_get_participants", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get participants")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Groove discovery — probe Burble's /.well-known/groove endpoint
// ============================================================================

/// Probe the Burble groove endpoint to discover capabilities.
/// GET http://localhost:6473/.well-known/groove
/// Returns the groove manifest JSON (service_id, capabilities, endpoints).
let checkGroove = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "burble_check_groove",
      {
        "url": "http://localhost:6473/.well-known/groove",
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Groove probe failed — Burble not reachable")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Room management — list and query rooms via groove API
// ============================================================================

/// List active rooms on the Burble server.
/// GET http://localhost:6473/api/v1/servers/:id/rooms
/// The serverId "local" is used for the default local Burble instance.
let listRooms = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "burble_list_rooms",
      {
        "url": "http://localhost:6473/api/v1/servers/local/rooms",
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list rooms")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Health check — query Burble server health
// ============================================================================

/// Check the Burble server health endpoint.
/// GET http://localhost:6473/api/v1/health
/// Returns JSON with server status, uptime, room count, participant count.
let getHealth = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke(
      "burble_get_health",
      {
        "url": "http://localhost:6473/api/v1/health",
      },
    )
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Health check failed — Burble not reachable")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Voice stats — WebRTC quality metrics
// ============================================================================

/// Query WebRTC voice statistics for the active session.
/// Returns latency, jitter, packet loss, bitrate, codec info as JSON.
let getVoiceStats = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("burble_get_voice_stats", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get voice stats")))
      Promise.resolve()
    })
    ->ignore
  })
}
