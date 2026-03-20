// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Harmonization Monitor Panel — live neural-symbolic verdict
/// fusion display.
///
/// Layout: Stats bar at top (3 verdict counters with colours), scrollable
/// entry list below. Each entry shows neural -> symbolic -> verdict with
/// colour coding. Filter dropdown for verdict type selection.

open Msg
open NesyHarmonizeModel
open NesyHarmonizeEngine
open Tea.Html

// ============================================================================
// Stats Bar
// ============================================================================

/// A single stat counter pill with a coloured background.
let statPill = (label: string, count: int, colorClass: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_(`flex flex-col items-center px-4 py-2 rounded ${colorClass}`)},
    list{
      span(
        list{Attrs.class_("text-2xl font-bold font-mono")},
        list{text(Int.toString(count))},
      ),
      span(
        list{Attrs.class_("text-xs uppercase tracking-wide opacity-80")},
        list{text(label)},
      ),
    },
  )
}

/// Stats bar showing 3 verdict counters and the symbolic win rate.
let statsBar = (stats: harmonizeStats): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex gap-3 p-3 bg-gray-900/50 rounded-lg mb-3")},
    list{
      statPill("Certified Safe", stats.certifiedSafe, "bg-emerald-600/80 text-white"),
      statPill("Requires Review", stats.requiresReview, "bg-amber-500/80 text-white"),
      statPill("Critical Unsafe", stats.criticalUnsafe, "bg-red-600/80 text-white"),
      div(
        list{Attrs.class_("flex flex-col items-center px-4 py-2 rounded bg-gray-700/50 text-gray-200")},
        list{
          span(
            list{Attrs.class_("text-2xl font-bold font-mono")},
            list{text(Float.toFixed(stats.symbolicWinRate *. 100.0, ~digits=1) ++ "%")},
          ),
          span(
            list{Attrs.class_("text-xs uppercase tracking-wide opacity-80")},
            list{text("Symbolic Win Rate")},
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Verdict Arrow Display
// ============================================================================

/// Arrow separator between verdict stages.
let arrow: Tea_Vdom.t<msg> = {
  span(
    list{Attrs.class_("text-gray-500 mx-1")},
    list{text("->")},
  )
}

/// Verdict badge with colour coding.
let verdictBadge = (label: string, colorClass: string): Tea_Vdom.t<msg> => {
  span(
    list{Attrs.class_(`px-2 py-0.5 text-xs rounded font-mono ${colorClass}`)},
    list{text(label)},
  )
}

// ============================================================================
// Entry Row
// ============================================================================

/// A single harmonization entry row showing the verdict pipeline.
let entryRow = (entry: harmonizationEntry): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center gap-2 px-3 py-2 border-b border-gray-800 hover:bg-gray-800/30")},
    list{
      // Timestamp
      span(
        list{Attrs.class_("text-xs text-gray-500 font-mono w-40 shrink-0")},
        list{text(entry.timestamp)},
      ),
      // Source
      span(
        list{Attrs.class_("text-xs text-gray-400 w-24 shrink-0 truncate")},
        list{text(entry.source)},
      ),
      // Neural verdict
      verdictBadge(neuralLabel(entry.neural), neuralVerdictColor(entry.neural)),
      arrow,
      // Symbolic verdict
      verdictBadge(symbolicLabel(entry.symbolic), symbolicVerdictColor(entry.symbolic)),
      arrow,
      // Harmonized verdict (main result)
      verdictBadge(verdictLabel(entry.verdict), verdictColor(entry.verdict)),
      // Confidence indicator
      span(
        list{Attrs.class_(`text-xs ml-2 ${confidenceColor(entry.confidence)}`)},
        list{text(confidenceLabel(entry.confidence))},
      ),
      // Symbolic wins indicator
      if entry.symbolicWins {
        span(
          list{Attrs.class_("text-xs text-blue-400 ml-auto")},
          list{text("[S wins]")},
        )
      } else {
        noNode
      },
    },
  )
}

// ============================================================================
// Filter Controls
// ============================================================================

/// Filter dropdown for selecting verdict type.
let filterControls = (currentFilter: option<harmonizedVerdict>): Tea_Vdom.t<msg> => {
  let filterBtn = (label: string, filterValue: option<harmonizedVerdict>) => {
    let isActive = currentFilter == filterValue
    let baseClass = "px-3 py-1 text-xs rounded cursor-pointer"
    let activeClass = if isActive {
      "bg-emerald-600 text-white"
    } else {
      "bg-gray-700 text-gray-300 hover:bg-gray-600"
    }
    button(
      list{Attrs.class_(`${baseClass} ${activeClass}`)},
      list{text(label)},
    )
  }
  div(
    list{Attrs.class_("flex gap-2 mb-3")},
    list{
      filterBtn("All", None),
      filterBtn("Certified Safe", Some(CertifiedSafe)),
      filterBtn("Requires Review", Some(RequiresReview)),
      filterBtn("Critical Unsafe", Some(CriticalUnsafe)),
    },
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Top-level view for the NeSy Harmonization Monitor panel.
let view = (state: nesyHarmonizeState): Tea_Vdom.t<msg> => {
  let filtered = filterEntries(state.entries, state.filter)
  div(
    list{Attrs.class_("flex flex-col h-full p-3 bg-gray-950 text-gray-100")},
    list{
      // Panel header
      div(
        list{Attrs.class_("flex items-center justify-between mb-3")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold")},
            list{text("NeSy Harmonization Monitor")},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text(`${Int.toString(state.stats.totalCount)} entries`)},
          ),
        },
      ),
      // Stats bar
      statsBar(state.stats),
      // Filter controls
      filterControls(state.filter),
      // Entry list (scrollable)
      div(
        list{Attrs.class_("flex-1 overflow-y-auto border border-gray-800 rounded")},
        list{
          div(
            list{Attrs.class_("divide-y divide-gray-800")},
            filtered->Array.map(entryRow)->List.fromArray,
          ),
        },
      ),
    },
  )
}
