// SPDX-License-Identifier: MPL-2.0

/// Build Dashboard messages -- build triggering, status reading, test
/// running, error display, and history for the IDApTIK build monitoring panel.

open Model

type buildDashboardMsg =
  /// Switch the active category tab.
  | SetBuildCategory(buildDashboardCategory)
  /// Trigger a build for a specific target.
  | TriggerBuild(buildTarget)
  /// Build triggered (or failed).
  | BuildTriggered(result<string, string>)
  /// Refresh build status for all targets.
  | RefreshBuildStatus
  /// Build status received.
  | BuildStatusReceived(result<string, string>)
  /// Run tests for a specific target.
  | RunTests(buildTarget)
  /// Test results received.
  | TestsReceived(result<string, string>)
  /// Cancel a running build.
  | CancelBuild(buildTarget)
  /// Build cancelled (or failed).
  | BuildCancelled(result<string, string>)
  /// Refresh build history.
  | RefreshHistory
  /// History received.
  | HistoryReceived(result<string, string>)
  /// Toggle watch mode.
  | ToggleWatchMode
  /// Toggle auto-rebuild.
  | ToggleAutoRebuild
  /// Toggle show passed tests.
  | ToggleShowPassed
  /// Dismiss the error banner.
  | DismissBuildError
  /// Toggle BoJ routing for BSP operations (bsp-mcp cartridge).
  | ToggleBuildBojRouting
  /// TypeLL cross-panel type check result for build config types.
  | TypeCheckResult(result<string, string>)
