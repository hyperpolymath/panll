// SPDX-License-Identifier: MPL-2.0

/// Wiring Inspector messages -- PCC verification lifecycle, audit tabs, and UI state.

type wiringInspectorMsg =
  | RunVerification
  | VerificationResult(result<string, string>)
  | RunSingleVerification(string)
  | SingleVerificationResult(result<string, string>)
  | SelectPanel(option<string>)
  | SetFilterStatus(option<string>)
  | SetAuditTab(WiringInspectorModel.auditTab)
  | SetSortBy(string)
  | ToggleStateSection(WiringInspectorModel.panelState)
