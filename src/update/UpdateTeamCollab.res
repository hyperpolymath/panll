// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

// ===========================================================================
// Team & Collaboration Sub-Updaters
// ===========================================================================

/// Handles all Code Review messages — PR review, inline comments, approval gates.
let updateCodeReview = (model: model, msg: codeReviewMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.codeReview
  switch msg {
  | SetCrTab(tab) => ({...model, codeReview: {...state, activeTab: tab}}, Tea_Cmd.none)
  | SetCrFilter(f) => ({...model, codeReview: {...state, filter: f}}, Tea_Cmd.none)
  | SelectPr(id) => ({...model, codeReview: {...state, selectedPr: Some(id)}}, Tea_Cmd.none)
  | ApprovePr => (model, Tea_Cmd.none)
  | DismissCrError => ({...model, codeReview: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Merge Coordinator messages — branch management, conflict resolution.
let updateMergeCoordinator = (model: model, msg: mergeCoordinatorMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.mergeCoordinator
  switch msg {
  | SetMcTab(tab) => ({...model, mergeCoordinator: {...state, activeTab: tab}}, Tea_Cmd.none)
  | SelectBranch(name) => (
      {...model, mergeCoordinator: {...state, selectedBranch: Some(name)}},
      Tea_Cmd.none,
    )
  | ResolveConflict(filePath, _resolution) => {
      let newConflicts =
        state.conflicts->Array.map(c => c.filePath === filePath ? {...c, resolved: true} : c)
      ({...model, mergeCoordinator: {...state, conflicts: newConflicts}}, Tea_Cmd.none)
    }
  | DismissMcError => ({...model, mergeCoordinator: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Team Dashboard messages — team presence, activity feed.
let updateTeamDashboard = (model: model, msg: teamDashboardMsg): (model, Tea_Cmd.t<msg>) => {
  let state = model.teamDashboard
  switch msg {
  | SetTdTab(tab) => ({...model, teamDashboard: {...state, activeTab: tab}}, Tea_Cmd.none)
  | SetTdFilter(f) => ({...model, teamDashboard: {...state, filter: f}}, Tea_Cmd.none)
  | DismissTdError => ({...model, teamDashboard: {...state, error: None}}, Tea_Cmd.none)
  }
}

/// Handles all Debugging Workbench messages — time-travel, state inspection, watches.
let updateDebuggingWorkbench = (model: model, msg: debuggingWorkbenchMsg): (
  model,
  Tea_Cmd.t<msg>,
) => {
  let state = model.debuggingWorkbench
  let tt = state.timeTravel
  switch msg {
  | SetDwTab(tab) => ({...model, debuggingWorkbench: {...state, activeTab: tab}}, Tea_Cmd.none)
  | DwStepBack =>
    if DebuggingWorkbenchEngine.canGoBack(tt) {
      let newTt = {...tt, currentIndex: tt.currentIndex - 1, isTimeTravelling: true}
      let snap = tt.snapshots->Array.get(newTt.currentIndex)
      let selectedId = switch snap {
      | Some(s) => Some(s.id)
      | None => state.selectedSnapshot
      }
      (
        {...model, debuggingWorkbench: {...state, timeTravel: newTt, selectedSnapshot: selectedId}},
        Tea_Cmd.none,
      )
    } else {
      (model, Tea_Cmd.none)
    }
  | DwStepForward =>
    if DebuggingWorkbenchEngine.canGoForward(tt) {
      let newTt = {...tt, currentIndex: tt.currentIndex + 1, isTimeTravelling: true}
      let snap = tt.snapshots->Array.get(newTt.currentIndex)
      let selectedId = switch snap {
      | Some(s) => Some(s.id)
      | None => state.selectedSnapshot
      }
      (
        {...model, debuggingWorkbench: {...state, timeTravel: newTt, selectedSnapshot: selectedId}},
        Tea_Cmd.none,
      )
    } else {
      (model, Tea_Cmd.none)
    }
  | DwGoToSnapshot(idx) =>
    if idx >= 0 && idx < Array.length(tt.snapshots) {
      let newTt = {...tt, currentIndex: idx, isTimeTravelling: idx < Array.length(tt.snapshots) - 1}
      let snap = tt.snapshots->Array.get(idx)
      let selectedId = switch snap {
      | Some(s) => Some(s.id)
      | None => state.selectedSnapshot
      }
      (
        {...model, debuggingWorkbench: {...state, timeTravel: newTt, selectedSnapshot: selectedId}},
        Tea_Cmd.none,
      )
    } else {
      (model, Tea_Cmd.none)
    }
  | DwCaptureSnapshot => {
      let now = Date.now()
      let snap: debugSnapshot = {
        id: `snap-${Float.toString(now)}`,
        modelJson: UpdateHelpers.snapshotToJson(model),
        timestamp: now,
        label: `Snapshot at ${Float.toFixed(now /. 1000.0, ~digits=1)}s`,
      }
      let newSnapshots = Array.concat(tt.snapshots, [snap])
      let newTt = {
        snapshots: newSnapshots,
        currentIndex: Array.length(newSnapshots) - 1,
        isTimeTravelling: false,
      }
      (
        {
          ...model,
          debuggingWorkbench: {...state, timeTravel: newTt, selectedSnapshot: Some(snap.id)},
        },
        Tea_Cmd.none,
      )
    }
  | DwAddWatch => {
      let id = `watch-${Int.toString(Array.length(state.watches) + 1)}`
      let watch: watchExpression = {
        id,
        expression: "",
        currentValue: "(not evaluated)",
        lastUpdated: Date.now(),
      }
      (
        {...model, debuggingWorkbench: {...state, watches: Array.concat(state.watches, [watch])}},
        Tea_Cmd.none,
      )
    }
  | DwRemoveWatch(id) => {
      let newWatches = state.watches->Array.filter(w => w.id !== id)
      ({...model, debuggingWorkbench: {...state, watches: newWatches}}, Tea_Cmd.none)
    }
  | DwClearConsole => ({...model, debuggingWorkbench: {...state, consoleLog: []}}, Tea_Cmd.none)
  | DismissDwError => ({...model, debuggingWorkbench: {...state, error: None}}, Tea_Cmd.none)
  }
}
