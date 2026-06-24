// SPDX-License-Identifier: MPL-2.0

/// AmbientOps messages -- hospital-model sysadmin diagnostics and repair.

open Model

type ambientOpsMsg =
  /// Switch the active tab.
  | SetOpsTab(ambientOpsTab)
  /// Start a diagnostic sweep.
  | RunDiagnostics
  /// Diagnostic sweep completed with findings.
  | DiagnosticsComplete(result<array<diagnosticFinding>, string>)
  /// Dismiss error banner.
  | DismissOpsError
