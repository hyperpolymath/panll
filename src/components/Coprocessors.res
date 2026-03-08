// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Coprocessors Component — view for monitoring IDApTIK's
/// coprocessor backends. Dashboard, call log, heatmap, and settings.

open Model
open Msg
open Tea.Html

/// Render a category tab button.
let renderTab = (
  label: string,
  cat: coprocessorsCategory,
  active: coprocessorsCategory,
): Tea_Vdom.t<msg> => {
  let isActive = cat === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{Attrs.class_(cls), Events.onClick(Coprocessors(SetCoprocCategory(cat)))},
    list{text(label)},
  )
}

/// Render a single backend metrics card.
let renderMetricsCard = (metrics: coprocMetrics): Tea_Vdom.t<msg> => {
  let colourCls = CoprocessorsEngine.backendColour(metrics.backend)
  let healthCls = CoprocessorsEngine.healthColour(metrics.health)
  div(
    list{Attrs.class_("p-3 bg-gray-800 rounded border border-gray-700")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          span(
            list{Attrs.class_(`text-sm font-medium ${colourCls}`)},
            list{text(CoprocessorsEngine.backendLabel(metrics.backend))},
          ),
          span(
            list{Attrs.class_(`text-xs ${healthCls}`)},
            list{text(CoprocessorsEngine.healthLabel(metrics.health))},
          ),
        },
      ),
      div(
        list{Attrs.class_("grid grid-cols-2 gap-2 text-xs")},
        list{
          div(
            list{},
            list{
              div(list{Attrs.class_("text-gray-500")}, list{text("Total Calls")}),
              div(list{Attrs.class_("text-gray-200 font-mono")}, list{text(Int.toString(metrics.totalCalls))}),
            },
          ),
          div(
            list{},
            list{
              div(list{Attrs.class_("text-gray-500")}, list{text("Avg Duration")}),
              div(
                list{Attrs.class_("text-gray-200 font-mono")},
                list{text(`${Float.toString(metrics.avgDurationMs)}ms`)},
              ),
            },
          ),
          div(
            list{},
            list{
              div(list{Attrs.class_("text-gray-500")}, list{text("Max Duration")}),
              div(
                list{Attrs.class_("text-gray-200 font-mono")},
                list{text(`${Float.toString(metrics.maxDurationMs)}ms`)},
              ),
            },
          ),
          div(
            list{},
            list{
              div(list{Attrs.class_("text-gray-500")}, list{text("Error Rate")}),
              div(
                list{
                  Attrs.class_(
                    if metrics.errorRate > 0.1 {
                      "text-red-400 font-mono"
                    } else {
                      "text-gray-200 font-mono"
                    },
                  ),
                },
                list{text(`${Float.toString(metrics.errorRate *. 100.0)}%`)},
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Render a discovered compute device card.
let renderDeviceCard = (device: computeDevice): Tea_Vdom.t<msg> => {
  let engineLabel = CoprocessorsEngine.engineLabel(device.engineId)
  let statusCls = if device.available { "text-emerald-400" } else { "text-gray-500" }
  div(
    list{Attrs.class_("p-3 bg-gray-800 rounded border border-gray-700")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          span(list{Attrs.class_("text-sm font-medium text-gray-200")}, list{text(device.deviceName)}),
          span(list{Attrs.class_(`text-xs ${statusCls}`)}, list{text(if device.available { "Online" } else { "Offline" })}),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-500")},
        list{text(`${engineLabel} / ${device.deviceType}`)},
      ),
    },
  )
}

/// Render the last compute result.
let renderComputeResult = (result: computeQueryResult): Tea_Vdom.t<msg> => {
  let engineLabel = CoprocessorsEngine.engineLabel(result.engineId)
  let borderCls = if result.success { "border-emerald-700" } else { "border-red-700" }
  div(
    list{Attrs.class_(`p-3 bg-gray-800 rounded border ${borderCls}`)},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          span(list{Attrs.class_("text-sm font-medium text-gray-200")}, list{text(`${engineLabel}: ${result.operation}`)}),
          span(
            list{Attrs.class_("text-xs text-gray-400 font-mono")},
            list{text(`${Float.toString(result.durationMs)}ms`)},
          ),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-400 font-mono whitespace-pre-wrap max-h-32 overflow-y-auto")},
        list{text(result.result)},
      ),
    },
  )
}

/// Render the dashboard view.
let renderDashboard = (state: coprocessorsState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Control plane: discovered devices
      div(
        list{Attrs.class_("space-y-2")},
        list{
          div(
            list{Attrs.class_("flex items-center justify-between")},
            list{
              span(list{Attrs.class_("text-xs text-gray-400 font-medium")}, list{text("COMPUTE ENGINES")}),
              button(
                list{
                  Attrs.class_("px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"),
                  Events.onClick(Coprocessors(DiscoverDevices)),
                },
                list{text("Discover")},
              ),
            },
          ),
          if Array.length(state.discoveredDevices) === 0 {
            div(
              list{Attrs.class_("text-center text-gray-500 text-xs py-4")},
              list{text("No compute engines discovered. Click Discover to probe Axiom.jl and BoJ.")},
            )
          } else {
            div(
              list{Attrs.class_("grid grid-cols-2 lg:grid-cols-3 gap-2")},
              state.discoveredDevices->Array.map(d => renderDeviceCard(d))->List.fromArray,
            )
          },
        },
      ),
      // Last compute result
      switch state.lastComputeResult {
      | Some(result) =>
        div(
          list{Attrs.class_("space-y-2")},
          list{
            div(list{Attrs.class_("text-xs text-gray-400 font-medium")}, list{text("LAST COMPUTE RESULT")}),
            renderComputeResult(result),
          },
        )
      | None => noNode
      },
      // Data plane: backend metrics (existing)
      div(
        list{Attrs.class_("space-y-2")},
        list{
          div(list{Attrs.class_("text-xs text-gray-400 font-medium")}, list{text("BACKEND METRICS")}),
          if Array.length(state.metrics) === 0 {
            div(
              list{Attrs.class_("text-center text-gray-500 text-xs py-4")},
              list{
                text("No backend metrics available"),
                button(
                  list{
                    Attrs.class_("ml-2 px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"),
                    Events.onClick(Coprocessors(RefreshMetrics)),
                  },
                  list{text("Refresh")},
                ),
              },
            )
          } else {
            div(
              list{Attrs.class_("grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-3")},
              state.metrics->Array.map(m => renderMetricsCard(m))->List.fromArray,
            )
          },
        },
      ),
    },
  )
}

/// Render the call log view.
let renderCallLog = (state: coprocessorsState): Tea_Vdom.t<msg> => {
  let entries = switch state.selectedBackend {
  | Some(backend) => CoprocessorsEngine.filterByBackend(state.callLog, backend)
  | None => state.callLog
  }
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Backend filter chips
      div(
        list{Attrs.class_("flex items-center gap-1 flex-wrap")},
        list{
          button(
            list{
              Attrs.class_(
                if state.selectedBackend === None {
                  "px-2 py-1 text-xs bg-gray-600 text-white rounded"
                } else {
                  "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                },
              ),
              Events.onClick(Coprocessors(SelectBackendFilter(None))),
            },
            list{text("All")},
          ),
          ...CoprocessorsEngine.allBackends
          ->Array.map(backend => {
            let isActive = state.selectedBackend === Some(backend)
            let colourCls = CoprocessorsEngine.backendColour(backend)
            button(
              list{
                Attrs.class_(
                  if isActive {
                    `px-2 py-1 text-xs bg-gray-600 ${colourCls} rounded`
                  } else {
                    "px-2 py-1 text-xs bg-gray-800 text-gray-500 rounded cursor-pointer hover:text-gray-300"
                  },
                ),
                Events.onClick(Coprocessors(SelectBackendFilter(Some(backend)))),
              },
              list{text(CoprocessorsEngine.backendShortLabel(backend))},
            )
          })
          ->List.fromArray,
        },
      ),
      // Log entries
      if Array.length(entries) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No call log entries")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-1 max-h-96 overflow-y-auto")},
          entries
          ->Array.map(entry => {
            let colourCls = CoprocessorsEngine.backendColour(entry.backend)
            div(
              list{
                Attrs.class_(
                  `flex items-center gap-3 p-2 rounded text-xs ${if entry.success {
                      "bg-gray-800"
                    } else {
                      "bg-red-900/20"
                    }}`,
                ),
              },
              list{
                span(
                  list{Attrs.class_(`w-8 font-mono ${colourCls}`)},
                  list{text(CoprocessorsEngine.backendShortLabel(entry.backend))},
                ),
                span(
                  list{Attrs.class_("text-gray-200 w-32 truncate")},
                  list{text(entry.operation)},
                ),
                span(
                  list{Attrs.class_("text-gray-500 w-24 truncate")},
                  list{text(entry.inputSummary)},
                ),
                span(
                  list{Attrs.class_("text-gray-400 font-mono")},
                  list{text(`${Float.toString(entry.durationMs)}ms`)},
                ),
                if entry.success {
                  span(list{Attrs.class_("text-emerald-400")}, list{text("OK")})
                } else {
                  span(list{Attrs.class_("text-red-400")}, list{text("ERR")})
                },
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render the heatmap view.
let renderHeatmap = (state: coprocessorsState): Tea_Vdom.t<msg> => {
  if Array.length(state.heatmap) === 0 {
    div(
      list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
      list{text("No heatmap data — coprocessor call frequency will appear here during gameplay")},
    )
  } else {
    div(
      list{Attrs.class_("space-y-2")},
      CoprocessorsEngine.allBackends
      ->Array.map(backend => {
        let cells = state.heatmap->Array.filter(c => c.backend === backend)
        let colourCls = CoprocessorsEngine.backendColour(backend)
        div(
          list{Attrs.class_("flex items-center gap-2")},
          list{
            span(
              list{Attrs.class_(`w-8 text-xs font-mono ${colourCls}`)},
              list{text(CoprocessorsEngine.backendShortLabel(backend))},
            ),
            div(
              list{Attrs.class_("flex gap-px flex-1")},
              cells
              ->Array.map(cell => {
                let intensity = if cell.callCount === 0 {
                  "bg-gray-800"
                } else if cell.callCount < 5 {
                  "bg-emerald-900"
                } else if cell.callCount < 20 {
                  "bg-emerald-700"
                } else if cell.callCount < 50 {
                  "bg-amber-700"
                } else {
                  "bg-red-700"
                }
                div(
                  list{
                    Attrs.class_(`w-4 h-6 rounded-sm ${intensity}`),
                    Attrs.title(`Slot ${Int.toString(cell.timeSlot)}: ${Int.toString(cell.callCount)} calls`),
                  },
                  list{},
                )
              })
              ->List.fromArray,
            ),
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// Render the settings view.
let renderSettings = (state: coprocessorsState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Auto-refresh toggle
      div(
        list{Attrs.class_("flex items-center justify-between p-3 bg-gray-800 rounded")},
        list{
          div(
            list{},
            list{
              div(list{Attrs.class_("text-sm text-gray-200")}, list{text("Auto-Refresh")}),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(`Every ${Int.toString(state.refreshIntervalMs)}ms`)},
              ),
            },
          ),
          button(
            list{
              Attrs.class_(
                if state.autoRefresh {
                  "px-3 py-1 text-xs bg-emerald-700 text-white rounded"
                } else {
                  "px-3 py-1 text-xs bg-gray-700 text-gray-300 rounded cursor-pointer"
                },
              ),
              Events.onClick(Coprocessors(ToggleAutoRefresh)),
            },
            list{text(if state.autoRefresh { "Enabled" } else { "Disabled" })},
          ),
        },
      ),
      // Backend toggles
      div(
        list{Attrs.class_("space-y-1")},
        list{
          div(list{Attrs.class_("text-xs text-gray-400 mb-1")}, list{text("Backend Toggles")}),
          ...CoprocessorsEngine.allBackends
          ->Array.map(backend => {
            let isEnabled = state.enabledBackends->Array.includes(backend)
            let colourCls = CoprocessorsEngine.backendColour(backend)
            div(
              list{Attrs.class_("flex items-center justify-between p-2 bg-gray-800/50 rounded")},
              list{
                span(
                  list{Attrs.class_(`text-sm ${colourCls}`)},
                  list{text(CoprocessorsEngine.backendLabel(backend))},
                ),
                button(
                  list{
                    Attrs.class_(
                      if isEnabled {
                        "px-2 py-0.5 text-xs bg-emerald-700 text-white rounded"
                      } else {
                        "px-2 py-0.5 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                      },
                    ),
                    Events.onClick(Coprocessors(ToggleCoprocBackend(backend))),
                  },
                  list{text(if isEnabled { "On" } else { "Off" })},
                ),
              },
            )
          })
          ->List.fromArray,
        },
      ),
    },
  )
}

/// Main view function.
let view = (state: coprocessorsState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Coprocessors panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(list{Attrs.class_("text-lg font-semibold text-gray-100")}, list{text("Coprocessors")}),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(`${Int.toString(Array.length(state.enabledBackends))} of 10 active`)},
              ),
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"),
              Events.onClick(Coprocessors(RefreshMetrics)),
            },
            list{text("Refresh")},
          ),
        },
      ),
      // Category tabs
      div(
        list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          renderTab("Dashboard", CoprocDashboard, state.activeCategory),
          renderTab("Call Log", CoprocCallLog, state.activeCategory),
          renderTab("Heatmap", CoprocHeatmap, state.activeCategory),
          renderTab("Settings", CoprocSettings, state.activeCategory),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("mx-4 mt-2 p-2 bg-red-900/50 border border-red-700 rounded text-xs text-red-300")},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between")},
              list{
                text(err),
                button(
                  list{
                    Attrs.class_("text-red-400 hover:text-red-200 cursor-pointer"),
                    Events.onClick(Coprocessors(DismissCoprocError)),
                  },
                  list{text("Dismiss")},
                ),
              },
            ),
          },
        )
      | None => noNode
      },
      // Loading indicator
      if state.loading {
        div(
          list{Attrs.class_("px-4 py-2 text-xs text-cyan-400 animate-pulse")},
          list{text("Loading coprocessor data...")},
        )
      } else {
        noNode
      },
      // Main content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4")},
        list{
          switch state.activeCategory {
          | CoprocDashboard => renderDashboard(state)
          | CoprocCallLog => renderCallLog(state)
          | CoprocHeatmap => renderHeatmap(state)
          | CoprocSettings => renderSettings(state)
          },
        },
      ),
    },
  )
}
