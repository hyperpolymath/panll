// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Databases Component — unified database management panel.
///
/// Manages VeriSimDB, QuandleDB, and LithoGlyph in a single view with:
///   - Multi-module connection dashboard with health cards
///   - Unified query console with per-module language switching
///   - Schema browser with entity detail drill-down
///   - Cross-modal drift heatmap with normalisation controls
///   - Opt-in telemetry dashboard with aggregate metrics
///   - TypeLL cross-panel type intelligence for query validation
///
/// 5 tabs: Dashboard, Query, Schema, Drift, Telemetry.
/// All views use Tea_Html (no JSX). Accessible with ARIA roles and labels.

open Msg
open DatabasesModel
open DatabasesEngine
open DatabaseModule
open Tea.Html

// ===========================================================================
// TypeLL Cross-Panel Type Intelligence
// ===========================================================================

/// Render TypeLL cross-panel type intelligence result (if available).
let viewTypeCheckResult = (lastTypeCheck: option<string>): Tea_Vdom.t<msg> => {
  switch lastTypeCheck {
  | None => noNode
  | Some(json) =>
    switch TypeLLEngine.parseCheckResult(json) {
    | Error(_) => noNode
    | Ok(result) =>
      let narrative = TypeLLEngine.generateNarrative(result)
      let borderColour = if result.valid {
        "border-green-700 bg-green-900/20"
      } else {
        "border-red-700 bg-red-900/20"
      }
      let labelColour = if result.valid {
        "text-green-400"
      } else {
        "text-red-400"
      }
      let statusText = if result.valid {
        "Type-safe"
      } else {
        "Type issues detected"
      }
      div(
        list{Attrs.class_("mt-4 p-3 rounded-lg border " ++ borderColour)},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2 mb-2")},
            list{
              span(
                list{Attrs.class_("text-xs font-bold uppercase tracking-wider " ++ labelColour)},
                list{text("TypeLL")},
              ),
              span(list{Attrs.class_("text-xs text-gray-400")}, list{text(statusText)}),
            },
          ),
          div(
            list{Attrs.class_("text-sm text-gray-300 font-mono mb-1")},
            list{text(result.typeSignature)},
          ),
          div(list{Attrs.class_("text-xs text-gray-400 mb-1")}, list{text(narrative.celebrate)}),
          if Array.length(result.proofObligations) > 0 {
            div(
              list{Attrs.class_("text-xs text-yellow-400 mt-1")},
              list{text("Proof obligations: " ++ Array.join(result.proofObligations, ", "))},
            )
          } else {
            noNode
          },
          if Array.length(result.linearityIssues) > 0 {
            div(
              list{Attrs.class_("text-xs text-orange-400 mt-1")},
              list{text("Linearity: " ++ Array.join(result.linearityIssues, ", "))},
            )
          } else {
            noNode
          },
        },
      )
    }
  }
}

// ===========================================================================
// Shared Components
// ===========================================================================

/// Render a tab button.
let renderTab = (label: string, active: bool, onClick: msg): Tea_Vdom.t<msg> => {
  let baseClass = "px-3 py-1.5 text-xs rounded-t border-b-2 transition-colors"
  let activeClass = active
    ? `${baseClass} text-emerald-300 border-emerald-400 bg-gray-800`
    : `${baseClass} text-gray-500 border-transparent hover:text-gray-300`
  button(
    list{
      Attrs.class_(activeClass),
      Events.onClick(onClick),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Render a stat card.
let renderStat = (label: string, value: string, colour: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("bg-gray-800/50 border border-gray-700 rounded p-3")},
    list{
      div(list{Attrs.class_(`text-lg font-bold ${colour}`)}, list{text(value)}),
      div(list{Attrs.class_("text-xs text-gray-500 mt-1")}, list{text(label)}),
    },
  )
}

/// Render a module selector pill.
let renderModulePill = (
  config: moduleConfig,
  selected: bool,
  connStatus: connectionStatus,
): Tea_Vdom.t<msg> => {
  let accent = moduleAccent(config.id)
  let bg = if selected {
    "bg-gray-700"
  } else {
    "bg-transparent hover:bg-gray-800"
  }
  let border = if selected {
    `border`
  } else {
    "border border-transparent"
  }
  button(
    list{
      Attrs.class_(
        `flex items-center gap-2 px-3 py-2 rounded-lg ${bg} ${border} transition-colors`,
      ),
      Attrs.style(
        "border-color",
        if selected {
          accent
        } else {
          "transparent"
        },
      ),
      Events.onClick(Databases(SelectModule(config.id))),
      Attrs.ariaLabel(`Select ${config.name} database`),
    },
    list{
      // Connection status dot
      div(
        list{Attrs.class_(`w-2 h-2 rounded-full flex-shrink-0 ${connectionColour(connStatus)}`)},
        list{},
      ),
      // Module icon
      span(
        list{
          Attrs.class_("text-xs font-bold px-1.5 py-0.5 rounded"),
          Attrs.style("background-color", accent ++ "20"),
          Attrs.style("color", accent),
        },
        list{text(moduleIcon(config.id))},
      ),
      // Module name
      span(list{Attrs.class_("text-sm text-gray-200")}, list{text(config.name)}),
      // Version badge
      span(list{Attrs.class_("text-[10px] text-gray-600")}, list{text("v" ++ config.version)}),
    },
  )
}

// ===========================================================================
// Dashboard Tab
// ===========================================================================

/// Render capability badge.
let renderCapabilityBadge = (cap: capability, supported: bool): Tea_Vdom.t<msg> => {
  let colour = if supported {
    "text-emerald-400 bg-emerald-900/30 border-emerald-700"
  } else {
    "text-gray-600 bg-gray-900/30 border-gray-800"
  }
  span(
    list{Attrs.class_(`text-[10px] px-2 py-0.5 rounded-full border ${colour}`)},
    list{text(capabilityLabel(cap))},
  )
}

/// Render the capability matrix row for a module.
let renderModuleRow = (ms: moduleState): Tea_Vdom.t<msg> => {
  let allCaps = [
    QueryExecution,
    DriftDetection,
    ProofGeneration,
    Normalisation,
    Federation,
    Telemetry,
    Playground,
  ]
  let accent = moduleAccent(ms.config.id)
  div(
    list{Attrs.class_("flex items-center gap-3 py-2 border-b border-gray-800")},
    list{
      // Module badge
      div(
        list{Attrs.class_("w-24 flex-shrink-0")},
        list{
          span(
            list{
              Attrs.class_("text-xs font-bold px-2 py-0.5 rounded"),
              Attrs.style("background-color", accent ++ "20"),
              Attrs.style("color", accent),
            },
            list{text(ms.config.name)},
          ),
        },
      ),
      // Connection
      div(
        list{Attrs.class_("w-28 flex-shrink-0 flex items-center gap-1.5")},
        list{
          div(
            list{Attrs.class_(`w-2 h-2 rounded-full ${connectionColour(ms.connection)}`)},
            list{},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-400 truncate")},
            list{
              text(
                switch ms.connection {
                | Disconnected => "Offline"
                | Connecting => "Connecting"
                | Connected(_) => "Online"
                | Error(_) => "Error"
                },
              ),
            },
          ),
        },
      ),
      // Capabilities
      div(
        list{Attrs.class_("flex flex-wrap gap-1")},
        allCaps
        ->Array.map(cap => renderCapabilityBadge(cap, hasCapability(ms.config, cap)))
        ->List.fromArray,
      ),
    },
  )
}

/// Render the Dashboard tab.
let viewDashboard = (state: databasesState): Tea_Vdom.t<msg> => {
  let connected = connectedCount(state)
  let total = Array.length(state.modules)
  let caps = totalCapabilities(state)
  let historyCount = Array.length(state.queryHistory)

  div(
    list{Attrs.class_("space-y-6")},
    list{
      // Health summary cards
      div(
        list{Attrs.class_("grid grid-cols-4 gap-4")},
        list{
          renderStat("Modules", Int.toString(total), "text-emerald-400"),
          renderStat(
            "Connected",
            `${Int.toString(connected)}/${Int.toString(total)}`,
            if connected == total {
              "text-emerald-400"
            } else {
              "text-amber-400"
            },
          ),
          renderStat("Capabilities", Int.toString(caps), "text-indigo-400"),
          renderStat("Queries Run", Int.toString(historyCount), "text-cyan-400"),
        },
      ),
      // Module capability matrix
      div(
        list{Attrs.class_("bg-gray-900/50 border border-gray-800 rounded-lg p-4")},
        list{
          div(
            list{Attrs.class_("text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3")},
            list{text("Module Capability Matrix")},
          ),
          div(
            list{Attrs.class_("space-y-1")},
            state.modules->Array.map(renderModuleRow)->List.fromArray,
          ),
        },
      ),
      // Action bar
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-emerald-700 hover:bg-emerald-600 text-white text-xs rounded transition-colors",
              ),
              Events.onClick(Databases(ConnectAll)),
              Attrs.ariaLabel("Connect to all database modules"),
            },
            list{text("Connect All")},
          ),
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white text-xs rounded transition-colors",
              ),
              Events.onClick(Databases(RefreshHealth)),
              Attrs.ariaLabel("Refresh database health"),
            },
            list{text("Refresh Health")},
          ),
          // BoJ routing toggle
          div(
            list{Attrs.class_("flex items-center gap-2 ml-auto")},
            list{
              span(list{Attrs.class_("text-xs text-gray-500")}, list{text("BoJ Routing")}),
              button(
                list{
                  Attrs.class_(
                    if state.bojRouting {
                      "w-8 h-4 rounded-full bg-emerald-600 relative transition-colors"
                    } else {
                      "w-8 h-4 rounded-full bg-gray-700 relative transition-colors"
                    },
                  ),
                  Events.onClick(Databases(ToggleBojRouting)),
                  Attrs.ariaLabel("Toggle BoJ cartridge routing"),
                },
                list{
                  div(
                    list{
                      Attrs.class_(
                        `w-3 h-3 rounded-full bg-white absolute top-0.5 transition-transform ${if (
                            state.bojRouting
                          ) {
                            "translate-x-4"
                          } else {
                            "translate-x-0.5"
                          }}`,
                      ),
                    },
                    list{},
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Recent query history
      if historyCount > 0 {
        div(
          list{Attrs.class_("bg-gray-900/50 border border-gray-800 rounded-lg p-4")},
          list{
            div(
              list{
                Attrs.class_("text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3"),
              },
              list{text("Recent Queries")},
            ),
            div(
              list{Attrs.class_("space-y-1 max-h-48 overflow-y-auto")},
              state.queryHistory
              ->Array.slice(~start=0, ~end=10)
              ->Array.map(entry => {
                let statusColour = if entry.success {
                  "text-emerald-400"
                } else {
                  "text-red-400"
                }
                let moduleBadge = moduleAccent(entry.moduleId)
                div(
                  list{
                    Attrs.class_(
                      "flex items-center gap-2 py-1.5 border-b border-gray-800/50 text-xs",
                    ),
                  },
                  list{
                    span(
                      list{
                        Attrs.class_("px-1.5 py-0.5 rounded font-mono"),
                        Attrs.style("background-color", moduleBadge ++ "20"),
                        Attrs.style("color", moduleBadge),
                      },
                      list{text(moduleIcon(entry.moduleId))},
                    ),
                    span(
                      list{Attrs.class_("text-gray-300 font-mono truncate flex-1")},
                      list{text(entry.query)},
                    ),
                    span(
                      list{Attrs.class_(statusColour)},
                      list{
                        text(
                          if entry.success {
                            "OK"
                          } else {
                            "ERR"
                          },
                        ),
                      },
                    ),
                    span(
                      list{Attrs.class_("text-gray-600")},
                      list{text(Float.toString(entry.durationMs) ++ "ms")},
                    ),
                    span(
                      list{Attrs.class_("text-gray-600")},
                      list{text(Int.toString(entry.rowCount) ++ " rows")},
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
}

// ===========================================================================
// Query Console Tab
// ===========================================================================

/// Render the query console for the selected module.
let viewQuery = (state: databasesState): Tea_Vdom.t<msg> => {
  let currentModule = selectedModuleState(state)
  let playground = currentModule->Option.flatMap(m => m.config.playground)
  let langName = playground->Option.map(p => p.languageName)->Option.getOr("SQL")

  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Module selector ribbon
      div(
        list{Attrs.class_("flex items-center gap-2 border-b border-gray-800 pb-3")},
        state.modules
        ->Array.map(m =>
          renderModulePill(m.config, m.config.id == state.selectedModule, m.connection)
        )
        ->List.fromArray,
      ),
      // Query editor
      div(
        list{Attrs.class_("bg-gray-900/50 border border-gray-800 rounded-lg p-4")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2 mb-2")},
            list{
              span(
                list{Attrs.class_("text-xs font-semibold text-gray-400 uppercase tracking-wider")},
                list{text(langName ++ " Editor")},
              ),
              // Example query buttons
              switch playground {
              | Some(pg) =>
                div(
                  list{Attrs.class_("flex gap-1 ml-auto")},
                  pg.exampleQueries
                  ->Array.slice(~start=0, ~end=4)
                  ->Array.map(eq =>
                    button(
                      list{
                        Attrs.class_(
                          "text-[10px] px-2 py-0.5 bg-gray-800 hover:bg-gray-700 text-gray-400 rounded transition-colors",
                        ),
                        Events.onClick(Databases(LoadExampleQuery(eq.query))),
                        Attrs.title(eq.query),
                      },
                      list{
                        text(eq.label),
                        if eq.isDependentType {
                          span(list{Attrs.class_("text-yellow-500 ml-0.5")}, list{text("DT")})
                        } else {
                          noNode
                        },
                      },
                    )
                  )
                  ->List.fromArray,
                )
              | None => noNode
              },
            },
          ),
          // Textarea
          textarea(
            list{
              Attrs.class_(
                "w-full h-32 bg-gray-950 text-gray-200 text-sm font-mono p-3 rounded border border-gray-700 focus:border-emerald-600 focus:outline-none resize-y",
              ),
              Attrs.value(state.queryInput),
              Attrs.placeholder(`Enter ${langName} query...`),
              Events.onInput(value => Databases(SetQueryInput(value))),
              Attrs.ariaLabel(`${langName} query input`),
              Attrs.spellCheck(false),
            },
            list{},
          ),
          // Execute bar
          div(
            list{Attrs.class_("flex items-center gap-3 mt-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    if state.queryLoading {
                      "px-4 py-2 bg-gray-600 text-gray-400 text-xs rounded cursor-not-allowed"
                    } else {
                      "px-4 py-2 bg-emerald-700 hover:bg-emerald-600 text-white text-xs rounded transition-colors"
                    },
                  ),
                  Events.onClick(Databases(ExecuteQuery)),
                  Attrs.disabled(state.queryLoading || state.queryInput == ""),
                  Attrs.ariaLabel("Execute query"),
                },
                list{
                  text(
                    if state.queryLoading {
                      "Executing..."
                    } else {
                      "Execute"
                    },
                  ),
                },
              ),
              button(
                list{
                  Attrs.class_(
                    "px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white text-xs rounded transition-colors",
                  ),
                  Events.onClick(Databases(ClearQuery)),
                  Attrs.ariaLabel("Clear query"),
                },
                list{text("Clear")},
              ),
              // Language features
              switch playground {
              | Some(pg) =>
                div(
                  list{Attrs.class_("flex items-center gap-2 ml-auto text-[10px] text-gray-600")},
                  list{
                    if pg.linterAvailable {
                      span(list{Attrs.class_("text-emerald-600")}, list{text("Linter")})
                    } else {
                      noNode
                    },
                    if pg.formatterAvailable {
                      span(list{Attrs.class_("text-emerald-600")}, list{text("Formatter")})
                    } else {
                      noNode
                    },
                    if pg.hasDependentTypes {
                      span(
                        list{Attrs.class_("text-yellow-600")},
                        list{text(pg.languageName ++ "-DT")},
                      )
                    } else {
                      noNode
                    },
                  },
                )
              | None => noNode
              },
            },
          ),
        },
      ),
      // Query result
      switch currentModule {
      | Some(ms) =>
        switch ms.queryResult {
        | Some(result) =>
          div(
            list{Attrs.class_("bg-gray-900/50 border border-gray-800 rounded-lg p-4")},
            list{
              div(
                list{Attrs.class_("flex items-center gap-2 mb-3")},
                list{
                  span(
                    list{Attrs.class_("text-xs font-semibold text-emerald-400")},
                    list{text("Result")},
                  ),
                  span(
                    list{Attrs.class_("text-xs text-gray-500")},
                    list{
                      text(
                        `${Int.toString(result.rowCount)} rows in ${Float.toString(
                            result.timingMs,
                          )}ms`,
                      ),
                    },
                  ),
                  span(
                    list{Attrs.class_("text-[10px] text-gray-600 ml-auto")},
                    list{text(result.statementType)},
                  ),
                },
              ),
              // Column headers
              if Array.length(result.columns) > 0 {
                div(
                  list{Attrs.class_("overflow-x-auto")},
                  list{
                    table(
                      list{Attrs.class_("w-full text-xs"), Attrs.role("grid")},
                      list{
                        thead(
                          list{},
                          list{
                            tr(
                              list{Attrs.class_("border-b border-gray-700")},
                              result.columns
                              ->Array.map(col =>
                                th(
                                  list{
                                    Attrs.class_(
                                      "text-left py-1.5 px-2 text-gray-400 font-semibold",
                                    ),
                                  },
                                  list{text(col)},
                                )
                              )
                              ->List.fromArray,
                            ),
                          },
                        ),
                        tbody(
                          list{},
                          result.rows
                          ->Array.map(row =>
                            tr(
                              list{
                                Attrs.class_("border-b border-gray-800/50 hover:bg-gray-800/30"),
                              },
                              row
                              ->Array.map(cell =>
                                td(
                                  list{Attrs.class_("py-1.5 px-2 text-gray-300 font-mono")},
                                  list{text(cell)},
                                )
                              )
                              ->List.fromArray,
                            )
                          )
                          ->List.fromArray,
                        ),
                      },
                    ),
                  },
                )
              } else {
                switch result.message {
                | Some(msg) => div(list{Attrs.class_("text-xs text-gray-400")}, list{text(msg)})
                | None => noNode
                }
              },
            },
          )
        | None =>
          switch ms.queryError {
          | Some(err) =>
            div(
              list{Attrs.class_("bg-red-900/20 border border-red-700 rounded-lg p-4")},
              list{
                div(
                  list{Attrs.class_("text-xs font-semibold text-red-400 mb-1")},
                  list{text("Query Error")},
                ),
                div(list{Attrs.class_("text-xs text-red-300 font-mono")}, list{text(err)}),
              },
            )
          | None => noNode
          }
        }
      | None => noNode
      },
      // TypeLL result
      viewTypeCheckResult(state.lastTypeCheck),
    },
  )
}

// ===========================================================================
// Schema Browser Tab
// ===========================================================================

/// Render entity detail panel.
let viewEntityDetail = (state: databasesState): Tea_Vdom.t<msg> => {
  switch state.selectedEntity {
  | None =>
    div(
      list{Attrs.class_("text-xs text-gray-600 text-center py-8")},
      list{text("Select an entity to view details")},
    )
  | Some(entityName) =>
    let entity = state.schemaEntities->Array.find(e => e.name == entityName)
    switch entity {
    | None => noNode
    | Some(e) =>
      div(
        list{Attrs.class_("bg-gray-900/50 border border-gray-800 rounded-lg p-4")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2 mb-3")},
            list{
              span(list{Attrs.class_("text-sm font-bold text-gray-200")}, list{text(e.name)}),
              span(
                list{
                  Attrs.class_("text-[10px] px-2 py-0.5 bg-gray-800 text-gray-500 rounded-full"),
                },
                list{text(e.kind)},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-600 ml-auto")},
                list{text(Int.toString(e.entryCount) ++ " entries")},
              ),
            },
          ),
          // Fields
          div(
            list{Attrs.class_("space-y-1")},
            list{
              div(
                list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-1")},
                list{text("Fields")},
              ),
              div(
                list{Attrs.class_("flex flex-wrap gap-1")},
                e.fields
                ->Array.map(field =>
                  span(
                    list{
                      Attrs.class_(
                        "text-xs font-mono px-2 py-0.5 bg-gray-800 text-gray-300 rounded border border-gray-700",
                      ),
                    },
                    list{text(field)},
                  )
                )
                ->List.fromArray,
              ),
            },
          ),
          // Entity detail JSON (if loaded)
          switch state.entityDetail {
          | Some(detail) =>
            div(
              list{Attrs.class_("mt-3")},
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wider mb-1")},
                  list{text("Detail")},
                ),
                pre(
                  list{
                    Attrs.class_(
                      "text-xs text-gray-300 font-mono bg-gray-950 p-3 rounded overflow-x-auto max-h-48 overflow-y-auto",
                    ),
                  },
                  list{text(detail)},
                ),
              },
            )
          | None => noNode
          },
          // Actions
          div(
            list{Attrs.class_("flex gap-2 mt-3")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-xs text-white rounded transition-colors",
                  ),
                  Events.onClick(Databases(LoadEntityDetail(entityName))),
                },
                list{text("Load Detail")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-xs text-white rounded transition-colors",
                  ),
                  Events.onClick(
                    Databases(LoadExampleQuery("SELECT * FROM " ++ entityName ++ " LIMIT 10")),
                  ),
                },
                list{text("Query This")},
              ),
            },
          ),
        },
      )
    }
  }
}

/// Render the Schema Browser tab.
let viewSchema = (state: databasesState): Tea_Vdom.t<msg> => {
  let entities = filteredEntities(state)

  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Module selector
      div(
        list{Attrs.class_("flex items-center gap-2 border-b border-gray-800 pb-3")},
        state.modules
        ->Array.map(m =>
          renderModulePill(m.config, m.config.id == state.selectedModule, m.connection)
        )
        ->List.fromArray,
      ),
      // Filter
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 bg-gray-900 text-gray-200 text-sm px-3 py-2 rounded border border-gray-700 focus:border-emerald-600 focus:outline-none",
              ),
              Attrs.placeholder("Filter entities..."),
              Attrs.value(state.filterText),
              Events.onInput(value => Databases(SetFilter(value))),
              Attrs.ariaLabel("Filter schema entities"),
            },
            list{},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-600")},
            list{text(`${Int.toString(Array.length(entities))} entities`)},
          ),
        },
      ),
      // Two-column: entity list + detail
      div(
        list{Attrs.class_("grid grid-cols-2 gap-4")},
        list{
          // Entity list
          div(
            list{Attrs.class_("space-y-1 max-h-96 overflow-y-auto")},
            entities
            ->Array.map(entity => {
              let isSelected = state.selectedEntity == Some(entity.name)
              button(
                list{
                  Attrs.class_(
                    `flex items-center gap-2 w-full px-3 py-2 rounded text-left transition-colors ${if (
                        isSelected
                      ) {
                        "bg-gray-700 text-white"
                      } else {
                        "hover:bg-gray-800 text-gray-300"
                      }}`,
                  ),
                  Events.onClick(Databases(SelectEntity(entity.name))),
                  Attrs.ariaLabel(`Select entity ${entity.name}`),
                },
                list{
                  span(
                    list{
                      Attrs.class_("text-[10px] px-1.5 py-0.5 bg-gray-800 text-gray-500 rounded"),
                    },
                    list{text(entity.kind)},
                  ),
                  span(
                    list{Attrs.class_("text-sm flex-1 truncate font-mono")},
                    list{text(entity.name)},
                  ),
                  span(
                    list{Attrs.class_("text-xs text-gray-600")},
                    list{text(Int.toString(entity.entryCount))},
                  ),
                  span(
                    list{Attrs.class_("text-xs text-gray-700")},
                    list{text(Int.toString(Array.length(entity.fields)) ++ " cols")},
                  ),
                },
              )
            })
            ->List.fromArray,
          ),
          // Entity detail panel
          viewEntityDetail(state),
        },
      ),
    },
  )
}

// ===========================================================================
// Drift Monitor Tab
// ===========================================================================

/// Render a single drift bar for a modality.
let renderDriftBar = (dimension: string, score: float): Tea_Vdom.t<msg> => {
  let pct = Float.toInt(score *. 100.0)
  let colour = if score < 0.1 {
    "bg-emerald-500"
  } else if score < 0.3 {
    "bg-amber-500"
  } else {
    "bg-red-500"
  }
  let textColour = if score < 0.1 {
    "text-emerald-400"
  } else if score < 0.3 {
    "text-amber-400"
  } else {
    "text-red-400"
  }

  div(
    list{Attrs.class_("flex items-center gap-3 py-1")},
    list{
      span(
        list{Attrs.class_("text-xs text-gray-400 w-24 text-right capitalize")},
        list{text(dimension)},
      ),
      div(
        list{Attrs.class_("flex-1 h-3 bg-gray-800 rounded-full overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_(`h-full ${colour} rounded-full transition-all`),
              Attrs.style("width", Int.toString(max(pct, 1)) ++ "%"),
            },
            list{},
          ),
        },
      ),
      span(
        list{Attrs.class_(`text-xs font-mono w-12 text-right ${textColour}`)},
        list{text(Float.toFixed(score, ~digits=3))},
      ),
    },
  )
}

/// Render the Drift Monitor tab.
let viewDrift = (state: databasesState): Tea_Vdom.t<msg> => {
  let currentModule = selectedModuleState(state)
  let hasDrift =
    currentModule->Option.map(m => hasCapability(m.config, DriftDetection))->Option.getOr(false)

  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Module selector
      div(
        list{Attrs.class_("flex items-center gap-2 border-b border-gray-800 pb-3")},
        state.modules
        ->Array.map(m =>
          renderModulePill(m.config, m.config.id == state.selectedModule, m.connection)
        )
        ->List.fromArray,
      ),
      if hasDrift {
        switch currentModule {
        | Some(ms) =>
          div(
            list{Attrs.class_("space-y-4")},
            list{
              // Drift heatmap
              div(
                list{Attrs.class_("bg-gray-900/50 border border-gray-800 rounded-lg p-4")},
                list{
                  div(
                    list{Attrs.class_("flex items-center gap-2 mb-4")},
                    list{
                      span(
                        list{
                          Attrs.class_(
                            "text-xs font-semibold text-gray-400 uppercase tracking-wider",
                          ),
                        },
                        list{text("Cross-Modal Drift Heatmap")},
                      ),
                      button(
                        list{
                          Attrs.class_(
                            "ml-auto px-3 py-1 bg-gray-700 hover:bg-gray-600 text-xs text-white rounded transition-colors",
                          ),
                          Events.onClick(Databases(RefreshDrift)),
                          Attrs.ariaLabel("Refresh drift scores"),
                        },
                        list{text("Refresh")},
                      ),
                    },
                  ),
                  switch ms.driftScores {
                  | Some(scores) =>
                    div(
                      list{Attrs.class_("space-y-1")},
                      scores
                      ->Array.map(ds => renderDriftBar(ds.dimension, ds.score))
                      ->List.fromArray,
                    )
                  | None =>
                    div(
                      list{Attrs.class_("text-xs text-gray-600 text-center py-8")},
                      list{text("Connect to backend to load drift scores")},
                    )
                  },
                },
              ),
              // Proof obligations
              if Array.length(ms.proofObligations) > 0 {
                div(
                  list{Attrs.class_("bg-gray-900/50 border border-gray-800 rounded-lg p-4")},
                  list{
                    div(
                      list{
                        Attrs.class_(
                          "text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3",
                        ),
                      },
                      list{text("Proof Obligations")},
                    ),
                    div(
                      list{Attrs.class_("space-y-2")},
                      ms.proofObligations
                      ->Array.map(po => {
                        let statusColour = switch po.status {
                        | "verified" => "text-emerald-400"
                        | "failed" => "text-red-400"
                        | _ => "text-amber-400"
                        }
                        div(
                          list{
                            Attrs.class_(
                              "flex items-center gap-3 text-xs py-1 border-b border-gray-800/50",
                            ),
                          },
                          list{
                            span(
                              list{Attrs.class_(`font-semibold ${statusColour} w-16`)},
                              list{text(po.status)},
                            ),
                            span(list{Attrs.class_("text-gray-300")}, list{text(po.contractName)}),
                            span(
                              list{Attrs.class_("text-gray-600 ml-auto")},
                              list{text(po.proofType)},
                            ),
                            span(
                              list{Attrs.class_("text-gray-700 font-mono text-[10px]")},
                              list{text(po.proofHash)},
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
              // Normalise button
              button(
                list{
                  Attrs.class_(
                    "px-4 py-2 bg-indigo-700 hover:bg-indigo-600 text-white text-xs rounded transition-colors",
                  ),
                  Events.onClick(Databases(NormaliseAll)),
                  Attrs.ariaLabel("Normalise all drifted modalities"),
                },
                list{text("Normalise Drifted Modalities")},
              ),
            },
          )
        | None => noNode
        }
      } else {
        div(
          list{Attrs.class_("text-xs text-gray-600 text-center py-12")},
          list{text("Selected module does not support drift detection. Switch to VeriSimDB.")},
        )
      },
    },
  )
}

// ===========================================================================
// Telemetry Tab
// ===========================================================================

/// Render the Telemetry tab.
let viewTelemetry = (state: databasesState): Tea_Vdom.t<msg> => {
  let currentModule = selectedModuleState(state)
  let hasTelemetry =
    currentModule->Option.map(m => hasCapability(m.config, Telemetry))->Option.getOr(false)

  div(
    list{Attrs.class_("space-y-4")},
    list{
      // Module selector
      div(
        list{Attrs.class_("flex items-center gap-2 border-b border-gray-800 pb-3")},
        state.modules
        ->Array.map(m =>
          renderModulePill(m.config, m.config.id == state.selectedModule, m.connection)
        )
        ->List.fromArray,
      ),
      if hasTelemetry {
        switch currentModule {
        | Some(ms) =>
          switch ms.telemetry {
          | Some(t) =>
            div(
              list{Attrs.class_("space-y-4")},
              list{
                // Summary cards
                div(
                  list{Attrs.class_("grid grid-cols-4 gap-4")},
                  list{
                    renderStat("Entities", Int.toString(t.entityCount), "text-emerald-400"),
                    renderStat(
                      "Avg Query",
                      Float.toFixed(t.avgQueryDurationMs, ~digits=1) ++ "ms",
                      "text-cyan-400",
                    ),
                    renderStat(
                      "Drift Events",
                      Int.toString(t.driftDetectedCount),
                      "text-amber-400",
                    ),
                    renderStat(
                      "Normalise Rate",
                      Float.toFixed(t.normaliseSuccessRate *. 100.0, ~digits=0) ++ "%",
                      "text-indigo-400",
                    ),
                  },
                ),
                // Modality heatmap
                div(
                  list{Attrs.class_("bg-gray-900/50 border border-gray-800 rounded-lg p-4")},
                  list{
                    div(
                      list{
                        Attrs.class_(
                          "text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3",
                        ),
                      },
                      list{text("Modality Usage Heatmap")},
                    ),
                    div(
                      list{Attrs.class_("flex gap-2 flex-wrap")},
                      t.modalityHeatmap
                      ->Array.map(((name, intensity)) => {
                        let opacity = Float.toFixed(Math.min(intensity, 1.0), ~digits=2)
                        div(
                          list{
                            Attrs.class_("px-3 py-2 rounded text-xs text-white font-mono"),
                            Attrs.style("background-color", `rgba(52, 211, 153, ${opacity})`),
                          },
                          list{
                            div(list{}, list{text(name)}),
                            div(
                              list{Attrs.class_("text-[10px] opacity-80")},
                              list{text(Float.toFixed(intensity *. 100.0, ~digits=0) ++ "%")},
                            ),
                          },
                        )
                      })
                      ->List.fromArray,
                    ),
                  },
                ),
                // Query patterns
                if Array.length(t.queryPatterns) > 0 {
                  div(
                    list{Attrs.class_("bg-gray-900/50 border border-gray-800 rounded-lg p-4")},
                    list{
                      div(
                        list{
                          Attrs.class_(
                            "text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3",
                          ),
                        },
                        list{text("Common Query Patterns")},
                      ),
                      div(
                        list{Attrs.class_("space-y-1")},
                        t.queryPatterns
                        ->Array.map(((pattern, count)) =>
                          div(
                            list{Attrs.class_("flex items-center gap-2 text-xs py-1")},
                            list{
                              span(list{Attrs.class_("text-gray-300 flex-1")}, list{text(pattern)}),
                              span(
                                list{Attrs.class_("text-gray-600 font-mono")},
                                list{text(Int.toString(count))},
                              ),
                            },
                          )
                        )
                        ->List.fromArray,
                      ),
                    },
                  )
                } else {
                  noNode
                },
                // Privacy notice
                div(
                  list{Attrs.class_("text-[10px] text-gray-700 text-center")},
                  list{
                    text(
                      "Telemetry is opt-in and aggregate-only. No query content, entity data, or PII.",
                    ),
                  },
                ),
                // Timestamp
                div(
                  list{Attrs.class_("text-[10px] text-gray-700 text-center")},
                  list{text("Generated: " ++ t.generatedAt)},
                ),
              },
            )
          | None =>
            div(
              list{Attrs.class_("text-center py-12")},
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-500 mb-3")},
                  list{text("No telemetry snapshot loaded")},
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white text-xs rounded transition-colors",
                    ),
                    Events.onClick(Databases(LoadTelemetry)),
                    Attrs.ariaLabel("Load telemetry snapshot"),
                  },
                  list{text("Load Telemetry")},
                ),
              },
            )
          }
        | None => noNode
        }
      } else {
        div(
          list{Attrs.class_("text-xs text-gray-600 text-center py-12")},
          list{text("Selected module does not expose telemetry. Switch to VeriSimDB.")},
        )
      },
    },
  )
}

// ===========================================================================
// Main View
// ===========================================================================

/// Root view for the Databases panel.
let view = (state: databasesState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 p-4 overflow-y-auto"),
      Attrs.role("region"),
      Attrs.ariaLabel("Databases panel — VeriSimDB, QuandleDB, LithoGlyph management"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center gap-3 mb-4")},
        list{
          h2(list{Attrs.class_("text-lg font-bold text-emerald-400")}, list{text("Databases")}),
          span(
            list{Attrs.class_("text-xs text-gray-600")},
            list{text(`${Int.toString(Array.length(state.modules))} modules registered`)},
          ),
          // Error display
          switch state.error {
          | Some(err) =>
            div(
              list{Attrs.class_("ml-auto flex items-center gap-2")},
              list{
                span(list{Attrs.class_("text-xs text-red-400")}, list{text(err)}),
                button(
                  list{
                    Attrs.class_("text-xs text-gray-500 hover:text-gray-300"),
                    Events.onClick(Databases(DismissError)),
                  },
                  list{text("dismiss")},
                ),
              },
            )
          | None => noNode
          },
        },
      ),
      // Tab bar
      div(
        list{Attrs.class_("flex gap-1 mb-4 border-b border-gray-800"), Attrs.role("tablist")},
        list{
          renderTab(
            "Dashboard",
            state.activeCategory == DbDashboard,
            Databases(SetCategory(DbDashboard)),
          ),
          renderTab("Query", state.activeCategory == DbQuery, Databases(SetCategory(DbQuery))),
          renderTab("Schema", state.activeCategory == DbSchema, Databases(SetCategory(DbSchema))),
          renderTab("Drift", state.activeCategory == DbDrift, Databases(SetCategory(DbDrift))),
          renderTab(
            "Telemetry",
            state.activeCategory == DbTelemetry,
            Databases(SetCategory(DbTelemetry)),
          ),
        },
      ),
      // Active tab content
      switch state.activeCategory {
      | DbDashboard => viewDashboard(state)
      | DbQuery => viewQuery(state)
      | DbSchema => viewSchema(state)
      | DbDrift => viewDrift(state)
      | DbTelemetry => viewTelemetry(state)
      },
    },
  )
}
