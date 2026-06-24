// SPDX-License-Identifier: MPL-2.0

/// PanLL Language Forge Component — view layer for the nextgen-languages panel.
///
/// Renders a full-screen overlay with the 14 nextgen-languages portfolio.
/// Layout follows the Farm panel pattern:
///   - Header with title, stats, and close button
///   - Category tab bar (All | Production Ready | In Progress | Needs Work)
///   - Filter/sort controls
///   - Language cards with score bars, phase badges, component indicators
///   - Selected language detail view with MoSCoW breakdown

open Model
open Msg
open Tea.Html

/// Render a single category tab button.
let renderCategoryTab = (cat: forgeCategory, isActive: bool): Tea_Vdom.t<msg> => {
  let activeClass = isActive
    ? "border-indigo-500 text-indigo-300 bg-gray-800/50"
    : "border-transparent text-gray-500 hover:text-gray-300 hover:border-gray-600"

  button(
    list{
      Attrs.class_(
        `px-3 py-2 text-sm font-medium border-b-2 cursor-pointer transition-colors ${activeClass}`,
      ),
      Attrs.role("tab"),
      Attrs.ariaLabel(`Filter by ${LanguageForgeEngine.categoryLabel(cat)}`),
      Events.onClick(LanguageForge(SetForgeCategory(cat))),
    },
    list{text(LanguageForgeEngine.categoryLabel(cat))},
  )
}

/// Render the category tab bar.
let renderCategoryTabBar = (activeCategory: forgeCategory): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex border-b border-gray-800 overflow-x-auto"),
      Attrs.role("tablist"),
      Attrs.ariaLabel("Language portfolio categories"),
    },
    LanguageForgeEngine.allCategories
    ->Array.map(cat => renderCategoryTab(cat, cat === activeCategory))
    ->List.fromArray,
  )
}

/// Render a phase badge with colour coding.
let renderPhaseBadge = (phase: languagePhase): Tea_Vdom.t<msg> => {
  span(
    list{
      Attrs.class_(
        `text-xs px-1.5 py-0.5 rounded border ${LanguageForgeEngine.phaseBadgeClass(phase)}`,
      ),
    },
    list{text(LanguageForgeEngine.phaseLabel(phase))},
  )
}

/// Render a score bar (horizontal progress indicator).
let renderScoreBar = (score: int): Tea_Vdom.t<msg> => {
  let pct = Int.toString(score)
  let barColour = if score >= 90 {
    "bg-emerald-500"
  } else if score >= 70 {
    "bg-green-500"
  } else if score >= 40 {
    "bg-amber-500"
  } else if score > 0 {
    "bg-red-500"
  } else {
    "bg-gray-700"
  }
  div(
    list{Attrs.class_("flex items-center gap-2"), Attrs.ariaLabel(`Score: ${pct} percent`)},
    list{
      div(
        list{Attrs.class_("flex-1 h-2 bg-gray-800 rounded-full overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_(`h-full ${barColour} rounded-full transition-all`),
              Attrs.style("width", `${pct}%`),
            },
            list{},
          ),
        },
      ),
      span(list{Attrs.class_("text-xs text-gray-400 w-8 text-right")}, list{text(`${pct}%`)}),
    },
  )
}

/// Render component pipeline indicators (lexer/parser/typechecker/wasm).
let renderPipelineIndicators = (lang: languageEntry): Tea_Vdom.t<msg> => {
  let indicator = (label: string, complete: bool): Tea_Vdom.t<msg> =>
    span(
      list{
        Attrs.class_(complete ? "text-emerald-400" : "text-gray-600"),
        Attrs.title(`${label}: ${complete ? "complete" : "incomplete"}`),
        Attrs.ariaLabel(`${label} ${complete ? "complete" : "incomplete"}`),
      },
      list{text(complete ? "Y" : "-")},
    )
  div(
    list{Attrs.class_("flex gap-3 text-xs")},
    list{
      indicator("Lexer", lang.lexerComplete),
      indicator("Parser", lang.parserComplete),
      indicator("Types", lang.typeCheckerComplete),
      indicator("WASM", lang.hasWasmBackend),
    },
  )
}

/// Render a single language card/row.
let renderLanguageRow = (lang: languageEntry, isSelected: bool): Tea_Vdom.t<msg> => {
  let selectedClass = isSelected
    ? "bg-gray-800/60 border-l-2 border-l-indigo-500"
    : "hover:bg-gray-800/30 border-l-2 border-l-transparent"

  div(
    list{
      Attrs.class_(
        `flex items-center gap-3 px-4 py-3 ${selectedClass} border-b border-gray-800/50 transition-colors cursor-pointer`,
      ),
      Attrs.role("button"),
      Attrs.tabIndex(0),
      Attrs.ariaLabel(
        `${lang.name} — ${LanguageForgeEngine.phaseLabel(lang.phase)}, score ${Int.toString(
            lang.score,
          )} percent`,
      ),
      Events.onClick(LanguageForge(SelectLanguage(Some(lang.name)))),
      KeyboardUtil.onEnterOrSpace(LanguageForge(SelectLanguage(Some(lang.name)))),
    },
    list{
      // Name + impl language
      div(
        list{Attrs.class_("w-36 min-w-0")},
        list{
          div(
            list{Attrs.class_("text-sm font-medium text-gray-200 truncate")},
            list{text(lang.name)},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-500 truncate")},
            list{text(lang.implLang === "" ? "unspecified" : lang.implLang)},
          ),
        },
      ),
      // Score bar
      div(list{Attrs.class_("flex-1 min-w-0")}, list{renderScoreBar(lang.score)}),
      // Phase badge
      div(list{Attrs.class_("w-28 flex justify-center")}, list{renderPhaseBadge(lang.phase)}),
      // Pipeline indicators
      div(list{Attrs.class_("w-28")}, list{renderPipelineIndicators(lang)}),
      // WASM readiness
      div(
        list{Attrs.class_("w-12 text-center")},
        list{
          span(
            list{
              Attrs.class_(
                lang.hasWasmBackend
                  ? "text-emerald-400 text-xs font-medium"
                  : "text-gray-600 text-xs",
              ),
              Attrs.title(lang.hasWasmBackend ? "WASM backend available" : "No WASM backend"),
            },
            list{text(lang.hasWasmBackend ? "WASM" : "-")},
          ),
        },
      ),
    },
  )
}

/// Render the table header row.
let renderTableHeader = (): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "flex items-center gap-3 px-4 py-2 border-b border-gray-700 text-xs font-medium text-gray-500 uppercase tracking-wider",
      ),
    },
    list{
      div(list{Attrs.class_("w-36")}, list{text("Language")}),
      div(list{Attrs.class_("flex-1")}, list{text("Score")}),
      div(list{Attrs.class_("w-28 text-center")}, list{text("Phase")}),
      div(list{Attrs.class_("w-28")}, list{text("L / P / T / W")}),
      div(list{Attrs.class_("w-12 text-center")}, list{text("WASM")}),
    },
  )
}

/// Render component detail table for a selected language.
let renderComponentDetails = (components: array<componentStatus>): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("space-y-2"),
      Attrs.role("list"),
      Attrs.ariaLabel("Component completion details"),
    },
    components
    ->Array.map(comp => {
      let pct = Int.toString(comp.completion)
      div(
        list{Attrs.class_("flex items-center gap-3"), Attrs.role("listitem")},
        list{
          div(list{Attrs.class_("w-32 text-sm text-gray-300")}, list{text(comp.name)}),
          div(
            list{Attrs.class_("flex-1 h-2 bg-gray-800 rounded-full overflow-hidden")},
            list{
              div(
                list{
                  Attrs.class_("h-full bg-indigo-500 rounded-full transition-all"),
                  Attrs.style("width", `${pct}%`),
                },
                list{},
              ),
            },
          ),
          div(list{Attrs.class_("w-12 text-xs text-gray-500 text-right")}, list{text(`${pct}%`)}),
          span(
            list{
              Attrs.class_(comp.hasTests ? "text-emerald-400 text-xs" : "text-gray-600 text-xs"),
              Attrs.title(comp.hasTests ? "Has tests" : "No tests"),
            },
            list{text(comp.hasTests ? "tested" : "untested")},
          ),
        },
      )
    })
    ->List.fromArray,
  )
}

/// Render the selected language detail panel.
let renderDetailView = (lang: languageEntry, showMoscow: bool): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("border-l border-gray-700 w-80 flex-shrink-0 overflow-y-auto p-4 space-y-4"),
      Attrs.role("complementary"),
      Attrs.ariaLabel(`${lang.name} detail view`),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          h3(list{Attrs.class_("text-lg font-medium text-gray-200")}, list{text(lang.name)}),
          button(
            list{
              Attrs.class_("text-gray-500 hover:text-gray-300 text-sm"),
              Attrs.ariaLabel("Close detail view"),
              Events.onClick(LanguageForge(SelectLanguage(None))),
            },
            list{text("X")},
          ),
        },
      ),
      // Summary stats
      div(
        list{Attrs.class_("space-y-1 text-sm")},
        list{
          div(
            list{Attrs.class_("flex justify-between text-gray-400")},
            list{
              text("Implementation"),
              span(
                list{Attrs.class_("text-gray-200")},
                list{text(lang.implLang === "" ? "None" : lang.implLang)},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex justify-between text-gray-400")},
            list{text("Phase"), renderPhaseBadge(lang.phase)},
          ),
          div(
            list{Attrs.class_("flex justify-between text-gray-400")},
            list{
              text("Score"),
              span(list{Attrs.class_("text-gray-200")}, list{text(`${Int.toString(lang.score)}%`)}),
            },
          ),
          div(
            list{Attrs.class_("flex justify-between text-gray-400")},
            list{
              text("LOC"),
              span(list{Attrs.class_("text-gray-200")}, list{text(Int.toString(lang.locCount))}),
            },
          ),
          div(
            list{Attrs.class_("flex justify-between text-gray-400")},
            list{
              text("TODOs"),
              span(
                list{Attrs.class_(lang.todoCount > 20 ? "text-amber-400" : "text-gray-200")},
                list{text(Int.toString(lang.todoCount))},
              ),
            },
          ),
        },
      ),
      // WASM readiness
      div(
        list{Attrs.class_("flex items-center gap-2 text-sm")},
        list{
          span(
            list{Attrs.class_(lang.hasWasmBackend ? "text-emerald-400" : "text-red-400")},
            list{text(lang.hasWasmBackend ? "WASM Ready" : "No WASM")},
          ),
        },
      ),
      // Component breakdown
      div(
        list{Attrs.class_("border-t border-gray-700 pt-3")},
        list{
          div(
            list{Attrs.class_("text-sm font-medium text-gray-300 mb-2")},
            list{text("Components")},
          ),
          if Array.length(lang.components) > 0 {
            renderComponentDetails(lang.components)
          } else {
            div(
              list{Attrs.class_("text-xs text-gray-500")},
              list{text("No components defined yet.")},
            )
          },
        },
      ),
      // MoSCoW toggle
      div(
        list{Attrs.class_("border-t border-gray-700 pt-3")},
        list{
          button(
            list{
              Attrs.class_("text-sm text-indigo-400 hover:text-indigo-300 transition-colors"),
              Attrs.ariaLabel(showMoscow ? "Hide MoSCoW breakdown" : "Show MoSCoW breakdown"),
              Events.onClick(LanguageForge(ToggleMoscow)),
              KeyboardNav.onActivate(LanguageForge(ToggleMoscow)),
            },
            list{text(showMoscow ? "Hide MoSCoW" : "Show MoSCoW")},
          ),
          if showMoscow {
            div(
              list{Attrs.class_("mt-2 space-y-1 text-xs text-gray-400")},
              list{
                div(list{}, list{text("Must Have: Lexer, Parser")}),
                div(list{}, list{text("Should Have: Type Checker, Tests")}),
                div(list{}, list{text("Could Have: WASM Backend, LSP")}),
                div(list{}, list{text("Won't Have (now): IDE Plugin, Package Manager")}),
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

/// Render summary statistics in the header.
let renderStats = (languages: array<languageEntry>): Tea_Vdom.t<msg> => {
  let total = Array.length(languages)
  let production = languages->Array.filter(l => l.phase === Production)->Array.length
  let withWasm = languages->Array.filter(l => l.hasWasmBackend)->Array.length
  div(
    list{Attrs.class_("flex items-center gap-3 text-xs text-gray-500")},
    list{
      span(list{}, list{text(`${Int.toString(total)} languages`)}),
      span(list{Attrs.class_("text-gray-700")}, list{text("|")}),
      span(
        list{Attrs.class_("text-emerald-400")},
        list{text(`${Int.toString(production)} production`)},
      ),
      span(list{Attrs.class_("text-gray-700")}, list{text("|")}),
      span(list{}, list{text(`${Int.toString(withWasm)} WASM`)}),
    },
  )
}

/// Render the header bar with title, stats, and controls.
let renderHeader = (forge: languageForgeState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center justify-between px-6 py-4 border-b border-gray-800")},
    list{
      // Title and stats
      div(
        list{Attrs.class_("flex items-center gap-4")},
        list{
          div(
            list{Attrs.class_("text-lg font-medium text-gray-200")},
            list{text("Language Forge")},
          ),
          if forge.loaded {
            renderStats(forge.languages)
          } else {
            noNode
          },
        },
      ),
      // Controls: filter, close
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          // Filter input
          input(
            list{
              Attrs.class_(
                "bg-gray-800 border border-gray-700 rounded px-3 py-1.5 text-sm text-gray-200 placeholder-gray-500 focus:border-indigo-500 focus:outline-none w-48",
              ),
              Attrs.placeholder("Filter languages..."),
              Attrs.value(forge.filterText),
              Attrs.ariaLabel("Filter languages by name or implementation"),
              Events.onInput(text => LanguageForge(SetForgeFilter(text))),
            },
            list{},
          ),
          // Close button
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-sm text-gray-400 hover:text-gray-200 bg-gray-800 rounded hover:bg-gray-700 transition-colors",
              ),
              Attrs.ariaLabel("Close Language Forge panel"),
              Events.onClick(PanelSwitcher(ClosePanels)),
              KeyboardNav.onActivate(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
          ),
        },
      ),
    },
  )
}

/// Render a loading state.
let renderLoading = (): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 flex items-center justify-center")},
    list{
      div(
        list{Attrs.class_("text-gray-500 animate-pulse")},
        list{text("Loading language portfolio...")},
      ),
    },
  )
}

/// Render an error state.
let renderError = (error: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 flex items-center justify-center")},
    list{
      div(
        list{Attrs.class_("text-center")},
        list{
          div(list{Attrs.class_("text-red-400 mb-2")}, list{text("Failed to load language data")}),
          div(list{Attrs.class_("text-sm text-gray-500 mb-4")}, list{text(error)}),
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-gray-800 text-gray-300 rounded hover:bg-gray-700 transition-colors",
              ),
              Attrs.ariaLabel("Retry loading language data"),
              Events.onClick(LanguageForge(LoadLanguages)),
              KeyboardNav.onActivate(LanguageForge(LoadLanguages)),
            },
            list{text("Retry")},
          ),
        },
      ),
    },
  )
}

/// Main Language Forge panel view — full-screen overlay.
let view = (forge: languageForgeState): Tea_Vdom.t<msg> => {
  let filtered = LanguageForgeEngine.filterLanguages(
    forge.languages,
    forge.activeCategory,
    forge.filterText,
  )
  let sorted = LanguageForgeEngine.sortLanguages(filtered, forge.sortBy)

  // Find selected language entry for detail view
  let selectedEntry = switch forge.selectedLanguage {
  | None => None
  | Some(name) => forge.languages->Array.find(l => l.name === name)
  }

  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.ariaLabel("Language Forge panel"),
    },
    list{
      // Header
      renderHeader(forge),
      // Category tabs
      renderCategoryTabBar(forge.activeCategory),
      // Content area with optional detail sidebar
      if forge.loading {
        renderLoading()
      } else {
        switch forge.error {
        | Some(e) => renderError(e)
        | None =>
          if !forge.loaded {
            renderLoading()
          } else {
            div(
              list{Attrs.class_("flex-1 flex overflow-hidden")},
              list{
                // Main language list
                div(
                  list{Attrs.class_("flex-1 overflow-y-auto")},
                  list{
                    renderTableHeader(),
                    div(
                      list{Attrs.role("list"), Attrs.ariaLabel("Language portfolio")},
                      sorted
                      ->Array.map(lang => {
                        let isSelected = forge.selectedLanguage === Some(lang.name)
                        renderLanguageRow(lang, isSelected)
                      })
                      ->List.fromArray,
                    ),
                  },
                ),
                // Detail sidebar (if a language is selected)
                switch selectedEntry {
                | Some(lang) => renderDetailView(lang, forge.showMoscow)
                | None => noNode
                },
              },
            )
          }
        }
      },
    },
  )
}
