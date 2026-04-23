// SPDX-License-Identifier: PMPL-1.0-or-later

/// Pane-A: Ambient Substrate Component (Cognitive Ergonomics)
///
/// This component implements the deep-reaching ambient interface layer
/// designed for cognitive relief. It monitors operator load (Vexometer)
/// and provides sensory feedback via Information Humidity and the Vexation Index.

open Model
open Msg
open Tea.Html

/// Render the Information Humidity indicator.
/// Higher humidity = more revealed detail, lower = simplified view.
let renderHumidityIndicator = (humidity: humidityLevel): Tea_Vdom.t<msg> => {
  let (label, colour, description) = switch humidity {
  | High => ("High Humidity", "text-blue-400", "Maximum detail revealed")
  | Medium => ("Balanced", "text-sky-400", "Standard information density")
  | Low => ("Low Humidity", "text-amber-400", "Environment simplified (Anti-Inflammatory)")
  }

  div(
    list{Attrs.class_("mb-4 p-3 rounded bg-gray-800/40 border border-gray-700/50")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(list{Attrs.class_("text-xs text-gray-500 font-medium")}, list{text("INFORMATION HUMIDITY")}),
          div(list{Attrs.class_(`text-xs font-bold ${colour}`)}, list{text(label)}),
        },
      ),
      div(list{Attrs.class_("text-[10px] text-gray-600 italic")}, list{text(description)}),
    },
  )
}

/// Render ergonomic metrics (cancellations and corrections).
let renderErgonomicMetrics = (state: paneAState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("grid grid-cols-2 gap-3 mb-4")},
    list{
      div(
        list{Attrs.class_("p-2 bg-gray-800/30 rounded border border-gray-800")},
        list{
          div(list{Attrs.class_("text-[10px] text-gray-500 uppercase")}, list{text("Cancellations")}),
          div(
            list{Attrs.class_("text-lg font-mono text-amber-300")},
            list{text(Int.toString(state.recentCancellations))},
          ),
        },
      ),
      div(
        list{Attrs.class_("p-2 bg-gray-800/30 rounded border border-gray-800")},
        list{
          div(list{Attrs.class_("text-[10px] text-gray-500 uppercase")}, list{text("Corrections")}),
          div(
            list{Attrs.class_("text-lg font-mono text-amber-300")},
            list{text(Int.toString(state.recentCorrections))},
          ),
        },
      ),
    },
  )
}

/// The main Pane-A view.
/// This sitting alongside L, N, and W to provide the ergonomic control layer.
let view = (state: paneAState): Tea_Vdom.t<msg> => {
  let vexPercent = Int.toString(Int.fromFloat(state.vexationIndex *. 100.0))
  let vexColour = if state.vexationIndex > 0.7 {
    "text-red-400"
  } else if state.vexationIndex > 0.4 {
    "text-amber-400"
  } else {
    "text-emerald-400"
  }

  div(
    list{
      Attrs.class_("h-full flex flex-col p-4 bg-gray-950 border-r border-gray-900"),
      Attrs.role("region"),
      Attrs.ariaLabel("Ambient Substrate Panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between mb-6")},
        list{
          div(list{Attrs.class_("text-gray-400 font-semibold flex items-center gap-2")}, list{
            span(list{Attrs.class_("w-2 h-2 rounded-full bg-blue-500 animate-pulse")}, list{}),
            text("Ambient Substrate")
          }),
          button(
             list{
               Attrs.class_("text-[10px] text-gray-600 hover:text-gray-400 font-mono"),
               Events.onClick(PaneA(ToggleExpansion)),
             },
             list{text(state.expanded ? "COLLAPSE" : "EXPAND")}
          )
        },
      ),

      // Vexation Summary
      div(
        list{Attrs.class_("mb-6")},
        list{
          div(list{Attrs.class_("text-xs text-gray-500 mb-1")}, list{text("VEXATION INDEX")}),
          div(
            list{Attrs.class_(`text-4xl font-light tracking-tighter ${vexColour}`)},
            list{text(vexPercent ++ "%")},
          ),
          if state.antiInflammatoryActive {
            div(
              list{Attrs.class_("mt-2 text-[10px] bg-indigo-900/40 text-indigo-300 px-2 py-1 rounded border border-indigo-800/50 inline-block")},
              list{text("ANTI-INFLAMMATORY ACTIVE")},
            )
          } else {
            noNode
          },
        },
      ),

      // Humidity Control
      renderHumidityIndicator(state.humidity),

      // Detailed metrics (only shown when expanded)
      if state.expanded {
        div(
          list{Attrs.class_("mt-2 animate-in fade-in slide-in-from-top-2 duration-300")},
          list{
            div(list{Attrs.class_("text-xs text-gray-500 mb-2 font-medium")}, list{text("FRICTION ANALYSIS")}),
            renderErgonomicMetrics(state),
            div(
              list{Attrs.class_("text-[10px] text-gray-500 leading-relaxed")},
              list{text("Panel-A implements the Cognitive Relief Layer (CRL). It dynamically rescales the information density of Panels L, N, and W to prevent operator stasis.")},
            )
          }
        )
      } else {
        noNode
      }
    },
  )
}
