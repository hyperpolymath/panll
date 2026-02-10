// SPDX-License-Identifier: PMPL-1.0-or-later

/// Pane-W: World/Task Barycentre Component
///
/// The central shared canvas where results manifest.
/// Contains the Topology View (Binary Star diagram) and
/// the shared world state.

open Model
open Msg
open Tea.Html

let renderEventChainPanel = (state: paneWState): Tea_Vdom.t<msg> => {
  let eventCount = Array.length(state.eventChain)
  let summaryView = switch state.eventChainSummary {
  | Some(summary) =>
    div(
      list{Attrs.class_("text-xs text-gray-500 mb-2")},
      list{
        text(
          "Program: "
          ++ summary.program
          ++ " · Weak points: "
          ++ Int.toString(summary.weakPoints)
          ++ " · Crashes: "
          ++ Int.toString(summary.totalCrashes)
          ++ " · Robustness: "
          ++ Float.toString(summary.robustnessScore),
        ),
      },
    )
  | None =>
    div(
      list{Attrs.class_("text-xs text-gray-600 mb-2")},
      list{text("No event-chain summary loaded.")},
    )
  }

  let errorView = switch state.eventChainError {
  | Some(err) =>
    div(
      list{Attrs.class_("text-xs text-red-400 mb-2")},
      list{text(err)},
    )
  | None => text("")
  }

  let previewCount = eventCount > 8 ? 8 : eventCount
  let eventRows =
    state.eventChain
    ->Array.slice(~offset=0, ~len=previewCount)
    ->Array.map(ev => {
        let startLabel = switch ev.startMs {
        | Some(ms) => Float.toString(ms) ++ "ms"
        | None => "n/a"
        }
        div(
          list{Attrs.class_("text-xs text-gray-400 flex justify-between")},
          list{
            div(list{Attrs.class_("truncate")}, list{text(ev.id)}),
            div(list{}, list{text(ev.axis)}),
            div(list{}, list{text(startLabel)}),
            div(list{}, list{text(Float.toString(ev.durationMs) ++ "ms")}),
            div(list{}, list{text(ev.status)}),
          },
        )
      })
    ->List.fromArray

  div(
    list{
      Attrs.class_(
        "mt-4 p-3 border border-gray-800 rounded bg-gray-900/60 space-y-2",
      ),
    },
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 tracking-widest")},
        list{text("EVENT CHAIN (PANLL IMPORT)")},
      ),
      summaryView,
      div(
        list{Attrs.class_("flex gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-300",
              ),
              Events.onClick(PaneW(ImportEventChain)),
            },
            list{text("Import JSON")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-300",
              ),
              Events.onClick(PaneW(ImportEventChainFile)),
            },
            list{text("Load File")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs bg-gray-900 hover:bg-gray-800 rounded text-gray-400",
              ),
              Events.onClick(PaneW(ClearEventChain)),
            },
            list{text("Clear")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-600 ml-auto")},
            list{text("Events: " ++ Int.toString(eventCount))},
          ),
        },
      ),
      errorView,
      textarea(
        list{
          Attrs.class_(
            "w-full h-24 bg-gray-950 border border-gray-800 rounded p-2 font-mono text-[11px] text-gray-400 resize-none focus:border-gray-600 focus:outline-none",
          ),
          Attrs.placeholder("Paste panic-attack PanLL JSON export here..."),
          Attrs.value(state.eventChainInput),
          Events.onInput(value => PaneW(UpdateEventChainInput(value))),
        },
        list{},
      ),
      div(
        list{Attrs.class_("space-y-1")},
        eventRows,
      ),
    },
  )
}

/// Render the Binary Star topology diagram
let renderTopologyView = (orbital: orbitalState): Tea_Vdom.t<msg> => {
  let stabilityPercent = Int.toString(Int.fromFloat(orbital.stability *. 100.0))
  let divergencePercent = Int.toString(Int.fromFloat(orbital.divergenceLevel *. 100.0))

  div(
    list{Attrs.class_("h-full flex flex-col items-center justify-center")},
    list{
      // Binary Star diagram
      div(
        list{Attrs.class_("relative")},
        list{
          // Orbital path (ellipse)
          div(
            list{
              Attrs.class_(
                "absolute inset-0 border-2 border-dashed border-gray-700 rounded-full",
              ),
              Attrs.style("width", "300px"),
              Attrs.style("height", "150px"),
              Attrs.style("top", "50%"),
              Attrs.style("left", "50%"),
              Attrs.style("transform", "translate(-50%, -50%)"),
            },
            list{},
          ),

          // Symbolic star (left)
          div(
            list{
              Attrs.class_(
                "absolute w-20 h-20 rounded-full bg-indigo-600/60 border-2 border-indigo-400 flex items-center justify-center shadow-lg shadow-indigo-500/30",
              ),
              Attrs.style("left", "-60px"),
              Attrs.style("top", "50%"),
              Attrs.style("transform", "translateY(-50%)"),
            },
            list{
              div(
                list{Attrs.class_("text-center")},
                list{
                  div(
                    list{Attrs.class_("text-indigo-200 text-xs font-bold")},
                    list{text("L")},
                  ),
                  div(
                    list{Attrs.class_("text-indigo-300 text-[10px]")},
                    list{text("Symbolic")},
                  ),
                },
              ),
            },
          ),

          // Neural star (right)
          div(
            list{
              Attrs.class_(
                "absolute w-20 h-20 rounded-full bg-emerald-600/60 border-2 border-emerald-400 flex items-center justify-center shadow-lg shadow-emerald-500/30",
              ),
              Attrs.style("right", "-60px"),
              Attrs.style("top", "50%"),
              Attrs.style("transform", "translateY(-50%)"),
            },
            list{
              div(
                list{Attrs.class_("text-center")},
                list{
                  div(
                    list{Attrs.class_("text-emerald-200 text-xs font-bold")},
                    list{text("N")},
                  ),
                  div(
                    list{Attrs.class_("text-emerald-300 text-[10px]")},
                    list{text("Neural")},
                  ),
                },
              ),
            },
          ),

          // Barycentre (center)
          div(
            list{
              Attrs.class_(
                "w-12 h-12 rounded-full bg-gray-600/60 border-2 border-gray-400 flex items-center justify-center",
              ),
            },
            list{
              div(
                list{Attrs.class_("text-gray-300 text-xs font-bold")},
                list{text("W")},
              ),
            },
          ),
        },
      ),

      // Metrics
      div(
        list{Attrs.class_("mt-12 grid grid-cols-2 gap-8 text-center")},
        list{
          div(
            list{},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-indigo-300")},
                list{text(stabilityPercent ++ "%")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("Orbital Stability (σ)")},
              ),
            },
          ),
          div(
            list{},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-amber-300")},
                list{text(divergencePercent ++ "%")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("Divergence Level")},
              ),
            },
          ),
        },
      ),

      // Toggle button
      div(
        list{Attrs.class_("mt-8")},
        list{
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-gray-800 hover:bg-gray-700 rounded text-sm text-gray-400 transition-colors",
              ),
              Events.onClick(PaneW(ToggleTopologyView)),
            },
            list{text("Switch to Code View")},
          ),
        },
      ),
    },
  )
}

/// Render the code/content view
let renderContentView = (state: paneWState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("h-full flex flex-col")},
    list{
      // Last validated output
      div(
        list{Attrs.class_("mb-4")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-500 mb-2")},
            list{text("LAST VALIDATED OUTPUT")},
          ),
          div(
            list{
              Attrs.class_(
                "p-3 bg-gray-800/50 rounded border border-emerald-900/30 font-mono text-sm text-emerald-200 min-h-[60px]",
              ),
            },
            list{
              text(
                state.lastValidatedOutput === ""
                  ? "No validated output yet"
                  : state.lastValidatedOutput,
              ),
            },
          ),
        },
      ),

      // Current content
      div(
        list{Attrs.class_("flex-1")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-500 mb-2")},
            list{text("SHARED WORLD STATE")},
          ),
          textarea(
            list{
              Attrs.class_(
                "w-full h-full bg-gray-800 border border-gray-700 rounded p-3 font-mono text-sm text-gray-300 resize-none focus:border-gray-500 focus:outline-none",
              ),
              Attrs.placeholder("Task output manifests here..."),
              Attrs.value(state.content),
              Events.onInput(value => PaneW(UpdateContent(value))),
            },
            list{},
          ),
        },
      ),

      renderEventChainPanel(state),

      // Toggle button
      div(
        list{Attrs.class_("mt-4 text-right")},
        list{
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-gray-800 hover:bg-gray-700 rounded text-sm text-gray-400 transition-colors",
              ),
              Events.onClick(PaneW(ToggleTopologyView)),
            },
            list{text("Switch to Topology View")},
          ),
        },
      ),
    },
  )
}

/// Main Pane-W view
let view = (state: paneWState, orbital: orbitalState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("h-full flex flex-col p-4 bg-gray-900")},
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between mb-4")},
        list{
          div(
            list{Attrs.class_("text-gray-400 font-semibold")},
            list{text("Task Barycentre")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-600")},
            list{text("Ctrl+Shift+B")},
          ),
        },
      ),

      // Content
      if state.topologyView {
        renderTopologyView(orbital)
      } else {
        renderContentView(state)
      },
    },
  )
}
