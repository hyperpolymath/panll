// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Build Dashboard Engine — pure computation and helpers for
/// monitoring build processes, test results, and compilation status.

open BuildDashboardModel

/// Human-readable labels for category tabs.
let categoryLabel = (cat: buildDashboardCategory): string =>
  switch cat {
  | BuildOverview => "Overview"
  | BuildErrors => "Errors"
  | BuildTests => "Tests"
  | BuildHistory => "History"
  }

/// Human-readable build target label.
let targetLabel = (target: buildTarget): string =>
  switch target {
  | TargetGame => "Game"
  | TargetVm => "VM"
  | TargetDlc => "DLC"
  | TargetSyncServer => "Sync Server"
  | TargetShared => "Shared"
  | TargetCoprocessors => "Coprocessors"
  | TargetCustom(name) => name
  }

/// Build target colour.
let targetColour = (target: buildTarget): string =>
  switch target {
  | TargetGame => "text-cyan-400"
  | TargetVm => "text-purple-400"
  | TargetDlc => "text-amber-400"
  | TargetSyncServer => "text-emerald-400"
  | TargetShared => "text-blue-400"
  | TargetCoprocessors => "text-orange-400"
  | TargetCustom(_) => "text-gray-400"
  }

/// Build status label.
let statusLabel = (status: buildStatus): string =>
  switch status {
  | BuildIdle => "Idle"
  | BuildRunning => "Building..."
  | BuildSuccess(_) => "Success"
  | BuildFailed(_) => "Failed"
  | BuildCancelled => "Cancelled"
  }

/// Build status colour.
let statusColour = (status: buildStatus): string =>
  switch status {
  | BuildIdle => "text-gray-500"
  | BuildRunning => "text-amber-400"
  | BuildSuccess(_) => "text-emerald-400"
  | BuildFailed(_) => "text-red-400"
  | BuildCancelled => "text-gray-400"
  }

/// All default build targets for IDApTIK.
let defaultTargets: array<(buildTarget, buildStatus)> = [
  (TargetGame, BuildIdle),
  (TargetVm, BuildIdle),
  (TargetDlc, BuildIdle),
  (TargetSyncServer, BuildIdle),
  (TargetShared, BuildIdle),
  (TargetCoprocessors, BuildIdle),
]

/// Count errors and warnings.
let errorCount = (messages: array<buildMessage>): int =>
  messages->Array.filter(m => m.severity === "error")->Array.length

let warningCount = (messages: array<buildMessage>): int =>
  messages->Array.filter(m => m.severity === "warning")->Array.length

/// Count passed/failed tests.
let passedTestCount = (results: array<testResult>): int =>
  results->Array.filter(r => r.passed)->Array.length

let failedTestCount = (results: array<testResult>): int =>
  results->Array.filter(r => !r.passed)->Array.length

/// Default state for the Build Dashboard panel.
let defaultState: buildDashboardState = {
  activeCategory: BuildOverview,
  targets: defaultTargets,
  messages: [],
  testResults: [],
  history: [],
  autoRebuild: false,
  watchMode: false,
  filterTarget: None,
  filterSeverity: "",
  showPassedTests: true,
  loading: false,
  error: None,
  bojRouting: false,
}
