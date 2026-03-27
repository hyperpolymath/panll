// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ExploratoryWorkbench — freeform play session recording and anomaly
/// detection for QA testers and designers.
///
/// Four tabs: Session (current recording with quick-flag button), Anomalies
/// (severity-badged anomaly list), Notes (session notes textarea), and History
/// (previous session summaries).

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tab label lookup for exploratoryTab variants.
let tabLabel = (tab: exploratoryTab): string =>
  switch tab {
  | TabSession => "Session"
  | TabAnomalies => "Anomalies"
  | TabNotes => "Notes"
  | TabHistory => "History"
  }

/// Render the tab bar.
let renderTabs = (active: exploratoryTab): Tea_Vdom.t<msg> => {
  let tabs: array<exploratoryTab> = [TabSession, TabAnomalies, TabNotes, TabHistory]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-cyan-400 border-b-2 border-cyan-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900 cursor-pointer"}`,
          ),
          Events.onClick(ExploratoryWorkbench(SetEwTab(tab))),
        },
        list{text(tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Anomaly severity badge with colour coding.
let severityBadge = (severity: anomalySeverity): Tea_Vdom.t<msg> => {
  let (colour, lbl) = switch severity {
  | AnomalyLow => ("bg-blue-600 text-white", "LOW")
  | AnomalyMedium => ("bg-amber-500 text-white", "MED")
  | AnomalyHigh => ("bg-orange-600 text-white", "HIGH")
  | AnomalyCritical => ("bg-red-600 text-white", "CRIT")
  }
  span(list{Attrs.class_(`px-1.5 py-0.5 text-xs rounded font-mono ${colour}`)}, list{text(lbl)})
}

// =========================================================================
// Tab content views
// =========================================================================

/// Session tab: current recording state, quick-flag button, and session vitals.
let renderSessionTab = (state: exploratoryWorkbenchState): Tea_Vdom.t<msg> => {
  switch state.currentSession {
  | None =>
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No active session. Click Start Recording to begin an exploratory play session.")},
    )
  | Some(session) =>
    div(
      list{Attrs.class_("flex flex-col gap-4 p-4")},
      list{
        // Session vitals
        div(
          list{Attrs.class_("grid grid-cols-3 gap-3")},
          list{
            div(
              list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
              list{
                div(
                  list{Attrs.class_("text-2xl font-light text-cyan-400")},
                  list{text(`${Float.toFixed(session.durationMinutes, ~digits=1)}`)},
                ),
                div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Minutes")}),
              },
            ),
            div(
              list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
              list{
                div(
                  list{Attrs.class_("text-2xl font-light text-gray-300")},
                  list{text(Int.toString(session.playerActions))},
                ),
                div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Actions")}),
              },
            ),
            div(
              list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
              list{
                div(
                  list{Attrs.class_("text-2xl font-light text-amber-400")},
                  list{text(Int.toString(Array.length(session.anomalies)))},
                ),
                div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Anomalies")}),
              },
            ),
          },
        ),
        // Quick-flag button — the "That felt weird" button
        div(
          list{Attrs.class_("flex justify-center")},
          list{
            button(
              list{
                Attrs.class_(
                  "px-6 py-3 bg-amber-600 text-white rounded-lg hover:bg-amber-500 cursor-pointer text-sm font-medium shadow-lg",
                ),
                Events.onClick(ExploratoryWorkbench(QuickFlag("anomaly"))),
              },
              list{text("That felt weird")},
            ),
          },
        ),
        // Anomaly detection toggle
        div(
          list{Attrs.class_("flex items-center gap-3")},
          list{
            button(
              list{
                Attrs.class_(
                  `px-3 py-1.5 text-xs rounded font-medium cursor-pointer ${state.anomalyDetectionEnabled
                      ? "bg-cyan-700 text-white"
                      : "bg-gray-700 text-gray-400"}`,
                ),
                Events.onClick(ExploratoryWorkbench(ToggleAnomalyDetection)),
              },
              list{
                text(state.anomalyDetectionEnabled ? "Auto-Detection: ON" : "Auto-Detection: OFF"),
              },
            ),
            span(
              list{Attrs.class_("text-xs text-gray-500")},
              list{text("Automatically detect gameplay anomalies")},
            ),
          },
        ),
      },
    )
  }
}

/// Anomalies tab: severity-badged list of detected anomalies.
let renderAnomaliesTab = (state: exploratoryWorkbenchState): Tea_Vdom.t<msg> => {
  if Array.length(state.anomalies) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No anomalies flagged yet. Use the quick-flag button or enable auto-detection.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4")},
      list{
        div(
          list{Attrs.class_("text-sm text-gray-400 mb-1")},
          list{text(`${Int.toString(Array.length(state.anomalies))} anomaly(ies) flagged`)},
        ),
        div(
          list{Attrs.class_("flex flex-col gap-1 max-h-96 overflow-y-auto")},
          state.anomalies
          ->Array.map(anomaly => {
            let autoTag = anomaly.autoDetected
              ? span(
                  list{
                    Attrs.class_("px-1 py-0.5 text-xs rounded bg-gray-600 text-gray-300 font-mono"),
                  },
                  list{text("AUTO")},
                )
              : noNode
            div(
              list{Attrs.class_("flex items-center gap-3 px-3 py-2 bg-gray-800 rounded text-sm")},
              list{
                severityBadge(anomaly.severity),
                autoTag,
                span(list{Attrs.class_("text-gray-300 flex-1")}, list{text(anomaly.description)}),
                span(list{Attrs.class_("text-gray-600 text-xs")}, list{text(anomaly.category)}),
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Notes tab: session notes textarea for recording observations.
let renderNotesTab = (state: exploratoryWorkbenchState): Tea_Vdom.t<msg> => {
  let currentNotes = switch state.currentSession {
  | Some(session) => session.notes
  | None => ""
  }
  div(
    list{Attrs.class_("flex flex-col gap-3 p-4")},
    list{
      h3(list{Attrs.class_("text-sm font-medium text-gray-300")}, list{text("Session Notes")}),
      textarea(
        list{
          Attrs.class_(
            "w-full h-48 bg-gray-800 text-gray-200 text-sm rounded p-3 border border-gray-700 focus:border-cyan-600 focus:outline-none resize-y font-mono",
          ),
          Attrs.placeholder("Record observations, hunches, and test ideas..."),
          Attrs.value(currentNotes),
          Events.onInput(text => ExploratoryWorkbench(UpdateNotes(text))),
        },
        list{},
      ),
      div(
        list{Attrs.class_("text-xs text-gray-500")},
        list{text(`${Int.toString(String.length(currentNotes))} character(s)`)},
      ),
    },
  )
}

/// History tab: previous exploratory session summaries.
let renderHistoryTab = (state: exploratoryWorkbenchState): Tea_Vdom.t<msg> => {
  if Array.length(state.sessions) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No previous sessions recorded.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4 max-h-96 overflow-y-auto")},
      state.sessions
      ->Array.map(session => {
        let anomalyCount = Array.length(session.anomalies)
        let borderCls = anomalyCount > 0 ? "border-amber-700" : "border-gray-700"
        div(
          list{Attrs.class_(`bg-gray-800 rounded p-3 border ${borderCls}`)},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between mb-1")},
              list{
                span(
                  list{Attrs.class_("text-sm font-medium text-gray-200")},
                  list{text(session.name)},
                ),
                span(list{Attrs.class_("text-xs text-gray-500 font-mono")}, list{text(session.id)}),
              },
            ),
            div(
              list{Attrs.class_("flex gap-4 text-xs text-gray-400")},
              list{
                text(`${Float.toFixed(session.durationMinutes, ~digits=1)} min`),
                text(`${Int.toString(session.playerActions)} actions`),
                text(`${Int.toString(anomalyCount)} anomalies`),
              },
            ),
            if session.notes !== "" {
              div(
                list{Attrs.class_("text-xs text-gray-500 mt-1 truncate")},
                list{text(session.notes)},
              )
            } else {
              noNode
            },
          },
        )
      })
      ->List.fromArray,
    )
  }
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function dispatching tab content based on active tab.
let view = (state: exploratoryWorkbenchState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabSession => renderSessionTab(state)
  | TabAnomalies => renderAnomaliesTab(state)
  | TabNotes => renderNotesTab(state)
  | TabHistory => renderHistoryTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header with Start/Stop Recording
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold text-cyan-300")},
            list{text("Exploratory Workbench")},
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(ExploratoryWorkbench(StartRecording)),
                },
                list{text("Start Recording")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-red-700 text-white rounded hover:bg-red-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(ExploratoryWorkbench(StopRecording)),
                },
                list{text("Stop Recording")},
              ),
            },
          ),
        },
      ),
      // Recording indicator
      if state.recording {
        div(
          list{
            Attrs.class_("flex items-center gap-2 px-4 py-2 bg-gray-800 border-b border-gray-700"),
          },
          list{
            div(list{Attrs.class_("w-3 h-3 bg-red-500 rounded-full animate-pulse")}, list{}),
            span(list{Attrs.class_("text-sm text-red-300")}, list{text("Recording...")}),
          },
        )
      } else {
        noNode
      },
      // Error display
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_("px-4 py-2 bg-red-900/30 text-red-300 text-sm border-b border-red-800"),
          },
          list{text(err)},
        )
      | None => noNode
      },
      // Tab bar
      renderTabs(state.activeTab),
      // Content
      div(list{Attrs.class_("flex-1 overflow-y-auto")}, list{content}),
    },
  )
}
