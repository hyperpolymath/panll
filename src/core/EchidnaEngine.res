// SPDX-License-Identifier: MPL-2.0

/// PanLL ECHIDNA Engine — pure helpers for theorem prover dispatch panel.

open EchidnaModel

/// Default enterprise model state.
let defaultEnterpriseModelState: enterpriseModelState = {
  elements: [],
  constraints: [],
  checkResults: [],
  checking: false,
  activeMetamodel: None,
  activeLayer: None,
  lastXmiImport: None,
}

/// Default initial state.
let defaultState: echidnaState = {
  connected: false,
  endpoint: "http://localhost:9000/api/v1",
  version: None,
  provers: [],
  lastProofResult: None,
  proofError: None,
  proofLoading: false,
  session: None,
  tacticSuggestions: [],
  selectedProver: None,
  proofInput: "",
  menuExpanded: false,
  activeTab: EchidnaProofTab,
  tacticInput: "",
  sessionLoading: false,
  lastProofObligations: None,
  bojRouting: false,
  enterpriseModel: defaultEnterpriseModelState,
}

/// Tab label for display.
let tabLabel = (tab: echidnaTab): string => {
  switch tab {
  | EchidnaProofTab => "Proof Workbench"
  | EchidnaEnterpriseTab => "Enterprise Model"
  }
}
