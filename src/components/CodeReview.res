// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL CodeReview — pull request review, inline comments, and approval gates.
/// Scanner clade panel for team code review workflows.
///
/// Four tabs: Pull Requests (list with status badges), File Changes (summary),
/// Comments (threaded inline review), and Approval Gate (merge readiness).

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Human-readable label for a PR status.
let statusLabel = (status: prStatus): string =>
  switch status {
  | PrOpen => "Open"
  | PrApproved => "Approved"
  | PrChangesRequested => "Changes Requested"
  | PrMerged => "Merged"
  | PrClosed => "Closed"
  }

/// Tailwind colour class for a PR status badge.
let statusColour = (status: prStatus): string =>
  switch status {
  | PrOpen => "bg-blue-600 text-blue-100"
  | PrApproved => "bg-emerald-600 text-emerald-100"
  | PrChangesRequested => "bg-amber-600 text-amber-100"
  | PrMerged => "bg-purple-600 text-purple-100"
  | PrClosed => "bg-gray-600 text-gray-300"
  }

/// Tab bar rendering.
let renderTabs = (active: codeReviewTab): Tea_Vdom.t<msg> => {
  let tabs = CodeReviewEngine.allTabs
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-3 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-cyan-400 border-b-2 border-cyan-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900 cursor-pointer"}`,
          ),
          Events.onClick(CodeReview(SetCrTab(tab))),
        },
        list{text(CodeReviewEngine.tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

// =========================================================================
// Tab content views
// =========================================================================

/// Pull Requests tab: list with status badges, file counts, and diff stats.
let renderPullRequestsTab = (state: codeReviewState): Tea_Vdom.t<msg> => {
  let filtered = CodeReviewEngine.filterPrs(state.pullRequests, state.filter)
  if Array.length(filtered) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No pull requests found. Open a PR to begin code review.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4 max-h-96 overflow-y-auto")},
      filtered
      ->Array.map(pr => {
        let isSelected = state.selectedPr === Some(pr.id)
        let bgCls = isSelected ? "bg-gray-750 border border-cyan-700" : "bg-gray-800"
        div(
          list{
            Attrs.class_(
              `p-3 rounded border border-gray-700 cursor-pointer hover:bg-gray-750 ${bgCls}`,
            ),
            Events.onClick(CodeReview(SelectPr(pr.id))),
          },
          list{
            div(
              list{Attrs.class_("flex items-center justify-between mb-1")},
              list{
                span(list{Attrs.class_("text-sm font-medium text-gray-200")}, list{text(pr.title)}),
                span(
                  list{Attrs.class_(`text-xs px-2 py-0.5 rounded-full ${statusColour(pr.status)}`)},
                  list{text(statusLabel(pr.status))},
                ),
              },
            ),
            div(
              list{Attrs.class_("flex gap-4 text-xs text-gray-500")},
              list{
                span(list{}, list{text(pr.author)}),
                span(list{}, list{text(`${pr.branch}`)}),
                span(list{}, list{text(`${Int.toString(pr.filesChanged)} files`)}),
                span(
                  list{Attrs.class_("text-emerald-500")},
                  list{text(`+${Int.toString(pr.additions)}`)},
                ),
                span(
                  list{Attrs.class_("text-red-400")},
                  list{text(`-${Int.toString(pr.deletions)}`)},
                ),
              },
            ),
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// File Changes tab: summary of changed files in the selected PR.
let renderFileChangesTab = (_state: codeReviewState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4")},
    list{
      div(
        list{Attrs.class_("bg-gray-800 rounded p-4 h-48 flex items-center justify-center")},
        list{
          span(
            list{Attrs.class_("text-gray-600 text-sm")},
            list{text("Select a pull request to view file changes.")},
          ),
        },
      ),
    },
  )
}

/// Comments tab: threaded inline review comments.
let renderCommentsTab = (state: codeReviewState): Tea_Vdom.t<msg> => {
  let unresolvedCount = CodeReviewEngine.countUnresolved(state.comments)
  if Array.length(state.comments) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No review comments yet.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4")},
      list{
        div(
          list{Attrs.class_("text-sm text-gray-400 mb-1")},
          list{
            text(
              `${Int.toString(Array.length(state.comments))} comment(s), ${Int.toString(unresolvedCount)} unresolved`,
            ),
          },
        ),
        div(
          list{Attrs.class_("flex flex-col gap-2 max-h-80 overflow-y-auto")},
          state.comments
          ->Array.map(comment => {
            let resolvedCls = comment.resolved ? "border-emerald-800 opacity-60" : "border-gray-700"
            div(
              list{Attrs.class_(`bg-gray-800 rounded p-3 border ${resolvedCls}`)},
              list{
                div(
                  list{Attrs.class_("flex items-center justify-between mb-1")},
                  list{
                    span(
                      list{Attrs.class_("text-xs text-gray-400 font-mono")},
                      list{text(`${comment.filePath}:${Int.toString(comment.lineNumber)}`)},
                    ),
                    span(
                      list{Attrs.class_("text-xs text-gray-500")},
                      list{text(comment.author)},
                    ),
                  },
                ),
                div(
                  list{Attrs.class_("text-sm text-gray-300")},
                  list{text(comment.body)},
                ),
                if comment.resolved {
                  div(
                    list{Attrs.class_("text-xs text-emerald-500 mt-1")},
                    list{text("Resolved")},
                  )
                } else {
                  noNode
                },
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Approval Gate tab: merge readiness check and approve button.
let renderApprovalGateTab = (state: codeReviewState): Tea_Vdom.t<msg> => {
  let unresolvedCount = CodeReviewEngine.countUnresolved(state.comments)
  let openCount = CodeReviewEngine.countByStatus(state.pullRequests, PrOpen)
  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      div(
        list{Attrs.class_("bg-gray-800 rounded p-4 border border-gray-700")},
        list{
          div(
            list{Attrs.class_("text-sm font-medium text-gray-300 mb-2")},
            list{text("Merge Readiness")},
          ),
          div(
            list{Attrs.class_("flex flex-col gap-1 text-xs")},
            list{
              div(
                list{
                  Attrs.class_(
                    if openCount === 0 { "text-emerald-400" } else { "text-amber-400" },
                  ),
                },
                list{text(`Open PRs: ${Int.toString(openCount)}`)},
              ),
              div(
                list{
                  Attrs.class_(
                    if unresolvedCount === 0 { "text-emerald-400" } else { "text-red-400" },
                  ),
                },
                list{text(`Unresolved comments: ${Int.toString(unresolvedCount)}`)},
              ),
            },
          ),
        },
      ),
      if unresolvedCount === 0 && state.selectedPr !== None {
        button(
          list{
            Attrs.class_(
              "px-4 py-2 text-sm bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer font-medium",
            ),
            Events.onClick(CodeReview(ApprovePr)),
          },
          list{text("Approve Selected PR")},
        )
      } else {
        noNode
      },
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function for the Code Review panel.
let view = (state: codeReviewState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabPullRequests => renderPullRequestsTab(state)
  | TabFileChanges => renderFileChangesTab(state)
  | TabComments => renderCommentsTab(state)
  | TabApprovalGate => renderApprovalGateTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold text-cyan-300")},
            list{text("Code Review")},
          ),
          // Filter input
          input(
            list{
              Attrs.class_(
                "bg-gray-800 border border-gray-700 rounded px-2 py-1 text-sm text-gray-300 w-48 placeholder-gray-600",
              ),
              Attrs.placeholder("Filter PRs..."),
              Attrs.value(state.filter),
              Events.onInput(value => CodeReview(SetCrFilter(value))),
            },
            list{},
          ),
        },
      ),
      // Error display
      switch state.error {
      | Some(err) =>
        div(
          list{Attrs.class_("px-4 py-2 bg-red-900/30 text-red-300 text-sm border-b border-red-800")},
          list{text(err)},
        )
      | None => noNode
      },
      // Tab bar
      renderTabs(state.activeTab),
      // Content
      div(list{Attrs.class_("flex-1 overflow-y-auto")}, list{content}),
    },
  )
}
