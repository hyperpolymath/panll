// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Manifest Coverage Component — AI manifest presence across all repos.
///
/// Two-column layout: left sidebar with repo list, right content with
/// detail view showing manifest presence, validity, and errors.

open Model
open Msg
open Tea.Html

/// Render a repo row in the sidebar.
let repoRow = (repo: repoManifestStatus, selected: bool): Tea_Vdom.t<msg> => {
  let statusColor = if repo.hasManifest && repo.isValid {
    "text-green-400"
  } else if repo.hasManifest {
    "text-amber-400"
  } else {
    "text-red-400"
  }
  let statusLabel = if repo.hasManifest && repo.isValid {
    "Valid"
  } else if repo.hasManifest {
    "Invalid"
  } else {
    "Missing"
  }
  button(
    list{
      Attrs.class_(
        "w-full text-left px-3 py-2 border-b border-gray-800 hover:bg-gray-800/60 transition-colors " ++
        if selected {"bg-gray-800/80 border-l-2 border-l-blue-500"} else {""},
      ),
      Events.onClick(ManifestCoverage(SelectRepo(repo.repoName))),
    },
    list{
      div(list{Attrs.class_("flex items-center justify-between")}, list{
        span(list{Attrs.class_("text-sm text-gray-200 truncate")}, list{text(repo.repoName)}),
        span(list{Attrs.class_("text-xs font-mono " ++ statusColor)}, list{text(statusLabel)}),
      }),
    },
  )
}

/// Render a tab button.
let tabBtn = (current: manifestCoverageTab, target: manifestCoverageTab, label: string): Tea_Vdom.t<msg> => {
  let active = current == target
  button(
    list{
      Attrs.class_(
        "px-3 py-1 text-xs rounded " ++
        if active {"bg-blue-600 text-white"} else {"bg-gray-800 text-gray-400 hover:bg-gray-700"},
      ),
      Events.onClick(ManifestCoverage(SetTab(target))),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Main view function for the Manifest Coverage panel.
let view = (state: manifestCoverageState): Tea_Vdom.t<msg> => {
  let valid = ManifestCoverageEngine.validManifestCount(state.repos)
  let total = Array.length(state.repos)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Manifest Coverage — AI Manifest Presence"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(list{Attrs.class_("flex items-center gap-3")}, list{
            h2(list{Attrs.class_("text-lg font-bold text-purple-300")}, list{text("Manifest Coverage")}),
            span(list{Attrs.class_("text-xs text-gray-500")}, list{
              text(`${Int.toString(valid)}/${Int.toString(total)} valid manifests`),
            }),
          }),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs rounded bg-green-700 text-white hover:bg-green-600"),
              Events.onClick(ManifestCoverage(ScanRepos)),
            },
            list{text(if state.scanning {"Scanning..."} else {"Scan"})},
          ),
        },
      ),
      // Tabs
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800"), Attrs.role("tablist")},
        ManifestCoverageEngine.allTabs->Array.map(t =>
          tabBtn(state.activeTab, t, ManifestCoverageEngine.tabLabel(t))
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
          // Left sidebar
          div(
            list{Attrs.class_("w-64 border-r border-gray-800 overflow-y-auto")},
            state.repos->Array.map(r =>
              repoRow(r, state.selectedRepo == Some(r.repoName))
            )->List.fromArray,
          ),
          // Right content
          div(
            list{Attrs.class_("flex-1 overflow-y-auto px-4 py-2")},
            list{
              switch state.selectedRepo {
              | None =>
                div(
                  list{Attrs.class_("flex items-center justify-center h-full text-gray-600")},
                  list{text("Select a repo to view manifest details")},
                )
              | Some(name) =>
                switch state.repos->Array.find(r => r.repoName == name) {
                | None => div(list{}, list{text("Repo not found")})
                | Some(repo) =>
                  div(list{}, list{
                    h3(list{Attrs.class_("text-md font-semibold text-gray-200 mb-3")}, list{text(repo.repoName)}),
                    div(list{Attrs.class_("space-y-2")}, list{
                      div(list{Attrs.class_("flex items-center gap-2")}, list{
                        span(list{Attrs.class_("text-xs text-gray-500 w-28")}, list{text("Has Manifest:")}),
                        span(
                          list{Attrs.class_(if repo.hasManifest {"text-xs text-green-400"} else {"text-xs text-red-400"})},
                          list{text(if repo.hasManifest {"Yes"} else {"No"})},
                        ),
                      }),
                      switch repo.manifestFile {
                      | Some(file) =>
                        div(list{Attrs.class_("flex items-center gap-2")}, list{
                          span(list{Attrs.class_("text-xs text-gray-500 w-28")}, list{text("File:")}),
                          span(list{Attrs.class_("text-xs text-gray-300 font-mono")}, list{text(file)}),
                        })
                      | None => noNode
                      },
                      div(list{Attrs.class_("flex items-center gap-2")}, list{
                        span(list{Attrs.class_("text-xs text-gray-500 w-28")}, list{text("Valid:")}),
                        span(
                          list{Attrs.class_(if repo.isValid {"text-xs text-green-400"} else {"text-xs text-red-400"})},
                          list{text(if repo.isValid {"Yes"} else {"No"})},
                        ),
                      }),
                      if Array.length(repo.validationErrors) > 0 {
                        div(list{Attrs.class_("mt-2")}, list{
                          span(list{Attrs.class_("text-xs text-gray-500 block mb-1")}, list{text("Errors:")}),
                          div(
                            list{Attrs.class_("space-y-1")},
                            repo.validationErrors->Array.map(e =>
                              div(list{Attrs.class_("text-xs text-red-300 font-mono pl-2")}, list{text(e)})
                            )->List.fromArray,
                          ),
                        })
                      } else {
                        noNode
                      },
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
        list{text(`${Int.toString(ManifestCoverageEngine.missingManifestCount(state.repos))} repos missing manifest`)},
      ),
    },
  )
}
