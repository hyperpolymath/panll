// SPDX-License-Identifier: MPL-2.0

/// PanLL DebuggingWorkbench — time-travel debugging, state inspection, watch
/// expressions, and console output for the TEA model.
/// Inspector clade panel for deep debugging workflows.
///
/// Four tabs: Time Travel (snapshot slider), State Inspector (model tree),
/// Watch Expressions (live evaluation), and Console (log output).

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tab bar rendering.
let renderTabs = (active: debuggingWorkbenchTab): Tea_Vdom.t<msg> => {
  let tabs = DebuggingWorkbenchEngine.allTabs
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
          Events.onClick(DebuggingWorkbench(SetDwTab(tab))),
        },
        list{text(DebuggingWorkbenchEngine.tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

// =========================================================================
// Tab content views
// =========================================================================

/// Time Travel tab: snapshot slider with step controls and snapshot list.
let renderTimeTravelTab = (state: debuggingWorkbenchState): Tea_Vdom.t<msg> => {
  let tt = state.timeTravel
  let count = DebuggingWorkbenchEngine.snapshotCount(tt)
  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      // Controls
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          button(
            list{
              Attrs.class_(
                `px-3 py-1.5 text-xs rounded font-medium ${if (
                    DebuggingWorkbenchEngine.canGoBack(tt)
                  ) {
                    "bg-cyan-700 text-white hover:bg-cyan-600 cursor-pointer"
                  } else {
                    "bg-gray-700 text-gray-500 cursor-not-allowed"
                  }}`,
              ),
              Events.onClick(DebuggingWorkbench(DwStepBack)),
              KeyboardNav.onActivate(DebuggingWorkbench(DwStepBack)),
              Attrs.disabled(!DebuggingWorkbenchEngine.canGoBack(tt)),
            },
            list{text("Step Back")},
          ),
          div(
            list{Attrs.class_("text-sm text-gray-400 flex-1 text-center")},
            list{
              text(
                if count > 0 {
                  `Snapshot ${Int.toString(tt.currentIndex + 1)} of ${Int.toString(count)}`
                } else {
                  "No snapshots captured"
                },
              ),
            },
          ),
          button(
            list{
              Attrs.class_(
                `px-3 py-1.5 text-xs rounded font-medium ${if (
                    DebuggingWorkbenchEngine.canGoForward(tt)
                  ) {
                    "bg-cyan-700 text-white hover:bg-cyan-600 cursor-pointer"
                  } else {
                    "bg-gray-700 text-gray-500 cursor-not-allowed"
                  }}`,
              ),
              Events.onClick(DebuggingWorkbench(DwStepForward)),
              KeyboardNav.onActivate(DebuggingWorkbench(DwStepForward)),
              Attrs.disabled(!DebuggingWorkbenchEngine.canGoForward(tt)),
            },
            list{text("Step Forward")},
          ),
        },
      ),
      // Time-travelling indicator
      if tt.isTimeTravelling {
        div(
          list{
            Attrs.class_(
              "flex items-center gap-2 bg-amber-900/30 border border-amber-700 rounded p-2",
            ),
          },
          list{
            div(list{Attrs.class_("w-2.5 h-2.5 bg-amber-400 rounded-full animate-pulse")}, list{}),
            span(
              list{Attrs.class_("text-xs text-amber-300")},
              list{text("Time-travelling — state is read-only")},
            ),
          },
        )
      } else {
        noNode
      },
      // Snapshot list
      if count > 0 {
        div(
          list{Attrs.class_("flex flex-col gap-1 max-h-64 overflow-y-auto")},
          tt.snapshots
          ->Array.mapWithIndex((snap, idx) => {
            let isCurrent = idx === tt.currentIndex
            let bgCls = isCurrent ? "bg-cyan-900/30 border-cyan-700" : "bg-gray-800 border-gray-700"
            div(
              list{
                Attrs.class_(
                  `flex items-center gap-2 p-2 rounded border cursor-pointer hover:bg-gray-750 ${bgCls}`,
                ),
                Events.onClick(DebuggingWorkbench(DwGoToSnapshot(idx))),
              },
              list{
                span(
                  list{Attrs.class_("text-xs text-gray-500 w-8 text-right")},
                  list{text(`#${Int.toString(idx + 1)}`)},
                ),
                span(list{Attrs.class_("text-sm text-gray-300 flex-1")}, list{text(snap.label)}),
                span(
                  list{Attrs.class_("text-xs text-gray-600 font-mono")},
                  list{text(Float.toFixed(snap.timestamp, ~digits=1))},
                ),
              },
            )
          })
          ->List.fromArray,
        )
      } else {
        div(
          list{Attrs.class_("bg-gray-800 rounded p-4 h-32 flex items-center justify-center")},
          list{
            span(
              list{Attrs.class_("text-gray-600 text-sm")},
              list{text("Click \"Capture Snapshot\" to begin time-travel debugging.")},
            ),
          },
        )
      },
      // Capture button
      button(
        list{
          Attrs.class_(
            "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer font-medium self-end",
          ),
          Events.onClick(DebuggingWorkbench(DwCaptureSnapshot)),
          KeyboardNav.onActivate(DebuggingWorkbench(DwCaptureSnapshot)),
        },
        list{text("Capture Snapshot")},
      ),
    },
  )
}

/// State Inspector tab: JSON tree view of the current model state.
let renderStateInspectorTab = (state: debuggingWorkbenchState): Tea_Vdom.t<msg> => {
  switch state.selectedSnapshot {
  | Some(snapshotId) => {
      let snap = state.timeTravel.snapshots->Array.find(s => s.id === snapshotId)
      switch snap {
      | Some(s) =>
        div(
          list{Attrs.class_("p-4")},
          list{
            div(
              list{Attrs.class_("text-sm text-gray-400 mb-2")},
              list{text(`Inspecting: ${s.label}`)},
            ),
            pre(
              list{
                Attrs.class_(
                  "bg-gray-800 rounded p-4 text-xs font-mono text-gray-300 max-h-96 overflow-auto border border-gray-700",
                ),
              },
              list{text(s.modelJson)},
            ),
          },
        )
      | None =>
        div(
          list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
          list{text("Snapshot not found.")},
        )
      }
    }
  | None =>
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("Select a snapshot to inspect its state tree.")},
    )
  }
}

/// Watch Expressions tab: live expression evaluation display.
let renderWatchExpressionsTab = (state: debuggingWorkbenchState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4")},
    list{
      if Array.length(state.watches) === 0 {
        div(
          list{Attrs.class_("text-gray-500 text-sm italic")},
          list{text("No watch expressions. Add one below.")},
        )
      } else {
        div(
          list{Attrs.class_("flex flex-col gap-2 max-h-64 overflow-y-auto")},
          state.watches
          ->Array.map(watch => {
            div(
              list{Attrs.class_("bg-gray-800 rounded p-3 border border-gray-700")},
              list{
                div(
                  list{Attrs.class_("flex items-center justify-between mb-1")},
                  list{
                    span(
                      list{Attrs.class_("text-xs font-mono text-cyan-400")},
                      list{text(watch.expression)},
                    ),
                    button(
                      list{
                        Attrs.class_("text-xs text-gray-600 hover:text-red-400 cursor-pointer"),
                        Events.onClick(DebuggingWorkbench(DwRemoveWatch(watch.id))),
                      },
                      list{text("x")},
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("text-sm font-mono text-gray-300")},
                  list{text(watch.currentValue)},
                ),
              },
            )
          })
          ->List.fromArray,
        )
      },
      // Add watch button
      button(
        list{
          Attrs.class_(
            "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer self-start",
          ),
          Events.onClick(DebuggingWorkbench(DwAddWatch)),
          KeyboardNav.onActivate(DebuggingWorkbench(DwAddWatch)),
        },
        list{text("+ Add Watch")},
      ),
    },
  )
}

/// Console tab: scrollable log output.
let renderConsoleTab = (state: debuggingWorkbenchState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4")},
    list{
      if Array.length(state.consoleLog) === 0 {
        div(
          list{Attrs.class_("text-gray-500 text-sm italic")},
          list{text("Console output is empty.")},
        )
      } else {
        div(
          list{
            Attrs.class_(
              "bg-gray-800 rounded p-4 font-mono text-xs text-gray-300 max-h-96 overflow-auto border border-gray-700",
            ),
          },
          state.consoleLog
          ->Array.map(line => {
            div(list{Attrs.class_("py-0.5")}, list{text(line)})
          })
          ->List.fromArray,
        )
      },
      // Clear console button
      if Array.length(state.consoleLog) > 0 {
        button(
          list{
            Attrs.class_(
              "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer self-end",
            ),
            Events.onClick(DebuggingWorkbench(DwClearConsole)),
            KeyboardNav.onActivate(DebuggingWorkbench(DwClearConsole)),
          },
          list{text("Clear Console")},
        )
      } else {
        noNode
      },
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function for the Debugging Workbench panel.
let view = (state: debuggingWorkbenchState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabTimeTravel => renderTimeTravelTab(state)
  | TabStateInspector => renderStateInspectorTab(state)
  | TabWatchExpressions => renderWatchExpressionsTab(state)
  | TabConsole => renderConsoleTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold text-cyan-300")},
            list{text("Debugging Workbench")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-500")},
            list{
              text(
                `${Int.toString(
                    DebuggingWorkbenchEngine.snapshotCount(state.timeTravel),
                  )} snapshots`,
              ),
            },
          ),
        },
      ),
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
