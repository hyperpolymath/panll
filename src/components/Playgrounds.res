// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Playgrounds Component — Code sandbox and NQC console.
///
/// Multi-language editor (VQL, KQL, GQL, ReScript, Gleam, Idris2, Nickel),
/// NQC database console connecting to proxy at :4000, snippet library,
/// and tutorial mode.

open Model
open Msg
open Tea.Html

let renderLanguageSelector = (active: playgroundLanguage): Tea_Vdom.t<msg> => {
  let langs: array<playgroundLanguage> = [LangVql, LangKql, LangGql, LangRescript, LangGleam, LangIdris2, LangNickel]
  div(
    list{Attrs.class_("flex gap-1 flex-wrap"), Attrs.role("radiogroup"), Attrs.ariaLabel("Select language")},
    langs->Array.map(lang => {
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
    })->List.fromArray,
  )
}

let renderTabs = (active: playgroundsCategory): Tea_Vdom.t<msg> => {
  let tabs: array<playgroundsCategory> = [PlayEditor, PlayNqc, PlaySnippets, PlayTutorials]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"), Attrs.role("tablist")},
    tabs->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(`px-4 py-2 text-sm rounded-t transition-colors ${isActive ? "bg-gray-800 text-gray-200 border-b-2 border-teal-500" : "text-gray-500 hover:text-gray-300"}`),
          Attrs.role("tab"), Attrs.ariaSelected(isActive),
          Events.onClick(Playgrounds(SetPlayCategory(tab))),
        },
        list{text(PlaygroundsEngine.categoryLabel(tab))},
      )
    })->List.fromArray,
  )
}

let view = (pg: playgroundsState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"), Attrs.role("dialog"), Attrs.ariaLabel("Playgrounds code sandbox")},
    list{
      // Header
      div(list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")}, list{
        div(list{Attrs.class_("flex items-center gap-3")}, list{
          h2(list{Attrs.class_("text-lg font-medium text-gray-200")}, list{text("Playgrounds")}),
          span(list{Attrs.class_("text-xs text-gray-500")}, list{text("code sandbox + NQC console")}),
          if pg.nqcConnected {
            span(list{Attrs.class_("text-xs text-green-400 ml-2")}, list{text("NQC connected")})
          } else {
            span(list{Attrs.class_("text-xs text-gray-600 ml-2")}, list{text("NQC disconnected")})
          },
        }),
        button(list{Attrs.class_("px-3 py-1 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700"), Events.onClick(PanelSwitcher(ClosePanels))}, list{text("Close")}),
      }),
      // Content
      div(list{Attrs.class_("flex-1 overflow-auto p-6")}, list{
        renderTabs(pg.activeCategory),
        switch pg.activeCategory {
        | PlayEditor =>
          div(list{Attrs.class_("space-y-4")}, list{
            renderLanguageSelector(pg.activeLanguage),
            // Editor area
            div(list{Attrs.class_("flex gap-4 h-80")}, list{
              // Code input
              div(list{Attrs.class_("flex-1 flex flex-col")}, list{
                div(list{Attrs.class_("text-xs text-gray-500 mb-1")}, list{text(`${PlaygroundsEngine.languageLabel(pg.activeLanguage)} ${PlaygroundsEngine.languageExt(pg.activeLanguage)}`)}),
                textarea(
                  list{
                    Attrs.class_("flex-1 bg-gray-900 border border-gray-700 rounded p-3 font-mono text-sm text-gray-200 resize-none"),
                    Attrs.placeholder("Write code here..."),
                    Attrs.ariaLabel("Code editor"),
                    Attrs.value(pg.editorContent),
                    Events.onInput(v => Playgrounds(UpdateCode(v))),
                  },
                  list{},
                ),
                button(
                  list{
                    Attrs.class_(`mt-2 px-4 py-2 text-sm rounded ${pg.executing ? "bg-gray-700 text-gray-400" : "bg-teal-600 text-white hover:bg-teal-500"}`),
                    Events.onClick(Playgrounds(Execute)),
                  },
                  list{text(pg.executing ? "Running..." : "Execute")},
                ),
              }),
              // Output pane
              div(list{Attrs.class_("flex-1 flex flex-col")}, list{
                div(list{Attrs.class_("text-xs text-gray-500 mb-1")}, list{text("Output")}),
                div(
                  list{Attrs.class_("flex-1 bg-gray-900 border border-gray-700 rounded p-3 font-mono text-xs text-gray-300 overflow-auto"), Attrs.role("log")},
                  list{
                    switch pg.lastResult {
                    | Some(result) =>
                      if result.success {
                        div(list{}, list{
                          div(list{Attrs.class_("text-green-400 mb-1")}, list{text(`OK (${Float.toFixedWithPrecision(result.durationMs, ~digits=1)}ms, ${Int.toString(result.rowCount)} rows)`)}),
                          switch result.data {
                          | Some(data) => pre(list{Attrs.class_("text-gray-300 whitespace-pre-wrap")}, list{text(data)})
                          | None => noNode
                          },
                        })
                      } else {
                        div(list{Attrs.class_("text-red-400")}, list{
                          text(switch result.error { | Some(e) => e | None => "Unknown error" }),
                        })
                      }
                    | None => div(list{Attrs.class_("text-gray-600")}, list{text("No output yet. Write code and hit Execute.")})
                    },
                  },
                ),
              }),
            }),
          })
        | PlayNqc =>
          div(list{Attrs.class_("text-center text-gray-500 mt-8")}, list{
            div(list{Attrs.class_("text-2xl mb-2")}, list{text("NQC Console")}),
            div(list{Attrs.class_("text-sm")}, list{text("VQL (VeriSimDB) + KQL (QuandleDB) + GQL (LithoGlyph)")}),
            div(list{Attrs.class_("text-xs text-gray-600 mt-1")}, list{text("Connects to NQC proxy at :4000")}),
          })
        | PlaySnippets =>
          div(list{Attrs.class_("space-y-3")},
            pg.snippets->Array.map(s =>
              div(list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 hover:border-gray-500 cursor-pointer"), Events.onClick(Playgrounds(LoadSnippet(s.id)))}, list{
                div(list{Attrs.class_("flex justify-between items-center mb-1")}, list{
                  span(list{Attrs.class_("text-sm text-gray-200")}, list{text(s.title)}),
                  span(list{Attrs.class_("text-xs text-gray-500")}, list{text(PlaygroundsEngine.languageLabel(s.language))}),
                }),
                pre(list{Attrs.class_("text-xs text-gray-400 truncate")}, list{text(s.code)}),
              })
            )->List.fromArray,
          )
        | PlayTutorials =>
          div(list{Attrs.class_("text-gray-500 text-sm")}, list{text("Interactive tutorials — coming soon")})
        },
        switch pg.error {
        | Some(e) => div(list{Attrs.class_("mt-4 p-3 bg-red-900/30 border border-red-700 rounded text-sm text-red-300"), Attrs.role("alert")}, list{text(e)})
        | None => noNode
        },
      }),
    },
  )
}
