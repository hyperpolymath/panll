// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL MergeCoordinator — branch management, conflict resolution, and merge queue.
/// Directive clade panel for coordinated merge workflows.
///
/// Four tabs: Branches (list with ahead/behind indicators), Conflicts (diff viewer),
/// Merge Queue (ordered queue), and History (merged branch log).

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Human-readable label for a branch status.
let statusLabel = (status: branchStatus): string =>
  switch status {
  | BrActive => "Active"
  | BrMerging => "Merging"
  | BrConflicted => "Conflicted"
  | BrMerged => "Merged"
  | BrStale => "Stale"
  }

/// Tailwind colour class for a branch status badge.
let statusColour = (status: branchStatus): string =>
  switch status {
  | BrActive => "text-blue-400"
  | BrMerging => "text-amber-400 animate-pulse"
  | BrConflicted => "text-red-400"
  | BrMerged => "text-emerald-400"
  | BrStale => "text-gray-500"
  }

/// Tab bar rendering.
let renderTabs = (active: mergeCoordinatorTab): Tea_Vdom.t<msg> => {
  let tabs = MergeCoordinatorEngine.allTabs
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
          Events.onClick(MergeCoordinator(SetMcTab(tab))),
        },
        list{text(MergeCoordinatorEngine.tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

// =========================================================================
// Tab content views
// =========================================================================

/// Branches tab: list with ahead/behind indicators and status badges.
let renderBranchesTab = (state: mergeCoordinatorState): Tea_Vdom.t<msg> => {
  if Array.length(state.branches) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No tracked branches. Branches appear here when merge coordination is active.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4 max-h-96 overflow-y-auto")},
      state.branches
      ->Array.map(branch => {
        let isSelected = state.selectedBranch === Some(branch.name)
        let bgCls = isSelected ? "bg-gray-750 border border-cyan-700" : "bg-gray-800"
        div(
          list{
            Attrs.class_(
              `p-3 rounded border border-gray-700 cursor-pointer hover:bg-gray-750 ${bgCls}`,
            ),
            Events.onClick(MergeCoordinator(SelectBranch(branch.name))),
          },
          list{
            div(
              list{Attrs.class_("flex items-center justify-between mb-1")},
              list{
                span(
                  list{Attrs.class_("text-sm font-mono text-gray-200")},
                  list{text(branch.name)},
                ),
                span(
                  list{Attrs.class_(`text-xs ${statusColour(branch.status)}`)},
                  list{text(statusLabel(branch.status))},
                ),
              },
            ),
            div(
              list{Attrs.class_("flex gap-4 text-xs text-gray-500")},
              list{
                span(list{}, list{text(`base: ${branch.baseBranch}`)}),
                span(list{}, list{text(branch.author)}),
                span(
                  list{Attrs.class_("text-emerald-500")},
                  list{text(`+${Int.toString(branch.aheadBy)}`)},
                ),
                span(
                  list{Attrs.class_("text-red-400")},
                  list{text(`-${Int.toString(branch.behindBy)}`)},
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

/// Conflicts tab: file-level conflict viewer with resolution controls.
let renderConflictsTab = (state: mergeCoordinatorState): Tea_Vdom.t<msg> => {
  let unresolvedCount = MergeCoordinatorEngine.countConflicts(state.conflicts)
  if Array.length(state.conflicts) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No merge conflicts detected.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-2 p-4")},
      list{
        div(
          list{Attrs.class_("text-sm text-gray-400 mb-1")},
          list{
            text(
              `${Int.toString(Array.length(state.conflicts))} conflict(s), ${Int.toString(
                  unresolvedCount,
                )} unresolved`,
            ),
          },
        ),
        div(
          list{Attrs.class_("flex flex-col gap-2 max-h-80 overflow-y-auto")},
          state.conflicts
          ->Array.map(conflict => {
            let resolvedCls = conflict.resolved ? "border-emerald-800 opacity-60" : "border-red-800"
            div(
              list{Attrs.class_(`bg-gray-800 rounded p-3 border ${resolvedCls}`)},
              list{
                div(
                  list{Attrs.class_("text-xs font-mono text-gray-300 mb-2")},
                  list{text(conflict.filePath)},
                ),
                div(
                  list{Attrs.class_("grid grid-cols-2 gap-2")},
                  list{
                    div(
                      list{
                        Attrs.class_(
                          "bg-gray-900 rounded p-2 text-xs font-mono text-emerald-400 max-h-24 overflow-auto",
                        ),
                      },
                      list{text(`ours: ${conflict.ours}`)},
                    ),
                    div(
                      list{
                        Attrs.class_(
                          "bg-gray-900 rounded p-2 text-xs font-mono text-blue-400 max-h-24 overflow-auto",
                        ),
                      },
                      list{text(`theirs: ${conflict.theirs}`)},
                    ),
                  },
                ),
                if !conflict.resolved {
                  div(
                    list{Attrs.class_("flex gap-2 mt-2")},
                    list{
                      button(
                        list{
                          Attrs.class_(
                            "px-2 py-1 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer",
                          ),
                          Events.onClick(
                            MergeCoordinator(ResolveConflict(conflict.filePath, "ours")),
                          ),
                        },
                        list{text("Accept Ours")},
                      ),
                      button(
                        list{
                          Attrs.class_(
                            "px-2 py-1 text-xs bg-blue-700 text-white rounded hover:bg-blue-600 cursor-pointer",
                          ),
                          Events.onClick(
                            MergeCoordinator(ResolveConflict(conflict.filePath, "theirs")),
                          ),
                        },
                        list{text("Accept Theirs")},
                      ),
                    },
                  )
                } else {
                  div(list{Attrs.class_("text-xs text-emerald-500 mt-1")}, list{text("Resolved")})
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

/// Merge Queue tab: ordered list of branches awaiting merge.
let renderMergeQueueTab = (state: mergeCoordinatorState): Tea_Vdom.t<msg> => {
  if Array.length(state.mergeQueue) === 0 {
    div(list{Attrs.class_("p-4 text-gray-500 text-sm italic")}, list{text("Merge queue is empty.")})
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-1 p-4 max-h-80 overflow-y-auto")},
      state.mergeQueue
      ->Array.mapWithIndex((entry, idx) => {
        div(
          list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-800 rounded")},
          list{
            span(
              list{Attrs.class_("text-xs text-gray-500 w-6 text-right")},
              list{text(`#${Int.toString(idx + 1)}`)},
            ),
            span(
              list{Attrs.class_("text-sm font-mono text-gray-300 flex-1")},
              list{text(entry.branchName)},
            ),
            if entry.checksPassed {
              span(list{Attrs.class_("text-xs text-green-400")}, list{text("Checks passed")})
            } else {
              span(
                list{Attrs.class_("text-xs text-yellow-400")},
                list{text(`${Int.toString(Array.length(entry.pendingChecks))} checks pending`)},
              )
            },
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// History tab: placeholder for merged branch history.
let renderHistoryTab = (_state: mergeCoordinatorState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4")},
    list{
      div(
        list{Attrs.class_("bg-gray-800 rounded p-4 h-48 flex items-center justify-center")},
        list{
          span(
            list{Attrs.class_("text-gray-600 text-sm")},
            list{text("Merge history will appear here as branches are merged.")},
          ),
        },
      ),
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function for the Merge Coordinator panel.
let view = (state: mergeCoordinatorState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabBranches => renderBranchesTab(state)
  | TabConflicts => renderConflictsTab(state)
  | TabMergeQueue => renderMergeQueueTab(state)
  | TabHistory => renderHistoryTab(state)
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
            list{text("Merge Coordinator")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-500")},
            list{
              text(
                `${Int.toString(MergeCoordinatorEngine.queueLength(state.mergeQueue))} in queue`,
              ),
            },
          ),
        },
      ),
      // Error display
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_("px-4 py-2 bg-red-900/30 text-red-300 text-sm border-b border-red-800"),
          },
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
