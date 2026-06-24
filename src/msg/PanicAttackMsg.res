// SPDX-License-Identifier: MPL-2.0

/// panic-attack panel messages -- scanning, report management, filtering,
/// comparison, and capability probing for the stress testing panel.

type panicAttackMsg =
  /// Probe whether panic-attack binary is available.
  | CheckCapability
  /// Capability probe result.
  | CapabilityLoaded(result<string, string>)
  /// Set the target path for scanning.
  | SetTargetPath(string)
  /// Run a static analysis scan (assail).
  | RunAssail
  /// Assail scan result.
  | AssailResult(result<string, string>)
  /// Run a full assault (static + stress).
  | RunAssault
  /// Assault result.
  | AssaultResult(result<string, string>)
  /// Load saved reports list.
  | LoadReports
  /// Reports list loaded.
  | ReportsLoaded(result<string, string>)
  /// View a specific report.
  | ViewReport(string)
  /// Report loaded.
  | ReportLoaded(result<string, string>)
  /// Compare two reports.
  | CompareReports(string, string)
  /// Comparison result.
  | ComparisonLoaded(result<string, string>)
  /// Export report as SARIF.
  | ExportSarif(string)
  /// SARIF export result.
  | SarifExported(result<string, string>)
  /// Export report as PanLL event chain.
  | ExportEventChain(string)
  /// Event chain export result.
  | EventChainExported(result<string, string>)
  /// Set the active category filter.
  | SetPanicCategory(PanicAttackModel.panicCategory)
  /// Set the text filter.
  | SetPanicFilter(string)
  /// Toggle report diff view.
  | ToggleDiffView
  /// Dismiss error.
  | DismissError
  /// TypeLL cross-panel type check result for attack vector types.
  | TypeCheckResult(result<string, string>)
