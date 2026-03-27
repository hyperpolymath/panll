// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Level Architect Component — view for the IDApTIK visual level
/// design tool. Grid editor, asset browser, patrol editor, and level
/// validation with undo/redo.

open Model
open Msg
open Tea.Html

/// Render a category tab button.
let renderTab = (
  label: string,
  cat: levelArchitectCategory,
  active: levelArchitectCategory,
): Tea_Vdom.t<msg> => {
  let isActive = cat === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{Attrs.class_(cls), Events.onClick(LevelArchitect(SetArchitectCategory(cat)))},
    list{text(label)},
  )
}

/// Render tool selector buttons.
let renderToolbar = (state: levelArchitectState): Tea_Vdom.t<msg> => {
  let tools: array<editorTool> = [
    ToolSelect,
    ToolPlace(EntityDevice),
    ToolPlace(EntityGuard),
    ToolPlace(EntitySpawnPoint),
    ToolErase,
    ToolPatrol,
    ToolDefenceFlag,
  ]
  div(
    list{Attrs.class_("flex items-center gap-1 flex-wrap")},
    tools
    ->Array.map(tool => {
      let isActive = state.selectedTool === tool
      let cls = isActive
        ? "px-2 py-1 text-xs bg-cyan-700 text-white rounded"
        : "px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"
      button(
        list{Attrs.class_(cls), Events.onClick(LevelArchitect(SelectTool(tool)))},
        list{text(LevelArchitectEngine.toolLabel(tool))},
      )
    })
    ->List.fromArray,
  )
}

/// Render a single grid cell.
let renderGridCell = (state: levelArchitectState, x: int, y: int): Tea_Vdom.t<msg> => {
  let entity = state.entities->Array.find(e => e.gridX === x && e.gridY === y)
  let isSelected = switch entity {
  | Some(e) => state.selectedEntityId === Some(e.id)
  | None => false
  }
  let bgCls = switch entity {
  | Some(e) =>
    switch e.kind {
    | EntityDevice => "bg-cyan-900/50"
    | EntityGuard => "bg-red-900/50"
    | EntitySpawnPoint => "bg-emerald-900/50"
    | EntityCompanion => "bg-purple-900/50"
    | EntityCollectable => "bg-amber-900/50"
    | EntityTrigger => "bg-orange-900/50"
    | EntityDecoration => "bg-gray-700/50"
    }
  | None => "bg-gray-900/30"
  }
  let borderCls = if isSelected {
    "border-cyan-400"
  } else {
    "border-gray-700"
  }
  div(
    list{
      Attrs.class_(
        `w-8 h-8 border ${borderCls} ${bgCls} flex items-center justify-center cursor-pointer hover:border-gray-500`,
      ),
      Events.onClick(LevelArchitect(ClickGrid(x, y))),
    },
    list{
      switch entity {
      | Some(e) =>
        span(
          list{Attrs.class_("text-xs text-gray-300")},
          list{
            text(
              switch e.kind {
              | EntityDevice => "D"
              | EntityGuard => "G"
              | EntitySpawnPoint => "S"
              | EntityCompanion => "C"
              | EntityCollectable => "$"
              | EntityTrigger => "!"
              | EntityDecoration => "."
              },
            ),
          },
        )
      | None => noNode
      },
    },
  )
}

/// Render the grid editor.
let renderGrid = (state: levelArchitectState): Tea_Vdom.t<msg> => {
  let rows = Array.fromInitializer(~length=state.gridHeight, i => i)
  let cols = Array.fromInitializer(~length=state.gridWidth, i => i)
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Toolbar
      renderToolbar(state),
      // Grid
      div(
        list{Attrs.class_("overflow-auto border border-gray-700 rounded p-2 bg-gray-900")},
        list{
          div(
            list{Attrs.class_("inline-block")},
            rows
            ->Array.map(y =>
              div(
                list{Attrs.class_("flex")},
                cols->Array.map(x => renderGridCell(state, x, y))->List.fromArray,
              )
            )
            ->List.fromArray,
          ),
        },
      ),
      // Entity count summary
      div(
        list{Attrs.class_("flex items-center gap-4 text-xs text-gray-400")},
        list{
          span(list{}, list{text(`Entities: ${Int.toString(Array.length(state.entities))}`)}),
          span(
            list{},
            list{
              text(
                `Guards: ${Int.toString(
                    LevelArchitectEngine.countByKind(state.entities, EntityGuard),
                  )}`,
              ),
            },
          ),
          span(
            list{},
            list{
              text(
                `Devices: ${Int.toString(
                    LevelArchitectEngine.countByKind(state.entities, EntityDevice),
                  )}`,
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Render the asset browser.
let renderAssets = (state: levelArchitectState): Tea_Vdom.t<msg> => {
  if Array.length(state.assets) === 0 {
    div(
      list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
      list{
        text("No assets loaded. "),
        button(
          list{
            Attrs.class_("text-cyan-400 hover:text-cyan-300 underline cursor-pointer"),
            Events.onClick(LevelArchitect(BrowseAssets)),
          },
          list{text("Browse assets")},
        ),
      },
    )
  } else {
    div(
      list{Attrs.class_("grid grid-cols-3 gap-2")},
      state.assets
      ->Array.map(asset =>
        div(
          list{
            Attrs.class_(
              "p-2 bg-gray-800 rounded border border-gray-700 cursor-pointer hover:border-gray-500",
            ),
            Events.onClick(LevelArchitect(SelectTool(ToolPlace(asset.entityKind)))),
          },
          list{
            div(list{Attrs.class_("text-xs text-gray-100 font-medium")}, list{text(asset.name)}),
            div(list{Attrs.class_("text-xs text-gray-500")}, list{text(asset.category)}),
          },
        )
      )
      ->List.fromArray,
    )
  }
}

/// Render patrol paths view.
let renderPatrols = (state: levelArchitectState): Tea_Vdom.t<msg> => {
  if Array.length(state.patrols) === 0 {
    div(
      list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
      list{
        text(
          "No guard patrols defined. Select the Patrol tool and click guard entities to add waypoints.",
        ),
      },
    )
  } else {
    div(
      list{Attrs.class_("space-y-2")},
      state.patrols
      ->Array.map(patrol =>
        div(
          list{Attrs.class_("p-3 bg-gray-800 rounded border border-gray-700")},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between mb-1")},
              list{
                span(
                  list{Attrs.class_("text-sm text-gray-100")},
                  list{text(`Guard: ${patrol.guardId}`)},
                ),
                span(
                  list{Attrs.class_("text-xs text-gray-400")},
                  list{text(`${Int.toString(Array.length(patrol.waypoints))} waypoints`)},
                ),
              },
            ),
            div(
              list{Attrs.class_("text-xs text-gray-500")},
              list{
                text(
                  if patrol.looping {
                    `Speed: ${Float.toString(patrol.speed)} | Looping`
                  } else {
                    `Speed: ${Float.toString(patrol.speed)} | One-way`
                  },
                ),
              },
            ),
          },
        )
      )
      ->List.fromArray,
    )
  }
}

/// Render validation issues.
/// Render a single ABI proof badge (pass/fail indicator).
let renderAbiProofBadge = (name: string, passed: bool): Tea_Vdom.t<msg> => {
  let (dotCls, textCls) = if passed {
    ("bg-emerald-400", "text-emerald-400")
  } else {
    ("bg-red-400", "text-red-400")
  }
  div(
    list{Attrs.class_("flex items-center gap-1.5")},
    list{
      div(list{Attrs.class_(`w-2 h-2 rounded-full ${dotCls}`)}, list{}),
      span(list{Attrs.class_(`text-xs ${textCls}`)}, list{text(name)}),
    },
  )
}

let renderValidation = (state: levelArchitectState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Action bar
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-xs bg-amber-700 text-white rounded hover:bg-amber-600 cursor-pointer",
              ),
              Events.onClick(LevelArchitect(ValidateLevel)),
            },
            list{text("Validate Level")},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-1 text-xs bg-gray-700 text-cyan-400 rounded hover:bg-gray-600 cursor-pointer",
              ),
              Events.onClick(Ums(NavigateToPanel(PanelLevelArchitect))),
            },
            list{text("Open in UMS")},
          ),
        },
      ),
      // UMS ABI Validation (5 Idris2 proofs)
      div(
        list{Attrs.class_("p-3 bg-gray-800 rounded border border-gray-700")},
        list{
          div(
            list{Attrs.class_("text-xs font-medium text-gray-300 mb-2")},
            list{text("Idris2 ABI Proofs (5 cross-domain invariants)")},
          ),
          switch state.umsValidation {
          | Some(v) =>
            div(
              list{Attrs.class_("grid grid-cols-2 lg:grid-cols-3 gap-2")},
              list{
                renderAbiProofBadge("Guards in Zones", v.guardsInZones),
                renderAbiProofBadge("Defence Targets Valid", v.defenceTargetsValid),
                renderAbiProofBadge("Zones Ordered", v.zonesOrdered),
                renderAbiProofBadge("PBX Consistent", v.pbxConsistent),
                renderAbiProofBadge("Devices Exist", v.devicesExist),
                div(
                  list{Attrs.class_("flex items-center gap-1.5")},
                  list{
                    div(
                      list{
                        Attrs.class_(
                          if v.allPassed {
                            "w-2 h-2 rounded-full bg-emerald-400"
                          } else {
                            "w-2 h-2 rounded-full bg-red-400"
                          },
                        ),
                      },
                      list{},
                    ),
                    span(
                      list{
                        Attrs.class_(
                          if v.allPassed {
                            "text-xs font-bold text-emerald-400"
                          } else {
                            "text-xs font-bold text-red-400"
                          },
                        ),
                      },
                      list{
                        text(
                          if v.allPassed {
                            "ALL PASSED"
                          } else {
                            "HAS FAILURES"
                          },
                        ),
                      },
                    ),
                  },
                ),
              },
            )
          | None =>
            div(
              list{Attrs.class_("text-xs text-gray-500")},
              list{text("Not yet validated. Click 'Validate Level' to run ABI proof checks.")},
            )
          },
        },
      ),
      // Classic validation issues
      if Array.length(state.validationIssues) === 0 {
        div(
          list{Attrs.class_("text-center text-emerald-400 text-sm py-4")},
          list{text("No validation issues found")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-1")},
          state.validationIssues
          ->Array.map(issue => {
            let severityCls = switch issue.severity {
            | "error" => "border-red-700 bg-red-900/30"
            | "warning" => "border-amber-700 bg-amber-900/30"
            | _ => "border-blue-700 bg-blue-900/30"
            }
            div(
              list{Attrs.class_(`p-2 rounded border ${severityCls} text-xs`)},
              list{
                span(list{Attrs.class_("text-gray-200")}, list{text(issue.message)}),
                switch issue.entityId {
                | Some(eid) =>
                  span(list{Attrs.class_("text-gray-500 ml-2")}, list{text(`(${eid})`)})
                | None => noNode
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

/// Render defence flags toggles.
let renderDefenceFlags = (state: levelArchitectState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-wrap gap-2 mt-2")},
    LevelArchitectEngine.allDefenceFlags
    ->Array.map(flag => {
      let isActive = state.defenceFlags->Array.includes(flag)
      let cls = if isActive {
        "px-2 py-1 text-xs bg-emerald-700 text-emerald-100 rounded"
      } else {
        "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer hover:bg-gray-600"
      }
      button(
        list{Attrs.class_(cls), Events.onClick(LevelArchitect(ToggleDefenceFlag(flag)))},
        list{text(LevelArchitectEngine.defenceFlagLabel(flag))},
      )
    })
    ->List.fromArray,
  )
}

/// Main view function.
let view = (state: levelArchitectState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Level Architect panel"),
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
                list{text("Level Architect")},
              ),
              span(list{Attrs.class_("text-sm text-gray-400")}, list{text(state.levelName)}),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              // Undo / Redo
              button(
                list{
                  Attrs.class_(
                    if state.historyIndex > 0 {
                      "px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"
                    } else {
                      "px-2 py-1 text-xs bg-gray-800 text-gray-600 rounded cursor-not-allowed"
                    },
                  ),
                  Events.onClick(LevelArchitect(UndoAction)),
                },
                list{text("Undo")},
              ),
              button(
                list{
                  Attrs.class_(
                    if state.historyIndex < Array.length(state.history) - 1 {
                      "px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"
                    } else {
                      "px-2 py-1 text-xs bg-gray-800 text-gray-600 rounded cursor-not-allowed"
                    },
                  ),
                  Events.onClick(LevelArchitect(RedoAction)),
                },
                list{text("Redo")},
              ),
              // Toggle grid lines
              button(
                list{
                  Attrs.class_(
                    if state.showGrid {
                      "px-2 py-1 text-xs bg-cyan-800 text-cyan-200 rounded"
                    } else {
                      "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                    },
                  ),
                  Events.onClick(LevelArchitect(ToggleGrid)),
                },
                list{text("Grid")},
              ),
              // Toggle patrol paths
              button(
                list{
                  Attrs.class_(
                    if state.showPatrolPaths {
                      "px-2 py-1 text-xs bg-purple-800 text-purple-200 rounded"
                    } else {
                      "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                    },
                  ),
                  Events.onClick(LevelArchitect(TogglePatrolPaths)),
                },
                list{text("Patrols")},
              ),
            },
          ),
        },
      ),
      // Category tabs
      div(
        list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          renderTab("Grid", ArchitectGrid, state.activeCategory),
          renderTab("Assets", ArchitectAssets, state.activeCategory),
          renderTab("Patrols", ArchitectPatrols, state.activeCategory),
          renderTab("Validation", ArchitectValidation, state.activeCategory),
        },
      ),
      // Defence flags bar
      div(
        list{Attrs.class_("px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(list{Attrs.class_("text-xs text-gray-400")}, list{text("Defence Flags:")}),
              renderDefenceFlags(state),
            },
          ),
        },
      ),
      // Error banner
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
                    Events.onClick(LevelArchitect(DismissArchitectError)),
                  },
                  list{text("Dismiss")},
                ),
              },
            ),
          },
        )
      | None => noNode
      },
      // Main content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4")},
        list{
          switch state.activeCategory {
          | ArchitectGrid => renderGrid(state)
          | ArchitectAssets => renderAssets(state)
          | ArchitectPatrols => renderPatrols(state)
          | ArchitectValidation => renderValidation(state)
          },
        },
      ),
    },
  )
}
