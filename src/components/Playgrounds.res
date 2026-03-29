// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Playgrounds Component — Code sandbox and NQC console.
///
/// Multi-language editor (VQL, KQL, GQL, ReScript, Gleam, Idris2, Nickel),
/// NQC database console connecting to proxy at :4000, snippet library,
/// and tutorial mode.

open Model
open Msg
open Tea.Html

/// Render the language selector radio group (VQL, KQL, GQL, ReScript, Gleam, Idris2, Nickel).
let renderLanguageSelector = (active: playgroundLanguage): Tea_Vdom.t<msg> => {
  let langs: array<playgroundLanguage> = [
    LangVql,
    LangKql,
    LangGql,
    LangRescript,
    LangGleam,
    LangIdris2,
    LangNickel,
  ]
  div(
    list{
      Attrs.class_("flex gap-1 flex-wrap"),
      Attrs.role("radiogroup"),
      Attrs.ariaLabel("Select language"),
    },
    langs
    ->Array.map(lang => {
      let isActive = lang === active
      let isDb = PlaygroundsEngine.isDbLanguage(lang)
      button(
        list{
          Attrs.class_(
            `px-3 py-1 text-xs rounded transition-colors ${isActive
                ? "bg-indigo-600 text-white"
                : isDb
                ? "bg-gray-800 text-teal-400 hover:bg-gray-700"
                : "bg-gray-800 text-gray-400 hover:bg-gray-700"}`,
          ),
          Attrs.role("radio"),
          Attrs.ariaSelected(isActive),
          Events.onClick(Playgrounds(SetLanguage(lang))),
        },
        list{text(PlaygroundsEngine.languageLabel(lang))},
      )
    })
    ->List.fromArray,
  )
}

/// Render the category tab bar (Editor, NQC Console, Snippets, Tutorials).
let renderTabs = (active: playgroundsCategory): Tea_Vdom.t<msg> => {
  let tabs: array<playgroundsCategory> = [PlayEditor, PlayNqc, PlaySnippets, PlayTutorials]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"), Attrs.role("tablist")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-teal-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(Playgrounds(SetPlayCategory(tab))),
        },
        list{text(PlaygroundsEngine.categoryLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Main Playgrounds panel view — full-screen overlay with code editor, NQC console, and snippets.
let view = (pg: playgroundsState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Playgrounds code sandbox"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-medium text-gray-200")},
                list{text("Playgrounds")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("code sandbox + NQC console")},
              ),
              if pg.nqcConnected {
                span(list{Attrs.class_("text-xs text-green-400 ml-2")}, list{text("NQC connected")})
              } else {
                span(
                  list{Attrs.class_("text-xs text-gray-600 ml-2")},
                  list{text("NQC disconnected")},
                )
              },
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700"),
              Events.onClick(PanelSwitcher(ClosePanels)),
              KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
          ),
        },
      ),
      // Content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-6")},
        list{
          renderTabs(pg.activeCategory),
          switch pg.activeCategory {
          | PlayEditor =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                renderLanguageSelector(pg.activeLanguage),
                // Editor area
                div(
                  list{Attrs.class_("flex gap-4 h-80")},
                  list{
                    // Code input
                    div(
                      list{Attrs.class_("flex-1 flex flex-col")},
                      list{
                        div(
                          list{Attrs.class_("text-xs text-gray-500 mb-1")},
                          list{
                            text(
                              `${PlaygroundsEngine.languageLabel(
                                  pg.activeLanguage,
                                )} ${PlaygroundsEngine.languageExt(pg.activeLanguage)}`,
                            ),
                          },
                        ),
                        textarea(
                          list{
                            Attrs.class_(
                              "flex-1 bg-gray-900 border border-gray-700 rounded p-3 font-mono text-sm text-gray-200 resize-none",
                            ),
                            Attrs.placeholder("Write code here..."),
                            Attrs.ariaLabel("Code editor"),
                            Attrs.value(pg.editorContent),
                            Events.onInput(v => Playgrounds(UpdateCode(v))),
                          },
                          list{},
                        ),
                        button(
                          list{
                            Attrs.class_(
                              `mt-2 px-4 py-2 text-sm rounded ${pg.executing
                                  ? "bg-gray-700 text-gray-400"
                                  : "bg-teal-600 text-white hover:bg-teal-500"}`,
                            ),
                            Events.onClick(Playgrounds(Execute)),
                            KeyboardNav.onActivate(Playgrounds(Execute)),
                          },
                          list{text(pg.executing ? "Running..." : "Execute")},
                        ),
                      },
                    ),
                    // Output pane
                    div(
                      list{Attrs.class_("flex-1 flex flex-col")},
                      list{
                        div(list{Attrs.class_("text-xs text-gray-500 mb-1")}, list{text("Output")}),
                        div(
                          list{
                            Attrs.class_(
                              "flex-1 bg-gray-900 border border-gray-700 rounded p-3 font-mono text-xs text-gray-300 overflow-auto",
                            ),
                            Attrs.role("log"),
                          },
                          list{
                            switch pg.lastResult {
                            | Some(result) =>
                              if result.success {
                                div(
                                  list{},
                                  list{
                                    div(
                                      list{Attrs.class_("text-green-400 mb-1")},
                                      list{
                                        text(
                                          `OK (${Float.toFixed(
                                              result.durationMs,
                                              ~digits=1,
                                            )}ms, ${Int.toString(result.rowCount)} rows)`,
                                        ),
                                      },
                                    ),
                                    switch result.data {
                                    | Some(data) =>
                                      pre(
                                        list{Attrs.class_("text-gray-300 whitespace-pre-wrap")},
                                        list{text(data)},
                                      )
                                    | None => noNode
                                    },
                                  },
                                )
                              } else {
                                div(
                                  list{Attrs.class_("text-red-400")},
                                  list{
                                    text(
                                      switch result.error {
                                      | Some(e) => e
                                      | None => "Unknown error"
                                      },
                                    ),
                                  },
                                )
                              }
                            | None =>
                              div(
                                list{Attrs.class_("text-gray-600")},
                                list{text("No output yet. Write code and hit Execute.")},
                              )
                            },
                          },
                        ),
                      },
                    ),
                  },
                ),
              },
            )
          | PlayNqc =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                // NQC language selector (VQL/KQL/GQL only)
                div(
                  list{Attrs.class_("flex items-center gap-3")},
                  list{
                    div(
                      list{
                        Attrs.class_("flex gap-1"),
                        Attrs.role("radiogroup"),
                        Attrs.ariaLabel("NQC query language"),
                      },
                      [LangVql, LangKql, LangGql]
                      ->Array.map(lang => {
                        let isActive = lang === pg.nqcLanguage
                        let accentColor = switch lang {
                        | LangVql => "bg-teal-600 text-white"
                        | LangKql => "bg-purple-600 text-white"
                        | LangGql => "bg-amber-600 text-white"
                        | _ => "bg-indigo-600 text-white"
                        }
                        button(
                          list{
                            Attrs.class_(
                              `px-3 py-1.5 text-xs rounded transition-colors ${isActive
                                  ? accentColor
                                  : "bg-gray-800 text-gray-400 hover:bg-gray-700"}`,
                            ),
                            Attrs.role("radio"),
                            Attrs.ariaSelected(isActive),
                            Events.onClick(Playgrounds(SetNqcLanguage(lang))),
                          },
                          list{text(PlaygroundsEngine.languageLabel(lang))},
                        )
                      })
                      ->List.fromArray,
                    ),
                    // Connection indicator
                    div(
                      list{
                        Attrs.class_(
                          `flex items-center gap-1 text-xs ${pg.nqcConnected
                              ? "text-green-400"
                              : "text-gray-600"}`,
                        ),
                      },
                      list{
                        div(
                          list{
                            Attrs.class_(
                              `w-1.5 h-1.5 rounded-full ${pg.nqcConnected
                                  ? "bg-green-400"
                                  : "bg-gray-600"}`,
                            ),
                          },
                          list{},
                        ),
                        text(pg.nqcConnected ? "Connected to :4000" : "Disconnected"),
                      },
                    ),
                    // Clear history
                    if Array.length(pg.nqcHistory) > 0 {
                      button(
                        list{
                          Attrs.class_("ml-auto text-xs text-gray-600 hover:text-gray-400"),
                          Events.onClick(Playgrounds(ClearNqcHistory)),
                          KeyboardNav.onActivate(Playgrounds(ClearNqcHistory)),
                        },
                        list{text("Clear History")},
                      )
                    } else {
                      noNode
                    },
                  },
                ),
                // Query input + execute
                div(
                  list{Attrs.class_("flex gap-2")},
                  list{
                    textarea(
                      list{
                        Attrs.class_(
                          "flex-1 bg-gray-900 border border-gray-700 rounded p-3 font-mono text-sm text-gray-200 resize-none h-20",
                        ),
                        Attrs.placeholder(
                          switch pg.nqcLanguage {
                          | LangVql => "SELECT * FROM entities WHERE confidence > 0.9 LIMIT 10"
                          | LangKql => "MATCH (n:Concept)-[r:RELATES_TO]->(m) RETURN n, r, m"
                          | LangGql => "{ entities(filter: {type: \"document\"}) { id name confidence } }"
                          | _ => "Enter query..."
                          },
                        ),
                        Attrs.ariaLabel("NQC query input"),
                        Attrs.value(pg.nqcInput),
                        Events.onInput(v => Playgrounds(SetNqcInput(v))),
                      },
                      list{},
                    ),
                    div(
                      list{Attrs.class_("flex flex-col gap-1")},
                      list{
                        button(
                          list{
                            Attrs.class_(
                              `px-4 py-2 text-sm rounded flex-1 ${pg.executing
                                  ? "bg-gray-700 text-gray-400"
                                  : "bg-teal-600 text-white hover:bg-teal-500"}`,
                            ),
                            Events.onClick(Playgrounds(ExecuteNqc)),
                            KeyboardNav.onActivate(Playgrounds(ExecuteNqc)),
                            Attrs.disabled(pg.executing || pg.nqcInput === ""),
                          },
                          list{text(pg.executing ? "Running..." : "Execute")},
                        ),
                        div(
                          list{Attrs.class_("text-[10px] text-gray-600 text-center")},
                          list{text(PlaygroundsEngine.languageLabel(pg.nqcLanguage))},
                        ),
                      },
                    ),
                  },
                ),
                // Last result
                switch pg.lastResult {
                | Some(result) =>
                  div(
                    list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3")},
                    list{
                      if result.success {
                        div(
                          list{},
                          list{
                            div(
                              list{Attrs.class_("flex items-center gap-3 mb-2")},
                              list{
                                span(
                                  list{Attrs.class_("text-xs text-green-400 font-medium")},
                                  list{text("OK")},
                                ),
                                span(
                                  list{Attrs.class_("text-xs text-gray-500")},
                                  list{text(`${Float.toFixed(result.durationMs, ~digits=1)}ms`)},
                                ),
                                span(
                                  list{Attrs.class_("text-xs text-gray-500")},
                                  list{text(`${Int.toString(result.rowCount)} rows`)},
                                ),
                              },
                            ),
                            switch result.data {
                            | Some(data) =>
                              pre(
                                list{
                                  Attrs.class_(
                                    "text-xs text-gray-300 font-mono whitespace-pre-wrap max-h-48 overflow-y-auto",
                                  ),
                                },
                                list{text(data)},
                              )
                            | None => noNode
                            },
                          },
                        )
                      } else {
                        div(
                          list{Attrs.class_("text-xs text-red-400")},
                          list{
                            text(
                              switch result.error {
                              | Some(e) => e
                              | None => "Unknown error"
                              },
                            ),
                          },
                        )
                      },
                    },
                  )
                | None => noNode
                },
                // Query history
                if Array.length(pg.nqcHistory) > 0 {
                  div(
                    list{Attrs.class_("space-y-2")},
                    list{
                      div(
                        list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider")},
                        list{text("Query History")},
                      ),
                      div(
                        list{Attrs.class_("space-y-1 max-h-48 overflow-y-auto")},
                        pg.nqcHistory
                        ->Array.map(((query, lang, result)) => {
                          let statusColor = switch result {
                          | Some(r) => r.success ? "border-l-green-600" : "border-l-red-600"
                          | None => "border-l-gray-600"
                          }
                          div(
                            list{
                              Attrs.class_(
                                `flex items-center gap-2 p-2 bg-gray-900/50 rounded border-l-2 ${statusColor} cursor-pointer hover:bg-gray-800/50`,
                              ),
                              Events.onClick(Playgrounds(SetNqcInput(query))),
                            },
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-8")},
                                list{text(PlaygroundsEngine.languageLabel(lang))},
                              ),
                              span(
                                list{
                                  Attrs.class_("flex-1 text-xs text-gray-400 font-mono truncate"),
                                },
                                list{text(query)},
                              ),
                            },
                          )
                        })
                        ->List.fromArray,
                      ),
                    },
                  )
                } else {
                  noNode
                },
              },
            )
          | PlaySnippets =>
            div(
              list{Attrs.class_("space-y-3")},
              pg.snippets
              ->Array.map(s =>
                div(
                  list{
                    Attrs.class_(
                      "bg-gray-900 border border-gray-700 rounded-lg p-3 hover:border-gray-500 cursor-pointer",
                    ),
                    Events.onClick(Playgrounds(LoadSnippet(s.id))),
                  },
                  list{
                    div(
                      list{Attrs.class_("flex justify-between items-center mb-1")},
                      list{
                        span(list{Attrs.class_("text-sm text-gray-200")}, list{text(s.title)}),
                        span(
                          list{Attrs.class_("text-xs text-gray-500")},
                          list{text(PlaygroundsEngine.languageLabel(s.language))},
                        ),
                      },
                    ),
                    pre(list{Attrs.class_("text-xs text-gray-400 truncate")}, list{text(s.code)}),
                  },
                )
              )
              ->List.fromArray,
            )
          | PlayTutorials =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                div(
                  list{
                    Attrs.class_("text-sm font-medium text-gray-400 border-b border-gray-800 pb-2"),
                  },
                  list{text("Interactive Tutorials")},
                ),
                div(
                  list{Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800")},
                  list{
                    div(
                      list{Attrs.class_("text-xs text-gray-400 font-medium mb-2")},
                      list{text("Getting Started")},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500")},
                      list{
                        text(
                          "Tutorials run in the sandbox environment. Select a language, follow the guided steps, and experiment with code in a safe, isolated context.",
                        ),
                      },
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800")},
                  list{
                    div(
                      list{Attrs.class_("text-xs text-gray-400 font-medium mb-2")},
                      list{text("NQC Playground")},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500")},
                      list{
                        text(
                          "Explore NQC queries against QuandleDB. Write and test quantum-safe database operations in a sandboxed environment.",
                        ),
                      },
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("p-4 bg-gray-900/50 rounded border border-gray-800")},
                  list{
                    div(
                      list{Attrs.class_("text-xs text-gray-400 font-medium mb-2")},
                      list{text("Proof Sketching")},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500")},
                      list{
                        text(
                          "Draft proof outlines using the ECHIDNA multi-solver dispatch. Connect Panel-L constraints to see how formal verification works.",
                        ),
                      },
                    ),
                  },
                ),
              },
            )
          },
          switch pg.error {
          | Some(e) =>
            div(
              list{
                Attrs.class_(
                  "mt-4 p-3 bg-red-900/30 border border-red-700 rounded text-sm text-red-300",
                ),
                Attrs.role("alert"),
              },
              list{text(e)},
            )
          | None => noNode
          },
        },
      ),
    },
  )
}
