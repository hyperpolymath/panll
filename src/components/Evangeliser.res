// SPDX-License-Identifier: MPL-2.0

/// PanLL Evangeliser Component — JS-to-ReScript transformation teaching panel.
///
/// Three-panel view integrated into PanLL's overlay system:
///   Panel-L section: Pattern constraints, category filters, confidence threshold
///   Panel-N section: Narrative reasoning, glyph annotations, scan progress
///   Panel-W section: JS→ReScript side-by-side with matched patterns
///
/// Philosophy: "Celebrate good, minimize bad, show better"

open Model
open Msg
open Tea.Html

// ============================================================================
// Tab Navigation
// ============================================================================

/// Render a tab button in the header.
let renderTab = (label: string, tab: evangeliserTab, active: evangeliserTab): Tea_Vdom.t<msg> => {
  let isActive = tab === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{Attrs.class_(cls), Attrs.ariaLabel(label), Events.onClick(Evangeliser(SetTab(tab)))},
    list{text(label)},
  )
}

// ============================================================================
// Panel-L: Constraints Sidebar
// ============================================================================

/// Render the constraint controls (left column in scan tab).
let renderConstraints = (state: evangeliserState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("w-64 border-r border-gray-800 p-3 flex flex-col gap-3 overflow-y-auto")},
    list{
      // Section header
      div(
        list{Attrs.class_("text-[10px] uppercase tracking-wider text-gray-500 font-medium")},
        list{text("Constraints (Panel-L)")},
      ),
      // Confidence threshold
      div(
        list{Attrs.class_("flex flex-col gap-1")},
        list{
          label(
            list{Attrs.class_("text-[10px] text-gray-500")},
            list{
              text(
                "Min Confidence: " ++
                Float.toFixed(state.constraints.minConfidence *. 100.0, ~digits=0) ++ "%",
              ),
            },
          ),
          input(
            list{
              Attrs.type_("range"),
              Attrs.class_("w-full accent-indigo-500"),
              Attrs.value(Float.toString(state.constraints.minConfidence *. 100.0)),
              Events.onInput(v => Evangeliser(
                SetMinConfidence(Float.fromString(v)->Option.getOr(50.0) /. 100.0),
              )),
              Attrs.ariaLabel("Minimum confidence threshold"),
            },
            list{},
          ),
        },
      ),
      // Difficulty filter
      div(
        list{Attrs.class_("flex flex-col gap-1")},
        list{
          span(list{Attrs.class_("text-[10px] text-gray-500")}, list{text("Difficulty")}),
          div(
            list{Attrs.class_("flex gap-1")},
            list{
              button(
                list{
                  Attrs.class_(
                    if state.constraints.difficultyFilter === None {
                      "px-2 py-0.5 text-[10px] bg-gray-700 text-white rounded"
                    } else {
                      "px-2 py-0.5 text-[10px] text-gray-500 hover:text-gray-300 rounded cursor-pointer"
                    },
                  ),
                  Events.onClick(Evangeliser(SetDifficultyFilter(None))),
                },
                list{text("All")},
              ),
              button(
                list{
                  Attrs.class_(
                    if state.constraints.difficultyFilter === Some(Beginner) {
                      "px-2 py-0.5 text-[10px] bg-emerald-900 text-emerald-300 rounded"
                    } else {
                      "px-2 py-0.5 text-[10px] text-gray-500 hover:text-gray-300 rounded cursor-pointer"
                    },
                  ),
                  Events.onClick(Evangeliser(SetDifficultyFilter(Some(Beginner)))),
                },
                list{text("Beginner")},
              ),
              button(
                list{
                  Attrs.class_(
                    if state.constraints.difficultyFilter === Some(Intermediate) {
                      "px-2 py-0.5 text-[10px] bg-amber-900 text-amber-300 rounded"
                    } else {
                      "px-2 py-0.5 text-[10px] text-gray-500 hover:text-gray-300 rounded cursor-pointer"
                    },
                  ),
                  Events.onClick(Evangeliser(SetDifficultyFilter(Some(Intermediate)))),
                },
                list{text("Intermediate")},
              ),
              button(
                list{
                  Attrs.class_(
                    if state.constraints.difficultyFilter === Some(Advanced) {
                      "px-2 py-0.5 text-[10px] bg-red-900 text-red-300 rounded"
                    } else {
                      "px-2 py-0.5 text-[10px] text-gray-500 hover:text-gray-300 rounded cursor-pointer"
                    },
                  ),
                  Events.onClick(Evangeliser(SetDifficultyFilter(Some(Advanced)))),
                },
                list{text("Advanced")},
              ),
            },
          ),
        },
      ),
      // Category toggles
      div(
        list{Attrs.class_("flex flex-col gap-1")},
        list{
          span(
            list{Attrs.class_("text-[10px] text-gray-500")},
            list{
              text(
                "Categories (" ++
                Int.toString(Array.length(EvangeliserEngine.allCategories)) ++ ")",
              ),
            },
          ),
          div(
            list{Attrs.class_("flex flex-wrap gap-1")},
            EvangeliserEngine.allCategories
            ->Array.map(cat => {
              let enabled =
                state.constraints.enabledCategories->Array.length === 0 ||
                  state.constraints.enabledCategories->Array.includes(cat)
              let colour = if enabled {
                EvangeliserEngine.categoryColour(cat)
              } else {
                "text-gray-600"
              }
              button(
                list{
                  Attrs.class_(
                    "px-1.5 py-0.5 text-[9px] rounded border border-gray-800 " ++
                    colour ++ " hover:border-gray-600 cursor-pointer",
                  ),
                  Attrs.title(EvangeliserEngine.categoryLabel(cat)),
                  Events.onClick(Evangeliser(ToggleCategory(cat))),
                },
                list{text(EvangeliserEngine.categoryCode(cat))},
              )
            })
            ->List.fromArray,
          ),
        },
      ),
      // Pattern count
      div(
        list{Attrs.class_("mt-2 text-[10px] text-gray-600")},
        list{text(Int.toString(Array.length(state.patterns)) ++ " patterns loaded")},
      ),
    },
  )
}

// ============================================================================
// Panel-N: Narrative Display
// ============================================================================

/// Render the narrative for a single match.
let renderNarrative = (m: evangeliserMatch): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-3 bg-gray-900/60 rounded border border-gray-800 flex flex-col gap-2")},
    list{
      // Glyphs
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          span(list{Attrs.class_("text-sm")}, list{text(EvangeliserEngine.glyphSymbols(m.glyphs))}),
          span(
            list{
              Attrs.class_("text-xs font-medium " ++ EvangeliserEngine.categoryColour(m.category)),
            },
            list{text(m.patternName)},
          ),
          span(
            list{Attrs.class_("text-[10px] text-gray-600")},
            list{
              text(
                "L" ++
                Int.toString(m.startLine) ++
                " \xc2\xb7 " ++
                Float.toFixed(m.confidence *. 100.0, ~digits=0) ++ "%",
              ),
            },
          ),
        },
      ),
      // Celebrate
      div(
        list{Attrs.class_("text-[11px] text-emerald-400")},
        list{
          span(list{Attrs.class_("font-medium")}, list{text("Celebrate: ")}),
          text(m.narrative.celebrate),
        },
      ),
      // Minimize
      div(
        list{Attrs.class_("text-[11px] text-amber-400")},
        list{
          span(list{Attrs.class_("font-medium")}, list{text("Note: ")}),
          text(m.narrative.minimize),
        },
      ),
      // Better
      div(
        list{Attrs.class_("text-[11px] text-cyan-400")},
        list{
          span(list{Attrs.class_("font-medium")}, list{text("Better: ")}),
          text(m.narrative.better),
        },
      ),
      // Safety
      div(
        list{Attrs.class_("text-[11px] text-indigo-400")},
        list{
          span(list{Attrs.class_("font-medium")}, list{text("Safety: ")}),
          text(m.narrative.safety),
        },
      ),
    },
  )
}

// ============================================================================
// Panel-W: Results — JS→ReScript side-by-side
// ============================================================================

/// Render a single match result with JS→ReScript comparison.
let renderMatchResult = (m: evangeliserMatch, idx: int, selected: option<int>): Tea_Vdom.t<msg> => {
  let isSelected = selected === Some(idx)
  let borderCls = isSelected ? "border-cyan-600" : "border-gray-800 hover:border-gray-700"

  div(
    list{
      Attrs.class_("rounded border " ++ borderCls ++ " transition-colors cursor-pointer"),
      Events.onClick(Evangeliser(SelectMatch(Some(idx)))),
      Attrs.ariaLabel("Pattern match: " ++ m.patternName),
    },
    list{
      // Header row
      div(
        list{
          Attrs.class_(
            "flex items-center justify-between px-3 py-1.5 bg-gray-900/40 border-b border-gray-800",
          ),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(
                list{Attrs.class_("text-sm")},
                list{text(EvangeliserEngine.glyphSymbols(m.glyphs))},
              ),
              span(
                list{
                  Attrs.class_(
                    "text-xs font-medium " ++ EvangeliserEngine.categoryColour(m.category),
                  ),
                },
                list{text(m.patternName)},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(
                list{Attrs.class_("text-[10px] text-gray-500")},
                list{text("line " ++ Int.toString(m.startLine))},
              ),
              span(
                list{Attrs.class_("text-[10px] px-1.5 py-0.5 rounded bg-gray-800 text-gray-400")},
                list{text(Float.toFixed(m.confidence *. 100.0, ~digits=0) ++ "%")},
              ),
            },
          ),
        },
      ),
      // Code comparison
      div(
        list{Attrs.class_("grid grid-cols-2 divide-x divide-gray-800")},
        list{
          // JS side
          div(
            list{Attrs.class_("p-3")},
            list{
              div(
                list{Attrs.class_("text-[9px] uppercase text-gray-600 mb-1")},
                list{text("JavaScript")},
              ),
              pre(
                list{
                  Attrs.class_(
                    "text-[11px] text-gray-300 whitespace-pre-wrap font-mono bg-gray-900/40 p-2 rounded",
                  ),
                },
                list{code(list{}, list{text(m.jsExample)})},
              ),
            },
          ),
          // ReScript side
          div(
            list{Attrs.class_("p-3")},
            list{
              div(
                list{Attrs.class_("text-[9px] uppercase text-emerald-600 mb-1")},
                list{text("ReScript")},
              ),
              pre(
                list{
                  Attrs.class_(
                    "text-[11px] text-emerald-300 whitespace-pre-wrap font-mono bg-gray-900/40 p-2 rounded",
                  ),
                },
                list{code(list{}, list{text(m.rescriptExample)})},
              ),
            },
          ),
        },
      ),
      // Narrative (expanded when selected)
      if isSelected {
        div(list{Attrs.class_("border-t border-gray-800 p-3")}, list{renderNarrative(m)})
      } else {
        noNode
      },
    },
  )
}

// ============================================================================
// Tab: Scan (main input + results view)
// ============================================================================

/// Render the scan tab — JS input on left, results on right.
let renderScanTab = (state: evangeliserState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 flex overflow-hidden")},
    list{
      // Left: Constraints + Input
      div(
        list{Attrs.class_("flex flex-col flex-1")},
        list{
          // JS code input
          div(
            list{Attrs.class_("flex-1 flex flex-col p-3")},
            list{
              div(
                list{Attrs.class_("flex items-center justify-between mb-2")},
                list{
                  span(
                    list{Attrs.class_("text-[10px] uppercase text-gray-500")},
                    list{text("Paste JavaScript Code")},
                  ),
                  button(
                    list{
                      Attrs.class_(
                        if state.scanning {
                          "px-3 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-not-allowed"
                        } else {
                          "px-3 py-1 text-xs bg-indigo-600 hover:bg-indigo-500 text-white rounded cursor-pointer"
                        },
                      ),
                      Attrs.disabled(state.scanning),
                      Events.onClick(Evangeliser(RunScan)),
                      KeyboardNav.onActivate(Evangeliser(RunScan)),
                      Attrs.ariaLabel("Scan JavaScript code for patterns"),
                    },
                    list{
                      text(
                        if state.scanning {
                          "Scanning..."
                        } else {
                          "Scan"
                        },
                      ),
                    },
                  ),
                },
              ),
              textarea(
                list{
                  Attrs.class_(
                    "flex-1 bg-gray-900 border border-gray-800 rounded p-3 text-xs text-gray-200 font-mono resize-none focus:border-indigo-500 outline-none",
                  ),
                  Attrs.placeholder(
                    "// Paste your JavaScript code here...\n// The evangeliser will detect patterns and show\n// how ReScript makes them safer and cleaner.",
                  ),
                  Attrs.value(state.jsInput),
                  Events.onInput(v => Evangeliser(SetJsInput(v))),
                  Attrs.ariaLabel("JavaScript code input"),
                },
                list{},
              ),
              // Error display
              switch state.scanError {
              | Some(err) =>
                div(
                  list{
                    Attrs.class_(
                      "mt-2 px-3 py-1.5 bg-red-900/30 border border-red-800 rounded text-xs text-red-400",
                    ),
                  },
                  list{text(err)},
                )
              | None => noNode
              },
            },
          ),
        },
      ),
      // Right: Results
      div(
        list{Attrs.class_("flex-1 flex flex-col border-l border-gray-800 overflow-y-auto")},
        list{
          switch state.analysis {
          | None =>
            div(
              list{Attrs.class_("flex-1 flex items-center justify-center text-gray-600 text-sm")},
              list{text("Paste JS code and click Scan to see patterns")},
            )
          | Some(analysis) =>
            div(
              list{Attrs.class_("flex flex-col gap-2 p-3")},
              list{
                // Summary bar
                div(
                  list{Attrs.class_("flex items-center gap-3 mb-2 pb-2 border-b border-gray-800")},
                  list{
                    span(
                      list{Attrs.class_("text-xs text-gray-400")},
                      list{text(Int.toString(Array.length(analysis.matches)) ++ " matches")},
                    ),
                    span(
                      list{Attrs.class_("text-xs text-gray-600")},
                      list{
                        text(Float.toFixed(analysis.coveragePercentage, ~digits=1) ++ "% coverage"),
                      },
                    ),
                    span(
                      list{
                        Attrs.class_(
                          "text-[10px] px-1.5 py-0.5 rounded " ++
                          EvangeliserEngine.difficultyColour(analysis.difficulty),
                        ),
                      },
                      list{text(EvangeliserEngine.difficultyLabel(analysis.difficulty))},
                    ),
                    span(
                      list{Attrs.class_("text-[10px] text-gray-600")},
                      list{text(Float.toFixed(analysis.analysisTime, ~digits=1) ++ "ms")},
                    ),
                  },
                ),
                // Category breakdown
                div(
                  list{Attrs.class_("flex flex-wrap gap-1 mb-2")},
                  EvangeliserEngine.matchCategoryStats(analysis.matches)
                  ->Array.map(((cat, count)) => {
                    span(
                      list{
                        Attrs.class_(
                          "text-[9px] px-1.5 py-0.5 rounded bg-gray-900 " ++
                          EvangeliserEngine.categoryColour(cat),
                        ),
                      },
                      list{text(EvangeliserEngine.categoryCode(cat) ++ ":" ++ Int.toString(count))},
                    )
                  })
                  ->List.fromArray,
                ),
                // Match list
                div(
                  list{Attrs.class_("flex flex-col gap-2")},
                  analysis.matches
                  ->Array.mapWithIndex((m, idx) => {
                    renderMatchResult(m, idx, state.selectedMatchIndex)
                  })
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

// ============================================================================
// Tab: Pattern Library Browser
// ============================================================================

/// Render the pattern library browser.
let renderPatternsTab = (state: evangeliserState): Tea_Vdom.t<msg> => {
  let filtered = state.patterns->EvangeliserEngine.filterBySearch(state.filterText)

  div(
    list{Attrs.class_("flex-1 flex flex-col overflow-hidden")},
    list{
      // Search bar
      div(
        list{Attrs.class_("px-3 py-2 border-b border-gray-800")},
        list{
          input(
            list{
              Attrs.class_(
                "w-full bg-gray-900 border border-gray-800 rounded px-3 py-1.5 text-xs text-gray-200 focus:border-indigo-500 outline-none",
              ),
              Attrs.placeholder("Search patterns by name or tag..."),
              Attrs.value(state.filterText),
              Events.onInput(v => Evangeliser(SetFilterText(v))),
              Attrs.ariaLabel("Filter patterns"),
            },
            list{},
          ),
        },
      ),
      // Pattern grid
      div(
        list{Attrs.class_("flex-1 overflow-y-auto p-3")},
        list{
          div(
            list{Attrs.class_("grid grid-cols-1 gap-2")},
            filtered
            ->Array.map(p => {
              div(
                list{
                  Attrs.class_(
                    "p-3 bg-gray-900/40 rounded border border-gray-800 hover:border-gray-700 transition-colors",
                  ),
                },
                list{
                  div(
                    list{Attrs.class_("flex items-center justify-between mb-2")},
                    list{
                      div(
                        list{Attrs.class_("flex items-center gap-2")},
                        list{
                          span(
                            list{Attrs.class_("text-sm")},
                            list{text(EvangeliserEngine.glyphSymbols(p.glyphs))},
                          ),
                          span(
                            list{
                              Attrs.class_(
                                "text-xs font-medium " ++
                                EvangeliserEngine.categoryColour(p.category),
                              ),
                            },
                            list{text(p.name)},
                          ),
                        },
                      ),
                      div(
                        list{Attrs.class_("flex items-center gap-1")},
                        list{
                          span(
                            list{
                              Attrs.class_(
                                "text-[10px] px-1.5 py-0.5 rounded " ++
                                EvangeliserEngine.difficultyColour(p.difficulty),
                              ),
                            },
                            list{text(EvangeliserEngine.difficultyLabel(p.difficulty))},
                          ),
                          span(
                            list{Attrs.class_("text-[10px] text-gray-600")},
                            list{text(Float.toFixed(p.confidence *. 100.0, ~digits=0) ++ "%")},
                          ),
                        },
                      ),
                    },
                  ),
                  // JS→ReScript comparison
                  div(
                    list{Attrs.class_("grid grid-cols-2 gap-2")},
                    list{
                      div(
                        list{Attrs.class_("bg-gray-950 p-2 rounded")},
                        list{
                          div(
                            list{Attrs.class_("text-[8px] uppercase text-gray-600 mb-1")},
                            list{text("JS")},
                          ),
                          pre(
                            list{
                              Attrs.class_(
                                "text-[10px] text-gray-400 whitespace-pre-wrap font-mono",
                              ),
                            },
                            list{code(list{}, list{text(p.jsExample)})},
                          ),
                        },
                      ),
                      div(
                        list{Attrs.class_("bg-gray-950 p-2 rounded")},
                        list{
                          div(
                            list{Attrs.class_("text-[8px] uppercase text-emerald-700 mb-1")},
                            list{text("ReScript")},
                          ),
                          pre(
                            list{
                              Attrs.class_(
                                "text-[10px] text-emerald-400 whitespace-pre-wrap font-mono",
                              ),
                            },
                            list{code(list{}, list{text(p.rescriptExample)})},
                          ),
                        },
                      ),
                    },
                  ),
                  // Tags
                  div(
                    list{Attrs.class_("flex flex-wrap gap-1 mt-2")},
                    p.tags
                    ->Array.map(t => {
                      span(
                        list{
                          Attrs.class_("text-[9px] px-1 py-0.5 bg-gray-800 text-gray-500 rounded"),
                        },
                        list{text(t)},
                      )
                    })
                    ->List.fromArray,
                  ),
                },
              )
            })
            ->List.fromArray,
          ),
        },
      ),
      // Footer with count
      div(
        list{Attrs.class_("px-3 py-1.5 border-t border-gray-800 text-[10px] text-gray-600")},
        list{
          text(
            Int.toString(Array.length(filtered)) ++
            " of " ++
            Int.toString(Array.length(state.patterns)) ++ " patterns",
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Tab: Glyph Legend
// ============================================================================

/// Render the Makaton glyph legend.
let renderLegendTab = (state: evangeliserState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto p-4")},
    list{
      div(
        list{Attrs.class_("mb-4")},
        list{
          span(
            list{Attrs.class_("text-sm font-medium text-gray-200")},
            list{text("Makaton-Inspired Glyph System")},
          ),
          div(
            list{Attrs.class_("text-[11px] text-gray-500 mt-1")},
            list{
              text(
                "Glyphs transcend syntax to show semantic meaning. Each glyph represents a programming concept that maps from JavaScript patterns to ReScript equivalents.",
              ),
            },
          ),
        },
      ),
      div(
        list{Attrs.class_("grid grid-cols-1 md:grid-cols-2 gap-2")},
        state.glyphs
        ->Array.map(g => {
          let catColour = switch g.semanticCategory {
          | Transformation => "text-emerald-400"
          | Safety => "text-red-400"
          | Flow => "text-cyan-400"
          | Structure => "text-violet-400"
          | State => "text-amber-400"
          | Data => "text-pink-400"
          }
          div(
            list{
              Attrs.class_(
                "flex items-start gap-3 p-2 bg-gray-900/40 rounded border border-gray-800",
              ),
            },
            list{
              span(list{Attrs.class_("text-xl")}, list{text(g.symbol)}),
              div(
                list{Attrs.class_("flex flex-col")},
                list{
                  div(
                    list{Attrs.class_("flex items-center gap-2")},
                    list{
                      span(
                        list{Attrs.class_("text-xs font-medium text-gray-200")},
                        list{text(g.name)},
                      ),
                      span(
                        list{Attrs.class_("text-[9px] " ++ catColour)},
                        list{
                          text(
                            switch g.semanticCategory {
                            | Transformation => "transformation"
                            | Safety => "safety"
                            | Flow => "flow"
                            | Structure => "structure"
                            | State => "state"
                            | Data => "data"
                            },
                          ),
                        },
                      ),
                    },
                  ),
                  span(list{Attrs.class_("text-[10px] text-gray-500")}, list{text(g.meaning)}),
                },
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Main view function for the Evangeliser panel.
let view = (state: evangeliserState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("ReScript Evangeliser — JS to ReScript transformation panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(
                list{Attrs.class_("text-sm font-medium text-gray-200")},
                list{text("Evangeliser")},
              ),
              span(
                list{Attrs.class_("text-[10px] text-gray-600")},
                list{text("Celebrate good, minimize bad, show better")},
              ),
              span(
                list{Attrs.class_("text-[10px] px-1.5 py-0.5 rounded bg-gray-800 text-gray-500")},
                list{text(Int.toString(Array.length(state.patterns)) ++ " patterns")},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-1")},
            list{
              renderTab("Scan", TabScan, state.activeTab),
              renderTab("Patterns", TabPatterns, state.activeTab),
              renderTab("Results", TabResults, state.activeTab),
              renderTab("Legend", TabLegend, state.activeTab),
              // View layer selector
              div(
                list{Attrs.class_("ml-2 flex items-center gap-1 border-l border-gray-800 pl-2")},
                list{
                  span(list{Attrs.class_("text-[9px] text-gray-600")}, list{text("View:")}),
                  button(
                    list{
                      Attrs.class_(
                        if state.viewLayer === ViewRaw {
                          "text-[9px] px-1.5 py-0.5 bg-gray-700 text-white rounded"
                        } else {
                          "text-[9px] px-1.5 py-0.5 text-gray-500 hover:text-gray-300 rounded cursor-pointer"
                        },
                      ),
                      Events.onClick(Evangeliser(SetViewLayer(ViewRaw))),
                    },
                    list{text("RAW")},
                  ),
                  button(
                    list{
                      Attrs.class_(
                        if state.viewLayer === ViewGlyphed {
                          "text-[9px] px-1.5 py-0.5 bg-gray-700 text-white rounded"
                        } else {
                          "text-[9px] px-1.5 py-0.5 text-gray-500 hover:text-gray-300 rounded cursor-pointer"
                        },
                      ),
                      Events.onClick(Evangeliser(SetViewLayer(ViewGlyphed))),
                    },
                    list{text("GLYPHED")},
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Tab content
      div(
        list{Attrs.class_("flex-1 flex overflow-hidden")},
        list{
          // Constraints sidebar (visible in Scan and Results tabs)
          if state.activeTab === TabScan || state.activeTab === TabResults {
            renderConstraints(state)
          } else {
            noNode
          },
          // Main content area
          switch state.activeTab {
          | TabScan => renderScanTab(state)
          | TabPatterns => renderPatternsTab(state)
          | TabResults => renderScanTab(state) // Results shown in scan view
          | TabLegend => renderLegendTab(state)
          },
        },
      ),
    },
  )
}
