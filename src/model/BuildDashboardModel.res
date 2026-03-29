// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Build Dashboard Model — types for monitoring build processes,
/// test results, and compilation status for IDApTIK and its sub-projects
/// (game, VM, DLC, sync server, shared libraries).

/// Build target identity.
type buildTarget =
  | TargetGame
  | TargetVm
  | TargetDlc
  | TargetSyncServer
  | TargetShared
  | TargetCoprocessors
  | TargetCustom(string)

/// Build status.
type buildStatus =
  | BuildIdle
  | BuildRunning
  | BuildSuccess(float)
  | BuildFailed(float)
  | BuildCancelled

/// A build error or warning.
type buildMessage = {
  filePath: string,
  line: int,
  col: int,
  severity: string,
  message: string,
  target: buildTarget,
}

/// A test result entry.
type testResult = {
  name: string,
  suite: string,
  passed: bool,
  durationMs: float,
  output: string,
}

/// Build history entry.
type buildHistoryEntry = {
  id: string,
  target: buildTarget,
  status: buildStatus,
  startedAt: float,
  durationMs: float,
  errorCount: int,
  warningCount: int,
}

/// Category tabs for the Build Dashboard panel.
type buildDashboardCategory =
  | BuildOverview
  | BuildErrors
  | BuildTests
  | BuildHistory

/// Root state for the Build Dashboard panel.
type buildDashboardState = {
  activeCategory: buildDashboardCategory,
  targets: array<(buildTarget, buildStatus)>,
  messages: array<buildMessage>,
  testResults: array<testResult>,
  history: array<buildHistoryEntry>,
  autoRebuild: bool,
  watchMode: bool,
  filterTarget: option<buildTarget>,
  filterSeverity: string,
  showPassedTests: bool,
  loading: bool,
  error: option<string>,
  /// Route BSP operations through BoJ's bsp-mcp cartridge instead of direct Gossamer.
  bojRouting: bool,
}
