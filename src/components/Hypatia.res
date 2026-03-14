// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Hypatia Component — Neurosymbolic scanner dashboard.
///
/// Renders the 5 neural network confidence gauges, scan results table,
/// quarantine status, pipeline health, and learning cycle progress.
/// The brain of the entire ecosystem.

open Model
open Msg
open Tea.Html

// ============================================================================
// Neural Network Gauge
// ============================================================================

/// Render a single neural network confidence gauge.
let renderNetGauge = (net: neuralNetState): Tea_Vdom.t<msg> => {
  let label = HypatiaEngine.netLabel(net.id)
  let desc = HypatiaEngine.netDescription(net.id)
  let dotColor = HypatiaEngine.netStatusColor(net.status)
  let confPct = Float.toFixed(net.confidence *. 100.0, ~digits=0)
  // Gauge bar width as percentage
  let barWidth = Float.toFixed(net.confidence *. 100.0, ~digits=0)
  let barColor = if net.confidence > 0.8 {
    "bg-green-500"
  } else if net.confidence > 0.5 {
    "bg-amber-500"
  } else {
    "bg-red-500"
  }

  div(
    list{
      Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4"),
      Attrs.role("meter"),
      Attrs.ariaLabel(`${label} confidence: ${confPct}%`),
      Attrs.prop("aria-valuenow", confPct),
      Attrs.prop("aria-valuemin", "0"),
      Attrs.prop("aria-valuemax", "100"),
    },
    list{
      // Header: name + status dot
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          span(list{Attrs.class_("text-sm font-medium text-gray-200")}, list{text(label)}),
          span(
            list{
              Attrs.class_(`w-2 h-2 rounded-full ${dotColor}`),
              Attrs.role("status"),
            },
            list{},
          ),
        },
      ),
      // Description
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-3")},
        list{text(desc)},
      ),
      // Confidence bar
      div(
        list{Attrs.class_("w-full bg-gray-800 rounded-full h-2 mb-2")},
        list{
          div(
            list{
              Attrs.class_(`${barColor} h-full rounded-full transition-all duration-500`),
              Attrs.prop("style", `width: ${barWidth}%`),
            },
            list{},
          ),
        },
      ),
      // Metrics
      div(
        list{Attrs.class_("flex justify-between text-xs text-gray-400")},
        list{
          span(list{}, list{text(`${confPct}% conf`)}),
          span(list{}, list{text(`${Int.toString(net.inferenceCount)} inferences`)}),
        },
      ),
    },
  )
}

// ============================================================================
// Scan Result Row
// ============================================================================

/// Render a single scan result row.
let renderScanRow = (scan: scanResult): Tea_Vdom.t<msg> => {
  let riskClass = if scan.riskScore > 0.7 {
    "text-red-400"
  } else if scan.riskScore > 0.3 {
    "text-amber-400"
  } else {
    "text-green-400"
  }
  let statusIcon = scan.passed ? "text-green-400" : "text-red-400"
  let statusText = scan.passed ? "PASS" : "FAIL"

  div(
    list{
      Attrs.class_("flex items-center gap-4 p-3 border-b border-gray-800 hover:bg-gray-900/50"),
      Attrs.role("row"),
    },
    list{
      // Pass/fail indicator
      span(
        list{Attrs.class_(`text-xs font-bold ${statusIcon} w-10`)},
        list{text(statusText)},
      ),
      // Repo name
      span(
        list{Attrs.class_("text-sm text-gray-300 w-48 truncate")},
        list{text(scan.repoName)},
      ),
      // Risk score
      span(
        list{Attrs.class_(`text-xs ${riskClass} w-16 text-right`)},
        list{text(`${Float.toFixed(scan.riskScore *. 100.0, ~digits=0)}%`)},
      ),
      // Finding count
      span(
        list{Attrs.class_("text-xs text-gray-400 w-20 text-right")},
        list{text(`${Int.toString(scan.findingCount)} findings`)},
      ),
      // Quarantine count
      span(
        list{Attrs.class_("text-xs text-gray-500 w-20 text-right")},
        list{text(`${Int.toString(scan.quarantineCount)} quarantined`)},
      ),
      // Last scanned
      span(
        list{Attrs.class_("text-xs text-gray-600 flex-1 text-right truncate")},
        list{text(scan.lastScanned)},
      ),
    },
  )
}

// ============================================================================
// Learning Cycle Status
// ============================================================================

/// Render the learning cycle progress indicator.
let renderLearningCycle = (cycle: learningCycle): Tea_Vdom.t<msg> => {
  let progress = if cycle.reposTotal > 0 {
    Int.toFloat(cycle.reposScanned) /. Int.toFloat(cycle.reposTotal) *. 100.0
  } else {
    0.0
  }
  let pctStr = Float.toFixed(progress, ~digits=0)

  div(
    list{
      Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4"),
      Attrs.role("status"),
      Attrs.ariaLabel(`Learning cycle: ${pctStr}% complete`),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          span(list{Attrs.class_("text-sm font-medium text-gray-300")}, list{text("Learning Cycle")}),
          span(
            list{Attrs.class_("text-xs text-indigo-400")},
            list{text(HypatiaEngine.stageLabel(cycle.stage))},
          ),
        },
      ),
      // Progress bar
      div(
        list{Attrs.class_("w-full bg-gray-800 rounded-full h-2 mb-2")},
        list{
          div(
            list{
              Attrs.class_("bg-indigo-500 h-full rounded-full transition-all"),
              Attrs.prop("style", `width: ${pctStr}%`),
            },
            list{},
          ),
        },
      ),
      div(
        list{Attrs.class_("flex justify-between text-xs text-gray-500")},
        list{
          span(list{}, list{text(`${Int.toString(cycle.reposScanned)}/${Int.toString(cycle.reposTotal)} repos`)}),
          if cycle.noveltyTriggered {
            span(
              list{Attrs.class_("text-amber-400")},
              list{text("Novelty detected")},
            )
          } else {
            noNode
          },
        },
      ),
    },
  )
}

// ============================================================================
// Category Tabs
// ============================================================================

/// Render the category tab bar (Dashboard, Scans, Quarantine, Neural, Recipes).
let renderTabs = (active: hypatiaCategory): Tea_Vdom.t<msg> => {
  let tabs: array<hypatiaCategory> = [HypatiaDashboard, HypatiaScans, HypatiaQuarantine, HypatiaNeural, HypatiaRecipes]
  div(
    list{
      Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"),
      Attrs.role("tablist"),
      Attrs.ariaLabel("Hypatia panel sections"),
    },
    tabs->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-emerald-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(Hypatia(SetHypatiaCategory(tab))),
        },
        list{text(HypatiaEngine.categoryLabel(tab))},
      )
    })->List.fromArray,
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Main Hypatia panel view — full-screen overlay with neural gauges, scan results, and recipes.
let view = (hypatia: hypatiaState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Hypatia neurosymbolic scanner panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-medium text-gray-200")}, list{text("Hypatia")}),
              span(list{Attrs.class_("text-xs text-gray-500")}, list{text("neurosymbolic CI/CD intelligence")}),
              span(
                list{Attrs.class_("text-xs text-emerald-400 ml-2")},
                list{
                  text(
                    `${Float.toFixed(HypatiaEngine.avgConfidence(hypatia.networks) *. 100.0, ~digits=0)}% ensemble confidence`,
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
                  Attrs.class_("px-3 py-1 text-xs bg-emerald-600 text-white rounded hover:bg-emerald-500"),
                  Events.onClick(Hypatia(LoadHypatia)),
                },
                list{text("Refresh")},
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
          if hypatia.loading {
            div(
              list{Attrs.class_("text-gray-400"), Attrs.role("status")},
              list{text("Scanning...")},
            )
          } else if !hypatia.loaded {
            div(
              list{Attrs.class_("text-center text-gray-500 mt-12")},
              list{
                div(list{Attrs.class_("text-4xl mb-2")}, list{text("Hypatia")}),
                div(list{Attrs.class_("text-sm mb-1")}, list{text("Neurosymbolic CI/CD Intelligence")}),
                div(list{Attrs.class_("text-xs text-gray-600 mb-6")}, list{text(`5 neural networks. ${Int.toString(hypatia.totalRepos)}+ repos. Safety triangle routing.`)}),
                button(
                  list{
                    Attrs.class_("px-4 py-2 bg-emerald-600 text-white rounded hover:bg-emerald-500"),
                    Events.onClick(Hypatia(LoadHypatia)),
                  },
                  list{text("Connect to Hypatia")},
                ),
              },
            )
          } else {
            div(
              list{Attrs.class_("space-y-4")},
              list{
                renderTabs(hypatia.activeCategory),
                switch hypatia.activeCategory {
                | HypatiaDashboard =>
                  div(
                    list{Attrs.class_("space-y-6")},
                    list{
                      // Summary bar
                      div(
                        list{Attrs.class_("flex gap-6 text-sm")},
                        list{
                          div(list{Attrs.class_("text-gray-400")}, list{text(`${Int.toString(hypatia.totalRepos)} repos`)}),
                          div(list{Attrs.class_("text-gray-400")}, list{text(`${Int.toString(Array.length(hypatia.scans))} scanned`)}),
                          div(list{Attrs.class_("text-gray-400")}, list{text(`${Int.toString(hypatia.quarantinedCount)} quarantined`)}),
                        },
                      ),
                      // Neural network gauges (5 in a row)
                      div(
                        list{
                          Attrs.class_("grid grid-cols-5 gap-3"),
                          Attrs.role("list"),
                          Attrs.ariaLabel("Neural network ensemble"),
                        },
                        hypatia.networks->Array.map(net => renderNetGauge(net))->List.fromArray,
                      ),
                      // Safety Triangle summary
                      switch hypatia.triangleCounts {
                      | Some((elim, sub, ctrl)) =>
                        div(
                          list{
                            Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4"),
                            Attrs.role("figure"),
                            Attrs.ariaLabel("Safety triangle — hierarchy of controls"),
                          },
                          list{
                            div(
                              list{Attrs.class_("text-sm font-medium text-gray-300 mb-3")},
                              list{text("Safety Triangle")},
                            ),
                            div(
                              list{Attrs.class_("space-y-2")},
                              list{
                                // Eliminate tier
                                div(
                                  list{Attrs.class_("flex items-center gap-3")},
                                  list{
                                    div(
                                      list{Attrs.class_("w-20 text-right text-xs text-red-400 font-medium")},
                                      list{text("Eliminate")},
                                    ),
                                    div(
                                      list{Attrs.class_("flex-1 bg-gray-800 rounded-full h-3 overflow-hidden")},
                                      list{
                                        div(
                                          list{
                                            Attrs.class_("bg-red-600 h-full rounded-full transition-all"),
                                            Attrs.prop("style", `width: ${Int.toString(elim * 10)}%`),
                                          },
                                          list{},
                                        ),
                                      },
                                    ),
                                    div(
                                      list{Attrs.class_("w-8 text-xs text-gray-400 text-right")},
                                      list{text(Int.toString(elim))},
                                    ),
                                  },
                                ),
                                // Substitute tier
                                div(
                                  list{Attrs.class_("flex items-center gap-3")},
                                  list{
                                    div(
                                      list{Attrs.class_("w-20 text-right text-xs text-amber-400 font-medium")},
                                      list{text("Substitute")},
                                    ),
                                    div(
                                      list{Attrs.class_("flex-1 bg-gray-800 rounded-full h-3 overflow-hidden")},
                                      list{
                                        div(
                                          list{
                                            Attrs.class_("bg-amber-600 h-full rounded-full transition-all"),
                                            Attrs.prop("style", `width: ${Int.toString(sub * 10)}%`),
                                          },
                                          list{},
                                        ),
                                      },
                                    ),
                                    div(
                                      list{Attrs.class_("w-8 text-xs text-gray-400 text-right")},
                                      list{text(Int.toString(sub))},
                                    ),
                                  },
                                ),
                                // Control tier
                                div(
                                  list{Attrs.class_("flex items-center gap-3")},
                                  list{
                                    div(
                                      list{Attrs.class_("w-20 text-right text-xs text-blue-400 font-medium")},
                                      list{text("Control")},
                                    ),
                                    div(
                                      list{Attrs.class_("flex-1 bg-gray-800 rounded-full h-3 overflow-hidden")},
                                      list{
                                        div(
                                          list{
                                            Attrs.class_("bg-blue-600 h-full rounded-full transition-all"),
                                            Attrs.prop("style", `width: ${Int.toString(ctrl * 10)}%`),
                                          },
                                          list{},
                                        ),
                                      },
                                    ),
                                    div(
                                      list{Attrs.class_("w-8 text-xs text-gray-400 text-right")},
                                      list{text(Int.toString(ctrl))},
                                    ),
                                  },
                                ),
                              },
                            ),
                          },
                        )
                      | None => noNode
                      },
                      // Outcomes summary
                      switch hypatia.outcomes {
                      | Some(out) =>
                        div(
                          list{
                            Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4"),
                            Attrs.role("region"),
                            Attrs.ariaLabel("Dispatch outcomes summary"),
                          },
                          list{
                            div(
                              list{Attrs.class_("text-sm font-medium text-gray-300 mb-3")},
                              list{text("Outcomes")},
                            ),
                            div(
                              list{Attrs.class_("flex gap-6 text-xs")},
                              list{
                                div(
                                  list{Attrs.class_("text-gray-400")},
                                  list{text(`${Int.toString(out.totalOutcomes)} total`)},
                                ),
                                div(
                                  list{Attrs.class_("text-gray-400")},
                                  list{text(`${Int.toString(out.successCount)} succeeded`)},
                                ),
                                div(
                                  list{
                                    Attrs.class_(
                                      if out.successRate >= 90.0 {
                                        "text-green-400"
                                      } else if out.successRate >= 70.0 {
                                        "text-amber-400"
                                      } else {
                                        "text-red-400"
                                      },
                                    ),
                                  },
                                  list{text(`${Float.toFixed(out.successRate, ~digits=1)}% success`)},
                                ),
                                div(
                                  list{
                                    Attrs.class_(
                                      if out.mismatchFixApplied {
                                        "text-green-400"
                                      } else {
                                        "text-amber-400"
                                      },
                                    ),
                                  },
                                  list{
                                    text(
                                      if out.mismatchFixApplied {
                                        "Mismatch fix: applied"
                                      } else {
                                        "Mismatch fix: pending"
                                      },
                                    ),
                                  },
                                ),
                              },
                            ),
                          },
                        )
                      | None => noNode
                      },
                      // Learning cycle
                      switch hypatia.learningCycle {
                      | Some(cycle) => renderLearningCycle(cycle)
                      | None => noNode
                      },
                    },
                  )
                | HypatiaScans => {
                    let filtered = HypatiaEngine.filterScans(hypatia.scans, hypatia.filterText)
                    div(
                      list{Attrs.class_("space-y-4")},
                      list{
                        // Filter
                        div(
                          list{Attrs.class_("flex items-center gap-3")},
                          list{
                            input(
                              list{
                                Attrs.class_("flex-1 bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 placeholder-gray-600"),
                                Attrs.placeholder("Filter by repo name..."),
                                Attrs.ariaLabel("Filter scan results"),
                                Attrs.value(hypatia.filterText),
                                Events.onInput(v => Hypatia(SetHypatiaFilter(v))),
                              },
                              list{},
                            ),
                            span(
                              list{Attrs.class_("text-xs text-gray-500")},
                              list{text(`${Int.toString(Array.length(filtered))} results`)},
                            ),
                          },
                        ),
                        // Results table
                        div(
                          list{
                            Attrs.class_("border border-gray-700 rounded-lg overflow-hidden"),
                            Attrs.role("table"),
                          },
                          list{
                            div(
                              list{Attrs.class_("flex items-center gap-4 p-3 bg-gray-900 border-b border-gray-700 text-xs text-gray-500")},
                              list{
                                span(list{Attrs.class_("w-10")}, list{text("Status")}),
                                span(list{Attrs.class_("w-48")}, list{text("Repository")}),
                                span(list{Attrs.class_("w-16 text-right")}, list{text("Risk")}),
                                span(list{Attrs.class_("w-20 text-right")}, list{text("Findings")}),
                                span(list{Attrs.class_("w-20 text-right")}, list{text("Quarantine")}),
                                span(list{Attrs.class_("flex-1 text-right")}, list{text("Last Scan")}),
                              },
                            ),
                            div(
                              list{Attrs.class_("max-h-96 overflow-y-auto")},
                              filtered->Array.map(s => renderScanRow(s))->List.fromArray,
                            ),
                          },
                        ),
                      },
                    )
                  }
                | HypatiaQuarantine =>
                  div(
                    list{
                      Attrs.class_("space-y-4"),
                      Attrs.role("region"),
                      Attrs.ariaLabel("Quarantine status"),
                    },
                    list{
                      if hypatia.quarantinedCount > 0 {
                        div(
                          list{Attrs.class_("bg-amber-900/20 border border-amber-700 rounded-lg p-4")},
                          list{
                            div(
                              list{Attrs.class_("flex items-center gap-3 mb-2")},
                              list{
                                span(
                                  list{Attrs.class_("text-amber-400 text-sm font-medium")},
                                  list{text(`${Int.toString(hypatia.quarantinedCount)} items quarantined`)},
                                ),
                              },
                            ),
                            div(
                              list{Attrs.class_("text-xs text-gray-400")},
                              list{text("These items have been held for human review. Connect to the Hypatia backend to inspect and resolve individual quarantine entries.")},
                            ),
                          },
                        )
                      } else {
                        div(
                          list{Attrs.class_("text-center py-12")},
                          list{
                            div(
                              list{Attrs.class_("text-3xl text-gray-600 mb-2")},
                              list{text("Clear")},
                            ),
                            div(
                              list{Attrs.class_("text-sm text-gray-500")},
                              list{text("No items in quarantine. All findings have been routed through the safety triangle.")},
                            ),
                          },
                        )
                      },
                    },
                  )
                | HypatiaNeural =>
                  div(
                    list{Attrs.class_("grid grid-cols-2 lg:grid-cols-3 gap-4")},
                    hypatia.networks->Array.map(net => renderNetGauge(net))->List.fromArray,
                  )
                | HypatiaRecipes =>
                  div(
                    list{
                      Attrs.class_("space-y-4"),
                      Attrs.role("region"),
                      Attrs.ariaLabel("Recipe inventory"),
                    },
                    list{
                      // Summary stats row
                      {
                        let total = Array.length(hypatia.recipeEntries)
                        let withFix = hypatia.recipeEntries->Array.filter(r => r.hasFixScript)->Array.length
                        let elimCount = hypatia.recipeEntries->Array.filter(r => r.tier === Eliminate)->Array.length
                        let subCount = hypatia.recipeEntries->Array.filter(r => r.tier === Substitute)->Array.length
                        let ctrlCount = hypatia.recipeEntries->Array.filter(r => r.tier === Control)->Array.length
                        div(
                          list{Attrs.class_("flex gap-4 text-xs flex-wrap")},
                          list{
                            div(list{Attrs.class_("text-gray-300 font-medium")}, list{text(`${Int.toString(total)} recipes`)}),
                            div(list{Attrs.class_("text-green-400")}, list{text(`${Int.toString(withFix)} with fix_script`)}),
                            div(list{Attrs.class_("text-red-400")}, list{text(`${Int.toString(elimCount)} eliminate`)}),
                            div(list{Attrs.class_("text-amber-400")}, list{text(`${Int.toString(subCount)} substitute`)}),
                            div(list{Attrs.class_("text-blue-400")}, list{text(`${Int.toString(ctrlCount)} control`)}),
                          },
                        )
                      },
                      // Filter input
                      input(
                        list{
                          Attrs.class_("w-full bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 placeholder-gray-600"),
                          Attrs.placeholder("Filter recipes by name, description, or language..."),
                          Attrs.ariaLabel("Filter recipes"),
                          Attrs.value(hypatia.recipeFilter),
                          Events.onInput(v => Hypatia(SetRecipeFilter(v))),
                        },
                        list{},
                      ),
                      // Two-column layout: recipe list + detail
                      {
                        let filtered = HypatiaEngine.filterRecipes(hypatia.recipeEntries, hypatia.recipeFilter)
                        div(
                          list{Attrs.class_("flex gap-4")},
                          list{
                            // Recipe list (left)
                            div(
                              list{
                                Attrs.class_("flex-1 border border-gray-700 rounded-lg overflow-hidden"),
                                Attrs.role("list"),
                              },
                              list{
                                // Column headers
                                div(
                                  list{Attrs.class_("flex items-center gap-2 p-2 bg-gray-900 border-b border-gray-700 text-xs text-gray-500")},
                                  list{
                                    span(list{Attrs.class_("w-6")}, list{text("")}),
                                    span(list{Attrs.class_("flex-1")}, list{text("Recipe")}),
                                    span(list{Attrs.class_("w-12 text-right")}, list{text("Conf")}),
                                    span(list{Attrs.class_("w-16 text-right")}, list{text("Tier")}),
                                    span(list{Attrs.class_("w-14 text-right")}, list{text("Fired")}),
                                  },
                                ),
                                div(
                                  list{Attrs.class_("max-h-[32rem] overflow-y-auto")},
                                  filtered->Array.map(recipe => {
                                    let isSelected = hypatia.selectedRecipe === Some(recipe.id)
                                    let confPct = Float.toFixed(recipe.confidence *. 100.0, ~digits=0)
                                    let tierCol = HypatiaEngine.tierColor(recipe.tier)
                                    div(
                                      list{
                                        Attrs.class_(`flex items-center gap-2 p-2 cursor-pointer transition-colors ${
                                          isSelected ? "bg-indigo-900/40 border-l-2 border-indigo-500" : "hover:bg-gray-900/50 border-l-2 border-transparent"
                                        }`),
                                        Attrs.role("listitem"),
                                        Events.onClick(Hypatia(SelectRecipe(Some(recipe.id)))),
                                      },
                                      list{
                                        // Fix script indicator
                                        span(
                                          list{Attrs.class_(`w-6 text-center text-xs ${recipe.hasFixScript ? "text-green-500" : "text-gray-700"}`)},
                                          list{text(recipe.hasFixScript ? "F" : "-")},
                                        ),
                                        // Name
                                        span(
                                          list{Attrs.class_("flex-1 text-sm text-gray-300 truncate")},
                                          list{text(recipe.name)},
                                        ),
                                        // Confidence
                                        span(
                                          list{Attrs.class_(`w-12 text-right text-xs ${
                                            recipe.confidence >= 0.97 ? "text-emerald-400" : recipe.confidence >= 0.93 ? "text-amber-400" : "text-red-400"
                                          }`)},
                                          list{text(`${confPct}%`)},
                                        ),
                                        // Tier
                                        span(
                                          list{Attrs.class_(`w-16 text-right text-xs ${tierCol}`)},
                                          list{text(HypatiaEngine.tierLabel(recipe.tier))},
                                        ),
                                        // Times triggered
                                        span(
                                          list{Attrs.class_("w-14 text-right text-xs text-gray-500 font-mono")},
                                          list{text(Int.toString(recipe.timesTriggered))},
                                        ),
                                      },
                                    )
                                  })->List.fromArray,
                                ),
                              },
                            ),
                            // Detail panel (right) — shown when a recipe is selected
                            switch hypatia.selectedRecipe {
                            | Some(recipeId) =>
                              switch HypatiaEngine.findRecipe(hypatia.recipeEntries, recipeId) {
                              | Some(recipe) =>
                                div(
                                  list{
                                    Attrs.class_(`w-80 border rounded-lg p-4 space-y-4 ${HypatiaEngine.tierBg(recipe.tier)}`),
                                    Attrs.role("complementary"),
                                    Attrs.ariaLabel(`Recipe detail: ${recipe.name}`),
                                  },
                                  list{
                                    // Header
                                    div(
                                      list{Attrs.class_("flex items-start justify-between")},
                                      list{
                                        div(
                                          list{Attrs.class_("space-y-1")},
                                          list{
                                            div(list{Attrs.class_("text-sm font-medium text-gray-200")}, list{text(recipe.name)}),
                                            div(list{Attrs.class_("text-xs text-gray-500 font-mono")}, list{text(recipe.id)}),
                                          },
                                        ),
                                        button(
                                          list{
                                            Attrs.class_("text-xs text-gray-500 hover:text-gray-300"),
                                            Events.onClick(Hypatia(SelectRecipe(None))),
                                            Attrs.ariaLabel("Close detail"),
                                          },
                                          list{text("x")},
                                        ),
                                      },
                                    ),
                                    // Description
                                    div(
                                      list{Attrs.class_("text-xs text-gray-400 leading-relaxed")},
                                      list{text(recipe.description)},
                                    ),
                                    // Properties grid
                                    div(
                                      list{Attrs.class_("grid grid-cols-2 gap-2 text-xs")},
                                      list{
                                        div(list{Attrs.class_("text-gray-500")}, list{text("Confidence")}),
                                        div(
                                          list{Attrs.class_(`font-mono ${recipe.confidence >= 0.97 ? "text-emerald-400" : "text-amber-400"}`)},
                                          list{text(`${Float.toFixed(recipe.confidence *. 100.0, ~digits=1)}%`)},
                                        ),
                                        div(list{Attrs.class_("text-gray-500")}, list{text("Tier")}),
                                        div(
                                          list{Attrs.class_(HypatiaEngine.tierColor(recipe.tier))},
                                          list{text(HypatiaEngine.tierLabel(recipe.tier))},
                                        ),
                                        div(list{Attrs.class_("text-gray-500")}, list{text("Fix script")}),
                                        div(
                                          list{Attrs.class_(recipe.hasFixScript ? "text-green-400" : "text-gray-600")},
                                          list{text(recipe.hasFixScript ? "Available" : "None")},
                                        ),
                                        div(list{Attrs.class_("text-gray-500")}, list{text("Times fired")}),
                                        div(list{Attrs.class_("text-gray-300 font-mono")}, list{text(Int.toString(recipe.timesTriggered))}),
                                        div(list{Attrs.class_("text-gray-500")}, list{text("Last triggered")}),
                                        div(list{Attrs.class_("text-gray-400")}, list{text(recipe.lastTriggered)}),
                                      },
                                    ),
                                    // Languages
                                    div(
                                      list{Attrs.class_("space-y-1")},
                                      list{
                                        div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Languages")}),
                                        div(
                                          list{Attrs.class_("flex flex-wrap gap-1")},
                                          recipe.languages->Array.map(lang =>
                                            span(
                                              list{Attrs.class_("px-2 py-0.5 text-xs bg-gray-800/80 text-gray-300 rounded border border-gray-700")},
                                              list{text(lang)},
                                            )
                                          )->List.fromArray,
                                        ),
                                      },
                                    ),
                                    // Confidence gauge
                                    div(
                                      list{Attrs.class_("space-y-1")},
                                      list{
                                        div(list{Attrs.class_("text-xs text-gray-500")}, list{text("Confidence gauge")}),
                                        div(
                                          list{Attrs.class_("w-full bg-gray-800/60 rounded-full h-2")},
                                          list{
                                            div(
                                              list{
                                                Attrs.class_(`h-full rounded-full transition-all ${
                                                  recipe.confidence >= 0.97 ? "bg-emerald-500" : recipe.confidence >= 0.93 ? "bg-amber-500" : "bg-red-500"
                                                }`),
                                                Attrs.prop("style", `width: ${Float.toFixed(recipe.confidence *. 100.0, ~digits=0)}%`),
                                              },
                                              list{},
                                            ),
                                          },
                                        ),
                                      },
                                    ),
                                  },
                                )
                              | None =>
                                div(
                                  list{Attrs.class_("w-80 border border-gray-700 rounded-lg p-4 text-xs text-gray-500")},
                                  list{text("Recipe not found")},
                                )
                              }
                            | None =>
                              div(
                                list{Attrs.class_("w-80 border border-gray-700 rounded-lg p-6 flex items-center justify-center")},
                                list{
                                  div(
                                    list{Attrs.class_("text-center text-gray-600 text-xs")},
                                    list{text("Select a recipe to view details")},
                                  ),
                                },
                              )
                            },
                          },
                        )
                      },
                    },
                  )
                },
              },
            )
          },
          switch hypatia.error {
          | Some(e) =>
            div(
              list{Attrs.class_("mt-4 p-3 bg-red-900/30 border border-red-700 rounded text-sm text-red-300"), Attrs.role("alert")},
              list{text(e)},
            )
          | None => noNode
          },
        },
      ),
    },
  )
}
