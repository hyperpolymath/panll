// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL View - The render layer for the eNSAID environment.
///
/// This module implements the TEA view function, rendering the
/// three-pane parallel architecture with ambient substrate.

open Model
open Msg
open Tea.Html

/// Render the Orbital Drift Aura background
let renderDriftAura = (orbital: orbitalState, humidity: humidityLevel): Tea_Vdom.t<msg> => {
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
      Attrs.class_(`fixed inset-0 ${colourClass} ${opacityClass} transition-all duration-1000 pointer-events-none`),
    },
    list{},
  )
}

/// Render Pane-L (Symbolic Mass) - using full component.
/// Receives proof obligations from VeriSimDB VQL-DT queries to display
/// as symbolic constraints alongside the constraint editor.
let renderPaneL = (paneL: paneLState, proofs: array<proofObligation>, visible: bool): Tea_Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{Attrs.class_("flex-1 overflow-auto")},
      list{PaneL.view(paneL, proofs)},
    )
  }
}

/// Render Pane-N (Neural Stream) with ECHIDNA theorem prover panel - using full component
let renderPaneN = (paneN: paneNState, echidna: echidnaState, visible: bool): Tea_Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{Attrs.class_("flex-1 overflow-auto")},
      list{PaneN.view(paneN, echidna)},
    )
  }
}

/// Render Pane-W (World/Barycentre) - using full component
/// This pane draws the central security panel, event chain importer, and
/// panic-attacker toolset, ensuring the time/space study is visible when dialogs open.
/// Render Pane-W (World/Barycentre) with VeriSimDB database tools.
let renderPaneW = (paneW: paneWState, orbital: orbitalState, db: verisimdbState, visible: bool): Tea_Vdom.t<msg> => {
  if !visible {
    noNode
  } else {
    div(
      list{Attrs.class_("flex-1 overflow-auto")},
      list{PaneW.view(paneW, orbital, db)},
    )
  }
}

/// Render the Dark Start architecture manifold
let renderDarkStart = (): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950 flex items-center justify-center cursor-pointer"),
      Attrs.role("button"),
      Attrs.ariaLabel("Enter eNSAID environment"),
      Events.onClick(View(SetViewMode(Standard))),
      KeyboardUtil.onEnterOrSpace(View(SetViewMode(Standard))),
    },
    list{
      div(
        list{Attrs.class_("text-center")},
        list{
          div(
            list{Attrs.class_("text-4xl font-light text-gray-600 mb-8")},
            list{text("PanLL")},
          ),
          div(
            list{Attrs.class_("flex items-center justify-center gap-16")},
            list{
              // Symbolic star
              div(
                list{Attrs.class_("w-24 h-24 rounded-full bg-indigo-600/50 border-2 border-indigo-400 flex items-center justify-center")},
                list{
                  div(
                    list{Attrs.class_("text-indigo-300 text-xs")},
                    list{text("SYMBOLIC")},
                  ),
                },
              ),
              // Orbital path indicator
              div(
                list{Attrs.class_("w-16 border-t-2 border-dashed border-gray-600")},
                list{},
              ),
              // Neural star
              div(
                list{Attrs.class_("w-24 h-24 rounded-full bg-emerald-600/50 border-2 border-emerald-400 flex items-center justify-center")},
                list{
                  div(
                    list{Attrs.class_("text-emerald-300 text-xs")},
                    list{text("NEURAL")},
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("mt-12 text-gray-600 text-sm")},
            list{text("eNSAID Environment")},
          ),
          div(
            list{Attrs.class_("mt-6 text-gray-700 text-xs animate-pulse")},
            list{text("Click anywhere to enter")},
          ),
        },
      ),
    },
  )
}

/// Main view function
let view = (model: model): Tea_Vdom.t<msg> => {
  // Dark Start mode - show architecture manifold
  if model.viewMode === DarkStart {
    renderDarkStart()
  } else {
    div(
      list{Attrs.class_("h-screen bg-gray-950 text-gray-100 flex flex-col")},
      list{
        // Ambient substrate - Orbital Drift Aura
        renderDriftAura(model.orbital, model.humidity),

        // Main three-pane layout
        div(
          list{Attrs.class_("flex-1 flex overflow-hidden relative z-10")},
          list{
            renderPaneL(model.paneL, model.verisimdb.proofObligations, model.paneLVisible),
            renderPaneN(model.paneN, model.echidna, model.paneNVisible),
            renderPaneW(model.paneW, model.orbital, model.verisimdb, model.paneWVisible),
          },
        ),

        // Vexometer - using full component with compact view by default
        Vexometer.view(model.vexometer, false),

        // Feedback-O-Tron - using full component
        FeedbackOTron.view(
          model.feedbackPending,
          model.feedbackError,
          model.feedbackReportType,
        ),

        // VAB (Verified Assembly Building) - full-screen overlay
        if model.vab.visible {
          Vab.view(model.vab)
        } else {
          noNode
        },
      },
    )
  }
}
