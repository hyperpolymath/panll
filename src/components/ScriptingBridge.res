// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Scripting Bridge Component — VM instruction scripting REPL.
/// Displays REPL with input/output history, instruction reference table,
/// saved scripts list, and analysis view.

open Model
open Msg
open Tea.Html

/// Render an instruction tier badge.
let tierBadge = (tier: instructionTier): Tea_Vdom.t<msg> => {
  let (color, label) = switch tier {
  | TierSafe => ("bg-green-700 text-green-100", "T0 Safe")
  | TierControlled => ("bg-blue-700 text-blue-100", "T1 Ctrl")
  | TierPrivileged => ("bg-yellow-700 text-yellow-100", "T2 Priv")
  | TierSystem => ("bg-red-700 text-red-100", "T3 Sys")
  }
  span(list{Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color)}, list{text(label)})
}

/// Render an analysis severity badge.
let analysisSevBadge = (sev: analysisSeverity): Tea_Vdom.t<msg> => {
  let (color, label) = switch sev {
  | AnalysisError => ("text-red-400", "ERR")
  | AnalysisWarning => ("text-yellow-400", "WARN")
  | AnalysisInfo => ("text-blue-400", "INFO")
  | AnalysisOptimisation => ("text-green-400", "OPT")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Main view function for the Scripting Bridge panel.
let view = (state: scriptingBridgeState): Tea_Vdom.t<msg> => {
  let scriptCount = Array.length(state.savedScripts)
  let historyCount = Array.length(state.replHistory)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Scripting Bridge — VM Instruction Scripting REPL"),
    },
    list{
      // Header row
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-bold text-rose-300")}, list{text("Scripting Bridge")}),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{text(Int.toString(scriptCount) ++ " scripts, " ++ Int.toString(historyCount) ++ " entries")},
              ),
              if state.executing {
                span(list{Attrs.class_("text-xs text-yellow-400 animate-pulse")}, list{text("Executing...")})
              } else {
                Tea_Html.noNode
              },
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-rose-800 hover:bg-rose-700 text-white rounded"),
              Events.onClick(ScriptingBridge(ScBStarted)),
            },
            list{text("Execute")},
          ),
        },
      ),
      // Tab bar
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Repl { "bg-rose-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(ScriptingBridge(SetScBTab(Repl))),
            },
            list{text("REPL")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Instructions { "bg-rose-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(ScriptingBridge(SetScBTab(Instructions))),
            },
            list{text("Instructions")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Scripts { "bg-rose-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(ScriptingBridge(SetScBTab(Scripts))),
            },
            list{text("Scripts")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Analysis { "bg-rose-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(ScriptingBridge(SetScBTab(Analysis))),
            },
            list{text("Analysis")},
          ),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200 flex justify-between items-center")},
          list{
            text(err),
            button(
              list{Attrs.class_("text-red-400 hover:text-red-200 text-xs ml-2"), Events.onClick(ScriptingBridge(DismissScBError))},
              list{text("Dismiss")},
            ),
          },
        )
      | None => Tea_Html.noNode
      },
      // Content area
      div(
        list{Attrs.class_("flex-1 overflow-y-auto px-4 py-4")},
        list{
          switch state.activeTab {
          | Repl =>
            div(
              list{Attrs.class_("flex flex-col h-full")},
              list{
                // REPL history
                div(
                  list{Attrs.class_("flex-1 overflow-y-auto mb-3 space-y-2")},
                  state.replHistory
                  ->Array.map(entry =>
                    div(
                      list{Attrs.class_("font-mono text-sm")},
                      list{
                        div(
                          list{Attrs.class_("flex items-start gap-2")},
                          list{
                            span(list{Attrs.class_("text-rose-400")}, list{text("> ")}),
                            span(list{Attrs.class_("text-gray-200")}, list{text(entry.input)}),
                          },
                        ),
                        div(
                          list{
                            Attrs.class_(
                              "pl-4 " ++
                              if entry.success { "text-gray-400" } else { "text-red-400" },
                            ),
                          },
                          list{text(entry.output)},
                        ),
                      },
                    )
                  )
                  ->List.fromArray,
                ),
                // Input area
                div(
                  list{Attrs.class_("flex items-center gap-2")},
                  list{
                    span(list{Attrs.class_("text-rose-400 font-mono")}, list{text("> ")}),
                    input(
                      list{
                        Attrs.class_("flex-1 bg-gray-900 border border-gray-700 rounded px-2 py-1 text-sm font-mono text-gray-200"),
                        Attrs.value(state.replInput),
                        Attrs.placeholder("Enter VM script..."),
                      },
                      list{},
                    ),
                  },
                ),
              },
            )
          | Instructions =>
            div(
              list{},
              list{
                // Table header
                div(
                  list{Attrs.class_("flex gap-2 text-xs text-gray-500 font-mono border-b border-gray-800 pb-1 mb-2")},
                  list{
                    span(list{Attrs.class_("w-12")}, list{text("Op")}),
                    span(list{Attrs.class_("w-28")}, list{text("Mnemonic")}),
                    span(list{Attrs.class_("w-20")}, list{text("Tier")}),
                    span(list{Attrs.class_("w-24")}, list{text("Stack")}),
                    span(list{Attrs.class_("flex-1")}, list{text("Description")}),
                  },
                ),
                div(
                  list{Attrs.class_("space-y-1")},
                  state.instructions
                  ->Array.map(instr =>
                    div(
                      list{Attrs.class_("flex gap-2 text-xs py-1 border-b border-gray-800/30 items-center")},
                      list{
                        span(list{Attrs.class_("w-12 font-mono text-gray-500")}, list{text(Int.toString(instr.opcode))}),
                        span(
                          list{Attrs.class_("w-28 font-mono " ++ if instr.allowed { "text-gray-200" } else { "text-gray-600 line-through" })},
                          list{text(instr.name)},
                        ),
                        span(list{Attrs.class_("w-20")}, list{tierBadge(instr.tier)}),
                        span(list{Attrs.class_("w-24 font-mono text-gray-500")}, list{text(instr.stackEffect)}),
                        span(list{Attrs.class_("flex-1 text-gray-400")}, list{text(instr.description)}),
                      },
                    )
                  )
                  ->List.fromArray,
                ),
              },
            )
          | Scripts =>
            div(
              list{Attrs.class_("space-y-2")},
              state.savedScripts
              ->Array.map(s => {
                let isSelected = state.selectedScript == Some(s.id)
                div(
                  list{
                    Attrs.class_(
                      "px-3 py-2 border rounded cursor-pointer " ++
                      if isSelected { "bg-rose-900/30 border-rose-700" } else { "bg-gray-900 border-gray-800 hover:border-gray-700" },
                    ),
                  },
                  list{
                    div(
                      list{Attrs.class_("flex items-center justify-between")},
                      list{
                        span(list{Attrs.class_("text-sm font-bold text-gray-200")}, list{text(s.name)}),
                        span(list{Attrs.class_("text-xs text-gray-500")}, list{text(s.description)}),
                      },
                    ),
                    div(
                      list{Attrs.class_("mt-1 text-xs text-gray-600 font-mono truncate")},
                      list{text(s.code)},
                    ),
                  },
                )
              })
              ->List.fromArray,
            )
          | Analysis =>
            div(
              list{Attrs.class_("space-y-2")},
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-400 mb-2")},
                  list{text(Int.toString(Array.length(state.analysisFindings)) ++ " findings")},
                ),
                div(
                  list{},
                  state.analysisFindings
                  ->Array.map(f =>
                    div(
                      list{Attrs.class_("px-3 py-2 bg-gray-900 border border-gray-800 rounded")},
                      list{
                        div(
                          list{Attrs.class_("flex items-center gap-2")},
                          list{
                            analysisSevBadge(f.severity),
                            span(list{Attrs.class_("text-sm text-gray-200")}, list{text(f.summary)}),
                            span(list{Attrs.class_("text-xs text-gray-500")}, list{text("L" ++ Int.toString(f.line))}),
                          },
                        ),
                        div(list{Attrs.class_("text-xs text-gray-400 mt-1")}, list{text(f.detail)}),
                      },
                    )
                  )
                  ->List.fromArray,
                ),
              },
            )
          },
        },
      ),
    },
  )
}
