// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Help Component — In-application help, glossary, and onboarding.
///
/// Renders a full-screen overlay containing the PanLL help system with
/// six content categories (Getting Started, Glossary, Panel Guides,
/// Shortcuts, FAQ, Architecture), a searchable entry list, detailed
/// article views, a glossary browser with related-term navigation,
/// and an 8-step onboarding walkthrough for new users.
///
/// All interactive elements carry ARIA attributes and keyboard semantics
/// so the help system itself meets the accessibility standard PanLL
/// enforces on every panel it mints.
///
/// This component is purely presentational — all state transformations
/// live in HelpEngine and are dispatched through Help(...) messages.

open Model
open Msg
open Tea.Html

// ============================================================================
// Constants
// ============================================================================

/// Ordered list of all help categories for tab rendering.
/// Kept local because HelpEngine does not export an enumeration array.
let allCategories: array<helpCategory> = [
  GettingStarted,
  Glossary,
  PanelGuide,
  Shortcuts,
  Faq,
  Architecture,
]

// ============================================================================
// Header
// ============================================================================

/// Renders the help panel header bar containing the title, a search input
/// for filtering entries and glossary terms, and a close button.
///
/// The search input dispatches `Help(SetHelpSearch(...))` on every keystroke
/// so the engine can recompute filtered results in real time.
///
/// The close button dispatches `Help(CloseHelp)` to dismiss the overlay.
///
/// @param state The current help system state (for pre-filling the search box)
/// @returns A virtual DOM node representing the header bar
let renderHeader = (state: helpState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center justify-between px-6 py-4 border-b border-gray-800 bg-gray-950 shrink-0")},
    list{
      // Title
      h2(
        list{Attrs.class_("text-lg font-semibold text-gray-100 tracking-tight")},
        list{text("Help & Documentation")},
      ),
      // Search + close cluster
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          // Search input
          div(
            list{Attrs.class_("relative")},
            list{
              span(
                list{
                  Attrs.class_("absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 text-sm pointer-events-none"),
                  Attrs.prop("aria-hidden", "true"),
                },
                list{text("search")},
              ),
              input(
                list{
                  Attrs.class_("w-72 bg-gray-900 border border-gray-700 rounded-lg pl-10 pr-3 py-2 text-sm text-gray-200 placeholder-gray-600 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500/30"),
                  Attrs.type_("text"),
                  Attrs.placeholder("Search help topics..."),
                  Attrs.value(state.searchQuery),
                  Attrs.ariaLabel("Search help topics"),
                  Events.onInput(v => Help(SetHelpSearch(v))),
                },
                list{},
              ),
            },
          ),
          // Close button
          button(
            list{
              Attrs.class_("p-2 rounded-lg text-gray-400 hover:text-gray-200 hover:bg-gray-800 transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500/50"),
              Attrs.ariaLabel("Close help panel"),
              Events.onClick(Help(CloseHelp)),
            },
            list{text("close")},
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Category Tabs
// ============================================================================

/// Renders the category tab bar for switching between help sections.
///
/// Each tab dispatches `Help(SetHelpCategory(...))` when clicked. The
/// currently active tab is highlighted with an indigo accent and carries
/// `ariaSelected="true"` for screen reader users.
///
/// The tab bar uses `role="tablist"` and each tab uses `role="tab"`.
///
/// @param active The currently selected help category
/// @returns A virtual DOM node representing the tab bar
let renderCategoryTabs = (active: helpCategory): Tea_Vdom.t<msg> => {
  let renderTab = (cat: helpCategory): Tea_Vdom.t<msg> => {
    let isActive = cat === active
    let baseClass = "px-4 py-2 text-sm font-medium rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500/50 whitespace-nowrap"
    let stateClass = if isActive {
      "bg-indigo-600 text-gray-100"
    } else {
      "text-gray-400 hover:text-gray-200 hover:bg-gray-800"
    }
    button(
      list{
        Attrs.class_(`${baseClass} ${stateClass}`),
        Attrs.role("tab"),
        Attrs.prop("aria-selected", isActive ? "true" : "false"),
        Attrs.ariaLabel(HelpEngine.categoryLabel(cat)),
        Events.onClick(Help(SetHelpCategory(cat))),
      },
      list{text(HelpEngine.categoryLabel(cat))},
    )
  }

  div(
    list{
      Attrs.class_("flex items-center gap-1 px-6 py-3 border-b border-gray-800 bg-gray-950/80 overflow-x-auto shrink-0"),
      Attrs.role("tablist"),
      Attrs.ariaLabel("Help category tabs"),
    },
    allCategories->Array.map(renderTab)->List.fromArray,
  )
}

// ============================================================================
// Entry List (Card Grid)
// ============================================================================

/// Renders a single help entry as a clickable card in the entry list.
///
/// Clicking the card dispatches `Help(SelectEntry(entry.id))` to open
/// the full article view for that entry.
///
/// @param entry The help entry to render as a card
/// @returns A virtual DOM node for the entry card
let renderEntryCard = (entry: helpEntry): Tea_Vdom.t<msg> => {
  let truncatedBody = if String.length(entry.body) > 160 {
    String.slice(entry.body, ~start=0, ~end=157) ++ "..."
  } else {
    entry.body
  }

  button(
    list{
      Attrs.class_("w-full text-left bg-gray-900 border border-gray-700 rounded-lg p-4 hover:border-indigo-500/50 hover:bg-gray-900/80 transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500/50 group"),
      Attrs.ariaLabel(`Read: ${entry.title}`),
      Events.onClick(Help(SelectEntry(entry.id))),
    },
    list{
      // Title
      h3(
        list{Attrs.class_("text-sm font-medium text-gray-200 group-hover:text-indigo-400 transition-colors mb-1")},
        list{text(entry.title)},
      ),
      // Category badge
      span(
        list{Attrs.class_("inline-block text-xs text-gray-500 bg-gray-800 rounded px-2 py-0.5 mb-2")},
        list{text(HelpEngine.categoryLabel(entry.category))},
      ),
      // Truncated body preview
      p(
        list{Attrs.class_("text-xs text-gray-400 leading-relaxed line-clamp-3")},
        list{text(truncatedBody)},
      ),
      // Keywords
      switch Array.length(entry.keywords) > 0 {
      | true =>
        div(
          list{Attrs.class_("flex flex-wrap gap-1 mt-2")},
          entry.keywords
          ->Array.slice(~start=0, ~end=4)
          ->Array.map(kw =>
            span(
              list{Attrs.class_("text-xs text-gray-600 bg-gray-800/50 rounded px-1.5 py-0.5")},
              list{text(kw)},
            )
          )
          ->List.fromArray,
        )
      | false => noNode
      },
    },
  )
}

/// Renders the entry list view — a grid of clickable help entry cards.
///
/// When no entries match the current filter/search, a "no results" message
/// is displayed. Otherwise entries are laid out in a responsive card grid.
///
/// @param entries The filtered array of help entries to display
/// @param _activeEntry The currently selected entry ID (unused here but kept for signature consistency)
/// @returns A virtual DOM node for the entry list grid
let renderEntryList = (entries: array<helpEntry>, _activeEntry: option<string>): Tea_Vdom.t<msg> => {
  if Array.length(entries) === 0 {
    div(
      list{Attrs.class_("flex flex-col items-center justify-center py-16 text-center")},
      list{
        div(
          list{Attrs.class_("text-4xl mb-4 text-gray-600")},
          list{text("?")},
        ),
        p(
          list{Attrs.class_("text-gray-400 text-sm")},
          list{text("No help entries found matching your search.")},
        ),
        p(
          list{Attrs.class_("text-gray-500 text-xs mt-1")},
          list{text("Try a different search term or switch categories.")},
        ),
      },
    )
  } else {
    div(
      list{
        Attrs.class_("grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-6"),
        Attrs.role("list"),
        Attrs.ariaLabel("Help entries"),
      },
      entries
      ->Array.map(entry =>
        div(
          list{Attrs.role("listitem")},
          list{renderEntryCard(entry)},
        )
      )
      ->List.fromArray,
    )
  }
}

// ============================================================================
// Entry Detail
// ============================================================================

/// Renders the full article view for a single help entry.
///
/// Includes a back button to return to the entry list, the entry title,
/// category badge, full body text, and keyword tags. The back button
/// dispatches `Help(SelectEntry(""))` with an empty string to clear the
/// active entry selection (the engine treats empty-string SelectEntry
/// as deselection, or alternatively we dispatch SetHelpSearch to reset).
///
/// @param entry The help entry to render in full detail
/// @returns A virtual DOM node for the article view
let renderEntryDetail = (entry: helpEntry): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col h-full")},
    list{
      // Back button bar
      div(
        list{Attrs.class_("px-6 py-3 border-b border-gray-800 shrink-0")},
        list{
          button(
            list{
              Attrs.class_("flex items-center gap-2 text-sm text-gray-400 hover:text-indigo-400 transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500/50 rounded px-2 py-1"),
              Attrs.ariaLabel("Back to entry list"),
              Events.onClick(Help(SelectEntry(""))),
            },
            list{
              span(list{Attrs.prop("aria-hidden", "true")}, list{text("back")}),
              text("Back to entries"),
            },
          ),
        },
      ),
      // Article content
      div(
        list{Attrs.class_("flex-1 overflow-y-auto px-6 py-6")},
        list{
          // Title
          h2(
            list{Attrs.class_("text-xl font-semibold text-gray-100 mb-2")},
            list{text(entry.title)},
          ),
          // Category badge
          span(
            list{Attrs.class_("inline-block text-xs text-indigo-400 bg-indigo-900/30 border border-indigo-800/50 rounded px-2 py-0.5 mb-6")},
            list{text(HelpEngine.categoryLabel(entry.category))},
          ),
          // Body text — rendered as paragraphs split on double newlines
          div(
            list{Attrs.class_("space-y-4")},
            entry.body
            ->String.split("\n\n")
            ->Array.map(paragraph =>
              p(
                list{Attrs.class_("text-sm text-gray-300 leading-relaxed")},
                list{text(paragraph)},
              )
            )
            ->List.fromArray,
          ),
          // Panel link (if panel-specific)
          switch entry.panelId {
          | Some(_pid) =>
            div(
              list{Attrs.class_("mt-6 p-3 bg-gray-900 border border-gray-700 rounded-lg")},
              list{
                span(
                  list{Attrs.class_("text-xs text-gray-500")},
                  list{text("This entry is associated with a specific panel. Use the Panel Switcher to navigate there.")},
                ),
              },
            )
          | None => noNode
          },
          // Keywords footer
          switch Array.length(entry.keywords) > 0 {
          | true =>
            div(
              list{Attrs.class_("mt-6 pt-4 border-t border-gray-800")},
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-500 mb-2")},
                  list{text("Related keywords")},
                ),
                div(
                  list{Attrs.class_("flex flex-wrap gap-2")},
                  entry.keywords
                  ->Array.map(kw =>
                    span(
                      list{Attrs.class_("text-xs text-gray-400 bg-gray-800 rounded-full px-3 py-1")},
                      list{text(kw)},
                    )
                  )
                  ->List.fromArray,
                ),
              },
            )
          | false => noNode
          },
        },
      ),
    },
  )
}

// ============================================================================
// Glossary
// ============================================================================

/// Renders a single glossary term card with its definition and related terms.
///
/// Related terms are rendered as clickable links that dispatch
/// `Help(SearchGlossary(relatedTerm))` to navigate the glossary graph.
///
/// @param term The glossary term to render
/// @returns A virtual DOM node for the glossary term card
let renderGlossaryTerm = (term: glossaryTerm): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4"),
      Attrs.role("article"),
      Attrs.ariaLabel(`Glossary term: ${term.term}`),
    },
    list{
      // Term heading
      h3(
        list{Attrs.class_("text-sm font-semibold text-indigo-400 mb-2")},
        list{text(term.term)},
      ),
      // Definition
      p(
        list{Attrs.class_("text-sm text-gray-300 leading-relaxed mb-3")},
        list{text(term.definition)},
      ),
      // Extended description (if available)
      switch term.extendedDescription {
      | Some(ext) =>
        p(
          list{Attrs.class_("text-xs text-gray-400 leading-relaxed mb-3 italic")},
          list{text(ext)},
        )
      | None => noNode
      },
      // Related terms
      switch Array.length(term.relatedTerms) > 0 {
      | true =>
        div(
          list{Attrs.class_("flex flex-wrap gap-1.5 pt-2 border-t border-gray-800")},
          [
            span(
              list{Attrs.class_("text-xs text-gray-500 mr-1 self-center")},
              list{text("See also:")},
            ),
          ]
          ->Array.concat(
            term.relatedTerms->Array.map(rt =>
              button(
                list{
                  Attrs.class_("text-xs text-indigo-400 hover:text-indigo-300 bg-indigo-900/20 hover:bg-indigo-900/40 rounded px-2 py-0.5 transition-colors focus:outline-none focus:ring-1 focus:ring-indigo-500/50"),
                  Attrs.ariaLabel(`Look up related term: ${rt}`),
                  Events.onClick(Help(SearchGlossary(rt))),
                },
                list{text(rt)},
              )
            ),
          )
          ->List.fromArray,
        )
      | false => noNode
      },
    },
  )
}

/// Renders the glossary view — an alphabetical list of neurosymbolic terms
/// with definitions and cross-reference links.
///
/// The glossary is filtered by the current search query. Terms are sorted
/// alphabetically by their `term` field. When no terms match the search,
/// a "no results" message is shown.
///
/// @param glossary The array of glossary terms (pre-filtered by the engine or raw)
/// @param searchQuery The current search string for additional client-side filtering
/// @returns A virtual DOM node for the glossary list
let renderGlossary = (glossary: array<glossaryTerm>, searchQuery: string): Tea_Vdom.t<msg> => {
  let filtered = HelpEngine.searchGlossary(searchQuery, glossary)
  let sorted = filtered->Array.toSorted((a, b) => {
    let la = String.toLowerCase(a.term)
    let lb = String.toLowerCase(b.term)
    if la < lb {
      -1.0
    } else if la > lb {
      1.0
    } else {
      0.0
    }
  })

  if Array.length(sorted) === 0 {
    div(
      list{Attrs.class_("flex flex-col items-center justify-center py-16 text-center")},
      list{
        div(
          list{Attrs.class_("text-4xl mb-4 text-gray-600")},
          list{text("A-Z")},
        ),
        p(
          list{Attrs.class_("text-gray-400 text-sm")},
          list{text("No glossary terms match your search.")},
        ),
      },
    )
  } else {
    div(
      list{Attrs.class_("p-6")},
      list{
        // Term count
        div(
          list{Attrs.class_("text-xs text-gray-500 mb-4")},
          list{text(`${Int.toString(Array.length(sorted))} term${Array.length(sorted) === 1 ? "" : "s"}`)},
        ),
        // Term list
        div(
          list{
            Attrs.class_("grid grid-cols-1 md:grid-cols-2 gap-4"),
            Attrs.role("list"),
            Attrs.ariaLabel("Glossary terms"),
          },
          sorted
          ->Array.map(term =>
            div(
              list{Attrs.role("listitem")},
              list{renderGlossaryTerm(term)},
            )
          )
          ->List.fromArray,
        ),
      },
    )
  }
}

// ============================================================================
// Onboarding Overlay
// ============================================================================

/// Renders the onboarding walkthrough overlay — a step-by-step card
/// sequence introducing new users to PanLL's core concepts.
///
/// The overlay floats above the help panel content with a semi-transparent
/// backdrop. Navigation buttons dispatch `Help(PrevOnboardingStep)`,
/// `Help(NextOnboardingStep)`, and `Help(SkipOnboarding)` messages.
///
/// On the final step, the "Next" button becomes "Finish" and dispatches
/// `Help(CompleteOnboarding)`.
///
/// @param state The current onboarding walkthrough state
/// @returns A virtual DOM node for the onboarding overlay (or noNode if inactive)
let renderOnboarding = (state: onboardingState): Tea_Vdom.t<msg> => {
  if !state.active {
    noNode
  } else {
    let totalSteps = Array.length(state.steps)
    let currentIdx = state.currentStep
    let isLast = currentIdx >= totalSteps - 1
    let isFirst = currentIdx <= 0

    let currentStep = state.steps->Array.get(currentIdx)

    switch currentStep {
    | None => noNode
    | Some(step) =>
      div(
        list{
          Attrs.class_("fixed inset-0 z-50 flex items-center justify-center bg-gray-950/80 backdrop-blur-sm"),
          Attrs.role("dialog"),
          Attrs.ariaLabel("Onboarding walkthrough"),
        },
        list{
          // Walkthrough card
          div(
            list{Attrs.class_("w-full max-w-lg bg-gray-900 border border-gray-700 rounded-xl shadow-2xl overflow-hidden")},
            list{
              // Progress bar
              div(
                list{Attrs.class_("h-1 bg-gray-800")},
                list{
                  div(
                    list{
                      Attrs.class_("h-full bg-indigo-500 transition-all duration-300"),
                      Attrs.style(
                        "width",
                        `${Float.toFixed(Int.toFloat(currentIdx + 1) /. Int.toFloat(totalSteps) *. 100.0, ~digits=0)}%`,
                      ),
                    },
                    list{},
                  ),
                },
              ),
              // Card body
              div(
                list{Attrs.class_("p-8")},
                list{
                  // Step counter
                  div(
                    list{Attrs.class_("text-xs text-gray-500 mb-4")},
                    list{text(`Step ${Int.toString(currentIdx + 1)} of ${Int.toString(totalSteps)}`)},
                  ),
                  // Title
                  h3(
                    list{Attrs.class_("text-lg font-semibold text-gray-100 mb-3")},
                    list{text(step.title)},
                  ),
                  // Description
                  p(
                    list{Attrs.class_("text-sm text-gray-300 leading-relaxed")},
                    list{text(step.description)},
                  ),
                },
              ),
              // Navigation footer
              div(
                list{Attrs.class_("flex items-center justify-between px-8 py-4 border-t border-gray-800 bg-gray-950/50")},
                list{
                  // Skip button
                  button(
                    list{
                      Attrs.class_("text-xs text-gray-500 hover:text-gray-300 transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500/50 rounded px-2 py-1"),
                      Attrs.ariaLabel("Skip onboarding walkthrough"),
                      Events.onClick(Help(SkipOnboarding)),
                    },
                    list{text("Skip walkthrough")},
                  ),
                  // Prev / Next buttons
                  div(
                    list{Attrs.class_("flex items-center gap-3")},
                    list{
                      // Previous
                      if isFirst {
                        noNode
                      } else {
                        button(
                          list{
                            Attrs.class_("px-4 py-2 text-sm text-gray-400 hover:text-gray-200 bg-gray-800 hover:bg-gray-700 rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500/50"),
                            Attrs.ariaLabel("Previous onboarding step"),
                            Events.onClick(Help(PrevOnboardingStep)),
                          },
                          list{text("Previous")},
                        )
                      },
                      // Next / Finish
                      button(
                        list{
                          Attrs.class_("px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-500 rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500/50"),
                          Attrs.ariaLabel(isLast ? "Finish onboarding" : "Next onboarding step"),
                          Events.onClick(
                            isLast ? Help(CompleteOnboarding) : Help(NextOnboardingStep),
                          ),
                        },
                        list{text(isLast ? "Finish" : "Next")},
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
}

// ============================================================================
// Main View
// ============================================================================

/// Main entry point for the Help panel.
///
/// Renders a full-screen overlay containing the header bar, category tabs,
/// and the appropriate content area based on the current state:
///
/// - If a specific entry is selected (`activeEntry = Some(id)`), shows
///   the full article view via `renderEntryDetail`.
/// - If the Glossary tab is active, shows the glossary browser via
///   `renderGlossary`.
/// - Otherwise, shows the entry list grid via `renderEntryList`.
///
/// The onboarding overlay is conditionally rendered on top of everything
/// when the walkthrough is active.
///
/// The outermost div carries `role="dialog"` and an ARIA label for
/// assistive technology.
///
/// @param state The complete help system state
/// @returns A virtual DOM tree for the entire Help panel overlay
let view = (state: helpState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col h-screen"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Help and documentation"),
    },
    list{
      // Header with search and close
      renderHeader(state),
      // Category tabs
      renderCategoryTabs(state.activeCategory),
      // Content area (scrollable)
      div(
        list{
          Attrs.class_("flex-1 overflow-y-auto"),
          Attrs.role("tabpanel"),
          Attrs.ariaLabel(`${HelpEngine.categoryLabel(state.activeCategory)} content`),
        },
        list{
          // Determine which view to render based on state
          switch state.activeEntry {
          | Some(entryId) if entryId !== "" =>
            // Entry detail view — find the entry and render it
            switch HelpEngine.findEntry(entryId, state.filteredEntries) {
            | Some(entry) => renderEntryDetail(entry)
            | None =>
              // Entry not found in filtered set — show a fallback message
              div(
                list{Attrs.class_("flex flex-col items-center justify-center py-16 text-center")},
                list{
                  p(
                    list{Attrs.class_("text-gray-400 text-sm")},
                    list{text("Entry not found. It may have been filtered out.")},
                  ),
                  button(
                    list{
                      Attrs.class_("mt-4 px-4 py-2 text-sm text-indigo-400 hover:text-indigo-300 bg-gray-900 border border-gray-700 rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500/50"),
                      Events.onClick(Help(SelectEntry(""))),
                    },
                    list{text("Back to entries")},
                  ),
                },
              )
            }
          | _ =>
            // List / glossary view depending on active category
            switch state.activeCategory {
            | Glossary => renderGlossary(state.glossary, state.searchQuery)
            | _ => renderEntryList(state.filteredEntries, state.activeEntry)
            }
          },
        },
      ),
      // Context panel indicator (when opened from a specific panel via F1)
      switch state.contextPanelId {
      | Some(_pid) =>
        div(
          list{Attrs.class_("px-6 py-2 border-t border-gray-800 bg-gray-950 shrink-0")},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between")},
              list{
                span(
                  list{Attrs.class_("text-xs text-gray-500")},
                  list{text("Showing context-sensitive help. ")},
                ),
                button(
                  list{
                    Attrs.class_("text-xs text-indigo-400 hover:text-indigo-300 transition-colors focus:outline-none focus:ring-1 focus:ring-indigo-500/50 rounded px-1"),
                    Attrs.ariaLabel("Show all help entries, clear panel filter"),
                    Events.onClick(Help(OpenContextHelp(None))),
                  },
                  list{text("Show all")},
                ),
              },
            ),
          },
        )
      | None => noNode
      },
      // Onboarding overlay (floats above everything when active)
      renderOnboarding(state.onboarding),
    },
  )
}
