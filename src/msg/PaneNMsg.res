// SPDX-License-Identifier: MPL-2.0

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
