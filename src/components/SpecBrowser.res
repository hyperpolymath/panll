// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL SpecBrowser Component — browse language specifications side-by-side.
///
/// Five tabs: Overview, Compare, Grammar, Typing Rules, Verification.
/// Shows all 16 nextgen-languages with their grammar, spec, typing rules,
/// taxonomy completeness, and verification status.

open Model
open Msg
open Tea.Html

// ============================================================================
// Shared sub-views
// ============================================================================

/// Render category tabs.
let renderTabs = (active: specBrowserCategory): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"),
      Attrs.role("tablist"),
    },
    SpecBrowserEngine.allCategories->Array.map(tab => {
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
          Events.onClick(SpecBrowser(SetSpecCategory(tab))),
        },
        list{text(SpecBrowserEngine.categoryLabel(tab))},
      )
    })->List.fromArray,
  )
}

/// Render a taxonomy completeness badge.
let renderCompletenessBadge = (pct: int): Tea_Vdom.t<msg> => {
  span(
    list{Attrs.class_(`px-2 py-0.5 text-xs rounded border ${SpecBrowserEngine.completenessBadge(pct)}`)},
    list{text(Int.toString(pct) ++ "%")},
  )
}

/// Render file presence indicators for a language.
let renderFilePresence = (files: array<SpecBrowserModel.filePresence>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex gap-1")},
    files->Array.map(f => {
      let colour = SpecBrowserEngine.presenceColour(f.exists)
      let code = SpecBrowserEngine.fileKindCode(f.kind)
      span(
        list{
          Attrs.class_(`px-1 py-0.5 text-[10px] rounded ${colour} ${if f.exists { "bg-emerald-900/20" } else { "bg-red-900/20" }}`),
          Attrs.ariaLabel(SpecBrowserEngine.fileKindLabel(f.kind) ++ (if f.exists { " present" } else { " missing" })),
        },
        list{text(code)},
      )
    })->List.fromArray,
  )
}

/// Render a language row in the overview grid.
let renderLanguageRow = (lang: SpecBrowserModel.specLanguageEntry): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex items-center gap-3 p-3 border-b border-gray-800 hover:bg-gray-900/50 cursor-pointer"),
      Events.onClick(SpecBrowser(SelectSpecLanguage(Some(lang.name)))),
    },
    list{
      div(
        list{Attrs.class_("w-32")},
        list{
          div(list{Attrs.class_("text-sm font-medium text-gray-200")}, list{text(lang.name)}),
          div(list{Attrs.class_("text-[10px] text-gray-500")}, list{text(lang.implLang)}),
        },
      ),
      div(
        list{Attrs.class_("flex-1 text-xs text-gray-400 truncate")},
        list{text(lang.description)},
      ),
      renderFilePresence(lang.files),
      renderCompletenessBadge(lang.taxonomyCompleteness),
      div(
        list{Attrs.class_("w-20 text-right text-xs text-gray-500")},
        list{text(Int.toString(lang.verification.totalTests) ++ " tests")},
      ),
    },
  )
}

/// Render a spec content pane (for grammar/typing rules/comparison).
let renderSpecContent = (title: string, content: option<string>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4 flex-1 min-h-64")},
    list{
      div(list{Attrs.class_("text-xs text-gray-500 uppercase tracking-wide mb-2")}, list{text(title)}),
      switch content {
      | Some(c) =>
        pre(
          list{Attrs.class_("font-mono text-xs text-gray-300 whitespace-pre-wrap overflow-auto max-h-96")},
          list{text(c)},
        )
      | None =>
        div(
          list{Attrs.class_("text-sm text-gray-600 italic")},
          list{text("Content not loaded. Select a language and the spec will be loaded from disk.")},
        )
      },
    },
  )
}

/// Render a comparison side selector.
let renderSideSelector = (side: SpecBrowserModel.comparisonSide, selected: option<string>, langs: array<SpecBrowserModel.specLanguageEntry>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-2")},
    list{
      label(
        list{Attrs.class_("text-xs text-gray-500")},
        list{text(switch side { | LeftSide => "Left" | RightSide => "Right" })},
      ),
      div(
        list{Attrs.class_("flex flex-wrap gap-1")},
        langs->Array.map(l => {
          let isSelected = selected === Some(l.name)
          button(
            list{
              Attrs.class_(`px-2 py-1 text-xs rounded transition-colors ${isSelected
                  ? "bg-teal-600 text-white"
                  : "bg-gray-800 text-gray-400 hover:text-gray-200"}`),
              Events.onClick(SpecBrowser(SetComparisonSide(side, l.name))),
            },
            list{text(l.name)},
          )
        })->List.fromArray,
      ),
    },
  )
}

// ============================================================================
// Main View
// ============================================================================

/// Main view for the SpecBrowser panel.
let view = (sb: specBrowserState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("SpecBrowser language specification panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-medium text-gray-200")}, list{text("Spec Browser")}),
              span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Language Specification Explorer")}),
              {
                let summary = SpecBrowserEngine.portfolioSummary()
                span(
                  list{Attrs.class_("text-xs text-gray-600")},
                  list{text(`${Int.toString(summary.totalLanguages)} languages, avg ${Int.toString(summary.avgCompleteness)}% complete`)},
                )
              },
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              input(
                list{
                  Attrs.class_("bg-gray-900 border border-gray-700 rounded px-3 py-1 text-sm text-gray-200 placeholder-gray-600 w-48"),
                  Attrs.placeholder("Filter languages..."),
                  Attrs.value(sb.filterText),
                  Events.onInput(v => SpecBrowser(SetSpecFilter(v))),
                },
                list{},
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
          renderTabs(sb.activeCategory),
          {
            let filtered = {
              let base = SpecBrowserEngine.allLanguageSpecs
              let searched = SpecBrowserEngine.filterBySearch(base, sb.filterText)
              if sb.showIncompleteOnly {
                SpecBrowserEngine.filterIncomplete(searched)
              } else {
                searched
              }
            }
            switch sb.activeCategory {
            // ── Overview Tab ──
            | SpecOverview =>
              div(
                list{Attrs.class_("space-y-4")},
                list{
                  // Portfolio summary bar
                  {
                    let summary = SpecBrowserEngine.portfolioSummary()
                    div(
                      list{Attrs.class_("grid grid-cols-5 gap-3 mb-4")},
                      list{
                        div(list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 text-center")}, list{
                          div(list{Attrs.class_("text-2xl font-mono text-teal-400")}, list{text(Int.toString(summary.totalLanguages))}),
                          div(list{Attrs.class_("text-[10px] text-gray-500")}, list{text("Languages")}),
                        }),
                        div(list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 text-center")}, list{
                          div(list{Attrs.class_(`text-2xl font-mono ${SpecBrowserEngine.completenessColour(summary.avgCompleteness)}`)}, list{text(Int.toString(summary.avgCompleteness) ++ "%")}),
                          div(list{Attrs.class_("text-[10px] text-gray-500")}, list{text("Avg Completeness")}),
                        }),
                        div(list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 text-center")}, list{
                          div(list{Attrs.class_("text-2xl font-mono text-emerald-400")}, list{text(Int.toString(summary.fullySpecified))}),
                          div(list{Attrs.class_("text-[10px] text-gray-500")}, list{text("Fully Specified")}),
                        }),
                        div(list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 text-center")}, list{
                          div(list{Attrs.class_("text-2xl font-mono text-cyan-400")}, list{text(Int.toString(summary.totalTests))}),
                          div(list{Attrs.class_("text-[10px] text-gray-500")}, list{text("Total Tests")}),
                        }),
                        div(list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3 text-center")}, list{
                          div(list{Attrs.class_(`text-2xl font-mono ${if summary.totalAdmitted > 0 { "text-amber-400" } else { "text-emerald-400" }}`)}, list{text(Int.toString(summary.totalAdmitted))}),
                          div(list{Attrs.class_("text-[10px] text-gray-500")}, list{text("Admitted/Sorry")}),
                        }),
                      },
                    )
                  },
                  // Toggle incomplete filter
                  div(
                    list{Attrs.class_("flex items-center gap-2")},
                    list{
                      button(
                        list{
                          Attrs.class_(`px-3 py-1 text-xs rounded ${sb.showIncompleteOnly ? "bg-amber-600 text-white" : "bg-gray-800 text-gray-400"}`),
                          Events.onClick(SpecBrowser(ToggleIncompleteOnly)),
                        },
                        list{text("Show Incomplete Only")},
                      ),
                    },
                  ),
                  // Language grid
                  div(
                    list{Attrs.class_("border border-gray-700 rounded-lg overflow-hidden")},
                    list{
                      // Header
                      div(
                        list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-800/50 border-b border-gray-700 text-xs text-gray-500")},
                        list{
                          div(list{Attrs.class_("w-32")}, list{text("Language")}),
                          div(list{Attrs.class_("flex-1")}, list{text("Description")}),
                          div(list{Attrs.class_("w-56")}, list{text("Files")}),
                          div(list{Attrs.class_("w-12")}, list{text("Tax%")}),
                          div(list{Attrs.class_("w-20 text-right")}, list{text("Tests")}),
                        },
                      ),
                      // Rows
                      div(
                        list{Attrs.class_("max-h-96 overflow-y-auto")},
                        filtered->Array.map(renderLanguageRow)->List.fromArray,
                      ),
                    },
                  ),
                },
              )
            // ── Comparison Tab ──
            | SpecComparison =>
              div(
                list{Attrs.class_("space-y-4")},
                list{
                  div(
                    list{Attrs.class_("text-sm text-gray-400 mb-2")},
                    list{text("Select two languages to compare their specifications side-by-side.")},
                  ),
                  div(
                    list{Attrs.class_("grid grid-cols-2 gap-4")},
                    list{
                      renderSideSelector(LeftSide, sb.comparisonLeft, filtered),
                      renderSideSelector(RightSide, sb.comparisonRight, filtered),
                    },
                  ),
                  // Side-by-side content
                  div(
                    list{Attrs.class_("grid grid-cols-2 gap-4")},
                    list{
                      {
                        let left = sb.comparisonLeft->Option.flatMap(SpecBrowserEngine.findLanguage)
                        switch left {
                        | Some(l) => renderSpecContent(l.name ++ " — Grammar", l.grammarContent)
                        | None => renderSpecContent("Left — Grammar", None)
                        }
                      },
                      {
                        let right = sb.comparisonRight->Option.flatMap(SpecBrowserEngine.findLanguage)
                        switch right {
                        | Some(l) => renderSpecContent(l.name ++ " — Grammar", l.grammarContent)
                        | None => renderSpecContent("Right — Grammar", None)
                        }
                      },
                    },
                  ),
                  // File presence comparison
                  div(
                    list{Attrs.class_("grid grid-cols-2 gap-4")},
                    list{
                      {
                        let left = sb.comparisonLeft->Option.flatMap(SpecBrowserEngine.findLanguage)
                        switch left {
                        | Some(l) =>
                          div(
                            list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3")},
                            list{
                              div(list{Attrs.class_("text-xs text-gray-500 mb-2")}, list{text(l.name ++ " Files")}),
                              div(
                                list{Attrs.class_("space-y-1")},
                                l.files->Array.map(f =>
                                  div(
                                    list{Attrs.class_("flex items-center gap-2 text-xs")},
                                    list{
                                      span(list{Attrs.class_(SpecBrowserEngine.presenceColour(f.exists))}, list{text(if f.exists { "Yes" } else { "No" })}),
                                      span(list{Attrs.class_("text-gray-400")}, list{text(SpecBrowserEngine.fileKindLabel(f.kind))}),
                                      if f.lineCount > 0 {
                                        span(list{Attrs.class_("text-gray-600")}, list{text(Int.toString(f.lineCount) ++ " lines")})
                                      } else { noNode },
                                    },
                                  )
                                )->List.fromArray,
                              ),
                            },
                          )
                        | None => div(list{Attrs.class_("text-sm text-gray-600 italic")}, list{text("Select a language")})
                        }
                      },
                      {
                        let right = sb.comparisonRight->Option.flatMap(SpecBrowserEngine.findLanguage)
                        switch right {
                        | Some(l) =>
                          div(
                            list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3")},
                            list{
                              div(list{Attrs.class_("text-xs text-gray-500 mb-2")}, list{text(l.name ++ " Files")}),
                              div(
                                list{Attrs.class_("space-y-1")},
                                l.files->Array.map(f =>
                                  div(
                                    list{Attrs.class_("flex items-center gap-2 text-xs")},
                                    list{
                                      span(list{Attrs.class_(SpecBrowserEngine.presenceColour(f.exists))}, list{text(if f.exists { "Yes" } else { "No" })}),
                                      span(list{Attrs.class_("text-gray-400")}, list{text(SpecBrowserEngine.fileKindLabel(f.kind))}),
                                      if f.lineCount > 0 {
                                        span(list{Attrs.class_("text-gray-600")}, list{text(Int.toString(f.lineCount) ++ " lines")})
                                      } else { noNode },
                                    },
                                  )
                                )->List.fromArray,
                              ),
                            },
                          )
                        | None => div(list{Attrs.class_("text-sm text-gray-600 italic")}, list{text("Select a language")})
                        }
                      },
                    },
                  ),
                },
              )
            // ── Grammar Tab ──
            | SpecGrammar =>
              div(
                list{Attrs.class_("space-y-4")},
                list{
                  div(
                    list{Attrs.class_("text-sm text-gray-400 mb-2")},
                    list{text("Select a language to view its grammar definition (EBNF).")},
                  ),
                  div(
                    list{Attrs.class_("flex flex-wrap gap-1 mb-4")},
                    filtered->Array.map(l => {
                      let isSelected = sb.selectedLanguage === Some(l.name)
                      let hasGrammar = l.files->Array.some(f => f.kind === GrammarEbnf && f.exists)
                      button(
                        list{
                          Attrs.class_(`px-2 py-1 text-xs rounded transition-colors ${isSelected
                              ? "bg-teal-600 text-white"
                              : hasGrammar
                                ? "bg-gray-800 text-gray-300 hover:text-gray-100"
                                : "bg-gray-800 text-gray-600"}`),
                          Events.onClick(SpecBrowser(SelectSpecLanguage(Some(l.name)))),
                        },
                        list{text(l.name)},
                      )
                    })->List.fromArray,
                  ),
                  {
                    let selected = sb.selectedLanguage->Option.flatMap(SpecBrowserEngine.findLanguage)
                    switch selected {
                    | Some(l) => renderSpecContent(l.name ++ " — grammar.ebnf", l.grammarContent)
                    | None => div(list{Attrs.class_("text-sm text-gray-600 italic mt-8 text-center")}, list{text("Select a language above to view its grammar.")})
                    }
                  },
                },
              )
            // ── Typing Rules Tab ──
            | SpecTypingRules =>
              div(
                list{Attrs.class_("space-y-4")},
                list{
                  div(
                    list{Attrs.class_("text-sm text-gray-400 mb-2")},
                    list{text("Select a language to view its typing rules.")},
                  ),
                  div(
                    list{Attrs.class_("flex flex-wrap gap-1 mb-4")},
                    filtered->Array.map(l => {
                      let isSelected = sb.selectedLanguage === Some(l.name)
                      let hasRules = l.files->Array.some(f => f.kind === TypingRules && f.exists)
                      button(
                        list{
                          Attrs.class_(`px-2 py-1 text-xs rounded transition-colors ${isSelected
                              ? "bg-teal-600 text-white"
                              : hasRules
                                ? "bg-gray-800 text-gray-300 hover:text-gray-100"
                                : "bg-gray-800 text-gray-600"}`),
                          Events.onClick(SpecBrowser(SelectSpecLanguage(Some(l.name)))),
                        },
                        list{text(l.name)},
                      )
                    })->List.fromArray,
                  ),
                  {
                    let selected = sb.selectedLanguage->Option.flatMap(SpecBrowserEngine.findLanguage)
                    switch selected {
                    | Some(l) => renderSpecContent(l.name ++ " — typing-rules.md", l.typingRulesContent)
                    | None => div(list{Attrs.class_("text-sm text-gray-600 italic mt-8 text-center")}, list{text("Select a language above to view its typing rules.")})
                    }
                  },
                },
              )
            // ── Verification Tab ──
            | SpecVerification =>
              div(
                list{Attrs.class_("space-y-4")},
                list{
                  div(
                    list{Attrs.class_("text-sm text-gray-400 mb-2")},
                    list{text("Test, proof, and conformance status across all language projects.")},
                  ),
                  // Verification table
                  div(
                    list{Attrs.class_("border border-gray-700 rounded-lg overflow-hidden")},
                    list{
                      // Header
                      div(
                        list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-800/50 border-b border-gray-700 text-xs text-gray-500")},
                        list{
                          div(list{Attrs.class_("w-28")}, list{text("Language")}),
                          div(list{Attrs.class_("w-20 text-right")}, list{text("Tests")}),
                          div(list{Attrs.class_("w-20 text-right")}, list{text("Passing")}),
                          div(list{Attrs.class_("w-16 text-right")}, list{text("Pass%")}),
                          div(list{Attrs.class_("w-20 text-right")}, list{text("Proved")}),
                          div(list{Attrs.class_("w-20 text-right")}, list{text("Admitted")}),
                          div(list{Attrs.class_("w-16 text-center")}, list{text("Fuzz")}),
                          div(list{Attrs.class_("w-16 text-center")}, list{text("Conf")}),
                        },
                      ),
                      // Rows
                      div(
                        list{Attrs.class_("max-h-96 overflow-y-auto")},
                        filtered->Array.map(l => {
                          let v = l.verification
                          let passPct = if v.totalTests > 0 { v.passingTests * 100 / v.totalTests } else { 0 }
                          div(
                            list{Attrs.class_("flex items-center gap-3 p-2 border-b border-gray-800 hover:bg-gray-900/50 text-xs")},
                            list{
                              div(list{Attrs.class_("w-28 text-gray-200 font-medium")}, list{text(l.name)}),
                              div(list{Attrs.class_("w-20 text-right text-gray-300 font-mono")}, list{text(Int.toString(v.totalTests))}),
                              div(list{Attrs.class_("w-20 text-right text-emerald-400 font-mono")}, list{text(Int.toString(v.passingTests))}),
                              div(list{Attrs.class_(`w-16 text-right font-mono ${if passPct >= 90 { "text-emerald-400" } else if passPct >= 70 { "text-amber-400" } else { "text-red-400" }}`)}, list{text(Int.toString(passPct) ++ "%")}),
                              div(list{Attrs.class_("w-20 text-right text-violet-400 font-mono")}, list{text(Int.toString(v.provedCount))}),
                              div(list{Attrs.class_(`w-20 text-right font-mono ${if v.admittedCount > 0 { "text-amber-400" } else { "text-gray-600" }}`)}, list{text(Int.toString(v.admittedCount))}),
                              div(list{Attrs.class_("w-16 text-center")}, list{text(if v.hasFuzzing { "Yes" } else { "-" })}),
                              div(list{Attrs.class_(`w-16 text-center ${if v.conformancePassing { "text-emerald-400" } else { "text-gray-600" }}`)}, list{text(if v.conformancePassing { "Pass" } else { "-" })}),
                            },
                          )
                        })->List.fromArray,
                      ),
                    },
                  ),
                },
              )
            }
          },
          // Error display
          switch sb.error {
          | Some(e) => div(list{Attrs.class_("mt-4 p-3 bg-red-900/30 border border-red-700 rounded text-sm text-red-300"), Attrs.role("alert")}, list{text(e)})
          | None => noNode
          },
        },
      ),
    },
  )
}
