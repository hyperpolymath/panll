// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL 007 Toolchain Component — Agentic compiler and high-rigor execution.
///
/// Monitor lexing, parsing, analysis, and execution in real-time.
/// Controls the Groove daemon lifecycle and permissions.

open Model
open Msg
open Tea.Html

let renderCategoryTab = (active: oo7Category, cat: oo7Category, label: string): Tea_Vdom.t<msg> => {
  let isActive = active === cat
  button(
    list{
      Attrs.class_(
        `px-4 py-2 text-sm rounded-t transition-colors ${isActive
            ? "bg-gray-800 text-gray-200 border-b-2 border-cyan-500"
            : "text-gray-500 hover:text-gray-300"}`,
      ),
      Events.onClick(Oo7Toolchain(SetCategory(cat))),
    },
    list{text(label)},
  )
}

let renderStageButton = (stage: oo7Stage, label: string): Tea_Vdom.t<msg> => {
  button(
    list{
      Attrs.class_(
        "px-3 py-1 text-xs bg-gray-800 text-gray-300 rounded border border-gray-700 hover:bg-gray-700",
      ),
      Events.onClick(Oo7Toolchain(RunStage(stage))),
    },
    list{text(label)},
  )
}

let view = (state: oo7State): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("fixed inset-0 bg-slate-950/95 z-40 flex flex-col")},
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between p-4 border-b border-slate-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-medium text-slate-200")},
                list{text("007 Toolchain")},
              ),
              span(
                list{Attrs.class_("text-xs text-slate-500")},
                list{text("agentic compiler & high-rigor execution")},
              ),
              div(
                list{
                  Attrs.class_(
                    `px-2 py-0.5 rounded-full text-[10px] ${state.isConnected
                        ? "bg-green-900/40 text-green-400"
                        : "bg-red-900/40 text-red-400"}`,
                  ),
                },
                list{text(state.isConnected ? "Groove Active" : "Groove Offline")},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-sm bg-slate-800 text-slate-300 rounded hover:bg-slate-700",
                  ),
                  Events.onClick(PanelSwitcher(ClosePanels)),
                },
                list{text("Close")},
              ),
            },
          ),
        },
      ),
      // Tabs
      div(
        list{Attrs.class_("px-6 pt-4 border-b border-slate-800 flex gap-1")},
        list{
          renderCategoryTab(state.activeCategory, Oo7Dashboard, "Dashboard"),
          renderCategoryTab(state.activeCategory, Oo7ControlPlane, "Control Plane"),
          renderCategoryTab(state.activeCategory, Oo7Permissions, "Permissions"),
          renderCategoryTab(state.activeCategory, Oo7Monitoring, "Monitoring"),
        },
      ),
      // Main Content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-6")},
        list{
          switch state.activeCategory {
          | Oo7Dashboard =>
            div(
              list{Attrs.class_("grid grid-cols-2 gap-6 h-full")},
              list{
                // Left: Editor
                div(
                  list{Attrs.class_("flex flex-col gap-3")},
                  list{
                    div(
                      list{
                        Attrs.class_(
                          "text-sm font-semibold text-slate-400 uppercase tracking-wider",
                        ),
                      },
                      list{text("Source (.007)")},
                    ),
                    textarea(
                      list{
                        Attrs.class_(
                          "flex-1 bg-slate-900 border border-slate-800 rounded p-4 font-mono text-sm text-slate-300 focus:outline-none focus:border-cyan-500/50",
                        ),
                        Attrs.value(state.sourceCode),
                        Events.onInput(code => Oo7Toolchain(UpdateSource(code))),
                      },
                      list{},
                    ),
                    div(
                      list{Attrs.class_("flex gap-2")},
                      list{
                        renderStageButton(Oo7Lexer, "Lex"),
                        renderStageButton(Oo7Parser, "Parse"),
                        renderStageButton(Oo7Analyser, "Analyse"),
                        button(
                          list{
                            Attrs.class_(
                              "px-3 py-1 text-xs bg-cyan-600 text-white rounded hover:bg-cyan-500",
                            ),
                            Events.onClick(Oo7Toolchain(RunStage(Oo7Evaluator))),
                          },
                          list{text("Evaluate")},
                        ),
                        renderStageButton(Oo7Linker, "Link"),
                      },
                    ),
                  },
                ),
                // Right: Output & Nesy
                div(
                  list{Attrs.class_("flex flex-col gap-6")},
                  list{
                    div(
                      list{Attrs.class_("flex-1 flex flex-col gap-3")},
                      list{
                        div(
                          list{
                            Attrs.class_(
                              "text-sm font-semibold text-slate-400 uppercase tracking-wider",
                            ),
                          },
                          list{text("Toolchain Output")},
                        ),
                        div(
                          list{
                            Attrs.class_(
                              "flex-1 bg-black/50 border border-slate-800 rounded p-4 font-mono text-xs text-cyan-400 overflow-auto",
                            ),
                          },
                          state.stageOutputs
                          ->Array.map(((stage, out)) =>
                            div(
                              list{Attrs.class_("mb-4")},
                              list{
                                div(
                                  list{
                                    Attrs.class_(
                                      "text-slate-500 mb-1 border-b border-slate-900 pb-1",
                                    ),
                                  },
                                  list{
                                    text(
                                      switch stage {
                                      | Oo7Lexer => "LEXER"
                                      | Oo7Parser => "PARSER"
                                      | Oo7Analyser => "ANALYSER"
                                      | Oo7Evaluator => "EVALUATOR"
                                      | Oo7Linker => "LINKER"
                                      },
                                    ),
                                  },
                                ),
                                text(out),
                              },
                            )
                          )
                          ->List.fromArray,
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("bg-slate-900/50 border border-slate-800 rounded p-4")},
                      list{
                        div(
                          list{Attrs.class_("text-xs font-semibold text-slate-500 uppercase mb-2")},
                          list{text("Neurosymbolic Status")},
                        ),
                        div(
                          list{Attrs.class_("text-sm text-slate-300")},
                          list{text(state.nesyStatus)},
                        ),
                        div(
                          list{Attrs.class_("mt-3 flex gap-2")},
                          list{
                            button(
                              list{
                                Attrs.class_(
                                  "text-[10px] px-2 py-0.5 bg-slate-800 text-slate-400 rounded hover:text-slate-200",
                                ),
                              },
                              list{text("Query TypeLL")},
                            ),
                            button(
                              list{
                                Attrs.class_(
                                  "text-[10px] px-2 py-0.5 bg-slate-800 text-slate-400 rounded hover:text-slate-200",
                                ),
                              },
                              list{text("Echidna Proof")},
                            ),
                          },
                        ),
                      },
                    ),
                  },
                ),
              },
            )
          | Oo7ControlPlane =>
            div(
              list{Attrs.class_("max-w-2xl space-y-8")},
              list{
                div(
                  list{},
                  list{
                    h3(
                      list{Attrs.class_("text-slate-200 font-medium mb-2")},
                      list{text("Groove Daemon Control")},
                    ),
                    p(
                      list{Attrs.class_("text-sm text-slate-500 mb-4")},
                      list{
                        text(
                          "Manage the lifecycle of the 007 control plane daemon. The daemon must be active to perform toolchain operations.",
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("flex gap-4")},
                      list{
                        if !state.isConnected {
                          button(
                            list{
                              Attrs.class_(
                                "px-4 py-2 bg-green-600 text-white rounded hover:bg-green-500",
                              ),
                              Events.onClick(Oo7Toolchain(ConnectDaemon)),
                            },
                            list{text("Start Daemon")},
                          )
                        } else {
                          button(
                            list{
                              Attrs.class_(
                                "px-4 py-2 bg-red-600 text-white rounded hover:bg-red-500",
                              ),
                              Events.onClick(Oo7Toolchain(DisconnectDaemon)),
                            },
                            list{text("Stop Daemon")},
                          )
                        },
                        button(
                          list{
                            Attrs.class_(
                              "px-4 py-2 bg-slate-800 text-slate-300 rounded hover:bg-slate-700",
                            ),
                          },
                          list{text("Restart")},
                        ),
                      },
                    ),
                  },
                ),
                div(
                  list{},
                  list{
                    h3(
                      list{Attrs.class_("text-slate-200 font-medium mb-2")},
                      list{text("Port Registry")},
                    ),
                    div(
                      list{
                        Attrs.class_(
                          "bg-slate-900 border border-slate-800 rounded p-4 font-mono text-sm",
                        ),
                      },
                      list{
                        div(
                          list{Attrs.class_("flex justify-between py-1")},
                          list{
                            span(list{}, list{text("007 Control Plane")}),
                            span(list{Attrs.class_("text-cyan-400")}, list{text(":7007")}),
                          },
                        ),
                        div(
                          list{Attrs.class_("flex justify-between py-1")},
                          list{
                            span(list{}, list{text("PanLL Groove")}),
                            span(list{Attrs.class_("text-cyan-400")}, list{text(":8000")}),
                          },
                        ),
                        div(
                          list{Attrs.class_("flex justify-between py-1")},
                          list{
                            span(list{}, list{text("Burble Gateway")}),
                            span(list{Attrs.class_("text-cyan-400")}, list{text(":4020")}),
                          },
                        ),
                      },
                    ),
                  },
                ),
              },
            )
          | Oo7Permissions =>
            div(
              list{Attrs.class_("max-w-xl space-y-6")},
              list{
                h3(
                  list{Attrs.class_("text-slate-200 font-medium")},
                  list{text("Daemon Permissions")},
                ),
                div(
                  list{Attrs.class_("space-y-3")},
                  [
                    (
                      PermissionReadOnly,
                      "Read Only",
                      "Can view toolchain status and results but cannot trigger stages.",
                    ),
                    (
                      PermissionExecute,
                      "Execute",
                      "Can trigger lexer, parser, and analysis stages.",
                    ),
                    (
                      PermissionAdministrative,
                      "Administrative",
                      "Full control over daemon lifecycle and memory allocators.",
                    ),
                  ]
                  ->Array.map(((p, label, desc)) =>
                    div(
                      list{
                        Attrs.class_(
                          `p-4 border rounded-lg cursor-pointer transition-colors ${state.permissions ===
                              p
                              ? "bg-cyan-900/20 border-cyan-500/50"
                              : "bg-slate-900 border-slate-800 hover:border-slate-700"}`,
                        ),
                        Events.onClick(Oo7Toolchain(SetPermissions(p))),
                      },
                      list{
                        div(list{Attrs.class_("font-medium text-slate-200")}, list{text(label)}),
                        div(list{Attrs.class_("text-xs text-slate-500 mt-1")}, list{text(desc)}),
                      },
                    )
                  )
                  ->List.fromArray,
                ),
              },
            )
          | Oo7Monitoring =>
            div(
              list{Attrs.class_("space-y-6")},
              list{
                div(
                  list{Attrs.class_("grid grid-cols-3 gap-4")},
                  list{
                    div(
                      list{Attrs.class_("bg-slate-900 p-4 rounded-lg border border-slate-800")},
                      list{
                        div(
                          list{Attrs.class_("text-xs text-slate-500 uppercase mb-1")},
                          list{text("Memory Usage")},
                        ),
                        div(
                          list{Attrs.class_("text-xl text-cyan-400 font-mono")},
                          list{text("42.5 MB")},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("bg-slate-900 p-4 rounded-lg border border-slate-800")},
                      list{
                        div(
                          list{Attrs.class_("text-xs text-slate-500 uppercase mb-1")},
                          list{text("JIT Latency")},
                        ),
                        div(
                          list{Attrs.class_("text-xl text-green-400 font-mono")},
                          list{text("0.8 ms")},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("bg-slate-900 p-4 rounded-lg border border-slate-800")},
                      list{
                        div(
                          list{Attrs.class_("text-xs text-slate-500 uppercase mb-1")},
                          list{text("Active Sessions")},
                        ),
                        div(
                          list{Attrs.class_("text-xl text-slate-200 font-mono")},
                          list{text("1")},
                        ),
                      },
                    ),
                  },
                ),
                div(
                  list{
                    Attrs.class_(
                      "bg-black/30 border border-slate-800 rounded p-4 font-mono text-[10px] text-slate-500 h-64 overflow-auto",
                    ),
                  },
                  list{
                    text("[groove] Initializing Level 2 handshake...\n"),
                    text("[oo7] Backend Zig evaluator loaded (High-Rigor mode)\n"),
                    text("[oo7] V-lang control plane listening on :7007\n"),
                    text("[nesy] TypeLL service attached to toolchain analyzer\n"),
                    text("[groove] Handshake complete. Session oo7-session-1 active.\n"),
                  },
                ),
              },
            )
          },
          if state.loading {
            div(
              list{
                Attrs.class_(
                  "fixed bottom-10 right-10 bg-cyan-600 text-white px-4 py-2 rounded-full shadow-lg animate-pulse text-sm",
                ),
              },
              list{text("Communicating with Daemon...")},
            )
          } else {
            noNode
          },
        },
      ),
      // Footer / Error
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "bg-red-900/50 border-t border-red-700 p-3 text-red-200 text-sm flex justify-between items-center",
            ),
          },
          list{
            text(err),
            button(
              list{
                Attrs.class_("text-red-200 hover:text-white"),
                Events.onClick(Oo7Toolchain(ClearError)),
              },
              list{text("Dismiss")},
            ),
          },
        )
      | None => noNode
      },
    },
  )
}
