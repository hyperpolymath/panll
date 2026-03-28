// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for Pane-N (Neural) -- token stream and filter controls.

open Model

type paneNMsg =
  | ReceiveToken(neuralToken)
  | ClearTokens
  | SetInferenceActive(bool)
  | UpdateMonologue(string)
  | UpdateAgency(agencyState)
  /// Token stream filter controls.
  | ToggleSourceFilter(tokenSource)
  | ToggleCategoryFilter(tokenCategory)
  | TogglePhaseFilter(oodaPhase)
  | SetConfidenceThreshold(float)
  | ToggleValidatedOnly
  | ToggleProofOnly
  | ClearFilters
