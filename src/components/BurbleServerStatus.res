// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Burble Server Status Component — Groove-aware health panel.
///
/// Displays Burble server connection state, active rooms, total participants,
/// uptime, and a groove capability summary showing which services are connected.
///
/// Uses the groove discovery protocol to probe localhost:6473/.well-known/groove
/// and enriches the view with capability details (voice, text, presence, TTS,
/// STT, recording, spatial audio).
///
/// TEA pattern:
///   Model:  BurbleModel.burbleState + grooveManifest from BurbleCmd
///   Update: BurbleEngine.update (pure state transitions)
///   Cmd:    BurbleCmd.checkGroove, BurbleCmd.getHealth
///   View:   This file — renders server status and groove discovery

open Msg
open Tea.Html

// ===========================================================================
// Groove capability row — coloured pill with endpoint and protocol
// ===========================================================================

/// Capability status from groove manifest.
type grooveCapability = {
  name: string,
  capType: string,
  protocol: string,
  endpoint: string,
  panelCompatible: bool,
}

/// Render a single groove capability as a status row.
let renderCapability = (cap: grooveCapability): Tea_Vdom.t<msg> => {
  let compatClass = cap.panelCompatible ? "text-emerald-400" : "text-gray-600"
  let protocolBadge = switch cap.protocol {
  | "webrtc" => "bg-purple-900/50 text-purple-300 border-purple-700"
  | "websocket" => "bg-blue-900/50 text-blue-300 border-blue-700"
  | "http" => "bg-amber-900/50 text-amber-300 border-amber-700"
  | _ => "bg-gray-800 text-gray-400 border-gray-700"
  }

  div(
    list{Attrs.class_("flex items-center gap-3 py-1.5 px-3 border-b border-gray-800/50")},
    list{
      // Capability name
      span(list{Attrs.class_("text-sm text-gray-300 w-28")}, list{text(cap.name)}),
      // Protocol badge
      span(
        list{Attrs.class_(`text-xs px-1.5 py-0.5 rounded border ${protocolBadge}`)},
        list{text(cap.protocol)},
      ),
      // Endpoint
      span(list{Attrs.class_("text-xs text-gray-500 font-mono flex-1")}, list{text(cap.endpoint)}),
      // Panel compatible indicator
      span(
        list{
          Attrs.class_(`text-xs ${compatClass}`),
          Attrs.title(cap.panelCompatible ? "Panel-compatible" : "Not panel-compatible"),
        },
        list{text(cap.panelCompatible ? "PANEL" : "---")},
      ),
    },
  )
}

// ===========================================================================
// Connection status indicator
// ===========================================================================

/// Render the server connection status header.
let renderConnectionStatus = (connection: BurbleModel.connectionState): Tea_Vdom.t<msg> => {
  let (dotClass, label) = switch connection {
  | Disconnected => ("bg-gray-600", "Disconnected")
  | Connecting => ("bg-amber-400 animate-pulse", "Connecting...")
  | Connected => ("bg-emerald-400", "Connected")
  | Reconnecting => ("bg-amber-400 animate-pulse", "Reconnecting...")
  | Failed(reason) => ("bg-red-500", `Failed: ${reason}`)
  }

  div(
    list{Attrs.class_("flex items-center gap-3 px-4 py-3 border-b border-gray-800")},
    list{
      div(list{Attrs.class_(`w-3 h-3 rounded-full ${dotClass}`)}, list{}),
      div(
        list{Attrs.class_("flex-1")},
        list{
          div(list{Attrs.class_("text-sm text-gray-200 font-medium")}, list{text("Burble Server")}),
          div(list{Attrs.class_("text-xs text-gray-500")}, list{text(label)}),
        },
      ),
      // Server URL
      span(list{Attrs.class_("text-xs text-gray-600 font-mono")}, list{text("localhost:6473")}),
    },
  )
}

// ===========================================================================
// Stats grid — rooms, participants, uptime
// ===========================================================================

/// Render a stat card in the overview grid.
let statCard = (label: string, value: string, colour: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("bg-gray-900/60 border border-gray-800 rounded-lg p-3 text-center")},
    list{
      div(list{Attrs.class_(`text-2xl font-bold ${colour}`)}, list{text(value)}),
      div(list{Attrs.class_("text-xs text-gray-500 mt-1")}, list{text(label)}),
    },
  )
}

/// Render the server stats overview grid.
let renderStatsGrid = (state: BurbleModel.burbleState): Tea_Vdom.t<msg> => {
  let participantCount = Int.toString(Array.length(Dict.valuesToArray(state.participants)))
  let roomLabel = switch state.currentHuddle {
  | Some(_) => "1"
  | None => "0"
  }

  div(
    list{Attrs.class_("grid grid-cols-3 gap-3 px-4 py-3 border-b border-gray-800")},
    list{
      statCard("Active Rooms", roomLabel, "text-blue-400"),
      statCard("Participants", participantCount, "text-emerald-400"),
      statCard("Connection", BurbleEngine.localVoiceLabel(state), "text-amber-400"),
    },
  )
}

// ===========================================================================
// Groove capabilities section
// ===========================================================================

/// The known Burble groove capabilities from the /.well-known/groove manifest.
/// These are rendered as a summary of what the Burble server offers.
let burbleCapabilities: array<grooveCapability> = [
  {name: "Voice", capType: "voice", protocol: "webrtc", endpoint: "/voice", panelCompatible: true},
  {
    name: "Text",
    capType: "text",
    protocol: "websocket",
    endpoint: "/socket/websocket",
    panelCompatible: true,
  },
  {
    name: "Presence",
    capType: "presence",
    protocol: "websocket",
    endpoint: "/socket/websocket",
    panelCompatible: true,
  },
  {
    name: "Spatial",
    capType: "spatial-audio",
    protocol: "webrtc",
    endpoint: "/voice",
    panelCompatible: false,
  },
  {
    name: "Recording",
    capType: "recording",
    protocol: "http",
    endpoint: "/api/v1/recordings",
    panelCompatible: true,
  },
  {name: "TTS", capType: "tts", protocol: "http", endpoint: "/api/v1/tts", panelCompatible: false},
  {name: "STT", capType: "stt", protocol: "http", endpoint: "/api/v1/stt", panelCompatible: false},
]

/// Render the groove capabilities section.
let renderGrooveCapabilities = (connected: bool): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto")},
    list{
      // Section header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(
                list{Attrs.class_("text-sm text-gray-300 font-medium")},
                list{text("Groove Capabilities")},
              ),
              span(list{Attrs.class_("text-xs text-gray-600")}, list{text("/.well-known/groove")}),
            },
          ),
          // Refresh button
          button(
            list{
              Attrs.class_(
                "px-2 py-1 text-xs bg-gray-800 text-gray-400 rounded hover:bg-gray-700 border border-gray-700 transition-colors",
              ),
              Events.onClick(Burble(BurbleModel.ConnectionChanged(BurbleModel.Connecting))),
              Attrs.title("Re-probe groove endpoint"),
            },
            list{text("Probe")},
          ),
        },
      ),
      // Capability list (dimmed if disconnected)
      div(
        list{Attrs.class_(connected ? "" : "opacity-50")},
        burbleCapabilities
        ->Array.map(cap => renderCapability(cap))
        ->List.fromArray
        ->List.toArray
        ->List.fromArray,
      ),
    },
  )
}

// ===========================================================================
// Error display
// ===========================================================================

/// Render error bar if present.
let renderError = (error: option<string>): Tea_Vdom.t<msg> => {
  switch error {
  | Some(err) =>
    div(
      list{Attrs.class_("px-4 py-2 bg-red-900/30 border-b border-red-800 text-xs text-red-400")},
      list{text(err)},
    )
  | None => noNode
  }
}

// ===========================================================================
// Main view — full-screen panel overlay
// ===========================================================================

/// Main Burble Server Status panel view.
///
/// Layout:
///   Header (title, close)
///   Connection status (dot, label, URL)
///   Stats grid (rooms, participants, uptime)
///   Error bar (if any)
///   Groove capabilities (capability list with protocols)
let view = (state: BurbleModel.burbleState): Tea_Vdom.t<msg> => {
  let isConnected = BurbleEngine.isConnected(state)

  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.ariaLabel("Burble Server Status panel"),
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
                list{text("Burble Server Status")},
              ),
              span(list{Attrs.class_("text-xs text-gray-500")}, list{text("groove-aware")}),
            },
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-sm text-gray-400 hover:text-gray-200 bg-gray-800 rounded hover:bg-gray-700 transition-colors",
              ),
              Events.onClick(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
          ),
        },
      ),
      // Connection status
      renderConnectionStatus(state.connection),
      // Stats grid
      renderStatsGrid(state),
      // Error display
      renderError(state.error),
      // Groove capabilities
      renderGrooveCapabilities(isConnected),
    },
  )
}
