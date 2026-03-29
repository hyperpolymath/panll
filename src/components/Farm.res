// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Farm Component — view layer for the Git-Private-Farm panel.
///
/// Renders a full-screen overlay with the repo inventory from
/// farm-manifest.json. Layout follows the CloudGuard pattern:
///   - Header with title, stats, and close button
///   - Category tab bar (All | By Group | By Language | By Forge | Enrollment | Health)
///   - Filter/sort controls
///   - Main inventory table/grid
///
/// The panel reads local JSON via the Gossamer backend — no HTTP service required.

open Model
open Msg
open Tea.Html

/// Render a single category tab button.
let renderCategoryTab = (cat: farmCategory, isActive: bool): Tea_Vdom.t<msg> => {
  let activeClass = isActive
    ? "border-indigo-500 text-indigo-300 bg-gray-800/50"
    : "border-transparent text-gray-500 hover:text-gray-300 hover:border-gray-600"

  button(
    list{
      Attrs.class_(
        `px-3 py-2 text-sm font-medium border-b-2 cursor-pointer transition-colors ${activeClass}`,
      ),
      Attrs.role("tab"),
      Events.onClick(Farm(SetFarmCategory(cat))),
    },
    list{text(FarmEngine.categoryLabel(cat))},
  )
}

/// Render the category tab bar.
let renderCategoryTabBar = (activeCategory: farmCategory): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex border-b border-gray-800 overflow-x-auto"),
      Attrs.role("tablist"),
      Attrs.ariaLabel("Farm view categories"),
    },
    FarmEngine.allCategories
    ->Array.map(cat => renderCategoryTab(cat, cat === activeCategory))
    ->List.fromArray,
  )
}

/// Render a priority badge with colour coding.
let renderPriorityBadge = (priority: farmPriority): Tea_Vdom.t<msg> => {
  let (label, bgClass) = switch priority {
  | High => ("HIGH", "bg-red-900/50 text-red-300 border-red-700")
  | Medium => ("MED", "bg-amber-900/50 text-amber-300 border-amber-700")
  | Low => ("LOW", "bg-gray-800/50 text-gray-400 border-gray-700")
  }
  span(list{Attrs.class_(`text-xs px-1.5 py-0.5 rounded border ${bgClass}`)}, list{text(label)})
}

/// Render forge badges for a repo (small coloured pills).
let renderForgeBadges = (forges: array<farmForge>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-wrap gap-1")},
    forges
    ->Array.map(f => {
      let colour = switch f.name {
      | "github" => "bg-gray-700 text-gray-200"
      | "gitlab" => "bg-orange-900/50 text-orange-300"
      | "sourcehut" => "bg-blue-900/50 text-blue-300"
      | "codeberg" => "bg-green-900/50 text-green-300"
      | "bitbucket" => "bg-blue-800/50 text-blue-200"
      | "radicle" => "bg-purple-900/50 text-purple-300"
      | _ => "bg-gray-800 text-gray-400"
      }
      span(list{Attrs.class_(`text-xs px-1.5 py-0.5 rounded ${colour}`)}, list{text(f.name)})
    })
    ->List.fromArray,
  )
}

/// Render a single repo row in the inventory table.
let renderRepoRow = (repo: farmRepo): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "flex items-center gap-3 px-4 py-2 hover:bg-gray-800/30 border-b border-gray-800/50 transition-colors",
      ),
    },
    list{
      // Name + description
      div(
        list{Attrs.class_("flex-1 min-w-0")},
        list{
          div(
            list{Attrs.class_("text-sm font-medium text-gray-200 truncate")},
            list{text(repo.name)},
          ),
          div(list{Attrs.class_("text-xs text-gray-500 truncate")}, list{text(repo.description)}),
        },
      ),
      // Language
      div(
        list{Attrs.class_("w-20 text-xs text-gray-400 text-center")},
        list{text(repo.language === "" ? "-" : repo.language)},
      ),
      // Priority
      div(list{Attrs.class_("w-16 flex justify-center")}, list{renderPriorityBadge(repo.priority)}),
      // Forges
      div(list{Attrs.class_("w-48")}, list{renderForgeBadges(repo.forges)}),
      // Auto-propagate indicator
      div(
        list{Attrs.class_("w-8 text-center")},
        list{
          span(
            list{
              Attrs.class_(repo.autoPropagation ? "text-emerald-400" : "text-gray-600"),
              Attrs.title(repo.autoPropagation ? "Auto-propagation enabled" : "Manual sync"),
            },
            list{text(repo.autoPropagation ? "A" : "-")},
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
      div(list{Attrs.class_("flex-1")}, list{text("Repository")}),
      div(list{Attrs.class_("w-20 text-center")}, list{text("Lang")}),
      div(list{Attrs.class_("w-16 text-center")}, list{text("Priority")}),
      div(list{Attrs.class_("w-48")}, list{text("Forges")}),
      div(list{Attrs.class_("w-8 text-center")}, list{text("Auto")}),
    },
  )
}

/// Render grouped repos (for By Group / By Language views).
let renderGroupedRepos = (groups: array<(string, array<farmRepo>)>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    groups
    ->Array.map(((groupName, repos)) => {
      div(
        list{Attrs.class_("border border-gray-800 rounded-lg overflow-hidden")},
        list{
          // Group header
          div(
            list{
              Attrs.class_(
                "px-4 py-2 bg-gray-800/50 text-sm font-medium text-gray-300 flex items-center justify-between",
              ),
            },
            list{
              text(groupName),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(`${Int.toString(Array.length(repos))} repos`)},
              ),
            },
          ),
          // Repo rows
          div(list{Attrs.class_("")}, repos->Array.map(renderRepoRow)->List.fromArray),
        },
      )
    })
    ->List.fromArray,
  )
}

/// Render the forge coverage summary (for By Forge view).
let renderForgeCoverage = (repos: array<farmRepo>): Tea_Vdom.t<msg> => {
  let forgeCounts = FarmEngine.countByForge(repos)
  let total = Array.length(repos)
  div(
    list{Attrs.class_("space-y-3 p-4")},
    list{
      div(
        list{Attrs.class_("text-sm text-gray-400 mb-2")},
        list{text(`Forge coverage across ${Int.toString(total)} repos`)},
      ),
      div(
        list{Attrs.class_("space-y-2")},
        forgeCounts
        ->Array.map(((forgeName, count)) => {
          let pct =
            total > 0
              ? Float.toFixed(Int.toFloat(count) /. Int.toFloat(total) *. 100.0, ~digits=0)
              : "0"
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              div(list{Attrs.class_("w-24 text-sm text-gray-300")}, list{text(forgeName)}),
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
              div(
                list{Attrs.class_("w-16 text-xs text-gray-500 text-right")},
                list{text(`${Int.toString(count)}/${Int.toString(total)}`)},
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Render the main content area based on active category.
let renderContent = (farm: farmState): Tea_Vdom.t<msg> => {
  let filtered = FarmEngine.filterRepos(farm.repos, farm.filterText)
  let sorted = FarmEngine.sortRepos(filtered, farm.sortBy)

  switch farm.activeCategory {
  | AllRepos =>
    div(
      list{Attrs.class_("flex-1 overflow-y-auto")},
      list{
        renderTableHeader(),
        div(list{Attrs.class_("")}, sorted->Array.map(renderRepoRow)->List.fromArray),
      },
    )
  | ByGroup =>
    div(
      list{Attrs.class_("flex-1 overflow-y-auto p-4")},
      list{renderGroupedRepos(FarmEngine.groupByGroup(filtered))},
    )
  | ByLanguage =>
    div(
      list{Attrs.class_("flex-1 overflow-y-auto p-4")},
      list{renderGroupedRepos(FarmEngine.groupByLanguage(filtered))},
    )
  | ByForge =>
    div(list{Attrs.class_("flex-1 overflow-y-auto")}, list{renderForgeCoverage(filtered)})
  | Enrollment => {
      let farmCount = filtered->Array.filter(r => r.enrollment.farm)->Array.length
      let hypatiaCount = filtered->Array.filter(r => r.enrollment.hypatia)->Array.length
      let fleetCount = filtered->Array.filter(r => r.enrollment.fleet)->Array.length
      let totalCount = Array.length(filtered)
      let pctBar = (count: int): string =>
        if totalCount > 0 {
          Float.toFixed(Int.toFloat(count) /. Int.toFloat(totalCount) *. 100.0, ~digits=0)
        } else {
          "0"
        }
      div(
        list{
          Attrs.class_("flex-1 overflow-y-auto p-4 space-y-6"),
          Attrs.role("region"),
          Attrs.ariaLabel("Three-tier enrollment status"),
        },
        list{
          // Summary heading
          div(
            list{Attrs.class_("text-sm font-medium text-gray-300 mb-2")},
            list{text("Three-Tier Enrollment Pipeline")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-500 mb-4")},
            list{
              text(
                "Each tier builds on the previous: Farm (admin registry) > Hypatia (scanning) > Fleet (execution)",
              ),
            },
          ),
          // Tier bars
          div(
            list{Attrs.class_("space-y-3")},
            list{
              // Tier 1: Farm
              div(
                list{Attrs.class_("flex items-center gap-3")},
                list{
                  div(
                    list{Attrs.class_("w-36 text-sm text-emerald-400 font-medium")},
                    list{text("git-private-farm")},
                  ),
                  div(
                    list{Attrs.class_("flex-1 h-4 bg-gray-800 rounded-full overflow-hidden")},
                    list{
                      div(
                        list{
                          Attrs.class_("h-full bg-emerald-600 rounded-full transition-all"),
                          Attrs.prop("style", `width: ${pctBar(farmCount)}%`),
                        },
                        list{},
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("w-20 text-xs text-gray-400 text-right")},
                    list{text(`${Int.toString(farmCount)}/${Int.toString(totalCount)}`)},
                  ),
                },
              ),
              // Tier 2: Hypatia
              div(
                list{Attrs.class_("flex items-center gap-3")},
                list{
                  div(
                    list{Attrs.class_("w-36 text-sm text-indigo-400 font-medium")},
                    list{text("hypatia")},
                  ),
                  div(
                    list{Attrs.class_("flex-1 h-4 bg-gray-800 rounded-full overflow-hidden")},
                    list{
                      div(
                        list{
                          Attrs.class_("h-full bg-indigo-600 rounded-full transition-all"),
                          Attrs.prop("style", `width: ${pctBar(hypatiaCount)}%`),
                        },
                        list{},
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("w-20 text-xs text-gray-400 text-right")},
                    list{text(`${Int.toString(hypatiaCount)}/${Int.toString(totalCount)}`)},
                  ),
                },
              ),
              // Tier 3: Fleet
              div(
                list{Attrs.class_("flex items-center gap-3")},
                list{
                  div(
                    list{Attrs.class_("w-36 text-sm text-purple-400 font-medium")},
                    list{text("gitbot-fleet")},
                  ),
                  div(
                    list{Attrs.class_("flex-1 h-4 bg-gray-800 rounded-full overflow-hidden")},
                    list{
                      div(
                        list{
                          Attrs.class_("h-full bg-purple-600 rounded-full transition-all"),
                          Attrs.prop("style", `width: ${pctBar(fleetCount)}%`),
                        },
                        list{},
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("w-20 text-xs text-gray-400 text-right")},
                    list{text(`${Int.toString(fleetCount)}/${Int.toString(totalCount)}`)},
                  ),
                },
              ),
            },
          ),
          // Per-repo enrollment table
          div(
            list{Attrs.class_("border border-gray-700 rounded-lg overflow-hidden mt-4")},
            list{
              // Header
              div(
                list{
                  Attrs.class_(
                    "flex items-center gap-3 px-4 py-2 border-b border-gray-700 text-xs font-medium text-gray-500 uppercase tracking-wider",
                  ),
                },
                list{
                  div(list{Attrs.class_("flex-1")}, list{text("Repository")}),
                  div(list{Attrs.class_("w-16 text-center")}, list{text("Farm")}),
                  div(list{Attrs.class_("w-16 text-center")}, list{text("Hypatia")}),
                  div(list{Attrs.class_("w-16 text-center")}, list{text("Fleet")}),
                },
              ),
              // Rows
              div(
                list{Attrs.class_("max-h-96 overflow-y-auto")},
                sorted
                ->Array.map(repo => {
                  let tierDot = (enrolled: bool): Tea_Vdom.t<msg> =>
                    span(
                      list{
                        Attrs.class_(enrolled ? "text-emerald-400" : "text-gray-700"),
                        Attrs.ariaLabel(enrolled ? "Enrolled" : "Not enrolled"),
                      },
                      list{text(enrolled ? "Y" : "-")},
                    )
                  div(
                    list{
                      Attrs.class_(
                        "flex items-center gap-3 px-4 py-2 border-b border-gray-800/50 hover:bg-gray-800/30 transition-colors",
                      ),
                      Attrs.ariaLabel(`${repo.name} enrollment status`),
                    },
                    list{
                      div(
                        list{Attrs.class_("flex-1 text-sm text-gray-300 truncate")},
                        list{text(repo.name)},
                      ),
                      div(
                        list{Attrs.class_("w-16 text-center")},
                        list{tierDot(repo.enrollment.farm)},
                      ),
                      div(
                        list{Attrs.class_("w-16 text-center")},
                        list{tierDot(repo.enrollment.hypatia)},
                      ),
                      div(
                        list{Attrs.class_("w-16 text-center")},
                        list{tierDot(repo.enrollment.fleet)},
                      ),
                    },
                  )
                })
                ->List.fromArray,
              ),
            },
          ),
        },
      )
    }
  | Health => {
      let unhealthy =
        filtered
        ->Array.filter(r =>
          switch r.healthScore {
          | Some(s) => s < 0.5
          | None => false
          }
        )
        ->Array.length
      let unassessed = filtered->Array.filter(r => Option.isNone(r.healthScore))->Array.length
      let withAlerts = filtered->Array.filter(r => r.hasDependabotAlerts)->Array.length
      div(
        list{
          Attrs.class_("flex-1 overflow-y-auto p-4 space-y-6"),
          Attrs.role("region"),
          Attrs.ariaLabel("Farm health dashboard"),
        },
        list{
          // Quick stats
          div(
            list{Attrs.class_("flex gap-6 text-sm")},
            list{
              div(
                list{Attrs.class_(unhealthy > 0 ? "text-red-400" : "text-gray-400")},
                list{text(`Unhealthy (score < 0.5): ${Int.toString(unhealthy)}`)},
              ),
              div(
                list{Attrs.class_("text-gray-400")},
                list{text(`Unassessed: ${Int.toString(unassessed)}`)},
              ),
              div(
                list{Attrs.class_(withAlerts > 0 ? "text-amber-400" : "text-gray-400")},
                list{text(`Dependabot alerts: ${Int.toString(withAlerts)}`)},
              ),
            },
          ),
          // Hypatia integration prompt
          div(
            list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-6 text-center")},
            list{
              div(
                list{Attrs.class_("text-sm text-gray-400 mb-3")},
                list{text("Health scores are populated by Hypatia neurosymbolic scanning.")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500 mb-4")},
                list{
                  text(
                    `${Int.toString(unassessed)} of ${Int.toString(
                        Array.length(filtered),
                      )} repos have not been assessed yet.`,
                  ),
                },
              ),
              button(
                list{
                  Attrs.class_(
                    "px-4 py-2 bg-indigo-600 text-white text-sm rounded hover:bg-indigo-500 transition-colors",
                  ),
                  Attrs.ariaLabel("Open Hypatia panel to run health scans"),
                  Events.onClick(PanelSwitcher(TogglePanel(PanelHypatia))),
                },
                list{text("Open Hypatia")},
              ),
            },
          ),
        },
      )
    }
  }
}

/// Render the header bar with title, stats summary, and controls.
let renderHeader = (farm: farmState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center justify-between px-6 py-4 border-b border-gray-800")},
    list{
      // Title and stats
      div(
        list{Attrs.class_("flex items-center gap-4")},
        list{
          div(
            list{Attrs.class_("text-lg font-medium text-gray-200")},
            list{text("Git-Private-Farm")},
          ),
          if farm.loaded {
            div(
              list{Attrs.class_("flex items-center gap-3 text-xs text-gray-500")},
              list{
                span(list{}, list{text(`${Int.toString(farm.totalRepos)} repos`)}),
                span(list{Attrs.class_("text-gray-700")}, list{text("|")}),
                span(list{}, list{text(`${Int.toString(Array.length(farm.repos))} loaded`)}),
              },
            )
          } else {
            noNode
          },
        },
      ),
      // Controls: filter, sort, close
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          // Filter input
          input(
            list{
              Attrs.class_(
                "bg-gray-800 border border-gray-700 rounded px-3 py-1.5 text-sm text-gray-200 placeholder-gray-500 focus:border-indigo-500 focus:outline-none w-48",
              ),
              Attrs.placeholder("Filter repos..."),
              Attrs.value(farm.filterText),
              Events.onInput(text => Farm(SetFarmFilter(text))),
            },
            list{},
          ),
          // Close button
          button(
            list{
              Attrs.class_(
                "px-3 py-1.5 text-sm text-gray-400 hover:text-gray-200 bg-gray-800 rounded hover:bg-gray-700 transition-colors",
              ),
              Events.onClick(PanelSwitcher(ClosePanels)),
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
        list{text("Loading farm manifest...")},
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
          div(list{Attrs.class_("text-red-400 mb-2")}, list{text("Failed to load farm manifest")}),
          div(list{Attrs.class_("text-sm text-gray-500 mb-4")}, list{text(error)}),
          button(
            list{
              Attrs.class_(
                "px-4 py-2 bg-gray-800 text-gray-300 rounded hover:bg-gray-700 transition-colors",
              ),
              Events.onClick(Farm(LoadRepos)),
            },
            list{text("Retry")},
          ),
        },
      ),
    },
  )
}

/// Main Farm panel view — full-screen overlay.
let view = (farm: farmState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.ariaLabel("Git-Private-Farm panel"),
    },
    list{
      // Header
      renderHeader(farm),
      // Category tabs
      renderCategoryTabBar(farm.activeCategory),
      // Content area
      if farm.loading {
        renderLoading()
      } else {
        switch farm.error {
        | Some(e) => renderError(e)
        | None =>
          if !farm.loaded {
            renderLoading()
          } else {
            renderContent(farm)
          }
        }
      },
    },
  )
}
