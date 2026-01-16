// SPDX-License-Identifier: AGPL-3.0-or-later

/// Pane-N: Neural Stream Component
///
/// The inference manifold showing the Agent's internal monologue,
/// OODA loop visibility, and Thing-Agency monitor.

open Model
open Msg
open Tea.Html

/// Render the OODA phase indicator
let renderOodaPhase = (phase: oodaPhase): Vdom.t<msg> => {
  let phases = [
    (Observe, "O", "Observe"),
    (Orient, "O", "Orient"),
    (Decide, "D", "Decide"),
    (Act, "A", "Act"),
  ]

  div(
    list{Attrs.class("flex gap-1 mb-4")},
    phases
    ->Array.map(((p, letter, label)) => {
      let isActive = p === phase
      let bgClass = isActive ? "bg-emerald-600" : "bg-gray-700"
      let textClass = isActive ? "text-white" : "text-gray-500"

      div(
        list{
          Attrs.class(`${bgClass} ${textClass} w-8 h-8 rounded flex items-center justify-center text-xs font-bold`),
          Attrs.title(label),
        },
        list{text(letter)},
      )
    })
    ->Array.toList,
  )
}

/// Render the Thing-Agency monitor
let renderAgencyMonitor = (agency: agencyState): Vdom.t<msg> => {
  let autonomyPercent = Int.toString(Int.fromFloat(agency.autonomyLevel *. 100.0))
  let barWidth = autonomyPercent ++ "%"

  div(
    list{Attrs.class("mb-4 p-3 bg-gray-800/50 rounded")},
    list{
      div(
        list{Attrs.class("text-xs text-gray-500 mb-2")},
        list{text("THING-AGENCY MONITOR")},
      ),
      renderOodaPhase(agency.phase),
      div(
        list{Attrs.class("flex items-center gap-2")},
        list{
          div(
            list{Attrs.class("text-xs text-gray-400 w-20")},
            list{text("Autonomy:")},
          ),
          div(
            list{Attrs.class("flex-1 h-2 bg-gray-700 rounded overflow-hidden")},
            list{
              div(
                list{
                  Attrs.class("h-full bg-emerald-500 transition-all duration-300"),
                  Attrs.style("width", barWidth),
                },
                list{},
              ),
            },
          ),
          div(
            list{Attrs.class("text-xs text-emerald-400 w-12 text-right")},
            list{text(autonomyPercent ++ "%")},
          ),
        },
      ),
    },
  )
}

/// Render a neural token
let renderToken = (token: neuralToken): Vdom.t<msg> => {
  let validatedClass = token.validated ? "border-emerald-700" : "border-amber-700"
  let confidencePercent = Int.toString(Int.fromFloat(token.confidence *. 100.0))

  div(
    list{Attrs.class(`p-2 mb-1 border-l-2 ${validatedClass} bg-gray-800/30`)},
    list{
      div(
        list{Attrs.class("text-sm text-gray-300")},
        list{text(token.content)},
      ),
      div(
        list{Attrs.class("text-xs text-gray-600 mt-1")},
        list{text(`confidence: ${confidencePercent}%`)},
      ),
    },
  )
}

/// Render the token stream
let renderTokenStream = (tokens: array<neuralToken>): Vdom.t<msg> => {
  div(
    list{Attrs.class("mb-4")},
    list{
      div(
        list{Attrs.class("text-xs text-gray-500 mb-2")},
        list{text("TOKEN STREAM")},
      ),
      if Array.length(tokens) === 0 {
        div(
          list{Attrs.class("text-gray-600 text-sm italic")},
          list{text("No tokens received")},
        )
      } else {
        div(
          list{Attrs.class("max-h-32 overflow-y-auto")},
          tokens->Array.map(renderToken)->Array.toList,
        )
      },
    },
  )
}

/// Render the monologue/inference stream
let renderMonologue = (monologue: string, inferenceActive: bool): Vdom.t<msg> => {
  let statusClass = inferenceActive ? "text-emerald-400" : "text-gray-500"
  let statusText = inferenceActive ? "streaming..." : "idle"

  div(
    list{Attrs.class("flex-1")},
    list{
      div(
        list{Attrs.class("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class("text-xs text-gray-500")},
            list{text("INFERENCE MANIFOLD")},
          ),
          div(
            list{Attrs.class(`text-xs ${statusClass}`)},
            list{text(statusText)},
          ),
        },
      ),
      div(
        list{
          Attrs.class(
            "h-48 bg-gray-800/50 rounded p-3 overflow-y-auto text-sm text-emerald-200 whitespace-pre-wrap",
          ),
        },
        list{text(monologue === "" ? "Awaiting neural inference..." : monologue)},
      ),
    },
  )
}

/// Main Pane-N view
let view = (state: paneNState): Vdom.t<msg> => {
  div(
    list{Attrs.class("h-full flex flex-col p-4 bg-gray-900")},
    list{
      // Header
      div(
        list{Attrs.class("flex items-center justify-between mb-4")},
        list{
          div(
            list{Attrs.class("text-emerald-400 font-semibold")},
            list{text("Neural Stream")},
          ),
          div(
            list{Attrs.class("text-xs text-gray-600")},
            list{text("Ctrl+Shift+N")},
          ),
        },
      ),

      // Agency monitor
      renderAgencyMonitor(state.agency),

      // Token stream
      renderTokenStream(state.tokens),

      // Monologue
      renderMonologue(state.monologue, state.inferenceActive),
    },
  )
}
