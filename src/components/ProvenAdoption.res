// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Proven Adoption Component — proven library adoption scanner.
///
/// Two-column layout: left sidebar with repo list, right content with
/// detail view showing which SafeX modules each repo uses.

open Model
open Msg
open Tea.Html

/// Render a binding status badge.
let statusBadge = (status: provenModuleStatus): Tea_Vdom.t<msg> => {
  let (color, label) = switch status {
  | Adopted => ("text-green-400", "Adopted")
  | PartiallyAdopted => ("text-amber-400", "Partial")
  | NotAdopted => ("text-red-400", "Not Adopted")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Render a repo row in the sidebar.
let repoRow = (repo: repoProvenSummary, selected: bool): Tea_Vdom.t<msg> => {
  button(
    list{
      Attrs.class_(
        "w-full text-left px-3 py-2 border-b border-gray-800 hover:bg-gray-800/60 transition-colors " ++
        if selected {"bg-gray-800/80 border-l-2 border-l-blue-500"} else {""},
      ),
      Events.onClick(ProvenAdoption(SelectRepo(repo.repoName))),
    },
    list{
      div(list{Attrs.class_("flex items-center justify-between")}, list{
        span(list{Attrs.class_("text-sm text-gray-200 truncate")}, list{text(repo.repoName)}),
        statusBadge(repo.bindingStatus),
      }),
      div(list{Attrs.class_("text-xs text-gray-500 mt-0.5")}, list{
        text(`${Int.toString(Array.length(repo.modules))} modules`),
      }),
    },
  )
}

/// Render a tab button.
let tabBtn = (current: provenAdoptionTab, target: provenAdoptionTab, label: string): Tea_Vdom.t<msg> => {
  let active = current == target
  button(
    list{
      Attrs.class_(
        "px-3 py-1 text-xs rounded " ++
        if active {"bg-blue-600 text-white"} else {"bg-gray-800 text-gray-400 hover:bg-gray-700"},
      ),
      Events.onClick(ProvenAdoption(SetTab(target))),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Main view function for the Proven Adoption panel.
let view = (state: provenAdoptionState): Tea_Vdom.t<msg> => {
  let adopted = ProvenAdoptionEngine.adoptedCount(state.repos)
  let total = Array.length(state.repos)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Proven Adoption — Formally Verified Safety Primitives"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(list{Attrs.class_("flex items-center gap-3")}, list{
            h2(list{Attrs.class_("text-lg font-bold text-green-300")}, list{text("Proven Adoption")}),
            span(list{Attrs.class_("text-xs text-gray-500")}, list{
              text(`${Int.toString(adopted)}/${Int.toString(total)} repos`),
            }),
          }),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs rounded bg-green-700 text-white hover:bg-green-600"),
              Events.onClick(ProvenAdoption(ScanRepos)),
            },
            list{text(if state.scanning {"Scanning..."} else {"Scan"})},
          ),
        },
      ),
      // Tabs
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800"), Attrs.role("tablist")},
        ProvenAdoptionEngine.allTabs->Array.map(t =>
          tabBtn(state.activeTab, t, ProvenAdoptionEngine.tabLabel(t))
        )->List.fromArray,
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200")},
          list{text(err)},
        )
      | None => noNode
      },
      // Two-column layout
      div(
        list{Attrs.class_("flex flex-1 overflow-hidden")},
        list{
          // Left sidebar — repo list
          div(
            list{Attrs.class_("w-64 border-r border-gray-800 overflow-y-auto")},
            state.repos->Array.map(r =>
              repoRow(r, state.selectedRepo == Some(r.repoName))
            )->List.fromArray,
          ),
          // Right content — detail view
          div(
            list{Attrs.class_("flex-1 overflow-y-auto px-4 py-2")},
            list{
              switch state.selectedRepo {
              | None =>
                div(
                  list{Attrs.class_("flex items-center justify-center h-full text-gray-600")},
                  list{text("Select a repo to view proven module details")},
                )
              | Some(name) =>
                switch state.repos->Array.find(r => r.repoName == name) {
                | None => div(list{}, list{text("Repo not found")})
                | Some(repo) =>
                  div(list{}, list{
                    h3(list{Attrs.class_("text-md font-semibold text-gray-200 mb-3")}, list{text(repo.repoName)}),
                    div(list{Attrs.class_("space-y-2")}, list{
                      div(list{Attrs.class_("flex items-center gap-2")}, list{
                        span(list{Attrs.class_("text-xs text-gray-500 w-32")}, list{text("Dependency:")}),
                        span(
                          list{Attrs.class_(if repo.dependencyDeclared {"text-xs text-green-400"} else {"text-xs text-red-400"})},
                          list{text(if repo.dependencyDeclared {"Declared"} else {"Missing"})},
                        ),
                      }),
                      div(list{Attrs.class_("flex items-center gap-2")}, list{
                        span(list{Attrs.class_("text-xs text-gray-500 w-32")}, list{text("Binding Status:")}),
                        statusBadge(repo.bindingStatus),
                      }),
                      div(list{Attrs.class_("mt-3")}, list{
                        span(list{Attrs.class_("text-xs text-gray-500 mb-1 block")}, list{text("Modules:")}),
                        div(
                          list{Attrs.class_("flex flex-wrap gap-1")},
                          repo.modules->Array.map(m =>
                            span(
                              list{Attrs.class_("px-2 py-0.5 text-xs bg-gray-800 rounded text-gray-300")},
                              list{text(m)},
                            )
                          )->List.fromArray,
                        ),
                      }),
                    }),
                  })
                }
              },
            },
          ),
        },
      ),
      // Footer
      div(
        list{Attrs.class_("px-4 py-2 border-t border-gray-800 text-xs text-gray-500")},
        list{text(`${Int.toString(ProvenAdoptionEngine.fullyBoundCount(state.repos))} repos fully bound`)},
      ),
    },
  )
}
