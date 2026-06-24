// SPDX-License-Identifier: MPL-2.0

/// Exploratory Workbench messages -- freeform play session recording, anomaly detection.

open Model

type exploratoryWorkbenchMsg =
  | SetEwTab(exploratoryTab)
  | EwStarted
  | EwCompleted(result<string, string>)
  | DismissEwError
  | StartRecording
  | StopRecording
  | QuickFlag(string)
  | ToggleAnomalyDetection
  | UpdateNotes(string)
