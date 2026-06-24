// SPDX-License-Identifier: MPL-2.0

/// Pane-A (Ambient) Message Types.

type paneAMsg =
  | ToggleExpansion
  | UpdateMetrics(float, bool, Model.humidityLevel) // index, antiInflammatory, humidity
