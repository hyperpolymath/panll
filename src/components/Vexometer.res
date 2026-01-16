// SPDX-License-Identifier: AGPL-3.0-or-later

/// Vexometer Component
///
/// Measures and displays the "Friction of Things" - the cognitive load
/// on the Operator. Triggers anti-inflammatory UI adjustments when
/// vexation exceeds thresholds.

open Model
open Msg
open Tea.Html

/// Vexation level thresholds
let lowThreshold = 0.3
let mediumThreshold = 0.5
let highThreshold = 0.7
let criticalThreshold = 0.9

/// Get colour based on vexation level
let getVexationColour = (index: float): string => {
  if index >= criticalThreshold {
    "text-red-400"
  } else if index >= highThreshold {
    "text-orange-400"
  } else if index >= mediumThreshold {
    "text-amber-400"
  } else if index >= lowThreshold {
    "text-yellow-400"
  } else {
    "text-emerald-400"
  }
}

/// Get bar colour based on vexation level
let getBarColour = (index: float): string => {
  if index >= criticalThreshold {
    "bg-red-500"
  } else if index >= highThreshold {
    "bg-orange-500"
  } else if index >= mediumThreshold {
    "bg-amber-500"
  } else if index >= lowThreshold {
    "bg-yellow-500"
  } else {
    "bg-emerald-500"
  }
}

/// Get status text based on vexation level
let getStatusText = (index: float, antiInflammatory: bool, inertia: bool): string => {
  if inertia {
    "Inertia Detected"
  } else if antiInflammatory {
    "Anti-Inflammatory Active"
  } else if index >= criticalThreshold {
    "Critical Vexation"
  } else if index >= highThreshold {
    "High Friction"
  } else if index >= mediumThreshold {
    "Moderate Friction"
  } else if index >= lowThreshold {
    "Mild Friction"
  } else {
    "Stable Co-Orbit"
  }
}

/// Render the expanded vexometer panel
let renderExpandedView = (state: vexometerState): Vdom.t<msg> => {
  let indexPercent = Int.toString(Int.fromFloat(state.index *. 100.0))
  let barWidth = indexPercent ++ "%"
  let barColour = getBarColour(state.index)
  let textColour = getVexationColour(state.index)
  let statusText = getStatusText(state.index, state.antiInflammatoryActive, state.inertiaDetected)

  div(
    list{Attrs.class("fixed bottom-4 right-4 w-64 bg-gray-900 border border-gray-700 rounded-lg p-4 shadow-xl")},
    list{
      // Header
      div(
        list{Attrs.class("flex items-center justify-between mb-3")},
        list{
          div(
            list{Attrs.class("text-sm font-semibold text-gray-300")},
            list{text("Vexation Index")},
          ),
          div(
            list{Attrs.class(`text-lg font-bold ${textColour}`)},
            list{text(indexPercent ++ "%")},
          ),
        },
      ),

      // Progress bar
      div(
        list{Attrs.class("h-3 bg-gray-800 rounded-full overflow-hidden mb-3")},
        list{
          div(
            list{
              Attrs.class(`h-full ${barColour} transition-all duration-500`),
              Attrs.style("width", barWidth),
            },
            list{},
          ),
        },
      ),

      // Status
      div(
        list{Attrs.class(`text-xs ${textColour} mb-3`)},
        list{text(statusText)},
      ),

      // Metrics
      div(
        list{Attrs.class("grid grid-cols-2 gap-2 text-xs")},
        list{
          div(
            list{Attrs.class("bg-gray-800/50 p-2 rounded")},
            list{
              div(
                list{Attrs.class("text-gray-500")},
                list{text("Cancellations")},
              ),
              div(
                list{Attrs.class("text-amber-300 font-mono")},
                list{text(Int.toString(state.recentCancellations))},
              ),
            },
          ),
          div(
            list{Attrs.class("bg-gray-800/50 p-2 rounded")},
            list{
              div(
                list{Attrs.class("text-gray-500")},
                list{text("Corrections")},
              ),
              div(
                list{Attrs.class("text-amber-300 font-mono")},
                list{text(Int.toString(state.recentCorrections))},
              ),
            },
          ),
        },
      ),

      // Anti-inflammatory indicator
      if state.antiInflammatoryActive {
        div(
          list{Attrs.class("mt-3 p-2 bg-indigo-900/30 border border-indigo-700/50 rounded text-xs text-indigo-300")},
          list{text("Environment simplified to reduce friction")},
        )
      } else {
        noNode
      },

      // Inertia breaker prompt
      if state.inertiaDetected {
        div(
          list{Attrs.class("mt-3 p-2 bg-amber-900/30 border border-amber-700/50 rounded text-xs text-amber-300")},
          list{text("Stasis detected. Consider: What's the smallest next step?")},
        )
      } else {
        noNode
      },
    },
  )
}

/// Render the compact vexometer indicator
let renderCompactView = (state: vexometerState): Vdom.t<msg> => {
  let indexPercent = Int.toString(Int.fromFloat(state.index *. 100.0))
  let barWidth = indexPercent ++ "%"
  let barColour = getBarColour(state.index)

  div(
    list{Attrs.class("fixed bottom-4 right-4 w-32")},
    list{
      div(
        list{Attrs.class("text-xs text-gray-500 mb-1 flex items-center justify-between")},
        list{
          text("Vexation"),
          div(
            list{Attrs.class("text-gray-400")},
            list{text(indexPercent ++ "%")},
          ),
        },
      ),
      div(
        list{Attrs.class("h-2 bg-gray-800 rounded-full overflow-hidden")},
        list{
          div(
            list{
              Attrs.class(`h-full ${barColour} transition-all duration-300`),
              Attrs.style("width", barWidth),
            },
            list{},
          ),
        },
      ),
    },
  )
}

/// Main Vexometer view
let view = (state: vexometerState, expanded: bool): Vdom.t<msg> => {
  if expanded {
    renderExpandedView(state)
  } else {
    renderCompactView(state)
  }
}
