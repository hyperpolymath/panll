// SPDX-License-Identifier: PMPL-1.0-or-later

/// Pane-W: World/Task Barycentre Component
///
/// The central shared canvas where results manifest.
/// Contains the Topology View (Binary Star diagram) and
/// the shared world state.

open Model
open Msg
open Tea.Html

// ===========================================================================
// TypeLL Cross-Panel Type Intelligence (shared helper)
// ===========================================================================

/// Render TypeLL cross-panel type intelligence result (if available).
/// Parses the raw JSON via TypeLLEngine.parseCheckResult and displays an
/// evangeliser-style narrative with proof obligations and linearity notes.
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
// VeriSimDB Database Panel
// ===========================================================================

/// Connection indicator: green dot when connected, red when disconnected.
let renderDbConnectionIndicator = (db: verisimdbState): Tea_Vdom.t<msg> => {
  let dotColour = db.connected ? "bg-emerald-400" : "bg-red-500"
  let statusText = db.connected ? "Connected" : "Disconnected"

  div(
    list{Attrs.class_("flex items-center gap-2")},
    list{
      div(list{Attrs.class_("w-2 h-2 rounded-full " ++ dotColour)}, list{}),
      div(
        list{Attrs.class_("text-[10px] text-gray-400")},
        list{text(statusText ++ " · " ++ db.endpoint)},
      ),
      button(
        list{
          Attrs.class_(
            "ml-auto px-2 py-0.5 text-[10px] bg-gray-800 hover:bg-gray-700 rounded text-gray-300",
          ),
          Events.onClick(VeriSimDB(CheckHealth)),
        },
        list{text("Ping")},
      ),
    },
  )
}

/// VQL query textarea and execute button.
let renderVqlQueryArea = (db: verisimdbState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-2")},
    list{
      div(list{Attrs.class_("text-[11px] text-gray-400")}, list{text("VQL Query")}),
      textarea(
        list{
          Attrs.class_(
            "w-full h-20 bg-gray-950 border border-gray-800 rounded p-2 font-mono text-[11px] text-cyan-200 resize-none focus:border-cyan-600 focus:outline-none",
          ),
          Attrs.placeholder("SELECT GRAPH.* FROM HEXAD 'entity-id'"),
          Attrs.value(db.lastQuery),
          Events.onInput(value => VeriSimDB(UpdateQueryInput(value))),
          Attrs.ariaLabel("VQL query input"),
        },
        list{},
      ),
      div(
        list{Attrs.class_("flex gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs bg-cyan-600 hover:bg-cyan-500 rounded text-gray-900 font-semibold",
              ),
              Events.onClick(VeriSimDB(SubmitQuery(db.lastQuery))),
            },
            list{text("Execute")},
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-300"),
              Events.onClick(VeriSimDB(ListEntities)),
            },
            list{text("List Entities")},
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-gray-900 hover:bg-gray-800 rounded text-gray-400"),
              Events.onClick(VeriSimDB(ClearQueryResult)),
            },
            list{text("Clear")},
          ),
        },
      ),
    },
  )
}

/// Query result display area — formatted JSON output or error message.
let renderQueryResult = (db: verisimdbState): Tea_Vdom.t<msg> => {
  let resultContent = switch (db.queryResult, db.queryError) {
  | (Some(json), _) =>
    div(
      list{
        Attrs.class_("p-2 bg-gray-950 border border-cyan-900/40 rounded max-h-40 overflow-y-auto"),
      },
      list{
        node(
          "pre",
          list{Attrs.class_("font-mono text-[10px] text-cyan-100 whitespace-pre-wrap")},
          list{text(json)},
        ),
      },
    )
  | (None, Some(err)) => div(list{Attrs.class_("text-xs text-red-400")}, list{text(err)})
  | (None, None) =>
    div(list{Attrs.class_("text-[10px] text-gray-600 italic")}, list{text("No query results yet.")})
  }

  div(
    list{Attrs.class_("space-y-1")},
    list{div(list{Attrs.class_("text-[11px] text-gray-400")}, list{text("Result")}), resultContent},
  )
}

/// Entity list sidebar with clickable items that load drift status.
let renderEntityList = (db: verisimdbState): Tea_Vdom.t<msg> => {
  if Array.length(db.entities) === 0 {
    text("")
  } else {
    let entityItems =
      db.entities
      ->Array.map(entityId => {
        let isSelected = db.selectedEntity == Some(entityId)
        let itemClass = isSelected
          ? "text-xs text-cyan-300 bg-gray-800 px-2 py-1 rounded cursor-pointer"
          : "text-xs text-gray-400 hover:text-cyan-200 px-2 py-1 rounded cursor-pointer"

        div(
          list{
            Attrs.class_(itemClass),
            Events.onClick(VeriSimDB(SelectEntity(entityId))),
            Attrs.role("option"),
          },
          list{text(entityId)},
        )
      })
      ->List.fromArray

    div(
      list{Attrs.class_("space-y-1")},
      list{
        div(
          list{Attrs.class_("text-[11px] text-gray-400")},
          list{text("Entities (" ++ Int.toString(Array.length(db.entities)) ++ ")")},
        ),
        div(
          list{Attrs.class_("max-h-24 overflow-y-auto space-y-0.5"), Attrs.role("listbox")},
          entityItems,
        ),
      },
    )
  }
}

/// Render a single drift bar for a modality.
/// Shows modality name and a coloured bar proportional to the drift score.
/// Colour transitions: green (0.0) -> amber (0.3) -> red (0.7+).
let renderDriftBar = (modality: string, score: float): Tea_Vdom.t<msg> => {
  let widthPercent = Int.toString(Int.fromFloat(score *. 100.0))
  let barColour = if score >= 0.7 {
    "bg-red-500"
  } else if score >= 0.3 {
    "bg-amber-400"
  } else {
    "bg-emerald-400"
  }

  div(
    list{Attrs.class_("flex items-center gap-2")},
    list{
      div(
        list{Attrs.class_("w-16 text-[10px] text-gray-400 font-mono text-right")},
        list{text(modality)},
      ),
      div(
        list{Attrs.class_("flex-1 h-2 bg-gray-800 rounded-full overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_("h-full rounded-full " ++ barColour),
              Attrs.style("width", widthPercent ++ "%"),
              Attrs.role("progressbar"),
              Attrs.ariaValueNow(score),
              Attrs.ariaValueMin(0.0),
              Attrs.ariaValueMax(1.0),
              Attrs.ariaLabel(modality ++ " drift score"),
            },
            list{},
          ),
        },
      ),
      div(
        list{Attrs.class_("w-8 text-[10px] text-gray-500 font-mono")},
        list{text(Float.toFixed(score, ~digits=2))},
      ),
    },
  )
}

/// Drift heatmap: visual representation of drift across all 8 octad modalities.
/// Renders as a vertical bar chart with colour-coded severity indicators.
let renderDriftHeatmap = (scores: driftScores): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-1")},
    list{
      renderDriftBar("GRAPH", scores.graph),
      renderDriftBar("VECTOR", scores.vector),
      renderDriftBar("TENSOR", scores.tensor),
      renderDriftBar("SEMANTIC", scores.semantic),
      renderDriftBar("DOCUMENT", scores.document),
      renderDriftBar("TEMPORAL", scores.temporal),
      renderDriftBar("PROV", scores.provenance),
      renderDriftBar("SPATIAL", scores.spatial),
    },
  )
}

/// Drift status display for the selected entity.
/// Shows a drift heatmap when structured scores are available, with a
/// normalise button for entities above the warning threshold.
let renderDriftStatus = (db: verisimdbState): Tea_Vdom.t<msg> => {
  switch (db.selectedEntity, db.driftStatus) {
  | (Some(entityId), Some(_json)) =>
    let heatmapView = switch db.driftScores {
    | Some(scores) => renderDriftHeatmap(scores)
    | None =>
      // Fallback to raw JSON if parsing failed
      div(
        list{
          Attrs.class_(
            "p-2 bg-gray-950 border border-amber-900/40 rounded max-h-24 overflow-y-auto",
          ),
        },
        list{
          node(
            "pre",
            list{Attrs.class_("font-mono text-[10px] text-amber-200 whitespace-pre-wrap")},
            list{
              text(
                switch db.driftStatus {
                | Some(j) => j
                | None => ""
                },
              ),
            },
          ),
        },
      )
    }

    let isNormalising = db.normalisingEntity == Some(entityId)
    let normaliseButton = button(
      list{
        Attrs.class_(
          if isNormalising {
            "px-2 py-0.5 text-[10px] bg-gray-700 rounded text-gray-500 cursor-not-allowed"
          } else {
            "px-2 py-0.5 text-[10px] bg-amber-600 hover:bg-amber-500 rounded text-gray-900 font-semibold"
          },
        ),
        Events.onClick(
          if isNormalising {
            VeriSimDB(ClearQueryResult)
          } else {
            VeriSimDB(TriggerNormalise(entityId))
          },
        ),
      },
      list{
        text(
          if isNormalising {
            "Normalising..."
          } else {
            "Normalise"
          },
        ),
      },
    )

    div(
      list{Attrs.class_("space-y-2")},
      list{
        div(
          list{Attrs.class_("flex items-center justify-between")},
          list{
            div(list{Attrs.class_("text-[11px] text-gray-400")}, list{text("Drift: " ++ entityId)}),
            normaliseButton,
          },
        ),
        heatmapView,
      },
    )
  | (Some(_), None) =>
    div(
      list{Attrs.class_("text-[10px] text-gray-600 italic")},
      list{text("Loading drift status...")},
    )
  | _ => text("")
  }
}

/// Telemetry dashboard panel — shows aggregate product development metrics.
/// Displays modality usage heatmap, query pattern distribution, performance,
/// drift frequency, and VQL-UT proof adoption. All data is aggregate-only.
let renderTelemetryPanel = (db: verisimdbState): Tea_Vdom.t<msg> => {
  if !db.telemetryVisible {
    text("")
  } else {
    switch db.telemetry {
    | None =>
      div(
        list{
          Attrs.class_("mt-2 p-3 bg-gray-900/80 border border-emerald-900/30 rounded space-y-2"),
        },
        list{
          div(
            list{Attrs.class_("text-[10px] text-gray-500 italic")},
            list{text("No telemetry data. Click 'Fetch Telemetry' to load product insights.")},
          ),
          div(
            list{Attrs.class_("text-[9px] text-gray-600")},
            list{text("Aggregate metrics only. No query content or entity data is captured.")},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-1 text-[10px] bg-emerald-700 hover:bg-emerald-600 rounded text-gray-100",
              ),
              Events.onClick(VeriSimDB(FetchTelemetry)),
            },
            list{text("Fetch Telemetry")},
          ),
        },
      )
    | Some(snapshot) =>
      let modalityBars =
        snapshot.modalityHeatmap
        ->Array.map(((name, pct)) => {
          let widthPct = Int.toString(Int.fromFloat(pct))
          let barColour = if pct >= 30.0 {
            "bg-emerald-400"
          } else if pct >= 10.0 {
            "bg-cyan-400"
          } else {
            "bg-gray-600"
          }

          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              div(
                list{Attrs.class_("w-16 text-[10px] text-gray-400 font-mono text-right")},
                list{text(name)},
              ),
              div(
                list{Attrs.class_("flex-1 h-2 bg-gray-800 rounded-full overflow-hidden")},
                list{
                  div(
                    list{
                      Attrs.class_("h-full rounded-full " ++ barColour),
                      Attrs.style("width", widthPct ++ "%"),
                    },
                    list{},
                  ),
                },
              ),
              div(
                list{Attrs.class_("w-10 text-[10px] text-gray-500 font-mono")},
                list{text(Float.toFixed(pct, ~digits=1) ++ "%")},
              ),
            },
          )
        })
        ->List.fromArray

      let patternRows =
        snapshot.queryPatterns
        ->Array.map(((pattern, count)) =>
          div(
            list{Attrs.class_("flex justify-between text-[10px]")},
            list{
              div(list{Attrs.class_("text-cyan-300 font-mono")}, list{text(pattern)}),
              div(list{Attrs.class_("text-gray-500")}, list{text(Int.toString(count))}),
            },
          )
        )
        ->List.fromArray

      div(
        list{
          Attrs.class_("mt-2 p-3 bg-gray-900/80 border border-emerald-900/30 rounded space-y-3"),
        },
        list{
          // Privacy notice
          div(
            list{Attrs.class_("text-[9px] text-gray-600 italic")},
            list{text(snapshot.privacyNotice)},
          ),
          // Modality usage heatmap
          div(
            list{Attrs.class_("space-y-1")},
            list{
              div(list{Attrs.class_("text-[11px] text-gray-400")}, list{text("Modality Usage")}),
              div(list{Attrs.class_("space-y-1")}, modalityBars),
            },
          ),
          // Query patterns
          div(
            list{Attrs.class_("space-y-1")},
            list{
              div(list{Attrs.class_("text-[11px] text-gray-400")}, list{text("Query Patterns")}),
              div(list{Attrs.class_("space-y-0.5")}, patternRows),
            },
          ),
          // Performance + drift summary
          div(
            list{Attrs.class_("grid grid-cols-3 gap-2 text-center")},
            list{
              div(
                list{},
                list{
                  div(
                    list{Attrs.class_("text-lg font-light text-cyan-300")},
                    list{text(Float.toFixed(snapshot.avgQueryDurationMs, ~digits=1) ++ "ms")},
                  ),
                  div(list{Attrs.class_("text-[9px] text-gray-500")}, list{text("Avg Query")}),
                },
              ),
              div(
                list{},
                list{
                  div(
                    list{Attrs.class_("text-lg font-light text-amber-300")},
                    list{text(Int.toString(snapshot.driftDetectedCount))},
                  ),
                  div(list{Attrs.class_("text-[9px] text-gray-500")}, list{text("Drift Events")}),
                },
              ),
              div(
                list{},
                list{
                  div(
                    list{Attrs.class_("text-lg font-light text-emerald-300")},
                    list{text(Float.toFixed(snapshot.normaliseSuccessRate, ~digits=0) ++ "%")},
                  ),
                  div(list{Attrs.class_("text-[9px] text-gray-500")}, list{text("Normalise OK")}),
                },
              ),
            },
          ),
          // Refresh button
          div(
            list{Attrs.class_("flex justify-between items-center")},
            list{
              div(
                list{Attrs.class_("text-[9px] text-gray-600")},
                list{text("Generated: " ++ snapshot.generatedAt)},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-2 py-0.5 text-[10px] bg-gray-800 hover:bg-gray-700 rounded text-gray-300",
                  ),
                  Events.onClick(VeriSimDB(FetchTelemetry)),
                },
                list{text("Refresh")},
              ),
            },
          ),
        },
      )
    }
  }
}

/// The complete VeriSimDB database tools panel, rendered in Pane-W.
let renderDatabaseTools = (db: verisimdbState): Tea_Vdom.t<msg> => {
  let submenu = if !db.dbMenuExpanded {
    text("")
  } else {
    div(
      list{
        Attrs.class_("mt-2 p-3 bg-gray-900/80 border border-cyan-900/30 rounded space-y-3"),
        Attrs.ariaExpanded(db.dbMenuExpanded),
      },
      list{
        renderDbConnectionIndicator(db),
        renderVqlQueryArea(db),
        renderQueryResult(db),
        viewTypeCheckResult(db.lastTypeCheck),
        renderEntityList(db),
        renderDriftStatus(db),
        // Telemetry section with toggle
        div(
          list{Attrs.class_("flex items-center gap-2 mt-2")},
          list{
            div(list{Attrs.class_("text-[11px] text-gray-400")}, list{text("Product Telemetry")}),
            button(
              list{
                Attrs.class_(
                  "px-2 py-0.5 text-[10px] bg-gray-800 hover:bg-gray-700 rounded text-gray-300",
                ),
                Events.onClick(VeriSimDB(ToggleTelemetryPanel)),
              },
              list{
                text(
                  if db.telemetryVisible {
                    "Hide"
                  } else {
                    "Show"
                  },
                ),
              },
            ),
          },
        ),
        renderTelemetryPanel(db),
        // Proof obligation display toggle
        div(
          list{Attrs.class_("flex items-center gap-2 mt-2")},
          list{
            div(
              list{Attrs.class_("text-[11px] text-gray-400")},
              list{text("VQL-UT Proof Obligations")},
            ),
            button(
              list{
                Attrs.class_(
                  "px-2 py-0.5 text-[10px] bg-gray-800 hover:bg-gray-700 rounded text-gray-300",
                ),
                Events.onClick(VeriSimDB(ToggleProofDisplay)),
              },
              list{
                text(
                  if db.proofDisplayActive {
                    "Hide in Panel-L"
                  } else {
                    "Show in Panel-L"
                  },
                ),
              },
            ),
          },
        ),
        // Anti-Crash validation toggle
        div(
          list{Attrs.class_("flex items-center gap-2 mt-2")},
          list{
            div(
              list{Attrs.class_("text-[11px] text-gray-400")},
              list{text("Anti-Crash VQL Validation")},
            ),
            button(
              list{
                Attrs.class_(
                  if db.antiCrashValidation {
                    "px-2 py-0.5 text-[10px] bg-green-900/40 hover:bg-green-800/40 rounded text-green-400 border border-green-500/30"
                  } else {
                    "px-2 py-0.5 text-[10px] bg-gray-800 hover:bg-gray-700 rounded text-gray-400"
                  },
                ),
                Events.onClick(VeriSimDB(ToggleAntiCrashValidation)),
              },
              list{
                text(
                  if db.antiCrashValidation {
                    "Active"
                  } else {
                    "Inactive"
                  },
                ),
              },
            ),
          },
        ),
        // BoJ routing toggle for VeriSimDB operations
        div(
          list{Attrs.class_("flex items-center gap-2 mt-2")},
          list{
            div(list{Attrs.class_("text-[11px] text-gray-400")}, list{text("BoJ Routing")}),
            button(
              list{
                Attrs.class_(
                  if db.bojRouting {
                    "px-2 py-0.5 text-[10px] bg-blue-700 text-white rounded"
                  } else {
                    "px-2 py-0.5 text-[10px] bg-gray-800 hover:bg-gray-700 rounded text-gray-300"
                  },
                ),
                Attrs.ariaLabel(
                  if db.bojRouting {
                    "Disable BoJ routing"
                  } else {
                    "Enable BoJ routing"
                  },
                ),
                Events.onClick(VeriSimDB(ToggleVeriSimBojRouting)),
              },
              list{
                text(
                  if db.bojRouting {
                    "BoJ On"
                  } else {
                    "BoJ"
                  },
                ),
              },
            ),
          },
        ),
        // Query count and inference stream summary
        div(
          list{Attrs.class_("flex items-center gap-3 mt-2 text-[10px] text-gray-500")},
          list{
            span(list{}, list{text(`Queries: ${Int.toString(db.queryCount)}`)}),
            if Array.length(db.inferenceStream) > 0 {
              span(
                list{Attrs.class_("text-violet-400")},
                list{
                  text(`${Int.toString(Array.length(db.inferenceStream))} inference suggestions`),
                },
              )
            } else {
              noNode
            },
          },
        ),
      },
    )
  }

  div(
    list{Attrs.class_("mt-4 space-y-1")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-400 tracking-widest uppercase")},
            list{text("Database Tools")},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-1 text-[10px] bg-gray-800 hover:bg-gray-700 rounded text-gray-300",
              ),
              Events.onClick(VeriSimDB(ToggleDbMenu)),
            },
            list{
              text(
                if db.dbMenuExpanded {
                  "Hide"
                } else {
                  "Show"
                },
              ),
            },
          ),
        },
      ),
      submenu,
    },
  )
}

// ===========================================================================
// Security Tools (existing)
// ===========================================================================

/// Render the security tools menu with panic-attacker and trace-agent buttons.
let renderSecurityTools = (state: paneWState): Tea_Vdom.t<msg> => {
  let tools = [("panic-attacker", "panic-attacker"), ("trace-agent", "trace-agent (future)")]

  let toolButtons =
    tools
    ->Array.map(((toolId, label)) =>
      button(
        list{
          Attrs.class_(
            "w-full text-left px-2 py-1 text-xs text-gray-300 hover:bg-gray-800 rounded",
          ),
          Events.onClick(PaneW(OpenSecurityDialog(toolId))),
        },
        list{text(label)},
      )
    )
    ->List.fromArray

  let submenu = if !state.securityMenuExpanded {
    text("")
  } else {
    div(
      list{
        Attrs.class_("mt-2 bg-gray-900/80 border border-gray-800 rounded p-2 space-y-1"),
        Attrs.ariaExpanded(state.securityMenuExpanded),
      },
      toolButtons,
    )
  }

  div(
    list{Attrs.class_("mt-4 space-y-1")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-400 tracking-widest uppercase")},
            list{text("Security Tools")},
          ),
          button(
            list{
              Attrs.class_(
                "px-2 py-1 text-[10px] bg-gray-800 hover:bg-gray-700 rounded text-gray-300",
              ),
              Events.onClick(PaneW(ToggleSecurityTools)),
            },
            list{
              text(
                if state.securityMenuExpanded {
                  "Hide"
                } else {
                  "Show"
                },
              ),
            },
          ),
        },
      ),
      submenu,
    },
  )
}

/// Render the security dialog overlay for configuring and launching security scans.
let renderSecurityDialog = (state: paneWState): Tea_Vdom.t<msg> => {
  if !state.securityDialogOpen {
    text("")
  } else {
    let statusView = switch state.securityStatus {
    | Some(msg) => div(list{Attrs.class_("text-xs text-emerald-300")}, list{text(msg)})
    | None => text("")
    }

    let errorView = switch state.securityError {
    | Some(err) => div(list{Attrs.class_("text-xs text-red-400")}, list{text(err)})
    | None => text("")
    }

    let toolName = switch state.securityDialogTool {
    | Some(tool) => tool
    | None => "security tool"
    }

    div(
      list{Attrs.class_("fixed inset-0 bg-black/60 z-40 flex items-start justify-center p-6")},
      list{
        div(
          list{
            Attrs.class_(
              "relative w-full max-w-3xl bg-gray-950 border border-gray-800 rounded-lg shadow-2xl p-6 space-y-4",
            ),
            Attrs.role("dialog"),
            Attrs.ariaLabel("Security Tool: " ++ toolName),
          },
          list{
            div(
              list{Attrs.class_("flex items-center justify-between")},
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-400 uppercase tracking-widest")},
                  list{text("Security Menu · " ++ toolName)},
                ),
                button(
                  list{
                    Attrs.class_("text-xs text-gray-300 px-2 py-1 border border-gray-700 rounded"),
                    Events.onClick(PaneW(CloseSecurityDialog)),
                  },
                  list{text("Close")},
                ),
              },
            ),
            statusView,
            div(
              list{Attrs.class_("space-y-1")},
              list{
                div(
                  list{Attrs.class_("text-[11px] text-gray-400")},
                  list{text("Target program / binary")},
                ),
                input(
                  list{
                    Attrs.class_(
                      "w-full text-xs bg-gray-950 border border-gray-800 rounded px-2 py-1 text-gray-300",
                    ),
                    Attrs.placeholder("/path/to/program"),
                    Attrs.value(state.securityTarget),
                    Events.onInput(value => PaneW(SetSecurityTarget(value))),
                    Attrs.ariaLabel("Target program or binary path"),
                  },
                  list{},
                ),
              },
            ),
            div(
              list{Attrs.class_("space-y-1")},
              list{
                div(
                  list{Attrs.class_("text-[11px] text-gray-400")},
                  list{text("Timeline file (JSON/YAML)")},
                ),
                div(
                  list{Attrs.class_("flex gap-2")},
                  list{
                    input(
                      list{
                        Attrs.class_(
                          "flex-1 text-xs bg-gray-950 border border-gray-800 rounded px-2 py-1 text-gray-300",
                        ),
                        Attrs.placeholder("timeline.yaml"),
                        Attrs.value(state.securityTimeline),
                        Events.onInput(value => PaneW(SetSecurityTimeline(value))),
                        Attrs.ariaLabel("Timeline file path"),
                      },
                      list{},
                    ),
                    button(
                      list{
                        Attrs.class_(
                          "px-2 py-1 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-300",
                        ),
                        Events.onClick(PaneW(LoadSecurityTimelineFile)),
                      },
                      list{text("Browse")},
                    ),
                  },
                ),
              },
            ),
            div(
              list{Attrs.class_("space-y-1")},
              list{
                div(list{Attrs.class_("text-[11px] text-gray-400")}, list{text("Axes")}),
                input(
                  list{
                    Attrs.class_(
                      "w-full text-xs bg-gray-950 border border-gray-800 rounded px-2 py-1 text-gray-300",
                    ),
                    Attrs.placeholder("cpu,memory,concurrency"),
                    Attrs.value(state.securityAxes),
                    Events.onInput(value => PaneW(SetSecurityAxes(value))),
                    Attrs.ariaLabel("Security test axes"),
                  },
                  list{},
                ),
              },
            ),
            div(
              list{Attrs.class_("flex gap-2")},
              list{
                div(
                  list{Attrs.class_("flex-1 space-y-1")},
                  list{
                    div(list{Attrs.class_("text-[11px] text-gray-400")}, list{text("Intensity")}),
                    input(
                      list{
                        Attrs.class_(
                          "w-full text-xs bg-gray-950 border border-gray-800 rounded px-2 py-1 text-gray-300",
                        ),
                        Attrs.placeholder("medium"),
                        Attrs.value(state.securityIntensity),
                        Events.onInput(value => PaneW(SetSecurityIntensity(value))),
                        Attrs.ariaLabel("Test intensity"),
                      },
                      list{},
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("flex-1 space-y-1")},
                  list{
                    div(
                      list{Attrs.class_("text-[11px] text-gray-400")},
                      list{text("Duration (s)")},
                    ),
                    input(
                      list{
                        Attrs.class_(
                          "w-full text-xs bg-gray-950 border border-gray-800 rounded px-2 py-1 text-gray-300",
                        ),
                        Attrs.placeholder("30"),
                        Attrs.value(state.securityDuration),
                        Events.onInput(value => PaneW(SetSecurityDuration(value))),
                        Attrs.ariaLabel("Test duration in seconds"),
                      },
                      list{},
                    ),
                  },
                ),
              },
            ),
            div(
              list{Attrs.class_("flex items-center gap-3")},
              list{
                button(
                  list{
                    Attrs.class_(
                      "px-4 py-2 text-xs bg-emerald-500 hover:bg-emerald-400 rounded text-gray-900 font-semibold",
                    ),
                    Events.onClick(PaneW(LaunchSecurityAmbush)),
                  },
                  list{text("Launch Ambush")},
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-4 py-2 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-300",
                    ),
                    Events.onClick(PaneW(ClearEventChain)),
                  },
                  list{text("Reset")},
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-3 py-1 text-xs bg-gray-700 hover:bg-gray-600 rounded text-gray-200",
                    ),
                    Events.onClick(PaneW(ToggleSecurityStudyView)),
                  },
                  list{
                    text(
                      if state.securityViewActive {
                        "Hide Time/Space View"
                      } else {
                        "Show Time/Space View"
                      },
                    ),
                  },
                ),
              },
            ),
            errorView,
          },
        ),
      },
    )
  }
}

/// Render the security study view with event chain timeline and analysis results.
let renderSecurityStudyView = (state: paneWState): Tea_Vdom.t<msg> => {
  if !state.securityViewActive {
    text("")
  } else {
    let timelineInfo = switch state.eventChainTimeline {
    | Some(timeline) =>
      "Timeline: " ++
      Int.toString(timeline.events) ++
      " events · " ++
      Float.toString(timeline.durationMs) ++ "ms"
    | None => "Timeline metadata unavailable"
    }

    let eventRows =
      state.eventChain
      ->Array.map(ev => {
        div(
          list{
            Attrs.class_(
              "text-xs text-gray-300 flex justify-between border-b border-gray-800/60 py-1",
            ),
          },
          list{
            div(list{}, list{text(ev.id)}),
            div(list{}, list{text(ev.axis ++ " · " ++ ev.status)}),
            div(list{}, list{text(Float.toString(ev.durationMs) ++ "ms")}),
          },
        )
      })
      ->List.fromArray

    div(
      list{
        Attrs.class_("mt-4 p-3 border border-emerald-500/20 rounded bg-emerald-900/30 space-y-2"),
      },
      list{
        div(
          list{Attrs.class_("text-xs font-semibold text-emerald-300")},
          list{text("Time/Space Study")},
        ),
        div(list{Attrs.class_("text-[11px] text-gray-400")}, list{text(timelineInfo)}),
        div(list{Attrs.class_("max-h-32 overflow-y-auto")}, eventRows),
      },
    )
  }
}

/// Render the event chain panel showing security event timeline, summary, and controls.
let renderEventChainPanel = (state: paneWState): Tea_Vdom.t<msg> => {
  let eventCount = Array.length(state.eventChain)
  let summaryView = switch state.eventChainSummary {
  | Some(summary) =>
    div(
      list{Attrs.class_("text-xs text-gray-500 mb-2")},
      list{
        text(
          "Program: " ++
          summary.program ++
          " · Weak points: " ++
          Int.toString(summary.weakPoints) ++
          " · Crashes: " ++
          Int.toString(summary.totalCrashes) ++
          " · Robustness: " ++
          Float.toString(summary.robustnessScore),
        ),
      },
    )
  | None =>
    div(
      list{Attrs.class_("text-xs text-gray-600 mb-2")},
      list{text("No event-chain summary loaded.")},
    )
  }

  let timelineView = switch state.eventChainTimeline {
  | Some(timeline) =>
    div(
      list{Attrs.class_("text-xs text-gray-500 mb-2")},
      list{
        text(
          "Timeline: " ++
          Int.toString(timeline.events) ++
          " events · Duration: " ++
          Float.toString(timeline.durationMs) ++ "ms",
        ),
      },
    )
  | None =>
    div(
      list{Attrs.class_("text-xs text-gray-600 mb-2")},
      list{text("No timeline metadata loaded.")},
    )
  }

  let capabilityTone = PanicAttackerMode.toneClass(state.panicAttackerMode)
  let capabilityLabel = PanicAttackerMode.label(state.panicAttackerMode)

  let capabilityBinaryView = switch state.panicAttackerBinary {
  | Some(binary) =>
    div(list{Attrs.class_("text-xs text-gray-600")}, list{text("Binary: " ++ binary)})
  | None => text("")
  }

  let capabilityDetailView = switch state.panicAttackerStatusDetail {
  | Some(detail) => div(list{Attrs.class_("text-xs text-gray-500")}, list{text(detail)})
  | None => text("")
  }

  let errorView = switch state.eventChainError {
  | Some(err) => div(list{Attrs.class_("text-xs text-red-400 mb-2")}, list{text(err)})
  | None => text("")
  }

  let previewCount = eventCount > 8 ? 8 : eventCount
  let eventRows =
    state.eventChain
    ->Array.slice(~start=0, ~end=previewCount)
    ->Array.map(ev => {
      let startLabel = switch ev.startMs {
      | Some(ms) => Float.toString(ms) ++ "ms"
      | None => "n/a"
      }
      div(
        list{Attrs.class_("text-xs text-gray-400 flex justify-between")},
        list{
          div(list{Attrs.class_("truncate")}, list{text(ev.id)}),
          div(list{}, list{text(ev.axis)}),
          div(list{}, list{text(startLabel)}),
          div(list{}, list{text(Float.toString(ev.durationMs) ++ "ms")}),
          div(list{}, list{text(ev.status)}),
        },
      )
    })
    ->List.fromArray

  div(
    list{Attrs.class_("mt-4 p-3 border border-gray-800 rounded bg-gray-900/60 space-y-2")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 tracking-widest")},
        list{text("EVENT CHAIN (PANLL IMPORT)")},
      ),
      summaryView,
      div(
        list{Attrs.class_("flex gap-2")},
        list{
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-300"),
              Events.onClick(PaneW(ImportEventChain)),
            },
            list{text("Import JSON")},
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-300"),
              Events.onClick(PaneW(ImportEventChainFile)),
            },
            list{text("Load File")},
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-300"),
              Events.onClick(PaneW(CheckPanicAttackerCapability)),
            },
            list{text("Probe panic-attacker")},
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-300"),
              Events.onClick(PaneW(ImportPanicAttackerReportFile)),
            },
            list{text("Load panic-attacker Report")},
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-300"),
              Events.onClick(PaneW(ImportLatestPanicAttacker)),
            },
            list{text("Latest panic-attacker")},
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-gray-900 hover:bg-gray-800 rounded text-gray-400"),
              Events.onClick(PaneW(ClearEventChain)),
            },
            list{text("Clear")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-600 ml-auto")},
            list{text("Events: " ++ Int.toString(eventCount))},
          ),
        },
      ),
      renderSecurityTools(state),
      timelineView,
      div(
        list{Attrs.class_("space-y-1")},
        list{
          div(list{Attrs.class_("text-xs " ++ capabilityTone)}, list{text(capabilityLabel)}),
          capabilityBinaryView,
          capabilityDetailView,
        },
      ),
      errorView,
      textarea(
        list{
          Attrs.class_(
            "w-full h-24 bg-gray-950 border border-gray-800 rounded p-2 font-mono text-[11px] text-gray-400 resize-none focus:border-gray-600 focus:outline-none",
          ),
          Attrs.placeholder(
            "Paste event-chain JSON here then click \"Import JSON\".\nFormat: {\"events\":[{\"id\":\"e1\",\"axis\":\"cpu\",\"durationMs\":100,\"intensity\":\"high\",\"status\":\"pass\"}]}",
          ),
          Attrs.value(state.eventChainInput),
          Events.onInput(value => PaneW(UpdateEventChainInput(value))),
          Attrs.ariaLabel("Event chain JSON input"),
        },
        list{},
      ),
      div(list{Attrs.class_("space-y-1")}, eventRows),
      renderSecurityDialog(state),
    },
  )
}

// ===========================================================================
// Barycentre Tour — Guided Walkthrough
// ===========================================================================

/// Tour step content: title, explanation, and what to look at.
let tourStepContent = (step: tourStep): (string, string) => {
  switch step {
  | TourIntro => (
      "Welcome to the Task Barycentre",
      "The Barycentre is the gravitational centre of your work. Like a binary star system, your symbolic reasoning (Panel-L) and neural inference (Panel-N) co-orbit around a shared centre of mass. This view shows you where that centre is and how healthy the orbit is.",
    )
  | TourBinaryStar => (
      "The Binary Star System",
      "The indigo star represents your Symbolic Panel (formal logic, constraints, type-checked code). The emerald star represents your Neural Panel (AI inference, natural language, creative output). They orbit each other — when balanced, your work is strongest.",
    )
  | TourBarycentrePosition => (
      "Barycentre Position",
      "The golden diamond shows where the centre of gravity currently sits. If it drifts toward Symbolic, you may be over-constraining. If it drifts toward Neural, you may lack formal grounding. The position bar below the diagram shows this as a spectrum.",
    )
  | TourOrbitalMetrics => (
      "Orbital Metrics",
      "Four gauges measure orbit health: Stability (how steady the co-orbit is), Divergence (how far apart the stars have drifted), Symbolic Mass (density of your formal content), and Neural Stream (throughput of inference). Green is healthy, amber needs attention, red means intervention needed.",
    )
  | TourContractiles => (
      "Contractile Boundaries",
      "Contractiles are elastic adaptive constraints that keep the orbit safe. Each one has an enforcement level (Strict/Warn/Adaptive) and an elasticity score. When a contractile is violated, it appears red. Elastic contractiles can stretch — rigid ones halt immediately.",
    )
  | TourSyncHealth => (
      "Synchronisation Health",
      "Sync Health measures how well the three panels communicate. Low latency and fresh hash states mean healthy sync. When sync degrades, the drift aura shifts from indigo to amber, and the system sheds visual complexity (Information Humidity drops) to reduce cognitive load.",
    )
  | TourComplete => (
      "Tour Complete",
      "You now understand the Task Barycentre. Use it to monitor your work balance, catch drift early, and understand when the system adapts to protect you. Click the tour button anytime to revisit.",
    )
  }
}

/// Tour step number (1-indexed, for display).
let tourStepNumber = (step: tourStep): int => {
  switch step {
  | TourIntro => 1
  | TourBinaryStar => 2
  | TourBarycentrePosition => 3
  | TourOrbitalMetrics => 4
  | TourContractiles => 5
  | TourSyncHealth => 6
  | TourComplete => 7
  }
}

/// Render the tour overlay card.
let renderTourOverlay = (tour: tourState): Tea_Vdom.t<msg> => {
  if !tour.active {
    noNode
  } else {
    let (title, body) = tourStepContent(tour.currentStep)
    let stepNum = tourStepNumber(tour.currentStep)
    let isFirst = tour.currentStep === TourIntro
    let isLast = tour.currentStep === TourComplete

    div(
      list{
        Attrs.class_(
          "absolute inset-0 z-50 flex items-end justify-center pb-4 pointer-events-none",
        ),
      },
      list{
        div(
          list{
            Attrs.class_(
              "pointer-events-auto w-[90%] max-w-lg bg-gray-900/95 border border-indigo-700/60 rounded-xl shadow-2xl shadow-indigo-900/30 p-5 backdrop-blur-sm",
            ),
            Attrs.role("dialog"),
            Attrs.ariaLabel("Barycentre tour"),
          },
          list{
            // Step indicator
            div(
              list{Attrs.class_("flex items-center justify-between mb-3")},
              list{
                span(
                  list{Attrs.class_("text-xs text-indigo-400 font-mono")},
                  list{text(`Step ${Int.toString(stepNum)} of 7`)},
                ),
                button(
                  list{
                    Attrs.class_("text-gray-500 hover:text-gray-300 text-xs px-2 py-1"),
                    Events.onClick(PaneW(CloseTour)),
                  },
                  list{text("Skip tour")},
                ),
              },
            ),
            // Progress dots
            div(
              list{Attrs.class_("flex gap-1.5 mb-4")},
              [1, 2, 3, 4, 5, 6, 7]
              ->Array.map(n => {
                let active = n <= stepNum
                div(
                  list{
                    Attrs.class_(
                      `h-1 flex-1 rounded-full transition-all ${active
                          ? "bg-indigo-500"
                          : "bg-gray-700"}`,
                    ),
                  },
                  list{},
                )
              })
              ->List.fromArray,
            ),
            // Title
            div(list{Attrs.class_("text-sm font-semibold text-gray-100 mb-2")}, list{text(title)}),
            // Body
            div(list{Attrs.class_("text-xs text-gray-400 leading-relaxed mb-4")}, list{text(body)}),
            // Navigation
            div(
              list{Attrs.class_("flex items-center justify-between")},
              list{
                if isFirst {
                  div(list{}, list{})
                } else {
                  button(
                    list{
                      Attrs.class_(
                        "px-3 py-1.5 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-300",
                      ),
                      Events.onClick(PaneW(PrevTourStep)),
                    },
                    list{text("Back")},
                  )
                },
                button(
                  list{
                    Attrs.class_(
                      `px-4 py-1.5 text-xs rounded font-medium ${isLast
                          ? "bg-indigo-600 hover:bg-indigo-500 text-white"
                          : "bg-indigo-600 hover:bg-indigo-500 text-white"}`,
                    ),
                    Events.onClick(
                      if isLast {
                        PaneW(CloseTour)
                      } else {
                        PaneW(NextTourStep)
                      },
                    ),
                  },
                  list{
                    text(
                      if isLast {
                        "Finish"
                      } else {
                        "Next"
                      },
                    ),
                  },
                ),
              },
            ),
          },
        ),
      },
    )
  }
}

// ===========================================================================
// Metric Gauge Component
// ===========================================================================

/// Render a circular-style metric gauge with label, value, and colour coding.
let renderMetricGauge = (
  label: string,
  value: float,
  unit: string,
  ~lowColour: string="text-red-400",
  ~midColour: string="text-amber-300",
  ~highColour: string="text-emerald-400",
  ~invert: bool=false,
): Tea_Vdom.t<msg> => {
  let displayValue = Int.toString(Int.fromFloat(value *. 100.0))
  let effective = if invert {
    1.0 -. value
  } else {
    value
  }
  let colour = if effective >= 0.7 {
    highColour
  } else if effective >= 0.4 {
    midColour
  } else {
    lowColour
  }
  let barWidth = Float.toFixed(value *. 100.0, ~digits=0)

  div(
    list{Attrs.class_("flex flex-col items-center gap-1")},
    list{
      // Value
      div(list{Attrs.class_(`text-xl font-light ${colour}`)}, list{text(`${displayValue}${unit}`)}),
      // Bar
      div(
        list{Attrs.class_("w-full h-1.5 bg-gray-800 rounded-full overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_(
                `h-full rounded-full transition-all duration-700 ${if effective >= 0.7 {
                    "bg-emerald-500"
                  } else if effective >= 0.4 {
                    "bg-amber-500"
                  } else {
                    "bg-red-500"
                  }}`,
              ),
              Attrs.style("width", `${barWidth}%`),
            },
            list{},
          ),
        },
      ),
      // Label
      div(list{Attrs.class_("text-[10px] text-gray-500 text-center")}, list{text(label)}),
    },
  )
}

// ===========================================================================
// Contractile Status Row
// ===========================================================================

/// Render a compact contractile status indicator.
let renderContractileRow = (c: contractile): Tea_Vdom.t<msg> => {
  let (statusColour, statusIcon) = switch c.status {
  | Satisfied => ("text-emerald-400", "[OK]")
  | Violated(_) => ("text-red-400", "[!!]")
  | Pending => ("text-gray-500", "[..]")
  | Suspended => ("text-gray-600", "[--]")
  }
  let enfLabel = switch c.enforcement {
  | Strict => "Strict"
  | Warn => "Warn"
  | Adaptive => "Adapt"
  }
  let elasticityBar = Float.toFixed(c.elasticity *. 100.0, ~digits=0)

  div(
    list{Attrs.class_("flex items-center gap-2 py-1 px-2 bg-gray-900/50 rounded text-[10px]")},
    list{
      span(list{Attrs.class_(`font-mono ${statusColour}`)}, list{text(statusIcon)}),
      span(list{Attrs.class_("text-gray-300 flex-1 truncate")}, list{text(c.name)}),
      span(list{Attrs.class_("text-gray-600")}, list{text(enfLabel)}),
      // Elasticity mini-bar
      div(
        list{Attrs.class_("w-10 h-1 bg-gray-800 rounded-full overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_("h-full bg-indigo-500/60 rounded-full"),
              Attrs.style("width", `${elasticityBar}%`),
            },
            list{},
          ),
        },
      ),
    },
  )
}

// ===========================================================================
// Enhanced Binary Star Topology View
// ===========================================================================

/// Render the Binary Star topology diagram with full orbital metrics,
/// barycentre position indicator, contractile status, sync health, and
/// guided tour.
let renderTopologyView = (
  orbital: orbitalState,
  contractiles: array<contractile>,
  tour: tourState,
): Tea_Vdom.t<msg> => {
  // Barycentre position as a CSS percentage offset from centre.
  // -1.0 maps to 15%, 0.0 maps to 50%, +1.0 maps to 85%.
  let baryPct = Float.toFixed(50.0 +. orbital.barycentrePosition *. 35.0, ~digits=1)

  div(
    list{Attrs.class_("h-full flex flex-col items-center overflow-y-auto py-4 relative")},
    list{
      // Section title
      div(
        list{Attrs.class_("text-center mb-2")},
        list{
          div(
            list{Attrs.class_("text-sm font-semibold text-gray-300 tracking-wide")},
            list{text("Task Barycentre")},
          ),
          div(
            list{Attrs.class_("text-[10px] text-gray-600")},
            list{text("Binary Star Co-Orbit Monitor")},
          ),
        },
      ),
      // Tour start button (if not active)
      if !tour.active {
        div(
          list{Attrs.class_("mb-3")},
          list{
            button(
              list{
                Attrs.class_(
                  "px-3 py-1 text-[10px] bg-indigo-900/50 hover:bg-indigo-800/50 border border-indigo-700/40 rounded-full text-indigo-300 transition-colors",
                ),
                Attrs.title("Take a guided tour of the Task Barycentre"),
                Events.onClick(PaneW(StartTour)),
              },
              list{
                text(
                  if tour.completed {
                    "Retake Tour"
                  } else {
                    "Take the Tour"
                  },
                ),
              },
            ),
          },
        )
      } else {
        noNode
      },
      // ─── Binary Star Diagram ───
      div(
        list{Attrs.class_("relative w-full max-w-md mx-auto"), Attrs.style("height", "200px")},
        list{
          // Orbital path (ellipse)
          div(
            list{
              Attrs.class_("absolute border-2 border-dashed border-gray-700/50 rounded-full"),
              Attrs.style("width", "320px"),
              Attrs.style("height", "140px"),
              Attrs.style("top", "50%"),
              Attrs.style("left", "50%"),
              Attrs.style("transform", "translate(-50%, -50%)"),
            },
            list{},
          ),
          // Symbolic star (left) — size scales with symbolicMass
          div(
            list{
              Attrs.class_(
                "absolute rounded-full bg-indigo-600/60 border-2 border-indigo-400 flex items-center justify-center shadow-lg shadow-indigo-500/30 transition-all duration-500",
              ),
              Attrs.style(
                "width",
                `${Int.toString(60 + Int.fromFloat(orbital.symbolicMass *. 30.0))}px`,
              ),
              Attrs.style(
                "height",
                `${Int.toString(60 + Int.fromFloat(orbital.symbolicMass *. 30.0))}px`,
              ),
              Attrs.style("left", "10%"),
              Attrs.style("top", "50%"),
              Attrs.style("transform", "translateY(-50%)"),
            },
            list{
              div(
                list{Attrs.class_("text-center")},
                list{
                  div(list{Attrs.class_("text-indigo-200 text-xs font-bold")}, list{text("L")}),
                  div(list{Attrs.class_("text-indigo-300 text-[9px]")}, list{text("Symbolic")}),
                },
              ),
            },
          ),
          // Neural star (right) — size scales with neuralStream
          div(
            list{
              Attrs.class_(
                "absolute rounded-full bg-emerald-600/60 border-2 border-emerald-400 flex items-center justify-center shadow-lg shadow-emerald-500/30 transition-all duration-500",
              ),
              Attrs.style(
                "width",
                `${Int.toString(60 + Int.fromFloat(orbital.neuralStream *. 30.0))}px`,
              ),
              Attrs.style(
                "height",
                `${Int.toString(60 + Int.fromFloat(orbital.neuralStream *. 30.0))}px`,
              ),
              Attrs.style("right", "10%"),
              Attrs.style("top", "50%"),
              Attrs.style("transform", "translateY(-50%)"),
            },
            list{
              div(
                list{Attrs.class_("text-center")},
                list{
                  div(list{Attrs.class_("text-emerald-200 text-xs font-bold")}, list{text("N")}),
                  div(list{Attrs.class_("text-emerald-300 text-[9px]")}, list{text("Neural")}),
                },
              ),
            },
          ),
          // Barycentre marker (diamond) — positioned dynamically on the axis
          div(
            list{
              Attrs.class_(
                "absolute w-8 h-8 bg-amber-500/70 border-2 border-amber-300 shadow-lg shadow-amber-500/40 flex items-center justify-center transition-all duration-700",
              ),
              Attrs.style("top", "50%"),
              Attrs.style("left", baryPct ++ "%"),
              Attrs.style("transform", "translate(-50%, -50%) rotate(45deg)"),
            },
            list{
              div(
                list{
                  Attrs.class_("text-amber-100 text-[9px] font-bold"),
                  Attrs.style("transform", "rotate(-45deg)"),
                },
                list{text("W")},
              ),
            },
          ),
          // Drift aura glow (subtle ring around the diagram)
          div(
            list{
              Attrs.class_(
                `absolute rounded-full pointer-events-none transition-all duration-1000 ${if (
                    orbital.driftAuraColour === "indigo"
                  ) {
                    "shadow-[0_0_40px_rgba(99,102,241,0.15)]"
                  } else {
                    "shadow-[0_0_40px_rgba(245,158,11,0.2)]"
                  }}`,
              ),
              Attrs.style("width", "340px"),
              Attrs.style("height", "160px"),
              Attrs.style("top", "50%"),
              Attrs.style("left", "50%"),
              Attrs.style("transform", "translate(-50%, -50%)"),
            },
            list{},
          ),
        },
      ),
      // ─── Barycentre Position Bar ───
      div(
        list{Attrs.class_("w-full max-w-sm mx-auto mt-2 px-4")},
        list{
          div(
            list{Attrs.class_("flex justify-between text-[9px] text-gray-600 mb-0.5")},
            list{
              span(list{}, list{text("Symbolic")}),
              span(list{}, list{text("Balanced")}),
              span(list{}, list{text("Neural")}),
            },
          ),
          div(
            list{Attrs.class_("h-2 bg-gray-800 rounded-full relative overflow-hidden")},
            list{
              // Gradient background
              div(
                list{
                  Attrs.class_("absolute inset-0 opacity-30"),
                  Attrs.style(
                    "background",
                    "linear-gradient(to right, rgb(99,102,241), rgb(107,114,128), rgb(16,185,129))",
                  ),
                },
                list{},
              ),
              // Position marker
              div(
                list{
                  Attrs.class_(
                    "absolute top-0 bottom-0 w-1 bg-amber-400 rounded-full transition-all duration-700",
                  ),
                  Attrs.style("left", baryPct ++ "%"),
                  Attrs.style("transform", "translateX(-50%)"),
                },
                list{},
              ),
            },
          ),
        },
      ),
      // ─── Metric Gauges Grid ───
      div(
        list{Attrs.class_("w-full max-w-md mx-auto mt-4 grid grid-cols-4 gap-3 px-4")},
        list{
          renderMetricGauge("Stability", orbital.stability, "%"),
          renderMetricGauge("Divergence", orbital.divergenceLevel, "%", ~invert=true),
          renderMetricGauge("Sym. Mass", orbital.symbolicMass, "%"),
          renderMetricGauge("Neu. Stream", orbital.neuralStream, "%"),
        },
      ),
      // ─── Sync Health Bar ───
      div(
        list{Attrs.class_("w-full max-w-md mx-auto mt-3 px-4")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(list{Attrs.class_("text-[10px] text-gray-500")}, list{text("Sync Health")}),
              div(
                list{Attrs.class_("flex-1 h-1.5 bg-gray-800 rounded-full overflow-hidden")},
                list{
                  div(
                    list{
                      Attrs.class_(
                        `h-full rounded-full transition-all duration-500 ${if (
                            orbital.syncHealth >= 0.8
                          ) {
                            "bg-emerald-500"
                          } else if orbital.syncHealth >= 0.5 {
                            "bg-amber-500"
                          } else {
                            "bg-red-500"
                          }}`,
                      ),
                      Attrs.style(
                        "width",
                        `${Float.toFixed(orbital.syncHealth *. 100.0, ~digits=0)}%`,
                      ),
                    },
                    list{},
                  ),
                },
              ),
              span(
                list{Attrs.class_("text-[10px] text-gray-500 font-mono")},
                list{text(`${Int.toString(Int.fromFloat(orbital.syncHealth *. 100.0))}%`)},
              ),
            },
          ),
        },
      ),
      // ─── Contractile Boundaries ───
      div(
        list{Attrs.class_("w-full max-w-md mx-auto mt-3 px-4")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2 mb-1.5")},
            list{
              span(
                list{
                  Attrs.class_("text-[10px] text-gray-500 font-semibold uppercase tracking-wider"),
                },
                list{text("Contractiles")},
              ),
              span(
                list{Attrs.class_("text-[9px] text-gray-600")},
                list{text("(elastic adaptive boundaries)")},
              ),
            },
          ),
          div(
            list{Attrs.class_("space-y-1")},
            contractiles
            ->Array.map(c => renderContractileRow(c))
            ->List.fromArray,
          ),
        },
      ),
      // ─── Action Bar ───
      div(
        list{Attrs.class_("mt-4 flex gap-2")},
        list{
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-gray-800 hover:bg-gray-700 rounded text-sm text-gray-400 transition-colors",
              ),
              Attrs.title("Toggle between topology graph and code output view"),
              Attrs.ariaLabel("Switch to Code View"),
              Events.onClick(PaneW(ToggleTopologyView)),
            },
            list{text("Code View")},
          ),
        },
      ),
      // ─── Tour Overlay ───
      renderTourOverlay(tour),
    },
  )
}

/// Render the code/content view
let renderContentView = (state: paneWState, db: verisimdbState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("h-full flex flex-col")},
    list{
      // Last validated output
      div(
        list{Attrs.class_("mb-4")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-500 mb-2")},
            list{text("LAST VALIDATED OUTPUT")},
          ),
          div(
            list{
              Attrs.class_(
                "p-3 bg-gray-800/50 rounded border border-emerald-900/30 font-mono text-sm text-emerald-200 min-h-[60px]",
              ),
            },
            list{
              text(
                state.lastValidatedOutput === ""
                  ? "No validated output yet"
                  : state.lastValidatedOutput,
              ),
            },
          ),
        },
      ),
      // Current content
      div(
        list{Attrs.class_("flex-1")},
        list{
          div(list{Attrs.class_("text-xs text-gray-500 mb-2")}, list{text("SHARED WORLD STATE")}),
          textarea(
            list{
              Attrs.class_(
                "w-full h-full bg-gray-800 border border-gray-700 rounded p-3 font-mono text-sm text-gray-300 resize-none focus:border-gray-500 focus:outline-none",
              ),
              Attrs.placeholder("Task output manifests here..."),
              Attrs.value(state.content),
              Events.onInput(value => PaneW(UpdateContent(value))),
              Attrs.ariaLabel("Shared World State"),
            },
            list{},
          ),
        },
      ),
      renderDatabaseTools(db),
      renderEventChainPanel(state),
      renderSecurityStudyView(state),
      renderSecurityDialog(state),
      // Toggle button
      div(
        list{Attrs.class_("mt-4 text-right")},
        list{
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-gray-800 hover:bg-gray-700 rounded text-sm text-gray-400 transition-colors",
              ),
              Events.onClick(PaneW(ToggleTopologyView)),
            },
            list{text("Switch to Topology View")},
          ),
        },
      ),
    },
  )
}

/// Main Pane-W view
let view = (
  state: paneWState,
  orbital: orbitalState,
  db: verisimdbState,
  ~contractiles: array<contractile>=[],
  ~tour: tourState={active: false, currentStep: TourIntro, completed: false},
): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("h-full flex flex-col p-4 bg-gray-900"),
      Attrs.role("region"),
      Attrs.ariaLabel("Task Barycentre Panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between mb-4")},
        list{
          div(list{Attrs.class_("text-gray-400 font-semibold")}, list{text("Task Barycentre")}),
          div(list{Attrs.class_("text-xs text-gray-600")}, list{text("Ctrl+Shift+B")}),
        },
      ),
      // Content
      if state.topologyView {
        renderTopologyView(orbital, contractiles, tour)
      } else {
        renderContentView(state, db)
      },
    },
  )
}
