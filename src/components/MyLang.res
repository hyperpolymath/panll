// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL My-Lang Component — AI-native language development panel.
///
/// Provides a code editor, REPL, compilation output, and dialect reference
/// for the 4 my-lang dialects: Solo, Duet, Ensemble, Me.

open Model
open Msg
open Tea.Html

/// Render a dialect selector button.
let renderDialectButton = (d: myLangDialect, active: myLangDialect): Tea_Vdom.t<msg> => {
  let isActive = d === active
  let colour = MyLangEngine.dialectColour(d)
  button(
    list{
      Attrs.class_(
        `px-3 py-1.5 text-xs rounded transition-colors ${isActive
            ? colour ++ " ring-1 ring-gray-600"
            : "text-gray-500 hover:text-gray-300"}`,
      ),
      Events.onClick(MyLang(SetDialect(d))),
    },
    list{text(MyLangEngine.dialectLabel(d))},
  )
}

/// Render a REPL entry.
let renderReplEntry = (entry: replEntry): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("font-mono text-xs space-y-0.5")},
    list{
      div(list{Attrs.class_("text-cyan-400")}, list{text(`> ${entry.input}`)}),
      div(
        list{Attrs.class_(if entry.isError { "text-red-400" } else { "text-gray-300" })},
        list{text(entry.output)},
      ),
    },
  )
}

/// Render category tabs.
let renderTabs = (active: myLangCategory): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"),
      Attrs.role("tablist"),
    },
    MyLangEngine.allCategories->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-cyan-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(MyLang(SetMlCategory(tab))),
        },
        list{text(MyLangEngine.categoryLabel(tab))},
      )
    })->List.fromArray,
  )
}

/// Main view for the My-Lang panel.
let view = (ml: myLangState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("My-Lang AI-native language panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-medium text-gray-200")}, list{text("My-Lang")}),
              span(list{Attrs.class_("text-xs text-gray-500")}, list{text("AI-native language workbench")}),
              if ml.cliAvailable {
                span(list{Attrs.class_("text-xs text-emerald-500")}, list{text("CLI ready")})
              } else {
                span(list{Attrs.class_("text-xs text-amber-500")}, list{text("CLI not found")})
              },
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              // Dialect selector
              div(
                list{Attrs.class_("flex gap-1")},
                MyLangEngine.allDialects->Array.map(d => renderDialectButton(d, ml.activeDialect))->List.fromArray,
              ),
              button(
                list{
                  Attrs.class_("px-3 py-1 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700"),
                  Events.onClick(PanelSwitcher(ClosePanels)),
                },
                list{text("Close")},
              ),
            },
          ),
        },
      ),
      // Content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-6")},
        list{
          renderTabs(ml.activeCategory),
          switch ml.activeCategory {
          | MlEditor =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                div(
                  list{Attrs.class_("flex items-center justify-between")},
                  list{
                    span(list{Attrs.class_("text-sm text-gray-400")}, list{text(`Editing in ${MyLangEngine.dialectLabel(ml.activeDialect)} dialect`)}),
                    button(
                      list{
                        Attrs.class_("px-3 py-1 text-xs bg-emerald-600 text-white rounded hover:bg-emerald-500"),
                        Events.onClick(MyLang(Compile)),
                      },
                      list{text("Compile")},
                    ),
                  },
                ),
                textarea(
                  list{
                    Attrs.class_("w-full h-96 bg-gray-900 border border-gray-700 rounded-lg p-4 font-mono text-sm text-gray-200 resize-none focus:border-cyan-500 focus:outline-none"),
                    Attrs.value(ml.editorContent),
                    Attrs.placeholder("Write your code here..."),
                    Events.onInput(v => MyLang(UpdateEditor(v))),
                  },
                  list{},
                ),
              },
            )
          | MlRepl =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                // REPL history
                div(
                  list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4 h-80 overflow-y-auto space-y-2")},
                  if ml.replHistory->Array.length === 0 {
                    list{div(list{Attrs.class_("text-gray-600 text-sm")}, list{text(`${MyLangEngine.dialectLabel(ml.activeDialect)} REPL — type an expression`)})}
                  } else {
                    ml.replHistory->Array.map(e => renderReplEntry(e))->List.fromArray
                  },
                ),
                // REPL input
                div(
                  list{Attrs.class_("flex gap-2")},
                  list{
                    span(list{Attrs.class_("text-cyan-400 font-mono text-sm pt-2")}, list{text(">")}),
                    input(
                      list{
                        Attrs.class_("flex-1 bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 font-mono placeholder-gray-600"),
                        Attrs.placeholder("Enter expression..."),
                        Attrs.value(ml.replInput),
                        Events.onInput(v => MyLang(UpdateReplInput(v))),
                        Events.onKeyDown(key =>
                          if key === "Enter" {
                            Some(MyLang(EvalRepl))
                          } else {
                            None
                          }
                        ),
                      },
                      list{},
                    ),
                    button(
                      list{
                        Attrs.class_("px-3 py-2 text-sm bg-cyan-600 text-white rounded hover:bg-cyan-500"),
                        Events.onClick(MyLang(EvalRepl)),
                      },
                      list{text("Eval")},
                    ),
                  },
                ),
              },
            )
          | MlCompile =>
            switch ml.lastCompilation {
            | Some(result) =>
              div(
                list{Attrs.class_("space-y-4")},
                list{
                  div(
                    list{Attrs.class_("flex items-center gap-3")},
                    list{
                      span(
                        list{Attrs.class_(if result.success { "text-emerald-400 text-sm font-medium" } else { "text-red-400 text-sm font-medium" })},
                        list{text(if result.success { "Compilation succeeded" } else { "Compilation failed" })},
                      ),
                      span(list{Attrs.class_("text-xs text-gray-500")}, list{text(`${Int.toString(result.compileTimeMs)}ms`)}),
                      span(list{Attrs.class_("text-xs text-gray-500")}, list{text(`${Int.toString(result.errorCount)} errors, ${Int.toString(result.warningCount)} warnings`)}),
                    },
                  ),
                  if result.output !== "" {
                    div(
                      list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4")},
                      list{
                        div(list{Attrs.class_("text-xs text-gray-500 mb-2")}, list{text("Output")}),
                        pre(list{Attrs.class_("font-mono text-sm text-gray-300 whitespace-pre-wrap")}, list{text(result.output)}),
                      },
                    )
                  } else {
                    noNode
                  },
                  if result.diagnostics !== "" {
                    div(
                      list{Attrs.class_("bg-gray-900 border border-red-700/50 rounded-lg p-4")},
                      list{
                        div(list{Attrs.class_("text-xs text-red-400 mb-2")}, list{text("Diagnostics")}),
                        pre(list{Attrs.class_("font-mono text-sm text-red-300 whitespace-pre-wrap")}, list{text(result.diagnostics)}),
                      },
                    )
                  } else {
                    noNode
                  },
                },
              )
            | None =>
              div(
                list{Attrs.class_("text-center text-gray-500 mt-8")},
                list{text("No compilation results. Write code in the Editor tab and click Compile.")},
              )
            }
          | MlDialects =>
            div(
              list{Attrs.class_("space-y-6 max-w-2xl")},
              list{
                h3(list{Attrs.class_("text-base font-medium text-gray-200")}, list{text("My-Lang Dialects")}),
                div(
                  list{Attrs.class_("space-y-4")},
                  MyLangEngine.allDialects->Array.map(d => {
                    let colour = MyLangEngine.dialectColour(d)
                    div(
                      list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4")},
                      list{
                        div(
                          list{Attrs.class_("flex items-center gap-3 mb-2")},
                          list{
                            span(list{Attrs.class_(`px-2 py-0.5 text-xs font-medium rounded ${colour}`)}, list{text(MyLangEngine.dialectLabel(d))}),
                            span(list{Attrs.class_("text-sm text-gray-400")}, list{text(MyLangEngine.dialectDescription(d))}),
                          },
                        ),
                        pre(
                          list{Attrs.class_("mt-2 font-mono text-xs text-gray-500 bg-gray-950 rounded p-3 whitespace-pre-wrap")},
                          list{text(MyLangEngine.dialectExample(d))},
                        ),
                      },
                    )
                  })->List.fromArray,
                ),
              },
            )
          },
          switch ml.error {
          | Some(e) => div(list{Attrs.class_("mt-4 p-3 bg-red-900/30 border border-red-700 rounded text-sm text-red-300"), Attrs.role("alert")}, list{text(e)})
          | None => noNode
          },
        },
      ),
    },
  )
}
