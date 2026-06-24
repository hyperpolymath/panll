// SPDX-License-Identifier: MPL-2.0

/// PanLL Contractile Completeness Component — Mustfile/Trustfile/Dustfile/K9 coverage.
///
/// Two-column layout: left sidebar with repo list, right content with
/// detail view showing which contractile files are present or missing.

open Model
open Msg
open Tea.Html

/// Render a presence indicator.
let presenceIcon = (present: bool): Tea_Vdom.t<msg> => {
  let (color, label) = if present {
    ("text-green-400", "Y")
  } else {
    ("text-red-400", "N")
  }
  span(list{Attrs.class_("text-xs font-mono " ++ color)}, list{text(label)})
}

/// Render a repo row in the sidebar.
let repoRow = (repo: repoContractileStatus, selected: bool): Tea_Vdom.t<msg> => {
  let complete = repo.hasMustfile && repo.hasTrustfile && repo.hasDustfile && repo.hasK9
  button(
    list{
      Attrs.class_(
        "w-full text-left px-3 py-2 border-b border-gray-800 hover:bg-gray-800/60 transition-colors " ++ if (
          selected
        ) {
          "bg-gray-800/80 border-l-2 border-l-blue-500"
        } else {
          ""
        },
      ),
      Events.onClick(ContractileCompleteness(SelectRepo(repo.repoName))),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between")},
        list{
          span(list{Attrs.class_("text-sm text-gray-200 truncate")}, list{text(repo.repoName)}),
          span(
            list{
              Attrs.class_(
                if complete {
                  "text-xs text-green-400"
                } else {
                  "text-xs text-amber-400"
                },
              ),
            },
            list{
              text(
                if complete {
                  "Complete"
                } else {
                  "Incomplete"
                },
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Render a tab button.
let tabBtn = (
  current: contractileCompletenessTab,
  target: contractileCompletenessTab,
  label: string,
): Tea_Vdom.t<msg> => {
  let active = current == target
  button(
    list{
      Attrs.class_(
        "px-3 py-1 text-xs rounded " ++ if active {
          "bg-blue-600 text-white"
        } else {
          "bg-gray-800 text-gray-400 hover:bg-gray-700"
        },
      ),
      Events.onClick(ContractileCompleteness(SetTab(target))),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Main view function for the Contractile Completeness panel.
let view = (state: contractileCompletenessState): Tea_Vdom.t<msg> => {
  let complete = ContractileCompletenessEngine.fullyCompleteCount(state.repos)
  let total = Array.length(state.repos)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Contractile Completeness — Mustfile/Trustfile/Dustfile/K9 Coverage"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-bold text-amber-300")},
                list{text("Contractile Completeness")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(`${Int.toString(complete)}/${Int.toString(total)} complete`)},
              ),
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs rounded bg-green-700 text-white hover:bg-green-600"),
              Events.onClick(ContractileCompleteness(ScanRepos)),
              KeyboardNav.onActivate(ContractileCompleteness(ScanRepos)),
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
      // Tabs
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800"), Attrs.role("tablist")},
        ContractileCompletenessEngine.allTabs
        ->Array.map(t => tabBtn(state.activeTab, t, ContractileCompletenessEngine.tabLabel(t)))
        ->List.fromArray,
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200",
            ),
          },
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
            state.repos
            ->Array.map(r => repoRow(r, state.selectedRepo == Some(r.repoName)))
            ->List.fromArray,
          ),
          // Right content — detail view
          div(
            list{Attrs.class_("flex-1 overflow-y-auto px-4 py-2")},
            list{
              switch state.selectedRepo {
              | None =>
                div(
                  list{Attrs.class_("flex items-center justify-center h-full text-gray-600")},
                  list{text("Select a repo to view contractile file details")},
                )
              | Some(name) =>
                switch state.repos->Array.find(r => r.repoName == name) {
                | None => div(list{}, list{text("Repo not found")})
                | Some(repo) =>
                  div(
                    list{},
                    list{
                      h3(
                        list{Attrs.class_("text-md font-semibold text-gray-200 mb-3")},
                        list{text(repo.repoName)},
                      ),
                      div(
                        list{Attrs.class_("space-y-2")},
                        list{
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-24")},
                                list{text("Mustfile:")},
                              ),
                              presenceIcon(repo.hasMustfile),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-24")},
                                list{text("Trustfile:")},
                              ),
                              presenceIcon(repo.hasTrustfile),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-24")},
                                list{text("Dustfile:")},
                              ),
                              presenceIcon(repo.hasDustfile),
                            },
                          ),
                          div(
                            list{Attrs.class_("flex items-center gap-2")},
                            list{
                              span(
                                list{Attrs.class_("text-xs text-gray-500 w-24")},
                                list{text("K9:")},
                              ),
                              presenceIcon(repo.hasK9),
                              if repo.hasK9 {
                                span(
                                  list{Attrs.class_("text-xs text-gray-500 ml-2")},
                                  list{text(`(${Int.toString(repo.k9Count)} configs)`)},
                                )
                              } else {
                                noNode
                              },
                            },
                          ),
                        },
                      ),
                    },
                  )
                }
              },
            },
          ),
        },
      ),
      // Footer
      div(
        list{Attrs.class_("px-4 py-2 border-t border-gray-800 text-xs text-gray-500")},
        list{
          text(
            `${Int.toString(
                ContractileCompletenessEngine.incompleteCount(state.repos),
              )} repos incomplete`,
          ),
        },
      ),
    },
  )
}
