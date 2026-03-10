// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Script Gist Component — portable computation gist browser and editor.
///
/// Minskian dual-axis design:
///   - Diachronic (time): Scripts as temporal sequences with rollback checkpoints.
///   - Synchronic (space): Schemata as spatial cardfiles — composable boards of gists.
///
/// Gists are saveable, shareable, LLM-callable (MCP tool schema), and user-runnable
/// standalone. The editor supports code, schema definition, and template expansion.

open Model
open Msg
open Tea.Html

/// Render a category tab button.
let renderTab = (
  label: string,
  cat: gistCategory,
  active: gistCategory,
  count: int,
): Tea_Vdom.t<msg> => {
  let isActive = cat === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{Attrs.class_(cls), Events.onClick(ScriptGist(SetGistCategory(cat)))},
    list{text(label ++ " (" ++ Int.toString(count) ++ ")")},
  )
}

/// Render a single gist row in the list.
let renderGistRow = (gist: scriptGist, isSelected: bool): Tea_Vdom.t<msg> => {
  let bgCls = isSelected ? "bg-gray-700 border-cyan-500" : "bg-gray-800/60 border-transparent hover:bg-gray-800"
  div(
    list{
      Attrs.class_("p-3 rounded border " ++ bgCls ++ " cursor-pointer transition-colors"),
      Events.onClick(ScriptGist(SelectGist(Some(gist.id)))),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(
                list{Attrs.class_("text-xs font-medium text-gray-200")},
                list{text(gist.title)},
              ),
              span(
                list{Attrs.class_("text-[10px] px-1.5 py-0.5 rounded " ++ ScriptGistEngine.languageColour(gist.language) ++ " bg-gray-900/60")},
                list{text(ScriptGistEngine.languageLabel(gist.language))},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              if gist.pinned {
                span(list{Attrs.class_("text-amber-400 text-[10px]")}, list{text("pinned")})
              } else {
                noNode
              },
              span(
                list{Attrs.class_("text-[10px] text-gray-600")},
                list{text("v" ++ Int.toString(gist.version))},
              ),
            },
          ),
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-3 text-[10px] text-gray-500")},
        list{
          span(list{}, list{text(ScriptGistEngine.targetLabel(gist.target))}),
          span(list{}, list{text(ScriptGistEngine.visibilityLabel(gist.visibility))}),
          span(list{}, list{text(gist.schema.toolName)}),
          span(list{}, list{text(Int.toString(Array.length(gist.history)) ++ " runs")}),
        },
      ),
    },
  )
}

/// Render the gist editor panel (right side).
let renderEditor = (state: scriptGistState): Tea_Vdom.t<msg> => {
  switch state.selectedGistId {
  | None =>
    div(
      list{Attrs.class_("flex-1 flex items-center justify-center text-gray-600 text-sm")},
      list{text("Select a gist or create a new one")},
    )
  | Some(id) =>
    switch ScriptGistEngine.findGist(state.gists, id) {
    | None =>
      div(
        list{Attrs.class_("flex-1 flex items-center justify-center text-gray-600 text-sm")},
        list{text("Gist not found")},
      )
    | Some(gist) =>
      div(
        list{Attrs.class_("flex-1 flex flex-col gap-3 overflow-y-auto")},
        list{
          // Title input
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              input(
                list{
                  Attrs.class_("flex-1 bg-gray-800 border border-gray-700 rounded px-3 py-1.5 text-sm text-gray-200 focus:border-cyan-500 outline-none"),
                  Attrs.value(gist.title),
                  Events.onInput(v => ScriptGist(UpdateGistTitle(v))),
                  Attrs.placeholder("Gist title"),
                },
                list{},
              ),
              button(
                list{
                  Attrs.class_("px-2 py-1.5 text-xs bg-cyan-700 hover:bg-cyan-600 text-white rounded"),
                  Events.onClick(ScriptGist(ExecuteGist)),
                },
                list{text("Run")},
              ),
              button(
                list{
                  Attrs.class_("px-2 py-1.5 text-xs bg-gray-700 hover:bg-gray-600 text-gray-300 rounded"),
                  Events.onClick(ScriptGist(ToggleGistPin(gist.id))),
                },
                list{text(gist.pinned ? "Unpin" : "Pin")},
              ),
              button(
                list{
                  Attrs.class_("px-2 py-1.5 text-xs bg-gray-700 hover:bg-gray-600 text-gray-300 rounded"),
                  Events.onClick(ScriptGist(SnapshotDiachronic)),
                },
                list{text("Checkpoint")},
              ),
            },
          ),
          // Schema info bar
          div(
            list{Attrs.class_("flex items-center gap-3 text-[10px] text-gray-500 px-1")},
            list{
              span(list{}, list{text("MCP: " ++ gist.schema.toolName)}),
              span(list{}, list{text("~" ++ Int.toString(ScriptGistEngine.schemaTokenCost(gist.schema)) ++ " tokens")}),
              span(list{}, list{text(ScriptGistEngine.languageLabel(gist.language))}),
              span(list{}, list{text(ScriptGistEngine.targetLabel(gist.target))}),
            },
          ),
          // Code editor
          textarea(
            list{
              Attrs.class_("w-full flex-1 min-h-[300px] bg-gray-900 border border-gray-700 rounded p-3 text-xs text-gray-200 font-mono resize-none focus:border-cyan-500 outline-none"),
              Attrs.value(gist.code),
              Events.onInput(v => ScriptGist(UpdateGistCode(v))),
              Attrs.placeholder("// Write your gist code here..."),
            },
            list{},
          ),
          // Last result
          switch state.lastResult {
          | Some(result) =>
            div(
              list{Attrs.class_("p-2 rounded text-xs font-mono " ++ (result.success ? "bg-green-900/30 text-green-400" : "bg-red-900/30 text-red-400"))},
              list{
                div(list{}, list{text(result.success ? "Success" : "Error")}),
                div(list{Attrs.class_("mt-1 text-gray-400")}, list{text(result.output)}),
                div(
                  list{Attrs.class_("mt-1 text-gray-600")},
                  list{text(Float.toString(result.durationMs) ++ "ms | " ++ result.invoker)},
                ),
              },
            )
          | None => noNode
          },
        },
      )
    }
  }
}

/// Render the diachronic timeline sidebar.
let renderDiachronicTimeline = (state: scriptGistState): Tea_Vdom.t<msg> => {
  if Array.length(state.diachronicHistory) === 0 {
    div(
      list{Attrs.class_("text-[10px] text-gray-600 p-2")},
      list{text("No diachronic checkpoints yet. Click 'Checkpoint' to snapshot.")},
    )
  } else {
    div(
      list{Attrs.class_("space-y-1")},
      state.diachronicHistory
      ->Array.map(cp =>
        button(
          list{
            Attrs.class_("w-full text-left px-2 py-1 text-[10px] text-gray-400 hover:bg-gray-800 rounded"),
            Events.onClick(ScriptGist(RestoreDiachronic(cp.index))),
          },
          list{text(cp.label)},
        )
      )
      ->List.fromArray,
    )
  }
}

/// Render the synchronic cardfiles sidebar.
let renderCardfiles = (state: scriptGistState): Tea_Vdom.t<msg> => {
  if Array.length(state.cardfiles) === 0 {
    div(
      list{Attrs.class_("text-[10px] text-gray-600 p-2")},
      list{text("No cardfiles yet. Cardfiles compose gists into spatial arrangements.")},
    )
  } else {
    div(
      list{Attrs.class_("space-y-1")},
      state.cardfiles
      ->Array.map(cf =>
        div(
          list{Attrs.class_("px-2 py-1.5 bg-gray-800/40 rounded text-xs text-gray-400")},
          list{text(ScriptGistEngine.cardfileLabel(cf))},
        )
      )
      ->List.fromArray,
    )
  }
}

/// Render template list.
let renderTemplates = (state: scriptGistState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("grid grid-cols-2 gap-2")},
    state.templates
    ->Array.map(tpl =>
      button(
        list{
          Attrs.class_("p-3 bg-gray-800/60 border border-gray-700 rounded hover:bg-gray-800 text-left transition-colors"),
          Events.onClick(ScriptGist(CreateFromTemplate(tpl.id))),
        },
        list{
          div(
            list{Attrs.class_("text-xs font-medium text-gray-200 mb-1")},
            list{text(tpl.name)},
          ),
          div(
            list{Attrs.class_("text-[10px] text-gray-500")},
            list{text(tpl.description)},
          ),
          div(
            list{Attrs.class_("text-[10px] mt-1 " ++ ScriptGistEngine.languageColour(tpl.language))},
            list{text(ScriptGistEngine.languageLabel(tpl.language))},
          ),
        },
      )
    )
    ->List.fromArray,
  )
}

/// Main panel view.
let view = (state: scriptGistState): Tea_Vdom.t<msg> => {
  let filtered = state.gists
    ->ScriptGistEngine.filterByCategory(state.activeCategory)
    ->ScriptGistEngine.filterBySearch(state.filterText)
    ->ScriptGistEngine.sortGists(state.sortBy)

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden")},
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(list{Attrs.class_("text-sm font-medium text-gray-200")}, list{text("Script Gist")}),
              span(list{Attrs.class_("text-[10px] text-gray-600")}, list{text("Minskian Drafting Board")}),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              button(
                list{
                  Attrs.class_("px-2 py-1 text-xs bg-cyan-700 hover:bg-cyan-600 text-white rounded"),
                  Events.onClick(ScriptGist(CreateGist)),
                },
                list{text("+ New Gist")},
              ),
              button(
                list{
                  Attrs.class_("px-2 py-1 text-xs rounded " ++ (state.mcpToolsActive ? "bg-green-700 text-white" : "bg-gray-700 text-gray-400 hover:bg-gray-600")),
                  Events.onClick(ScriptGist(ToggleMcpTools)),
                },
                list{text("MCP " ++ (state.mcpToolsActive ? "ON" : "OFF"))},
              ),
            },
          ),
        },
      ),
      // Category tabs
      div(
        list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-800/50")},
        ScriptGistEngine.allCategories
        ->Array.map(cat =>
          renderTab(ScriptGistEngine.categoryLabel(cat), cat, state.activeCategory, ScriptGistEngine.countByCategory(state.gists, cat))
        )
        ->List.fromArray,
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("mx-4 mt-2 p-2 bg-red-900/30 border border-red-800 rounded text-xs text-red-400 flex justify-between")},
          list{
            span(list{}, list{text(err)}),
            button(
              list{Attrs.class_("text-red-500 hover:text-red-300"), Events.onClick(ScriptGist(DismissGistError))},
              list{text("dismiss")},
            ),
          },
        )
      | None => noNode
      },
      // Main content area
      div(
        list{Attrs.class_("flex flex-1 overflow-hidden")},
        list{
          // Left sidebar: gist list + filter
          div(
            list{Attrs.class_("w-64 border-r border-gray-800 flex flex-col overflow-hidden")},
            list{
              // Search
              div(
                list{Attrs.class_("p-2")},
                list{
                  input(
                    list{
                      Attrs.class_("w-full bg-gray-800 border border-gray-700 rounded px-2 py-1 text-xs text-gray-300 placeholder-gray-600 outline-none focus:border-cyan-600"),
                      Attrs.value(state.filterText),
                      Events.onInput(v => ScriptGist(SetGistFilter(v))),
                      Attrs.placeholder("Search gists..."),
                    },
                    list{},
                  ),
                },
              ),
              // Gist list or templates
              div(
                list{Attrs.class_("flex-1 overflow-y-auto p-2 space-y-1")},
                if state.activeCategory === GistTemplates {
                  list{renderTemplates(state)}
                } else {
                  filtered->Array.map(g => renderGistRow(g, Some(g.id) === state.selectedGistId))->List.fromArray
                },
              ),
            },
          ),
          // Centre: editor
          div(
            list{Attrs.class_("flex-1 flex flex-col p-3 overflow-hidden")},
            list{renderEditor(state)},
          ),
          // Right sidebar: diachronic timeline + synchronic cardfiles
          div(
            list{Attrs.class_("w-48 border-l border-gray-800 flex flex-col overflow-hidden")},
            list{
              div(
                list{Attrs.class_("p-2 border-b border-gray-800/50")},
                list{span(list{Attrs.class_("text-[10px] text-gray-500 uppercase tracking-wide")}, list{text("Diachronic (Time)")})},
              ),
              div(
                list{Attrs.class_("flex-1 overflow-y-auto p-1")},
                list{renderDiachronicTimeline(state)},
              ),
              div(
                list{Attrs.class_("p-2 border-t border-gray-800/50 border-b border-gray-800/50")},
                list{span(list{Attrs.class_("text-[10px] text-gray-500 uppercase tracking-wide")}, list{text("Synchronic (Space)")})},
              ),
              div(
                list{Attrs.class_("flex-1 overflow-y-auto p-1")},
                list{renderCardfiles(state)},
              ),
            },
          ),
        },
      ),
    },
  )
}
