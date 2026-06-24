// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Reasoning Mode Selector Panel — mode grid for choosing
/// neural-symbolic reasoning strategies.
///
/// Layout: 6 mode cards in a 2x3 grid. Each card shows mode name,
/// symbolic/neural indicators, and description. Click to select.
/// Active mode is highlighted with an emerald border.

open Msg
open NesyModesModel
open NesyModesEngine
open Tea.Html

// ============================================================================
// Subsystem Indicator
// ============================================================================

/// Small indicator badge showing whether a subsystem is active.
let subsystemIndicator = (label: string, isActive: bool): Tea_Vdom.t<msg> => {
  let colorClass = if isActive {
    "bg-emerald-600 text-white"
  } else {
    "bg-gray-700 text-gray-500"
  }
  span(list{Attrs.class_(`px-2 py-0.5 text-xs rounded font-mono ${colorClass}`)}, list{text(label)})
}

// ============================================================================
// Mode Card
// ============================================================================

/// A single mode card in the selection grid.
let modeCard = (info: modeInfo, isActive: bool): Tea_Vdom.t<msg> => {
  let borderClass = modeBorderColor(info.mode, isActive)
  let bgClass = modeBgColor(info.mode)
  div(
    list{
      Attrs.class_(
        `flex flex-col p-4 rounded-lg border-2 cursor-pointer transition-all ${borderClass} ${bgClass} hover:brightness-110`,
      ),
    },
    list{
      // Mode name
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          span(
            list{Attrs.class_("font-semibold text-sm text-gray-100")},
            list{text(info.displayName)},
          ),
          if isActive {
            span(list{Attrs.class_("text-xs text-emerald-400 font-mono")}, list{text("ACTIVE")})
          } else {
            noNode
          },
        },
      ),
      // Description
      p(
        list{Attrs.class_("text-xs text-gray-400 mb-3 leading-relaxed")},
        list{text(info.description)},
      ),
      // Subsystem indicators
      div(
        list{Attrs.class_("flex gap-2 mt-auto")},
        list{
          subsystemIndicator("Symbolic", info.usesSymbolic),
          subsystemIndicator("Neural", info.usesNeural),
          if info.isHybrid {
            span(
              list{Attrs.class_("px-2 py-0.5 text-xs rounded font-mono bg-purple-600 text-white")},
              list{text("Hybrid")},
            )
          } else {
            noNode
          },
        },
      ),
    },
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Top-level view for the NeSy Reasoning Mode Selector panel.
let view = (state: nesyModesState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col h-full p-3 bg-gray-950 text-gray-100")},
    list{
      // Panel header
      div(
        list{Attrs.class_("flex items-center justify-between mb-4")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold")},
            list{text("NeSy Reasoning Mode Selector")},
          ),
          if state.switching {
            span(
              list{Attrs.class_("text-xs text-amber-400 animate-pulse")},
              list{text("Switching mode...")},
            )
          } else {
            noNode
          },
        },
      ),
      // Error display
      switch state.lastError {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "p-2 mb-3 rounded bg-red-900/30 border border-red-500/40 text-xs text-red-400",
            ),
          },
          list{text(err)},
        )
      | None => noNode
      },
      // Mode grid (2x3)
      div(
        list{Attrs.class_("grid grid-cols-2 gap-3 flex-1")},
        state.availableModes
        ->Array.map(info => modeCard(info, info.mode == state.activeMode))
        ->List.fromArray,
      ),
    },
  )
}
