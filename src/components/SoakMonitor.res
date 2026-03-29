// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL SoakMonitor — long-running session tracking, memory leak detection,
/// and trend analysis for IDApTIK extended play sessions.
///
/// Four tabs: Live Monitor (current session vitals), Trends (memory trend
/// display), Leak Detection (suspects table with growth rate and confidence),
/// and History (previous soak session summaries).

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tab label lookup for soakTab variants.
let tabLabel = (tab: soakTab): string =>
  switch tab {
  | TabLiveMonitor => "Live Monitor"
  | TabTrends => "Trends"
  | TabLeakDetection => "Leak Detection"
  | TabHistory => "History"
  }

/// Render the tab bar.
let renderTabs = (active: soakTab): Tea_Vdom.t<msg> => {
  let tabs: array<soakTab> = [TabLiveMonitor, TabTrends, TabLeakDetection, TabHistory]
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
          Events.onClick(SoakMonitor(SetSmTab(tab))),
        },
        list{text(tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Format bytes into human-readable string.
let formatBytes = (bytes: int): string => {
  let b = Int.toFloat(bytes)
  if b >= 1073741824.0 {
    `${Float.toFixed(b /. 1073741824.0, ~digits=2)} GB`
  } else if b >= 1048576.0 {
    `${Float.toFixed(b /. 1048576.0, ~digits=1)} MB`
  } else if b >= 1024.0 {
    `${Float.toFixed(b /. 1024.0, ~digits=0)} KB`
  } else {
    `${Int.toString(bytes)} B`
  }
}

/// Session status badge.
let sessionStatusBadge = (status: soakSessionStatus): Tea_Vdom.t<msg> =>
  switch status {
  | SoakRunning =>
    span(
      list{
        Attrs.class_(
          "px-1.5 py-0.5 text-xs rounded bg-emerald-600 text-white font-mono animate-pulse",
        ),
      },
      list{text("RUNNING")},
    )
  | SoakCompleted =>
    span(
      list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-blue-600 text-white font-mono")},
      list{text("COMPLETED")},
    )
  | SoakAborted(_) =>
    span(
      list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-red-600 text-white font-mono")},
      list{text("ABORTED")},
    )
  }

/// Confidence level colour for leak suspects.
let confidenceColour = (confidence: float): string =>
  if confidence >= 0.8 {
    "text-red-400"
  } else if confidence >= 0.5 {
    "text-amber-400"
  } else {
    "text-gray-400"
  }

// =========================================================================
// Tab content views
// =========================================================================

/// Live Monitor tab: current session vitals and real-time memory display.
let renderLiveMonitorTab = (state: soakMonitorState): Tea_Vdom.t<msg> => {
  switch state.currentSession {
  | None =>
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No active soak session. Click Start Monitor to begin tracking.")},
    )
  | Some(session) => {
      let latestMem = state.trendData->Array.get(Array.length(state.trendData) - 1)
      div(
        list{Attrs.class_("flex flex-col gap-4 p-4")},
        list{
          // Session info
          div(
            list{Attrs.class_("flex items-center justify-between")},
            list{
              div(
                list{Attrs.class_("flex items-center gap-2")},
                list{
                  sessionStatusBadge(session.status),
                  span(
                    list{Attrs.class_("text-sm text-gray-300")},
                    list{text(`Session: ${session.id}`)},
                  ),
                },
              ),
              span(
                list{Attrs.class_("text-sm text-gray-400")},
                list{text(`${Float.toFixed(session.durationMinutes, ~digits=1)} min`)},
              ),
            },
          ),
          // Key metrics
          div(
            list{Attrs.class_("grid grid-cols-3 gap-3")},
            list{
              div(
                list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
                list{
                  div(
                    list{Attrs.class_("text-2xl font-light text-cyan-400")},
                    list{text(formatBytes(session.peakMemoryBytes))},
                  ),
                  div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Peak Memory")}),
                },
              ),
              div(
                list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
                list{
                  div(
                    list{Attrs.class_("text-2xl font-light text-gray-300")},
                    list{text(`${Float.toFixed(session.gcFrequencyPerMinute, ~digits=1)}/min`)},
                  ),
                  div(list{Attrs.class_("text-xs text-gray-500")}, list{text("GC Frequency")}),
                },
              ),
              div(
                list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
                list{
                  div(
                    list{Attrs.class_("text-2xl font-light text-amber-400")},
                    list{text(Int.toString(Array.length(session.leakSuspects)))},
                  ),
                  div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Leak Suspects")}),
                },
              ),
            },
          ),
          // Current heap usage from latest trend point
          switch latestMem {
          | Some(point) => {
              let usedPct =
                Int.toFloat(point.heapUsedBytes) /.
                Int.toFloat(max(1, point.heapTotalBytes)) *. 100.0
              let widthPct = Int.toString(Int.fromFloat(usedPct))
              let barColour = if usedPct > 85.0 {
                "bg-red-500"
              } else if usedPct > 60.0 {
                "bg-amber-500"
              } else {
                "bg-emerald-500"
              }
              div(
                list{Attrs.class_("bg-gray-800 rounded p-3")},
                list{
                  div(
                    list{Attrs.class_("flex justify-between text-xs text-gray-400 mb-1")},
                    list{
                      text("Heap"),
                      text(
                        `${formatBytes(point.heapUsedBytes)} / ${formatBytes(
                            point.heapTotalBytes,
                          )}`,
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("w-full h-2 bg-gray-700 rounded overflow-hidden")},
                    list{
                      div(
                        list{
                          Attrs.class_(
                            `h-full ${barColour} transition-all duration-300 w-[${widthPct}%]`,
                          ),
                        },
                        list{},
                      ),
                    },
                  ),
                },
              )
            }
          | None => noNode
          },
        },
      )
    }
  }
}

/// Trends tab: memory trend data points display.
let renderTrendsTab = (state: soakMonitorState): Tea_Vdom.t<msg> => {
  let pointCount = Array.length(state.trendData)
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4")},
    list{
      div(
        list{Attrs.class_("bg-gray-800 rounded p-4 h-32 flex items-center justify-center")},
        list{
          span(
            list{Attrs.class_("text-gray-600 text-sm")},
            list{text(`Memory trend chart (${Int.toString(pointCount)} data points)`)},
          ),
        },
      ),
      // Recent trend data rows
      div(
        list{Attrs.class_("flex flex-col gap-1 max-h-64 overflow-y-auto")},
        state.trendData
        ->Array.sliceToEnd(~start=max(0, pointCount - 15))
        ->Array.map(point => {
          div(
            list{
              Attrs.class_("flex justify-between text-xs font-mono px-2 py-1 bg-gray-800 rounded"),
            },
            list{
              span(
                list{Attrs.class_("text-gray-500")},
                list{text(formatBytes(point.heapUsedBytes))},
              ),
              span(
                list{Attrs.class_("text-gray-600")},
                list{text(`GC: ${Int.toString(point.gcCount)}`)},
              ),
              span(
                list{Attrs.class_("text-gray-600")},
                list{text(`Pause: ${Float.toFixed(point.gcPauseMs, ~digits=1)}ms`)},
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Leak Detection tab: suspects table with growth rate and confidence.
let renderLeakDetectionTab = (state: soakMonitorState): Tea_Vdom.t<msg> => {
  if Array.length(state.leakSuspects) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No leak suspects detected. Memory allocation patterns appear healthy.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4")},
      list{
        div(
          list{Attrs.class_("text-sm text-gray-400 mb-1")},
          list{text(`${Int.toString(Array.length(state.leakSuspects))} suspect(s)`)},
        ),
        div(
          list{Attrs.class_("flex flex-col gap-1 max-h-96 overflow-y-auto")},
          state.leakSuspects
          ->Array.map(suspect => {
            let confColour = confidenceColour(suspect.confidence)
            div(
              list{
                Attrs.class_(
                  "flex items-center justify-between px-3 py-2 bg-gray-800 rounded text-sm",
                ),
              },
              list{
                span(
                  list{Attrs.class_("text-gray-300 flex-1 font-mono text-xs")},
                  list{text(suspect.source)},
                ),
                span(
                  list{Attrs.class_("text-gray-400 text-xs")},
                  list{text(`+${formatBytes(suspect.growthRatePerHour)}/hr`)},
                ),
                span(
                  list{Attrs.class_(`text-xs font-mono ${confColour}`)},
                  list{text(`${Float.toFixed(suspect.confidence *. 100.0, ~digits=0)}%`)},
                ),
                span(
                  list{Attrs.class_("text-gray-600 text-xs")},
                  list{text(`${Int.toString(suspect.samples)} samples`)},
                ),
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// History tab: previous soak session summaries.
let renderHistoryTab = (state: soakMonitorState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4 max-h-96 overflow-y-auto")},
    state.sessions
    ->Array.map(session => {
      let leakCount = Array.length(session.leakSuspects)
      let borderCls = leakCount > 0 ? "border-amber-700" : "border-gray-700"
      div(
        list{Attrs.class_(`bg-gray-800 rounded p-3 border ${borderCls}`)},
        list{
          div(
            list{Attrs.class_("flex items-center justify-between mb-1")},
            list{
              span(list{Attrs.class_("text-sm text-gray-300 font-mono")}, list{text(session.id)}),
              sessionStatusBadge(session.status),
            },
          ),
          div(
            list{Attrs.class_("flex gap-4 text-xs text-gray-400")},
            list{
              text(`${Float.toFixed(session.durationMinutes, ~digits=1)} min`),
              text(`Peak: ${formatBytes(session.peakMemoryBytes)}`),
              text(`GC: ${Float.toFixed(session.gcFrequencyPerMinute, ~digits=1)}/min`),
              text(`${Int.toString(leakCount)} leak suspect(s)`),
            },
          ),
        },
      )
    })
    ->List.fromArray,
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function dispatching tab content based on active tab.
let view = (state: soakMonitorState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabLiveMonitor => renderLiveMonitorTab(state)
  | TabTrends => renderTrendsTab(state)
  | TabLeakDetection => renderLeakDetectionTab(state)
  | TabHistory => renderHistoryTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header with Start/Stop
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(list{Attrs.class_("text-lg font-semibold text-cyan-300")}, list{text("Soak Monitor")}),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(SoakMonitor(StartMonitor)),
                  KeyboardNav.onActivate(SoakMonitor(StartMonitor)),
                },
                list{text("Start Monitor")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-red-700 text-white rounded hover:bg-red-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(SoakMonitor(StopMonitor)),
                  KeyboardNav.onActivate(SoakMonitor(StopMonitor)),
                },
                list{text("Stop Monitor")},
              ),
            },
          ),
        },
      ),
      // Monitoring indicator
      if state.monitoring {
        div(
          list{
            Attrs.class_("flex items-center gap-2 px-4 py-2 bg-gray-800 border-b border-gray-700"),
          },
          list{
            div(list{Attrs.class_("w-3 h-3 bg-emerald-400 rounded-full animate-pulse")}, list{}),
            span(
              list{Attrs.class_("text-sm text-emerald-300")},
              list{text("Soak monitoring active...")},
            ),
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
