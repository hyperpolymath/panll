// SPDX-License-Identifier: PMPL-1.0-or-later

/// Pane-A (Ambient) Message Types.

type paneAMsg =
  | ToggleExpansion
  | UpdateMetrics(float, bool, Model.humidityLevel) // index, antiInflammatory, humidity
