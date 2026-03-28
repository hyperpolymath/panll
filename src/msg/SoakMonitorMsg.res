// SPDX-License-Identifier: PMPL-1.0-or-later

/// Soak Monitor messages -- long-running session memory trend and leak detection.

open Model

type soakMonitorMsg =
  | SetSmTab(soakTab)
  | SmStarted
  | SmCompleted(result<string, string>)
  | DismissSmError
  | StartMonitor
  | StopMonitor
