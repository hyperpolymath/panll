// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Repo Loader Component — Repository scanner and panel configuration wizard.
///
/// Three views:
///   1. Browse: Directory picker + farm search to select a repo
///   2. Configure: Panel suggestion cards with enable/disable toggles
///   3. Recent: Quick-switch list of recently loaded repos
///
/// When a repo is loaded, its manifests are scanned and the AI panel is given
/// full context about the project. Panel configs save to PANELS.a2ml.

open Model
open Msg
open Tea.Html

// ===========================================================================
// Category tab bar
// ===========================================================================

/// Render a single category tab.
let renderCategoryTab = (cat: repoLoaderCategory, isActive: bool): Tea_Vdom.t<msg> => {
  button(
    list{
      Attrs.class_(
        `px-4 py-2 text-sm transition-colors ${isActive
            ? "text-gray-100 border-b-2 border-blue-500"
            : "text-gray-500 hover:text-gray-300"}`,
      ),
      Events.onClick(RepoLoader(SetRepoCategory(cat))),
    },
    list{text(RepoLoaderEngine.categoryLabel(cat))},
  )
}

/// Render the category tab bar.
let renderCategoryTabBar = (activeCategory: repoLoaderCategory): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex border-b border-gray-800")},
    list{
      ...RepoLoaderEngine.allCategories
      ->Array.map(cat => renderCategoryTab(cat, cat === activeCategory))
      ->List.fromArray
    },
  )
}

// ===========================================================================
// Browse view
// ===========================================================================

/// Render the repo browse/picker view.
let renderBrowse = (rl: repoLoaderState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto p-6")},
    list{
      // Directory picker
      div(
        list{Attrs.class_("mb-8")},
        list{
          div(
            list{Attrs.class_("text-lg font-light text-gray-300 mb-4")},
            list{text("Open Repository")},
          ),
          div(
            list{Attrs.class_("flex gap-3")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-6 py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-lg text-sm font-medium transition-colors",
                  ),
                  Events.onClick(RepoLoader(PickRepoDirectory)),
                },
                list{text("Pick Directory")},
              ),
              {
                if rl.scanning {
                  div(
                    list{Attrs.class_("flex items-center text-sm text-gray-500 animate-pulse")},
                    list{text("Scanning...")},
                  )
                } else {
                  noNode
                }
              },
            },
          ),
        },
      ),
      // Quick path input
      div(
        list{Attrs.class_("mb-8")},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-400 mb-2")},
            list{text("Or enter a path directly:")},
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              input(
                list{
                  Attrs.class_(
                    "flex-1 bg-gray-900 border border-gray-700 rounded-lg px-4 py-2 text-sm text-gray-200 placeholder-gray-600 focus:outline-none focus:border-blue-500",
                  ),
                  Attrs.placeholder("/path/to/repos/..."),
                  Attrs.value(rl.searchText),
                  Events.onInput(text => RepoLoader(SetRepoSearchText(text))),
                  KeyboardUtil.onEnterOrSpace(RepoLoader(ScanRepo(rl.searchText))),
                },
                list{},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-4 py-2 bg-gray-800 text-gray-300 rounded-lg hover:bg-gray-700 transition-colors text-sm",
                  ),
                  Attrs.disabled(rl.searchText === ""),
                  Events.onClick(RepoLoader(ScanRepo(rl.searchText))),
                },
                list{text("Scan")},
              ),
            },
          ),
        },
      ),
      // Current repo info (if loaded)
      {
        switch rl.currentRepo {
        | Some(repo) =>
          div(
            list{Attrs.class_("border border-gray-700 rounded-lg p-4")},
            list{
              div(
                list{Attrs.class_("text-lg font-medium text-gray-200 mb-2")},
                list{text(repo.name)},
              ),
              {
                if repo.description !== "" {
                  div(
                    list{Attrs.class_("text-sm text-gray-400 mb-3")},
                    list{text(repo.description)},
                  )
                } else {
                  noNode
                }
              },
              div(
                list{Attrs.class_("text-xs text-gray-500 mb-2")},
                list{text(repo.path)},
              ),
              // Languages
              {
                if Array.length(repo.languages) > 0 {
                  div(
                    list{Attrs.class_("flex gap-1 flex-wrap mb-2")},
                    list{
                      ...repo.languages
                      ->Array.map(lang =>
                        span(
                          list{
                            Attrs.class_(
                              "text-xs px-2 py-0.5 rounded bg-blue-500/20 text-blue-300",
                            ),
                          },
                          list{text(lang)},
                        )
                      )
                      ->List.fromArray
                    },
                  )
                } else {
                  noNode
                }
              },
              // Status badges
              div(
                list{Attrs.class_("flex gap-2 text-xs")},
                list{
                  span(
                    list{
                      Attrs.class_(
                        `px-2 py-0.5 rounded ${repo.hasAiManifest
                            ? "bg-green-500/20 text-green-300"
                            : "bg-gray-700 text-gray-500"}`,
                      ),
                    },
                    list{text("AI Manifest")},
                  ),
                  span(
                    list{
                      Attrs.class_(
                        `px-2 py-0.5 rounded ${repo.hasMachineReadable
                            ? "bg-green-500/20 text-green-300"
                            : "bg-gray-700 text-gray-500"}`,
                      ),
                    },
                    list{text(".machine_readable/")},
                  ),
                  span(
                    list{
                      Attrs.class_(
                        `px-2 py-0.5 rounded ${repo.hasPanelsManifest
                            ? "bg-green-500/20 text-green-300"
                            : "bg-gray-700 text-gray-500"}`,
                      ),
                    },
                    list{text("PANELS.a2ml")},
                  ),
                  span(
                    list{
                      Attrs.class_(
                        `px-2 py-0.5 rounded ${repo.hasState
                            ? "bg-green-500/20 text-green-300"
                            : "bg-gray-700 text-gray-500"}`,
                      ),
                    },
                    list{text("STATE.scm")},
                  ),
                },
              ),
            },
          )
        | None =>
          div(
            list{Attrs.class_("text-center text-gray-600 mt-12")},
            list{
              div(
                list{Attrs.class_("text-2xl mb-4")},
                list{text("No Repository Loaded")},
              ),
              div(
                list{Attrs.class_("text-sm")},
                list{text("Pick a directory or enter a path to scan a repository.")},
              ),
            },
          )
        }
      },
      // Error display
      {
        switch rl.error {
        | Some(e) =>
          div(
            list{Attrs.class_("mt-4 px-3 py-2 bg-red-900/30 border border-red-700 rounded text-sm text-red-300")},
            list{text(e)},
          )
        | None => noNode
        }
      },
    },
  )
}

// ===========================================================================
// Configure view
// ===========================================================================

/// Render a single panel suggestion card with toggle.
let renderSuggestionCard = (suggestion: panelSuggestion): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        `border ${suggestion.enabled ? "border-gray-700" : "border-gray-800"} rounded-lg p-4 transition-colors`,
      ),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              div(
                list{Attrs.class_("text-sm font-medium text-gray-200")},
                list{text(suggestion.panelName)},
              ),
              span(
                list{
                  Attrs.class_(
                    `text-xs px-2 py-0.5 rounded ${RepoLoaderEngine.priorityColour(suggestion.priority)}`,
                  ),
                },
                list{text(suggestion.priority)},
              ),
            },
          ),
          button(
            list{
              Attrs.class_(
                `px-3 py-1 rounded text-sm transition-colors ${suggestion.enabled
                    ? "bg-green-500/20 text-green-300 hover:bg-green-500/30"
                    : "bg-gray-700 text-gray-400 hover:bg-gray-600"}`,
              ),
              Events.onClick(RepoLoader(ToggleSuggestion(suggestion.panelName))),
            },
            list{text(suggestion.enabled ? "Enabled" : "Disabled")},
          ),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-500")},
        list{text(suggestion.reason)},
      ),
    },
  )
}

/// Render the panel configuration wizard.
let renderConfigure = (rl: repoLoaderState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto p-6")},
    list{
      {
        if Array.length(rl.suggestions) > 0 {
          div(
            list{},
            list{
              div(
                list{Attrs.class_("flex items-center justify-between mb-4")},
                list{
                  div(
                    list{Attrs.class_("text-lg font-light text-gray-300")},
                    list{
                      text(
                        `Panel Configuration (${Int.toString(RepoLoaderEngine.enabledCount(rl.suggestions))} enabled)`,
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("flex gap-2")},
                    list{
                      button(
                        list{
                          Attrs.class_(
                            "px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-lg text-sm font-medium transition-colors disabled:opacity-50",
                          ),
                          Attrs.disabled(rl.saved),
                          Events.onClick(RepoLoader(SavePanels)),
                        },
                        list{text(rl.saved ? "Saved" : "Save to PANELS.a2ml")},
                      ),
                    },
                  ),
                },
              ),
              div(
                list{Attrs.class_("space-y-3")},
                list{
                  ...rl.suggestions
                  ->Array.map(renderSuggestionCard)
                  ->List.fromArray
                },
              ),
            },
          )
        } else {
          div(
            list{Attrs.class_("text-center text-gray-600 mt-12")},
            list{
              div(
                list{Attrs.class_("text-lg mb-2")},
                list{text("No panel suggestions")},
              ),
              div(
                list{Attrs.class_("text-sm")},
                list{text("Scan a repository first to get panel recommendations.")},
              ),
            },
          )
        }
      },
    },
  )
}

// ===========================================================================
// Recent view
// ===========================================================================

/// Render the recent repos list.
let renderRecent = (rl: repoLoaderState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto p-6")},
    list{
      div(
        list{Attrs.class_("text-lg font-light text-gray-300 mb-4")},
        list{text("Recent Repositories")},
      ),
      {
        if Array.length(rl.recentPaths) > 0 {
          div(
            list{Attrs.class_("space-y-2")},
            list{
              ...rl.recentPaths
              ->Array.map(path => {
                let name = switch String.split(path, "/")->Array.at(-1) {
                | Some(n) => n
                | None => path
                }
                button(
                  list{
                    Attrs.class_(
                      "w-full text-left px-4 py-3 border border-gray-800 rounded-lg hover:border-gray-600 transition-colors",
                    ),
                    Events.onClick(RepoLoader(ScanRepo(path))),
                  },
                  list{
                    div(
                      list{Attrs.class_("text-sm font-medium text-gray-200")},
                      list{text(name)},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500 mt-1")},
                      list{text(path)},
                    ),
                  },
                )
              })
              ->List.fromArray
            },
          )
        } else {
          div(
            list{Attrs.class_("text-center text-gray-600 mt-12")},
            list{
              div(list{Attrs.class_("text-sm")}, list{text("No recently loaded repos.")}),
            },
          )
        }
      },
    },
  )
}

// ===========================================================================
// Farm search view
// ===========================================================================

/// Render the farm search interface.
let renderFarmSearch = (rl: repoLoaderState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1 overflow-y-auto p-6")},
    list{
      div(
        list{Attrs.class_("text-lg font-light text-gray-300 mb-4")},
        list{text("Search Git-Private-Farm")},
      ),
      div(
        list{Attrs.class_("flex gap-2 mb-4")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 bg-gray-900 border border-gray-700 rounded-lg px-4 py-2 text-sm text-gray-200 placeholder-gray-600 focus:outline-none focus:border-blue-500",
              ),
              Attrs.placeholder("Search by name or description..."),
              Attrs.value(rl.searchText),
              Events.onInput(text => RepoLoader(SetRepoSearchText(text))),
              KeyboardUtil.onEnterOrSpace(RepoLoader(SearchFarm(rl.searchText))),
            },
            list{},
          ),
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-gray-800 text-gray-300 rounded-lg hover:bg-gray-700 transition-colors text-sm",
              ),
              Attrs.disabled(rl.searchText === ""),
              Events.onClick(RepoLoader(SearchFarm(rl.searchText))),
            },
            list{text("Search")},
          ),
        },
      ),
      div(
        list{Attrs.class_("text-xs text-gray-600")},
        list{
          text("Searches the farm-manifest.json for matching repos."),
        },
      ),
    },
  )
}

// ===========================================================================
// Main view (full panel overlay)
// ===========================================================================

/// Render the full Repo Loader panel overlay.
let view = (rl: repoLoaderState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
    },
    list{
      // Header bar
      div(
        list{Attrs.class_("flex items-center justify-between px-6 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              div(
                list{Attrs.class_("text-lg font-light text-gray-200")},
                list{text("Repo Loader")},
              ),
              {
                switch rl.currentRepo {
                | Some(repo) =>
                  span(
                    list{Attrs.class_("text-xs px-2 py-0.5 rounded bg-blue-500/20 text-blue-300")},
                    list{text(repo.name)},
                  )
                | None => noNode
                }
              },
            },
          ),
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-gray-800 text-gray-300 rounded hover:bg-gray-700 transition-colors",
              ),
              Events.onClick(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
          ),
        },
      ),
      // Category tabs
      renderCategoryTabBar(rl.activeCategory),
      // Main content (switches by category)
      {
        switch rl.activeCategory {
        | Browse => renderBrowse(rl)
        | Configure => renderConfigure(rl)
        | Recent => renderRecent(rl)
        | FarmSearch => renderFarmSearch(rl)
        }
      },
    },
  )
}
