// SPDX-License-Identifier: AGPL-3.0-or-later

/// Pane-W: World/Task Barycentre Component
///
/// The central shared canvas where results manifest.
/// Contains the Topology View (Binary Star diagram) and
/// the shared world state.

open Model
open Msg
open Tea.Html

/// Render the Binary Star topology diagram
let renderTopologyView = (orbital: orbitalState): Vdom.t<msg> => {
  let stabilityPercent = Int.toString(Int.fromFloat(orbital.stability *. 100.0))
  let divergencePercent = Int.toString(Int.fromFloat(orbital.divergenceLevel *. 100.0))

  div(
    list{Attrs.class("h-full flex flex-col items-center justify-center")},
    list{
      // Binary Star diagram
      div(
        list{Attrs.class("relative")},
        list{
          // Orbital path (ellipse)
          div(
            list{
              Attrs.class(
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
              Attrs.class(
                "absolute w-20 h-20 rounded-full bg-indigo-600/60 border-2 border-indigo-400 flex items-center justify-center shadow-lg shadow-indigo-500/30",
              ),
              Attrs.style("left", "-60px"),
              Attrs.style("top", "50%"),
              Attrs.style("transform", "translateY(-50%)"),
            },
            list{
              div(
                list{Attrs.class("text-center")},
                list{
                  div(
                    list{Attrs.class("text-indigo-200 text-xs font-bold")},
                    list{text("L")},
                  ),
                  div(
                    list{Attrs.class("text-indigo-300 text-[10px]")},
                    list{text("Symbolic")},
                  ),
                },
              ),
            },
          ),

          // Neural star (right)
          div(
            list{
              Attrs.class(
                "absolute w-20 h-20 rounded-full bg-emerald-600/60 border-2 border-emerald-400 flex items-center justify-center shadow-lg shadow-emerald-500/30",
              ),
              Attrs.style("right", "-60px"),
              Attrs.style("top", "50%"),
              Attrs.style("transform", "translateY(-50%)"),
            },
            list{
              div(
                list{Attrs.class("text-center")},
                list{
                  div(
                    list{Attrs.class("text-emerald-200 text-xs font-bold")},
                    list{text("N")},
                  ),
                  div(
                    list{Attrs.class("text-emerald-300 text-[10px]")},
                    list{text("Neural")},
                  ),
                },
              ),
            },
          ),

          // Barycentre (center)
          div(
            list{
              Attrs.class(
                "w-12 h-12 rounded-full bg-gray-600/60 border-2 border-gray-400 flex items-center justify-center",
              ),
            },
            list{
              div(
                list{Attrs.class("text-gray-300 text-xs font-bold")},
                list{text("W")},
              ),
            },
          ),
        },
      ),

      // Metrics
      div(
        list{Attrs.class("mt-12 grid grid-cols-2 gap-8 text-center")},
        list{
          div(
            list{},
            list{
              div(
                list{Attrs.class("text-2xl font-light text-indigo-300")},
                list{text(stabilityPercent ++ "%")},
              ),
              div(
                list{Attrs.class("text-xs text-gray-500")},
                list{text("Orbital Stability (σ)")},
              ),
            },
          ),
          div(
            list{},
            list{
              div(
                list{Attrs.class("text-2xl font-light text-amber-300")},
                list{text(divergencePercent ++ "%")},
              ),
              div(
                list{Attrs.class("text-xs text-gray-500")},
                list{text("Divergence Level")},
              ),
            },
          ),
        },
      ),

      // Toggle button
      div(
        list{Attrs.class("mt-8")},
        list{
          button(
            list{
              Attrs.class(
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
let renderContentView = (content: string, lastValidated: string): Vdom.t<msg> => {
  div(
    list{Attrs.class("h-full flex flex-col")},
    list{
      // Last validated output
      div(
        list{Attrs.class("mb-4")},
        list{
          div(
            list{Attrs.class("text-xs text-gray-500 mb-2")},
            list{text("LAST VALIDATED OUTPUT")},
          ),
          div(
            list{
              Attrs.class(
                "p-3 bg-gray-800/50 rounded border border-emerald-900/30 font-mono text-sm text-emerald-200 min-h-[60px]",
              ),
            },
            list{text(lastValidated === "" ? "No validated output yet" : lastValidated)},
          ),
        },
      ),

      // Current content
      div(
        list{Attrs.class("flex-1")},
        list{
          div(
            list{Attrs.class("text-xs text-gray-500 mb-2")},
            list{text("SHARED WORLD STATE")},
          ),
          textarea(
            list{
              Attrs.class(
                "w-full h-full bg-gray-800 border border-gray-700 rounded p-3 font-mono text-sm text-gray-300 resize-none focus:border-gray-500 focus:outline-none",
              ),
              Attrs.placeholder("Task output manifests here..."),
              Attrs.value(content),
              Events.onInput(value => PaneW(UpdateContent(value))),
            },
            list{},
          ),
        },
      ),

      // Toggle button
      div(
        list{Attrs.class("mt-4 text-right")},
        list{
          button(
            list{
              Attrs.class(
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
let view = (state: paneWState, orbital: orbitalState): Vdom.t<msg> => {
  div(
    list{Attrs.class("h-full flex flex-col p-4 bg-gray-900")},
    list{
      // Header
      div(
        list{Attrs.class("flex items-center justify-between mb-4")},
        list{
          div(
            list{Attrs.class("text-gray-400 font-semibold")},
            list{text("Task Barycentre")},
          ),
          div(
            list{Attrs.class("text-xs text-gray-600")},
            list{text("Ctrl+Shift+B")},
          ),
        },
      ),

      // Content
      if state.topologyView {
        renderTopologyView(orbital)
      } else {
        renderContentView(state.content, state.lastValidatedOutput)
      },
    },
  )
}
