// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL NeSy Drift Dashboard Panel — model drift detection and alerting
/// display.
///
/// Layout: Current drift status (large indicator) at top, action
/// recommendation beneath, scrollable alert timeline below. Model status
/// cards show per-model drift state.

open Msg
open NesyDriftModel
open NesyDriftEngine
open Tea.Html

// ============================================================================
// Model Status Card
// ============================================================================

/// A single model status card showing current drift state.
let modelStatusCard = (status: modelDriftStatus): Tea_Vdom.t<msg> => {
  let borderColor = driftBorderColor(status.isDrifting)
  div(
    list{Attrs.class_(`flex flex-col p-3 rounded border ${borderColor} bg-gray-900/50`)},
    list{
      // Model name
      div(
        list{Attrs.class_("font-semibold text-sm text-gray-100 mb-1")},
        list{text(status.modelName)},
      ),
      // Drift indicator
      div(
        list{Attrs.class_("flex items-center gap-2 mb-1")},
        list{
          span(
            list{
              Attrs.class_(
                if status.isDrifting {
                  "w-2 h-2 rounded-full bg-red-500 animate-pulse"
                } else {
                  "w-2 h-2 rounded-full bg-emerald-500"
                },
              ),
            },
            list{},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-400")},
            list{
              text(
                if status.isDrifting {
                  "DRIFTING"
                } else {
                  "STABLE"
                },
              ),
            },
          ),
        },
      ),
      // Last drift kind
      switch status.lastDriftKind {
      | Some(kind) =>
        span(
          list{Attrs.class_("text-xs text-amber-400")},
          list{text(driftKindLabel(kind))},
        )
      | None =>
        span(
          list{Attrs.class_("text-xs text-gray-600")},
          list{text("No drift detected")},
        )
      },
      // Magnitude bar
      div(
        list{Attrs.class_("mt-2 w-full bg-gray-800 rounded-full h-1.5")},
        list{
          div(
            list{
              Attrs.class_(
                `h-1.5 rounded-full ${if status.lastMagnitude >= 0.7 {
                    "bg-red-500"
                  } else if status.lastMagnitude >= 0.4 {
                    "bg-amber-500"
                  } else {
                    "bg-emerald-500"
                  }}`,
              ),
              Attrs.style(
                "width",
                Float.toFixedWithPrecision(status.lastMagnitude *. 100.0, ~digits=0) ++ "%",
              ),
            },
            list{},
          ),
        },
      ),
      // Alert count
      span(
        list{Attrs.class_("text-xs text-gray-500 mt-1")},
        list{text(`${Int.toString(status.alertCount)} alerts`)},
      ),
    },
  )
}

// ============================================================================
// Alert Row
// ============================================================================

/// A single alert row in the timeline.
let alertRow = (alert: driftAlert): Tea_Vdom.t<msg> => {
  let urgencyColor = alertColor(alert.urgency)
  div(
    list{Attrs.class_("flex items-start gap-3 px-3 py-3 border-b border-gray-800 hover:bg-gray-800/30")},
    list{
      // Urgency badge
      span(
        list{Attrs.class_(`px-2 py-0.5 text-xs rounded font-mono shrink-0 ${urgencyColor}`)},
        list{text(urgencyLabel(alert.urgency))},
      ),
      // Alert content
      div(
        list{Attrs.class_("flex-1 min-w-0")},
        list{
          // Model name + drift kind
          div(
            list{Attrs.class_("flex items-center gap-2 mb-1")},
            list{
              span(
                list{Attrs.class_("text-sm font-semibold text-gray-100")},
                list{text(alert.modelName)},
              ),
              span(
                list{Attrs.class_(`text-xs ${severityTextColor(alert.severity)}`)},
                list{text(driftKindLabel(alert.kind))},
              ),
            },
          ),
          // Description
          p(
            list{Attrs.class_("text-xs text-gray-400 mb-1")},
            list{text(alert.description)},
          ),
          // Action recommendation
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("Recommended:")},
              ),
              span(
                list{Attrs.class_("text-xs text-cyan-400 font-mono")},
                list{text(actionLabel(alert.recommendedAction))},
              ),
            },
          ),
        },
      ),
      // Timestamp
      span(
        list{Attrs.class_("text-xs text-gray-500 font-mono shrink-0")},
        list{text(alert.timestamp)},
      ),
    },
  )
}

// ============================================================================
// Urgency Filter
// ============================================================================

/// Urgency filter buttons.
let urgencyFilter = (currentFilter: option<driftUrgency>): Tea_Vdom.t<msg> => {
  let filterBtn = (label: string, filterValue: option<driftUrgency>) => {
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
      filterBtn("Immediate", Some(Immediate)),
      filterBtn("Soon", Some(Soon)),
      filterBtn("Scheduled", Some(Scheduled)),
      filterBtn("FYI", Some(FYI)),
    },
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Top-level view for the NeSy Drift Dashboard panel.
let view = (state: nesyDriftState): Tea_Vdom.t<msg> => {
  let filteredAlerts = filterByUrgency(state.alerts, state.urgencyFilter)
  div(
    list{Attrs.class_("flex flex-col h-full p-3 bg-gray-950 text-gray-100")},
    list{
      // Panel header
      div(
        list{Attrs.class_("flex items-center justify-between mb-3")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold")},
            list{text("NeSy Drift Dashboard")},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{
              text(
                `${Int.toString(Array.length(state.modelStatuses))} models monitored`,
              ),
            },
          ),
        },
      ),
      // Model status cards (horizontal scroll)
      div(
        list{Attrs.class_("flex gap-3 overflow-x-auto pb-3 mb-3")},
        state.modelStatuses->Array.map(modelStatusCard)->Array.toList,
      ),
      // Urgency filter
      urgencyFilter(state.urgencyFilter),
      // Alert timeline (scrollable)
      div(
        list{Attrs.class_("flex-1 overflow-y-auto border border-gray-800 rounded")},
        list{
          div(
            list{Attrs.class_("divide-y divide-gray-800")},
            filteredAlerts->Array.map(alertRow)->Array.toList,
          ),
        },
      ),
    },
  )
}
