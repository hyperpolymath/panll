// SPDX-License-Identifier: MPL-2.0

/// PanLL PerformanceProfiler — frame budget monitoring, GC pressure tracking,
/// memory snapshots, and performance alert display for IDApTIK game profiling.
///
/// Five tabs: Frame Budget (FPS counter + frame time chart placeholder),
/// Memory (heap usage bars), GC Pressure (event log), Alerts (severity-coloured
/// list), and Flamegraph (placeholder for future integration).

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tab label lookup for performanceTab variants.
let tabLabel = (tab: performanceTab): string =>
  switch tab {
  | TabFrameBudget => "Frame Budget"
  | TabMemory => "Memory"
  | TabGcPressure => "GC Pressure"
  | TabAlerts => "Alerts"
  | TabFlamegraph => "Flamegraph"
  }

/// Render the tab bar.
let renderTabs = (active: performanceTab): Tea_Vdom.t<msg> => {
  let tabs: array<performanceTab> = [
    TabFrameBudget,
    TabMemory,
    TabGcPressure,
    TabAlerts,
    TabFlamegraph,
  ]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-3 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-cyan-400 border-b-2 border-cyan-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900 cursor-pointer"}`,
          ),
          Events.onClick(PerformanceProfiler(SetPpTab(tab))),
        },
        list{text(tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Alert severity colour and label.
let severityStyle = (sev: perfAlertSeverity): (string, string) =>
  switch sev {
  | PerfInfo => ("bg-blue-600 text-white", "INFO")
  | PerfWarning => ("bg-amber-500 text-white", "WARN")
  | PerfCritical => ("bg-red-600 text-white", "CRIT")
  }

/// Format bytes into a human-readable string (KB/MB/GB).
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

// =========================================================================
// Tab content views
// =========================================================================

/// Frame Budget tab: FPS counter, budget display, and recent frame samples.
let renderFrameBudgetTab = (state: performanceProfilerState): Tea_Vdom.t<msg> => {
  let sampleCount = Array.length(state.frameSamples)
  let avgFps = if sampleCount > 0 {
    let totalMs = state.frameSamples->Array.reduce(0.0, (acc, s) => acc +. s.totalMs)
    let avg = totalMs /. Int.toFloat(sampleCount)
    if avg > 0.0 {
      1000.0 /. avg
    } else {
      0.0
    }
  } else {
    0.0
  }
  let fpsColour = if avgFps >= state.targetFps {
    "text-emerald-400"
  } else if avgFps >= state.targetFps *. 0.75 {
    "text-amber-400"
  } else {
    "text-red-400"
  }

  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      // FPS + budget row
      div(
        list{Attrs.class_("grid grid-cols-3 gap-3")},
        list{
          div(
            list{Attrs.class_("p-4 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_(`text-3xl font-light ${fpsColour}`)},
                list{text(Float.toFixed(avgFps, ~digits=1))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("AVG FPS")}),
            },
          ),
          div(
            list{Attrs.class_("p-4 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-3xl font-light text-cyan-400")},
                list{text(Float.toFixed(state.targetFps, ~digits=0))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("TARGET FPS")}),
            },
          ),
          div(
            list{Attrs.class_("p-4 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-3xl font-light text-gray-300")},
                list{text(`${Float.toFixed(state.frameBudgetMs, ~digits=1)}ms`)},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("BUDGET")}),
            },
          ),
        },
      ),
      // Frame time chart placeholder
      div(
        list{Attrs.class_("bg-gray-800 rounded p-4 h-32 flex items-center justify-center")},
        list{
          span(
            list{Attrs.class_("text-gray-600 text-sm")},
            list{text(`Frame time chart (${Int.toString(sampleCount)} samples)`)},
          ),
        },
      ),
      // Recent samples list
      div(
        list{Attrs.class_("flex flex-col gap-1 max-h-40 overflow-y-auto")},
        state.frameSamples
        ->Array.sliceToEnd(~start=max(0, sampleCount - 10))
        ->Array.map(s => {
          let overBudget = s.totalMs > state.frameBudgetMs
          let cls = overBudget ? "text-red-400" : "text-gray-400"
          div(
            list{Attrs.class_("flex justify-between text-xs font-mono px-2 py-1")},
            list{
              span(
                list{Attrs.class_("text-gray-500")},
                list{text(`#${Int.toString(s.frameNumber)}`)},
              ),
              span(list{Attrs.class_(cls)}, list{text(`${Float.toFixed(s.totalMs, ~digits=2)}ms`)}),
              span(
                list{Attrs.class_("text-gray-600")},
                list{
                  text(
                    `R:${Float.toFixed(s.renderMs, ~digits=1)} U:${Float.toFixed(
                        s.updateMs,
                        ~digits=1,
                      )} GC:${Float.toFixed(s.gcMs, ~digits=1)}`,
                  ),
                },
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Memory tab: heap usage display with usage bars.
let renderMemoryTab = (state: performanceProfilerState): Tea_Vdom.t<msg> => {
  let latest = state.memorySnapshots->Array.get(Array.length(state.memorySnapshots) - 1)
  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      switch latest {
      | Some(snap) => {
          let usedPct =
            Int.toFloat(snap.heapUsedBytes) /. Int.toFloat(max(1, snap.heapTotalBytes)) *. 100.0
          let usedWidth = Int.toString(Int.fromFloat(usedPct))
          let barColour = if usedPct > 90.0 {
            "bg-red-500"
          } else if usedPct > 70.0 {
            "bg-amber-500"
          } else {
            "bg-emerald-500"
          }
          div(
            list{Attrs.class_("bg-gray-800 rounded p-4")},
            list{
              div(
                list{Attrs.class_("flex justify-between text-sm mb-2")},
                list{
                  span(list{Attrs.class_("text-gray-300")}, list{text("Heap Usage")}),
                  span(
                    list{Attrs.class_("text-gray-400 font-mono")},
                    list{
                      text(
                        `${formatBytes(snap.heapUsedBytes)} / ${formatBytes(snap.heapTotalBytes)}`,
                      ),
                    },
                  ),
                },
              ),
              div(
                list{Attrs.class_("w-full h-3 bg-gray-700 rounded overflow-hidden")},
                list{
                  div(
                    list{
                      Attrs.class_(
                        `h-full ${barColour} transition-all duration-300 w-[${usedWidth}%]`,
                      ),
                    },
                    list{},
                  ),
                },
              ),
              div(
                list{Attrs.class_("grid grid-cols-2 gap-3 mt-3")},
                list{
                  div(
                    list{Attrs.class_("text-center")},
                    list{
                      div(
                        list{Attrs.class_("text-lg font-light text-gray-300")},
                        list{text(formatBytes(snap.externalBytes))},
                      ),
                      div(list{Attrs.class_("text-xs text-gray-500")}, list{text("External")}),
                    },
                  ),
                  div(
                    list{Attrs.class_("text-center")},
                    list{
                      div(
                        list{Attrs.class_("text-lg font-light text-gray-300")},
                        list{text(formatBytes(snap.arrayBufferBytes))},
                      ),
                      div(list{Attrs.class_("text-xs text-gray-500")}, list{text("ArrayBuffers")}),
                    },
                  ),
                },
              ),
            },
          )
        }
      | None =>
        div(
          list{Attrs.class_("text-gray-500 text-sm italic p-4")},
          list{text("No memory snapshots yet. Start profiling to collect data.")},
        )
      },
    },
  )
}

/// GC Pressure tab: event log of garbage collection pauses.
let renderGcPressureTab = (state: performanceProfilerState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4")},
    list{
      div(
        list{Attrs.class_("text-sm text-gray-400 mb-1")},
        list{text(`${Int.toString(Array.length(state.gcEvents))} GC event(s) recorded`)},
      ),
      div(
        list{Attrs.class_("flex flex-col gap-1 max-h-96 overflow-y-auto")},
        state.gcEvents
        ->Array.map(evt => {
          let pauseColour = if evt.pauseMs > 16.0 {
            "text-red-400"
          } else if evt.pauseMs > 5.0 {
            "text-amber-400"
          } else {
            "text-gray-400"
          }
          div(
            list{
              Attrs.class_(
                "flex items-center justify-between px-3 py-2 bg-gray-800 rounded text-xs font-mono",
              ),
            },
            list{
              span(list{Attrs.class_("text-gray-500")}, list{text(evt.kind)}),
              span(
                list{Attrs.class_(pauseColour)},
                list{text(`${Float.toFixed(evt.pauseMs, ~digits=2)}ms`)},
              ),
              span(
                list{Attrs.class_("text-gray-500")},
                list{text(`-${formatBytes(evt.reclaimedBytes)}`)},
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Alerts tab: severity-coloured list of performance alerts.
let renderAlertsTab = (state: performanceProfilerState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4")},
    list{
      div(
        list{Attrs.class_("text-sm text-gray-400 mb-1")},
        list{text(`${Int.toString(Array.length(state.alerts))} alert(s)`)},
      ),
      div(
        list{Attrs.class_("flex flex-col gap-1 max-h-96 overflow-y-auto")},
        state.alerts
        ->Array.map(alert => {
          let (sevCls, sevLbl) = severityStyle(alert.severity)
          div(
            list{Attrs.class_("flex items-center gap-3 px-3 py-2 bg-gray-800 rounded text-sm")},
            list{
              span(
                list{Attrs.class_(`px-1.5 py-0.5 text-xs rounded font-mono ${sevCls}`)},
                list{text(sevLbl)},
              ),
              span(list{Attrs.class_("text-gray-300 flex-1")}, list{text(alert.message)}),
              span(
                list{Attrs.class_("text-gray-500 text-xs font-mono")},
                list{text(`${alert.metric}: ${Float.toFixed(alert.value, ~digits=1)}`)},
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Flamegraph tab: placeholder for future integration.
let renderFlamegraphTab = (_state: performanceProfilerState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4 flex items-center justify-center h-64")},
    list{
      span(
        list{Attrs.class_("text-gray-600 text-sm")},
        list{text("Flamegraph integration pending (Phase 2)")},
      ),
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function dispatching tab content based on active tab.
let view = (state: performanceProfilerState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabFrameBudget => renderFrameBudgetTab(state)
  | TabMemory => renderMemoryTab(state)
  | TabGcPressure => renderGcPressureTab(state)
  | TabAlerts => renderAlertsTab(state)
  | TabFlamegraph => renderFlamegraphTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header with Start/Stop Profiling
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold text-cyan-300")},
            list{text("Performance Profiler")},
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(PerformanceProfiler(StartProfiling)),
                  KeyboardNav.onActivate(PerformanceProfiler(StartProfiling)),
                },
                list{text("Start Profiling")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-red-700 text-white rounded hover:bg-red-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(PerformanceProfiler(StopProfiling)),
                  KeyboardNav.onActivate(PerformanceProfiler(StopProfiling)),
                },
                list{text("Stop Profiling")},
              ),
            },
          ),
        },
      ),
      // Profiling indicator
      if state.profiling {
        div(
          list{
            Attrs.class_("flex items-center gap-2 px-4 py-2 bg-gray-800 border-b border-gray-700"),
          },
          list{
            div(list{Attrs.class_("w-3 h-3 bg-red-400 rounded-full animate-pulse")}, list{}),
            span(list{Attrs.class_("text-sm text-red-300")}, list{text("Profiling active...")}),
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
