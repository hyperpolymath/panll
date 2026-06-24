// SPDX-License-Identifier: MPL-2.0

/// PanLL RegressionGuard — snapshot comparison and golden-file testing panel.
///
/// Displays a snapshot inventory with matched/mismatched badges, an inline diff
/// viewer for old-vs-new comparison, history of regression check runs, and
/// settings for auto-update and diff thresholds.

open Model
open Msg
open Tea.Html

// =========================================================================
// Helpers
// =========================================================================

/// Tab label lookup for regressionTab variants.
let tabLabel = (tab: regressionTab): string =>
  switch tab {
  | TabSnapshots => "Snapshots"
  | TabDiffs => "Diffs"
  | TabHistory => "History"
  | TabSettings => "Settings"
  }

/// Render the tab bar.
let renderTabs = (active: regressionTab): Tea_Vdom.t<msg> => {
  let tabs: array<regressionTab> = [TabSnapshots, TabDiffs, TabHistory, TabSettings]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 px-4")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm font-medium transition-colors rounded-t ${isActive
                ? "bg-gray-800 text-cyan-400 border-b-2 border-cyan-400"
                : "text-gray-500 hover:text-gray-300 hover:bg-gray-900 cursor-pointer"}`,
          ),
          Events.onClick(RegressionGuard(SetRgTab(tab))),
        },
        list{text(tabLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Badge for matched/mismatched snapshot state.
let matchBadge = (matched: option<bool>): Tea_Vdom.t<msg> =>
  switch matched {
  | Some(true) =>
    span(
      list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-emerald-600 text-white font-mono")},
      list{text("MATCH")},
    )
  | Some(false) =>
    span(
      list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-red-600 text-white font-mono")},
      list{text("MISMATCH")},
    )
  | None =>
    span(
      list{Attrs.class_("px-1.5 py-0.5 text-xs rounded bg-gray-600 text-gray-300 font-mono")},
      list{text("PENDING")},
    )
  }

/// Snapshot kind label.
let kindLabel = (kind: snapshotKind): string =>
  switch kind {
  | SnapshotGameState => "Game State"
  | SnapshotRenderOutput => "Render"
  | SnapshotApiResponse => "API"
  | SnapshotTestOutput => "Test"
  | SnapshotCustom(name) => name
  }

// =========================================================================
// Tab content views
// =========================================================================

/// Snapshots tab: inventory list with match badges and snapshot kind labels.
let renderSnapshotsTab = (state: regressionGuardState): Tea_Vdom.t<msg> => {
  let total = Array.length(state.snapshots)
  let matched = state.snapshots->Array.filter(s => s.matched === Some(true))->Array.length
  let mismatched = state.snapshots->Array.filter(s => s.matched === Some(false))->Array.length

  div(
    list{Attrs.class_("flex flex-col gap-3 p-4")},
    list{
      // Summary counts
      div(
        list{Attrs.class_("flex gap-4 text-sm")},
        list{
          span(list{Attrs.class_("text-gray-400")}, list{text(`Total: ${Int.toString(total)}`)}),
          span(
            list{Attrs.class_("text-emerald-400")},
            list{text(`Matched: ${Int.toString(matched)}`)},
          ),
          span(
            list{Attrs.class_("text-red-400")},
            list{text(`Mismatched: ${Int.toString(mismatched)}`)},
          ),
        },
      ),
      // Snapshot rows
      div(
        list{Attrs.class_("flex flex-col gap-1 max-h-96 overflow-y-auto")},
        state.snapshots
        ->Array.map(snap => {
          div(
            list{
              Attrs.class_(
                "flex items-center justify-between gap-3 px-3 py-2 bg-gray-800 rounded text-sm",
              ),
            },
            list{
              matchBadge(snap.matched),
              span(list{Attrs.class_("text-gray-300 flex-1 font-medium")}, list{text(snap.name)}),
              span(
                list{Attrs.class_("text-gray-500 text-xs font-mono")},
                list{text(kindLabel(snap.kind))},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-2 py-1 text-xs bg-cyan-700 text-white rounded hover:bg-cyan-600 cursor-pointer",
                  ),
                  Events.onClick(RegressionGuard(ViewDiff(snap.id))),
                },
                list{text("Diff")},
              ),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

/// Diffs tab: side-by-side old vs new comparison for mismatched snapshots.
let renderDiffsTab = (state: regressionGuardState): Tea_Vdom.t<msg> => {
  let mismatched = state.snapshots->Array.filter(s => s.matched === Some(false))
  if Array.length(mismatched) === 0 {
    div(
      list{Attrs.class_("p-4 text-gray-500 text-sm italic")},
      list{text("No mismatches found. All snapshots match their golden files.")},
    )
  } else {
    div(
      list{Attrs.class_("flex flex-col gap-3 p-4 max-h-96 overflow-y-auto")},
      mismatched
      ->Array.map(snap => {
        div(
          list{Attrs.class_("bg-gray-800 rounded p-3 border border-red-800")},
          list{
            div(
              list{Attrs.class_("flex items-center justify-between mb-2")},
              list{
                span(
                  list{Attrs.class_("text-sm font-medium text-gray-200")},
                  list{text(snap.name)},
                ),
                button(
                  list{
                    Attrs.class_(
                      "px-2 py-1 text-xs bg-amber-700 text-white rounded hover:bg-amber-600 cursor-pointer",
                    ),
                    Events.onClick(RegressionGuard(UpdateSnapshot(snap.id))),
                  },
                  list{text("Accept New")},
                ),
              },
            ),
            // Diff summary
            switch snap.diffSummary {
            | Some(diff) =>
              div(
                list{Attrs.class_("grid grid-cols-2 gap-2")},
                list{
                  div(
                    list{Attrs.class_("bg-gray-900 rounded p-2 border border-gray-700")},
                    list{
                      div(
                        list{Attrs.class_("text-xs text-gray-500 mb-1")},
                        list{text("Golden (old)")},
                      ),
                      div(
                        list{Attrs.class_("text-xs font-mono text-gray-400 whitespace-pre-wrap")},
                        list{text(snap.goldenPath)},
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("bg-gray-900 rounded p-2 border border-red-900")},
                    list{
                      div(
                        list{Attrs.class_("text-xs text-gray-500 mb-1")},
                        list{text("Current (new)")},
                      ),
                      div(
                        list{Attrs.class_("text-xs font-mono text-red-300 whitespace-pre-wrap")},
                        list{text(diff)},
                      ),
                    },
                  ),
                },
              )
            | None =>
              div(
                list{Attrs.class_("text-xs text-gray-500 italic")},
                list{text("Diff not yet computed")},
              )
            },
          },
        )
      })
      ->List.fromArray,
    )
  }
}

/// History tab: previous regression check results.
let renderHistoryTab = (state: regressionGuardState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-2 p-4 max-h-96 overflow-y-auto")},
    state.results
    ->Array.map(result => {
      let allMatched = result.mismatched === 0 && result.missing === 0
      let borderCls = allMatched ? "border-emerald-700" : "border-red-700"
      div(
        list{Attrs.class_(`bg-gray-800 rounded p-3 border ${borderCls}`)},
        list{
          div(
            list{Attrs.class_("flex justify-between text-xs text-gray-400 mb-1")},
            list{
              span(list{}, list{text(result.timestamp)}),
              span(list{}, list{text(`${Float.toFixed(result.durationMs, ~digits=0)}ms`)}),
            },
          ),
          div(
            list{Attrs.class_("flex gap-3 text-sm")},
            list{
              span(
                list{Attrs.class_("text-emerald-400")},
                list{text(`${Int.toString(result.matched)} matched`)},
              ),
              span(
                list{Attrs.class_("text-red-400")},
                list{text(`${Int.toString(result.mismatched)} mismatched`)},
              ),
              span(
                list{Attrs.class_("text-amber-400")},
                list{text(`${Int.toString(result.missing)} missing`)},
              ),
              span(
                list{Attrs.class_("text-blue-400")},
                list{text(`${Int.toString(result.newSnapshots)} new`)},
              ),
            },
          ),
        },
      )
    })
    ->List.fromArray,
  )
}

/// Settings tab: auto-update toggle and configuration.
let renderSettingsTab = (state: regressionGuardState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-4 p-4")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          button(
            list{
              Attrs.class_(
                `px-3 py-1.5 text-xs rounded font-medium cursor-pointer ${state.autoUpdate
                    ? "bg-cyan-700 text-white"
                    : "bg-gray-700 text-gray-400"}`,
              ),
              Events.onClick(RegressionGuard(ToggleAutoUpdate)),
              KeyboardNav.onActivate(RegressionGuard(ToggleAutoUpdate)),
            },
            list{text(state.autoUpdate ? "Auto-Update: ON" : "Auto-Update: OFF")},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text("Automatically accept new snapshots when golden files are missing")},
          ),
        },
      ),
      div(
        list{Attrs.class_("text-sm text-gray-400")},
        list{
          text(
            `Filter: "${state.filter}" (${Int.toString(Array.length(state.snapshots))} visible)`,
          ),
        },
      ),
    },
  )
}

// =========================================================================
// Main view
// =========================================================================

/// Primary view function dispatching tab content based on active tab.
let view = (state: regressionGuardState): Tea_Vdom.t<msg> => {
  let content = switch state.activeTab {
  | TabSnapshots => renderSnapshotsTab(state)
  | TabDiffs => renderDiffsTab(state)
  | TabHistory => renderHistoryTab(state)
  | TabSettings => renderSettingsTab(state)
  }

  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100")},
    list{
      // Header with Check All / Update All
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          h2(
            list{Attrs.class_("text-lg font-semibold text-cyan-300")},
            list{text("Regression Guard")},
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded hover:bg-emerald-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(RegressionGuard(CheckAll)),
                  KeyboardNav.onActivate(RegressionGuard(CheckAll)),
                },
                list{text("Check All")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1.5 text-xs bg-amber-700 text-white rounded hover:bg-amber-600 cursor-pointer font-medium",
                  ),
                  Events.onClick(RegressionGuard(UpdateAll)),
                  KeyboardNav.onActivate(RegressionGuard(UpdateAll)),
                },
                list{text("Update All")},
              ),
            },
          ),
        },
      ),
      // Running indicator
      if state.running {
        div(
          list{
            Attrs.class_("flex items-center gap-2 px-4 py-2 bg-gray-800 border-b border-gray-700"),
          },
          list{
            div(list{Attrs.class_("w-3 h-3 bg-amber-400 rounded-full animate-pulse")}, list{}),
            span(list{Attrs.class_("text-sm text-amber-300")}, list{text("Checking snapshots...")}),
          },
        )
      } else {
        noNode
      },
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
