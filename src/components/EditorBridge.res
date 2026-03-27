// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Editor Bridge Component — view for federating with external
/// code editors. Shows diagnostics, open files, symbols, and activity
/// from the connected editor without duplicating the editing surface.

open Model
open Msg
open Tea.Html

/// Render a category tab button.
let renderTab = (
  label: string,
  cat: editorBridgeCategory,
  active: editorBridgeCategory,
): Tea_Vdom.t<msg> => {
  let isActive = cat === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{Attrs.class_(cls), Events.onClick(EditorBridge(SetBridgeCategory(cat)))},
    list{text(label)},
  )
}

/// Render the overview — connection status, open files, diagnostic summary.
let renderOverview = (state: editorBridgeState): Tea_Vdom.t<msg> => {
  let connCls = EditorBridgeEngine.connectionColour(state.connection)
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Connection card
      div(
        list{Attrs.class_("p-4 bg-gray-800 rounded border border-gray-700")},
        list{
          div(
            list{Attrs.class_("flex items-center justify-between mb-3")},
            list{
              div(
                list{Attrs.class_("flex items-center gap-2")},
                list{
                  span(
                    list{Attrs.class_("text-sm font-medium text-gray-200")},
                    list{text(EditorBridgeEngine.editorLabel(state.editorKind))},
                  ),
                  span(
                    list{Attrs.class_(`text-xs ${connCls}`)},
                    list{text(EditorBridgeEngine.connectionLabel(state.connection))},
                  ),
                },
              ),
              div(
                list{Attrs.class_("flex items-center gap-2")},
                list{
                  button(
                    list{
                      Attrs.class_(
                        "px-2 py-1 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer",
                      ),
                      Events.onClick(EditorBridge(DetectEditor)),
                    },
                    list{text("Detect")},
                  ),
                  button(
                    list{
                      Attrs.class_(
                        "px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                      ),
                      Events.onClick(EditorBridge(ConnectLsp)),
                    },
                    list{text("Connect LSP")},
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("text-xs text-gray-500")},
            list{
              text(
                `LSP port: ${Int.toString(state.lspPort)} | Auto-sync: ${if state.autoSync {
                    "on"
                  } else {
                    "off"
                  }}`,
              ),
            },
          ),
        },
      ),
      // Stats row
      div(
        list{Attrs.class_("grid grid-cols-4 gap-3")},
        list{
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-gray-100")},
                list{text(Int.toString(Array.length(state.openFiles)))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Open Files")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-red-400")},
                list{
                  text(
                    Int.toString(EditorBridgeEngine.countBySeverity(state.diagnostics, "error")),
                  ),
                },
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Errors")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-amber-400")},
                list{
                  text(
                    Int.toString(EditorBridgeEngine.countBySeverity(state.diagnostics, "warning")),
                  ),
                },
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Warnings")}),
            },
          ),
          div(
            list{Attrs.class_("p-3 bg-gray-800 rounded text-center")},
            list{
              div(
                list{Attrs.class_("text-2xl font-light text-gray-100")},
                list{text(Int.toString(Array.length(state.symbols)))},
              ),
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Symbols")}),
            },
          ),
        },
      ),
      // Open files list
      if Array.length(state.openFiles) > 0 {
        div(
          list{Attrs.class_("space-y-1")},
          list{
            div(list{Attrs.class_("text-xs text-gray-400 mb-1")}, list{text("Open Files")}),
            ...state.openFiles
            ->Array.map(file =>
              div(
                list{
                  Attrs.class_(
                    "flex items-center gap-3 p-2 bg-gray-800/50 rounded cursor-pointer hover:bg-gray-700/50",
                  ),
                  Events.onClick(EditorBridge(OpenFileInEditor(file.path, file.cursorLine))),
                },
                list{
                  span(
                    list{
                      Attrs.class_(
                        if file.modified {
                          "text-amber-400 text-xs"
                        } else {
                          "text-gray-400 text-xs"
                        },
                      ),
                    },
                    list{
                      text(
                        if file.modified {
                          "*"
                        } else {
                          " "
                        },
                      ),
                    },
                  ),
                  span(
                    list{Attrs.class_("text-sm text-gray-200 flex-1 truncate font-mono")},
                    list{text(file.path)},
                  ),
                  span(list{Attrs.class_("text-xs text-gray-500")}, list{text(file.language)}),
                  span(
                    list{Attrs.class_("text-xs text-gray-600 font-mono")},
                    list{text(`L${Int.toString(file.cursorLine)}`)},
                  ),
                },
              )
            )
            ->List.fromArray,
          },
        )
      } else {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No files open — connect to an editor to see open files")},
        )
      },
    },
  )
}

/// Render diagnostics list.
let renderDiagnostics = (state: editorBridgeState): Tea_Vdom.t<msg> => {
  let filtered = EditorBridgeEngine.filterDiagnostics(
    state.diagnostics,
    state.showErrors,
    state.showWarnings,
    state.showInfo,
    state.diagnosticFilter,
  )
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Filter controls
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 px-3 py-1.5 bg-gray-800 border border-gray-700 rounded text-sm text-gray-200 placeholder-gray-500",
              ),
              Attrs.placeholder("Filter diagnostics..."),
              Attrs.value(state.diagnosticFilter),
              Events.onInput(text => EditorBridge(SetDiagnosticFilter(text))),
            },
            list{},
          ),
          button(
            list{
              Attrs.class_(
                if state.showErrors {
                  "px-2 py-1 text-xs bg-red-800 text-red-200 rounded"
                } else {
                  "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                },
              ),
              Events.onClick(EditorBridge(ToggleShowErrors)),
            },
            list{text("Errors")},
          ),
          button(
            list{
              Attrs.class_(
                if state.showWarnings {
                  "px-2 py-1 text-xs bg-amber-800 text-amber-200 rounded"
                } else {
                  "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                },
              ),
              Events.onClick(EditorBridge(ToggleShowWarnings)),
            },
            list{text("Warnings")},
          ),
          button(
            list{
              Attrs.class_(
                if state.showInfo {
                  "px-2 py-1 text-xs bg-blue-800 text-blue-200 rounded"
                } else {
                  "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                },
              ),
              Events.onClick(EditorBridge(ToggleShowInfo)),
            },
            list{text("Info")},
          ),
        },
      ),
      // Diagnostics list
      if Array.length(filtered) === 0 {
        div(
          list{Attrs.class_("text-center text-emerald-400 text-sm py-8")},
          list{text("No diagnostics — code is clean")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-1 max-h-96 overflow-y-auto")},
          filtered
          ->Array.map(diag => {
            let sevCls = EditorBridgeEngine.severityColour(diag.severity)
            div(
              list{
                Attrs.class_("p-2 bg-gray-800 rounded cursor-pointer hover:bg-gray-700"),
                Events.onClick(EditorBridge(OpenFileInEditor(diag.filePath, diag.line))),
              },
              list{
                div(
                  list{Attrs.class_("flex items-center gap-2 mb-1")},
                  list{
                    span(
                      list{Attrs.class_(`text-xs font-bold ${sevCls} uppercase`)},
                      list{text(diag.severity)},
                    ),
                    span(
                      list{Attrs.class_("text-xs text-gray-400 font-mono")},
                      list{text(`${diag.filePath}:${Int.toString(diag.line)}`)},
                    ),
                    if diag.source !== "" {
                      span(
                        list{Attrs.class_("text-xs text-gray-600")},
                        list{text(`[${diag.source}]`)},
                      )
                    } else {
                      noNode
                    },
                  },
                ),
                div(list{Attrs.class_("text-xs text-gray-300")}, list{text(diag.message)}),
              },
            )
          })
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render symbols view.
let renderSymbols = (state: editorBridgeState): Tea_Vdom.t<msg> => {
  let filtered = EditorBridgeEngine.filterSymbols(state.symbols, state.symbolFilter)
  div(
    list{Attrs.class_("space-y-3")},
    list{
      input(
        list{
          Attrs.class_(
            "w-full px-3 py-1.5 bg-gray-800 border border-gray-700 rounded text-sm text-gray-200 placeholder-gray-500",
          ),
          Attrs.placeholder("Search symbols..."),
          Attrs.value(state.symbolFilter),
          Events.onInput(text => EditorBridge(SetSymbolFilter(text))),
        },
        list{},
      ),
      if Array.length(filtered) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No symbols found")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-1 max-h-96 overflow-y-auto")},
          filtered
          ->Array.map(sym =>
            div(
              list{
                Attrs.class_(
                  "flex items-center gap-3 p-2 bg-gray-800 rounded cursor-pointer hover:bg-gray-700",
                ),
                Events.onClick(EditorBridge(OpenFileInEditor(sym.filePath, sym.line))),
              },
              list{
                span(list{Attrs.class_("text-xs text-gray-500 w-16")}, list{text(sym.kind)}),
                span(list{Attrs.class_("text-sm text-cyan-400 font-mono")}, list{text(sym.name)}),
                if sym.containerName !== "" {
                  span(
                    list{Attrs.class_("text-xs text-gray-500")},
                    list{text(`in ${sym.containerName}`)},
                  )
                } else {
                  noNode
                },
                span(
                  list{Attrs.class_("ml-auto text-xs text-gray-600 font-mono")},
                  list{text(`${sym.filePath}:${Int.toString(sym.line)}`)},
                ),
              },
            )
          )
          ->List.fromArray,
        )
      },
    },
  )
}

/// Render activity feed.
let renderActivity = (state: editorBridgeState): Tea_Vdom.t<msg> => {
  if Array.length(state.activity) === 0 {
    div(
      list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
      list{text("No editor activity recorded yet")},
    )
  } else {
    div(
      list{Attrs.class_("space-y-1 max-h-96 overflow-y-auto")},
      state.activity
      ->Array.map(act =>
        div(
          list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-800/50 rounded text-xs")},
          list{
            span(
              list{Attrs.class_("text-gray-500 font-mono w-16")},
              list{text(Float.toString(act.timestamp))},
            ),
            span(list{Attrs.class_("text-gray-300")}, list{text(act.action)}),
            span(list{Attrs.class_("text-gray-400 font-mono truncate")}, list{text(act.filePath)}),
          },
        )
      )
      ->List.fromArray,
    )
  }
}

/// Render settings view.
let renderSettings = (state: editorBridgeState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Editor selection
      div(
        list{Attrs.class_("p-3 bg-gray-800 rounded")},
        list{
          div(list{Attrs.class_("text-xs text-gray-400 mb-2")}, list{text("Editor")}),
          div(
            list{Attrs.class_("flex flex-wrap gap-1")},
            EditorBridgeEngine.allEditors
            ->Array.map(editor => {
              let isActive = state.editorKind === editor
              button(
                list{
                  Attrs.class_(
                    if isActive {
                      "px-2 py-1 text-xs bg-cyan-700 text-white rounded"
                    } else {
                      "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer hover:bg-gray-600"
                    },
                  ),
                  Events.onClick(EditorBridge(SetEditorKind(editor))),
                },
                list{text(EditorBridgeEngine.editorLabel(editor))},
              )
            })
            ->List.fromArray,
          ),
        },
      ),
      // Auto-sync toggle
      div(
        list{Attrs.class_("flex items-center justify-between p-3 bg-gray-800 rounded")},
        list{
          span(list{Attrs.class_("text-sm text-gray-200")}, list{text("Auto-Sync")}),
          button(
            list{
              Attrs.class_(
                if state.autoSync {
                  "px-3 py-1 text-xs bg-emerald-700 text-white rounded"
                } else {
                  "px-3 py-1 text-xs bg-gray-700 text-gray-300 rounded cursor-pointer"
                },
              ),
              Events.onClick(EditorBridge(ToggleAutoSync)),
            },
            list{
              text(
                if state.autoSync {
                  "Enabled"
                } else {
                  "Disabled"
                },
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Main view function.
let view = (state: editorBridgeState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Editor Bridge panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-lg font-semibold text-gray-100")},
                list{text("Editor Bridge")},
              ),
              span(
                list{
                  Attrs.class_(`text-xs ${EditorBridgeEngine.connectionColour(state.connection)}`),
                },
                list{text(EditorBridgeEngine.connectionLabel(state.connection))},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    if state.bojRouting {
                      "px-3 py-1.5 text-xs bg-blue-700 text-white rounded"
                    } else {
                      "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600"
                    },
                  ),
                  Attrs.ariaLabel(
                    if state.bojRouting {
                      "Disable BoJ routing"
                    } else {
                      "Enable BoJ routing"
                    },
                  ),
                  Events.onClick(EditorBridge(ToggleBojRouting)),
                },
                list{
                  text(
                    if state.bojRouting {
                      "BoJ On"
                    } else {
                      "BoJ"
                    },
                  ),
                },
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                  ),
                  Events.onClick(EditorBridge(RefreshBridge)),
                },
                list{text("Refresh")},
              ),
            },
          ),
        },
      ),
      // Tabs
      div(
        list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          renderTab("Overview", BridgeOverview, state.activeCategory),
          renderTab("Diagnostics", BridgeDiagnostics, state.activeCategory),
          renderTab("Symbols", BridgeSymbols, state.activeCategory),
          renderTab("Activity", BridgeActivity, state.activeCategory),
          renderTab("Settings", BridgeSettings, state.activeCategory),
        },
      ),
      // Error
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 p-2 bg-red-900/50 border border-red-700 rounded text-xs text-red-300",
            ),
          },
          list{
            div(
              list{Attrs.class_("flex items-center justify-between")},
              list{
                text(err),
                button(
                  list{
                    Attrs.class_("text-red-400 hover:text-red-200 cursor-pointer"),
                    Events.onClick(EditorBridge(DismissBridgeError)),
                  },
                  list{text("Dismiss")},
                ),
              },
            ),
          },
        )
      | None => noNode
      },
      // Content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4")},
        list{
          switch state.activeCategory {
          | BridgeOverview => renderOverview(state)
          | BridgeDiagnostics => renderDiagnostics(state)
          | BridgeSymbols => renderSymbols(state)
          | BridgeActivity => renderActivity(state)
          | BridgeSettings => renderSettings(state)
          },
        },
      ),
    },
  )
}
