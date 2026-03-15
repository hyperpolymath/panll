// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Architect Mode Component — PixiJS fine-grained level editor.
/// Displays tool palette, canvas placeholder, property inspector for
/// selected entities, AI suggestion list, and undo/redo buttons.

open Model
open Msg
open Tea.Html

/// Render a tool label from architectEditorTool.
let toolLabel = (tool: architectEditorTool): string => {
  switch tool {
  | SelectTool => "Select"
  | PlaceTool(_) => "Place"
  | EraseTool => "Erase"
  | WireTool => "Wire"
  | ZoneTool => "Zone"
  | PanTool => "Pan"
  }
}

/// Render a tool palette button.
let toolButton = (currentTool: architectEditorTool, tool: architectEditorTool, label: string): Tea_Vdom.t<msg> => {
  let isActive = toolLabel(currentTool) == toolLabel(tool)
  button(
    list{
      Attrs.class_(
        "px-3 py-1.5 text-xs rounded border " ++
        if isActive { "bg-fuchsia-700 border-fuchsia-600 text-white" } else { "bg-gray-800 border-gray-700 text-gray-400 hover:text-gray-200" },
      ),
    },
    list{text(label)},
  )
}

/// Main view function for the Architect Mode panel.
let view = (state: architectModeState): Tea_Vdom.t<msg> => {
  let entityCount = Array.length(state.entities)
  let zoneCount = Array.length(state.zones)
  let undoCount = Array.length(state.undoStack)
  let redoCount = Array.length(state.redoStack)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Architect Mode — PixiJS Level Editor"),
    },
    list{
      // Header row
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-bold text-fuchsia-300")}, list{text("Architect Mode")}),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{text(Int.toString(entityCount) ++ " entities, " ++ Int.toString(zoneCount) ++ " zones")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("Zoom: " ++ Float.toFixed(state.zoom, ~digits=1) ++ "x")},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-2 py-1 text-xs rounded " ++
                    if undoCount > 0 { "bg-gray-700 text-gray-200 hover:bg-gray-600" } else { "bg-gray-800 text-gray-600 cursor-not-allowed" },
                  ),
                },
                list{text("Undo (" ++ Int.toString(undoCount) ++ ")")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-2 py-1 text-xs rounded " ++
                    if redoCount > 0 { "bg-gray-700 text-gray-200 hover:bg-gray-600" } else { "bg-gray-800 text-gray-600 cursor-not-allowed" },
                  ),
                },
                list{text("Redo (" ++ Int.toString(redoCount) ++ ")")},
              ),
            },
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
                if state.activeTab == Canvas { "bg-fuchsia-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(ArchitectMode(SetArchModeCategory(Canvas))),
            },
            list{text("Canvas")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Properties { "bg-fuchsia-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(ArchitectMode(SetArchModeCategory(Properties))),
            },
            list{text("Properties")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == AiSuggestions { "bg-fuchsia-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(ArchitectMode(SetArchModeCategory(AiSuggestions))),
            },
            list{text("AI Suggestions")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++
                if state.activeTab == Validation { "bg-fuchsia-700 text-white" } else { "bg-gray-800 text-gray-400 hover:text-gray-200" },
              ),
              Events.onClick(ArchitectMode(SetArchModeCategory(Validation))),
            },
            list{text("Validation")},
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
              list{Attrs.class_("text-red-400 hover:text-red-200 text-xs ml-2"), Events.onClick(ArchitectMode(DismissArchModeError))},
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
          | Canvas =>
            div(
              list{Attrs.class_("space-y-3")},
              list{
                // Tool palette
                div(
                  list{Attrs.class_("flex gap-2 flex-wrap")},
                  list{
                    toolButton(state.selectedTool, SelectTool, "Select"),
                    toolButton(state.selectedTool, PlaceTool(""), "Place"),
                    toolButton(state.selectedTool, EraseTool, "Erase"),
                    toolButton(state.selectedTool, WireTool, "Wire"),
                    toolButton(state.selectedTool, ZoneTool, "Zone"),
                    toolButton(state.selectedTool, PanTool, "Pan"),
                  },
                ),
                // Canvas placeholder
                div(
                  list{Attrs.class_("w-full h-64 bg-gray-900 border border-gray-800 rounded flex items-center justify-center")},
                  list{
                    span(
                      list{Attrs.class_("text-gray-600 text-sm")},
                      list{text("PixiJS canvas — " ++ Int.toString(entityCount) ++ " entities, " ++ Int.toString(zoneCount) ++ " zones")},
                    ),
                  },
                ),
                // Grid controls
                div(
                  list{Attrs.class_("flex gap-4 text-xs text-gray-400")},
                  list{
                    span(list{}, list{text("Grid: " ++ if state.gridVisible { "visible" } else { "hidden" })}),
                    span(list{}, list{text("Snap: " ++ if state.snapToGrid { "on" } else { "off" })}),
                    span(list{}, list{text("Cell: " ++ Int.toString(state.gridSize) ++ "px")}),
                  },
                ),
              },
            )
          | Properties =>
            switch state.selectedEntityId {
            | Some(eid) =>
              switch state.entities->Array.find(e => e.id == eid) {
              | Some(entity) =>
                div(
                  list{Attrs.class_("space-y-3")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-2 mb-2")},
                      list{
                        span(list{Attrs.class_("text-sm font-bold text-fuchsia-300")}, list{text(entity.kind)}),
                        span(list{Attrs.class_("text-xs text-gray-500 font-mono")}, list{text(entity.id)}),
                      },
                    ),
                    div(
                      list{Attrs.class_("grid grid-cols-2 gap-2 text-xs")},
                      list{
                        span(list{Attrs.class_("text-gray-400")}, list{text("X:")}),
                        span(list{Attrs.class_("text-gray-200 font-mono")}, list{text(Float.toFixed(entity.x, ~digits=1))}),
                        span(list{Attrs.class_("text-gray-400")}, list{text("Y:")}),
                        span(list{Attrs.class_("text-gray-200 font-mono")}, list{text(Float.toFixed(entity.y, ~digits=1))}),
                        span(list{Attrs.class_("text-gray-400")}, list{text("Rotation:")}),
                        span(list{Attrs.class_("text-gray-200 font-mono")}, list{text(Float.toFixed(entity.rotation, ~digits=0) ++ " deg")}),
                      },
                    ),
                  },
                )
              | None =>
                div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Entity not found: " ++ eid)})
              }
            | None =>
              div(
                list{Attrs.class_("text-center text-gray-500 py-8")},
                list{text("Select an entity on the canvas to inspect its properties.")},
              )
            }
          | AiSuggestions =>
            div(
              list{Attrs.class_("space-y-2")},
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-400 mb-2")},
                  list{text(Int.toString(Array.length(state.aiSuggestions)) ++ " AI suggestions")},
                ),
                div(
                  list{},
                  state.aiSuggestions
                  ->Array.map(s =>
                    div(
                      list{
                        Attrs.class_(
                          "px-3 py-2 mb-2 border rounded " ++
                          if s.applied { "bg-green-900/20 border-green-800" } else { "bg-gray-900 border-gray-800" },
                        ),
                      },
                      list{
                        div(
                          list{Attrs.class_("flex items-center justify-between")},
                          list{
                            span(list{Attrs.class_("text-sm text-gray-200")}, list{text(s.description)}),
                            span(
                              list{Attrs.class_("text-xs font-mono text-fuchsia-400")},
                              list{text(Float.toFixed(s.confidence *. 100.0, ~digits=0) ++ "%")},
                            ),
                          },
                        ),
                        div(
                          list{Attrs.class_("text-xs text-gray-500 mt-1")},
                          list{text(Int.toString(Array.length(s.entities)) ++ " entities suggested")},
                        ),
                        if s.applied {
                          span(list{Attrs.class_("text-xs text-green-400 mt-1")}, list{text("Applied")})
                        } else {
                          button(
                            list{Attrs.class_("text-xs text-fuchsia-400 hover:text-fuchsia-300 mt-1")},
                            list{text("Apply")},
                          )
                        },
                      },
                    )
                  )
                  ->List.fromArray,
                ),
              },
            )
          | Validation =>
            div(
              list{Attrs.class_("space-y-3")},
              list{
                // Entity list for validation
                div(
                  list{Attrs.class_("text-xs text-gray-400 mb-2")},
                  list{
                    text(
                      Int.toString(entityCount) ++ " entities, " ++
                      Int.toString(zoneCount) ++ " zones on canvas",
                    ),
                  },
                ),
                // Show entities without zones
                div(
                  list{Attrs.class_("space-y-1")},
                  state.entities
                  ->Array.filter(e => e.selected)
                  ->Array.map(e =>
                    div(
                      list{Attrs.class_("flex items-center gap-2 text-xs px-2 py-1 bg-gray-900 rounded")},
                      list{
                        span(list{Attrs.class_("text-fuchsia-300")}, list{text(e.kind)}),
                        span(list{Attrs.class_("text-gray-500 font-mono")}, list{text("(" ++ Float.toFixed(e.x, ~digits=0) ++ ", " ++ Float.toFixed(e.y, ~digits=0) ++ ")")}),
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
