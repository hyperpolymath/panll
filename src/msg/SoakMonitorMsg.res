// SPDX-License-Identifier: MPL-2.0

/// Soak Monitor messages -- long-running session memory trend and leak detection.

open Model

type soakMonitorMsg =
  | SetSmTab(soakTab)
  | SmStarted
  | SmCompleted(result<string, string>)
  | DismissSmError
  | StartMonitor
  | StopMonitor
