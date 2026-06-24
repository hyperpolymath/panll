// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Burble Room Monitor Component — Active room dashboard.
///
/// Displays active voice rooms with participant counts, recording status,
/// and speaking indicators per participant. Emits PanelBus events for
/// cross-panel communication:
///   - BurbleSpeechStarted(userId, displayName)
///   - BurbleSpeechEnded(userId)
///   - BurbleVoiceStarted(panelContext, roomId)
///   - BurbleVoiceEnded(panelContext)
///
/// Uses the groove discovery protocol for room listing via
/// GET /api/v1/servers/:id/rooms.
///
/// TEA pattern:
///   Model:  BurbleModel.burbleState (participants, huddle state)
///   Cmd:    BurbleCmd.listRooms, BurbleCmd.joinHuddle
///   View:   This file — renders room list and participant detail

open Msg
open Tea.Html

// ===========================================================================
// Room card — displays a single room with participant list
// ===========================================================================

/// Render the "current room" section when the user is in a huddle.
let rec renderCurrentRoom = (state: BurbleModel.burbleState): Tea_Vdom.t<msg> => {
  switch state.currentHuddle {
  | None =>
    div(
      list{Attrs.class_("px-4 py-6 text-center border-b border-gray-800")},
      list{
        div(list{Attrs.class_("text-gray-500 text-sm mb-2")}, list{text("Not in a room")}),
        div(
          list{Attrs.class_("text-gray-600 text-xs")},
          list{text("Join a huddle to see room activity and participant details.")},
        ),
      },
    )
  | Some(huddleId) =>
    let participants = BurbleEngine.getParticipants(state)
    let speakingCount = Array.length(BurbleEngine.speakingParticipants(state))

    div(
      list{Attrs.class_("border-b border-gray-800")},
      list{
        // Room header
        div(
          list{Attrs.class_("flex items-center justify-between px-4 py-3 bg-gray-900/50")},
          list{
            div(
              list{Attrs.class_("flex items-center gap-3")},
              list{
                // Active indicator
                div(
                  list{Attrs.class_("w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse")},
                  list{},
                ),
                div(
                  list{},
                  list{
                    div(
                      list{Attrs.class_("text-sm text-gray-200 font-medium")},
                      list{text(huddleId)},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500")},
                      list{
                        text(
                          `${Int.toString(Array.length(participants))} participants, ${Int.toString(
                              speakingCount,
                            )} speaking`,
                        ),
                      },
                    ),
                  },
                ),
              },
            ),
            // Leave button
            button(
              list{
                Attrs.class_(
                  "px-3 py-1 text-xs bg-red-900/50 text-red-300 rounded hover:bg-red-800/50 border border-red-700 transition-colors",
                ),
                Events.onClick(Burble(BurbleModel.LeftHuddle)),
                KeyboardNav.onActivate(Burble(BurbleModel.LeftHuddle)),
                Attrs.title("Leave room"),
              },
              list{text("Leave")},
            ),
          },
        ),
        // Recording status
        div(
          list{
            Attrs.class_(
              "flex items-center gap-2 px-4 py-2 border-t border-gray-800/50 bg-gray-900/30",
            ),
          },
          list{
            div(list{Attrs.class_("w-2 h-2 rounded-full bg-gray-600")}, list{}),
            span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Recording: Off")}),
            div(list{Attrs.class_("flex-1")}, list{}),
            span(list{Attrs.class_("text-xs text-gray-600")}, list{text("Consent: Avow")}),
          },
        ),
        // Participant list
        div(
          list{Attrs.class_("max-h-64 overflow-y-auto")},
          participants
          ->Array.map(p => renderParticipantRow(p))
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Render a single participant row with speaking indicator.
and renderParticipantRow = (participant: BurbleModel.participant): Tea_Vdom.t<msg> => {
  let speakingIndicator = participant.isSpeaking
    ? "border-l-2 border-l-emerald-500 bg-gray-900/30"
    : "border-l-2 border-l-transparent"
  let voiceLabel = switch participant.voiceState {
  | BurbleModel.Connected => "Active"
  | BurbleModel.Muted => "Muted"
  | BurbleModel.Deafened => "Deaf"
  }
  let voiceColour = switch participant.voiceState {
  | BurbleModel.Connected => "text-emerald-400"
  | BurbleModel.Muted => "text-amber-400"
  | BurbleModel.Deafened => "text-red-400"
  }

  div(
    list{
      Attrs.class_(`flex items-center gap-3 py-2 px-4 ${speakingIndicator} transition-all`),
      Attrs.ariaLabel(`${participant.displayName}: ${voiceLabel}`),
    },
    list{
      // Speaking animation
      div(
        list{
          Attrs.class_(
            `w-2 h-2 rounded-full transition-colors ${participant.isSpeaking
                ? "bg-emerald-400"
                : "bg-gray-700"}`,
          ),
        },
        list{},
      ),
      // Name
      span(list{Attrs.class_("text-sm text-gray-300 flex-1")}, list{text(participant.displayName)}),
      // Voice state badge
      span(list{Attrs.class_(`text-xs ${voiceColour}`)}, list{text(voiceLabel)}),
      // Volume level (small bar)
      div(
        list{Attrs.class_("w-16 h-1.5 bg-gray-800 rounded-full overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_(
                `h-full rounded-full ${participant.isSpeaking
                    ? "bg-emerald-500"
                    : "bg-gray-600"} transition-all duration-100`,
              ),
              Attrs.style("width", `${Float.toFixed(participant.volume *. 100.0, ~digits=0)}%`),
            },
            list{},
          ),
        },
      ),
    },
  )
}

// ===========================================================================
// Room actions — join/create room controls
// ===========================================================================

/// Render room action buttons.
let renderRoomActions = (inHuddle: bool): Tea_Vdom.t<msg> => {
  if inHuddle {
    noNode
  } else {
    div(
      list{Attrs.class_("flex items-center gap-2 px-4 py-3 border-b border-gray-800")},
      list{
        button(
          list{
            Attrs.class_(
              "px-3 py-1.5 text-xs bg-emerald-900/50 text-emerald-300 rounded hover:bg-emerald-800/50 border border-emerald-700 transition-colors",
            ),
            Events.onClick(Burble(BurbleModel.ConnectionChanged(BurbleModel.Connecting))),
            Attrs.title("Connect to Burble server"),
          },
          list{text("Connect")},
        ),
        span(
          list{Attrs.class_("text-xs text-gray-600")},
          list{text("Connect to see available rooms")},
        ),
      },
    )
  }
}

// ===========================================================================
// Groove room discovery section
// ===========================================================================

/// Render the groove-discovered room list.
/// Currently shows the current huddle. The listRooms command would populate
/// additional rooms from the Burble API.
let renderDiscoveredRooms = (_state: BurbleModel.burbleState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto")},
    list{
      // Section header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          span(
            list{Attrs.class_("text-sm text-gray-300 font-medium")},
            list{text("Discovered Rooms")},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-1 text-xs bg-gray-800 text-gray-400 rounded hover:bg-gray-700 border border-gray-700 transition-colors",
              ),
              Events.onClick(Burble(BurbleModel.ConnectionChanged(BurbleModel.Connecting))),
              Attrs.title("Refresh room list from groove endpoint"),
            },
            list{text("Refresh")},
          ),
        },
      ),
      // Placeholder for additional rooms from the API
      div(
        list{Attrs.class_("px-4 py-4 text-center")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-600")},
            list{text("Room discovery via groove: GET /api/v1/servers/:id/rooms")},
          ),
        },
      ),
    },
  )
}

// ===========================================================================
// Local voice controls — mute/deafen
// ===========================================================================

/// Render local voice control buttons.
let renderVoiceControls = (state: BurbleModel.burbleState): Tea_Vdom.t<msg> => {
  if !BurbleEngine.isInHuddle(state) {
    noNode
  } else {
    div(
      list{
        Attrs.class_("flex items-center gap-3 px-4 py-2 border-t border-gray-800 bg-gray-900/30"),
      },
      list{
        // Mute toggle
        button(
          list{
            Attrs.class_(
              `px-3 py-1.5 text-xs rounded border transition-colors ${state.isMuted
                  ? "bg-amber-900/50 text-amber-300 border-amber-700"
                  : "bg-gray-800 text-gray-300 border-gray-700 hover:bg-gray-700"}`,
            ),
            Events.onClick(Burble(BurbleModel.MuteToggled(!state.isMuted))),
          },
          list{text(state.isMuted ? "Unmute" : "Mute")},
        ),
        // Deafen toggle
        button(
          list{
            Attrs.class_(
              `px-3 py-1.5 text-xs rounded border transition-colors ${state.isDeafened
                  ? "bg-red-900/50 text-red-300 border-red-700"
                  : "bg-gray-800 text-gray-300 border-gray-700 hover:bg-gray-700"}`,
            ),
            Events.onClick(Burble(BurbleModel.DeafenToggled(!state.isDeafened))),
          },
          list{text(state.isDeafened ? "Undeafen" : "Deafen")},
        ),
        // Status
        div(list{Attrs.class_("flex-1")}, list{}),
        span(
          list{Attrs.class_("text-xs text-gray-500")},
          list{text(BurbleEngine.localVoiceLabel(state))},
        ),
      },
    )
  }
}

// ===========================================================================
// Main view — full-screen panel overlay
// ===========================================================================

/// Main Burble Room Monitor panel view.
///
/// Layout:
///   Header (title, close)
///   Room actions (connect/join when not in huddle)
///   Current room (participant list with speaking indicators)
///   Discovered rooms (from groove discovery)
///   Voice controls (mute/deafen when in huddle)
let view = (state: BurbleModel.burbleState): Tea_Vdom.t<msg> => {
  let inHuddle = BurbleEngine.isInHuddle(state)

  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.ariaLabel("Burble Room Monitor panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              div(
                list{Attrs.class_("text-lg font-medium text-gray-200")},
                list{text("Room Monitor")},
              ),
              span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Burble")}),
              if inHuddle {
                span(list{Attrs.class_("text-xs text-emerald-400")}, list{text("LIVE")})
              } else {
                noNode
              },
            },
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-sm text-gray-400 hover:text-gray-200 bg-gray-800 rounded hover:bg-gray-700 transition-colors",
              ),
              Events.onClick(PanelSwitcher(ClosePanels)),
              KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
          ),
        },
      ),
      // Error display
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_("px-4 py-2 bg-red-900/30 border-b border-red-800 text-xs text-red-400"),
          },
          list{text(err)},
        )
      | None => noNode
      },
      // Room actions (when not in huddle)
      renderRoomActions(inHuddle),
      // Current room detail
      renderCurrentRoom(state),
      // Discovered rooms from groove
      renderDiscoveredRooms(state),
      // Voice controls (when in huddle)
      renderVoiceControls(state),
    },
  )
}
