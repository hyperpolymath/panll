// SPDX-License-Identifier: AGPL-3.0-or-later

/// PanLL View - The render layer for the eNSAID environment.
///
/// This module implements the TEA view function, rendering the
/// three-pane parallel architecture with ambient substrate.

open Model
open Msg
open Tea.Html

/// Render the Orbital Drift Aura background
let renderDriftAura = (orbital: orbitalState, humidity: humidityLevel): Vdom.t<msg> => {
  let opacityClass = switch humidity {
  | High => "opacity-30"
  | Medium => "opacity-20"
  | Low => "opacity-10"
  }
  let colourClass = orbital.driftAuraColour === "indigo"
    ? "bg-indigo-900"
    : "bg-amber-900"

  div(
    list{
      Attrs.class(`fixed inset-0 ${colourClass} ${opacityClass} transition-all duration-1000 pointer-events-none`),
    },
    list{},
  )
}

/// Render the Vexation Index indicator
let renderVexometer = (vex: vexometerState): Vdom.t<msg> => {
  let barWidth = Int.toString(Int.fromFloat(vex.index *. 100.0)) ++ "%"
  let barColour = if vex.index > 0.7 {
    "bg-red-500"
  } else if vex.index > 0.4 {
    "bg-amber-500"
  } else {
    "bg-emerald-500"
  }

  div(
    list{Attrs.class("fixed bottom-4 right-4 w-32")},
    list{
      div(
        list{Attrs.class("text-xs text-gray-400 mb-1")},
        list{text("Vexation Index")},
      ),
      div(
        list{Attrs.class("h-2 bg-gray-800 rounded overflow-hidden")},
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

/// Render Pane-L (Symbolic Mass)
let renderPaneL = (paneL: paneLState, visible: bool): Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{
        Attrs.class("flex-1 bg-gray-900 border-r border-indigo-900/50 p-4 overflow-auto"),
      },
      list{
        div(
          list{Attrs.class("text-indigo-400 text-sm font-semibold mb-2")},
          list{text("SYMBOLIC MASS (Pane-L)")},
        ),
        div(
          list{Attrs.class("text-gray-300 font-mono text-sm whitespace-pre-wrap")},
          list{text(paneL.editorContent === "" ? "// Enter constraints..." : paneL.editorContent)},
        ),
      },
    )
  }
}

/// Render Pane-N (Neural Stream)
let renderPaneN = (paneN: paneNState, visible: bool): Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{
        Attrs.class("flex-1 bg-gray-900 border-r border-emerald-900/50 p-4 overflow-auto"),
      },
      list{
        div(
          list{Attrs.class("text-emerald-400 text-sm font-semibold mb-2")},
          list{text("NEURAL STREAM (Pane-N)")},
        ),
        div(
          list{Attrs.class("text-gray-300 text-sm")},
          list{text(paneN.monologue === "" ? "Awaiting inference..." : paneN.monologue)},
        ),
        div(
          list{Attrs.class("mt-4 text-xs text-gray-500")},
          list{
            text(
              `Agency: ${Float.toString(paneN.agency.autonomyLevel *. 100.0)}% autonomous`,
            ),
          },
        ),
      },
    )
  }
}

/// Render the Binary Star diagram (Topology View)
let renderBinaryStarDiagram = (): Vdom.t<msg> => {
  div(
    list{Attrs.class("flex items-center justify-center h-full")},
    list{
      div(
        list{Attrs.class("text-center")},
        list{
          div(
            list{Attrs.class("flex items-center justify-center gap-16")},
            list{
              // Symbolic star
              div(
                list{Attrs.class("w-24 h-24 rounded-full bg-indigo-600/50 border-2 border-indigo-400 flex items-center justify-center")},
                list{
                  div(
                    list{Attrs.class("text-indigo-300 text-xs")},
                    list{text("SYMBOLIC")},
                  ),
                },
              ),
              // Orbital path indicator
              div(
                list{Attrs.class("w-16 border-t-2 border-dashed border-gray-600")},
                list{},
              ),
              // Neural star
              div(
                list{Attrs.class("w-24 h-24 rounded-full bg-emerald-600/50 border-2 border-emerald-400 flex items-center justify-center")},
                list{
                  div(
                    list{Attrs.class("text-emerald-300 text-xs")},
                    list{text("NEURAL")},
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class("mt-8 text-gray-500 text-sm")},
            list{text("Binary Star Co-Orbit")},
          ),
        },
      ),
    },
  )
}

/// Render Pane-W (World/Barycentre)
let renderPaneW = (paneW: paneWState, visible: bool): Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{Attrs.class("flex-1 bg-gray-900 p-4 overflow-auto")},
      list{
        div(
          list{Attrs.class("text-gray-400 text-sm font-semibold mb-2")},
          list{text("TASK BARYCENTRE (Pane-W)")},
        ),
        if paneW.topologyView {
          renderBinaryStarDiagram()
        } else {
          div(
            list{Attrs.class("text-gray-300 text-sm")},
            list{text(paneW.content === "" ? "Shared world state..." : paneW.content)},
          )
        },
      },
    )
  }
}

/// Render the Dark Start architecture manifold
let renderDarkStart = (): Vdom.t<msg> => {
  div(
    list{Attrs.class("fixed inset-0 bg-gray-950 flex items-center justify-center")},
    list{
      div(
        list{Attrs.class("text-center")},
        list{
          div(
            list{Attrs.class("text-4xl font-light text-gray-600 mb-8")},
            list{text("PanLL")},
          ),
          renderBinaryStarDiagram(),
          div(
            list{Attrs.class("mt-12 text-gray-600 text-sm")},
            list{text("eNSAID Environment")},
          ),
        },
      ),
    },
  )
}

/// Main view function
let view = (model: model): Vdom.t<msg> => {
  // Dark Start mode - show architecture manifold
  if model.viewMode === DarkStart {
    renderDarkStart()
  } else {
    div(
      list{Attrs.class("h-screen bg-gray-950 text-gray-100 flex flex-col")},
      list{
        // Ambient substrate - Orbital Drift Aura
        renderDriftAura(model.orbital, model.humidity),

        // Main three-pane layout
        div(
          list{Attrs.class("flex-1 flex overflow-hidden relative z-10")},
          list{
            renderPaneL(model.paneL, model.paneLVisible),
            renderPaneN(model.paneN, model.paneNVisible),
            renderPaneW(model.paneW, model.paneWVisible),
          },
        ),

        // Vexometer indicator
        renderVexometer(model.vexometer),
      },
    )
  }
}
