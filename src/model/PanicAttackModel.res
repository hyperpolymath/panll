// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Panic-Attack Model — types for the stress testing and weak point
/// analysis panel.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Severity level for a detected weak point.
type weakPointSeverity =
  | Critical
  | High
  | Medium
  | Low
  | Info

/// Category of a detected weak point. Maps to panic-attack's 20 categories.
type weakPointCategory =
  | UnsafeCode
  | PanicPath
  | CommandInjection
  | UnsafeDeserialization
  | DOMInjection
  | HardcodedSecret
  | PathTraversal
  | InsecureProtocol
  | AtomExhaustion
  | UnsafeFFI
  | ResourceLeak
  | DeadlockPotential
  | RaceCondition
  | ErrorHandling
  | MemoryManagement
  | TypeUnsafety
  | ExceptionHandling
  | ConcurrencyIssues
  | DeprecatedAPIs
  | MissingValidation
  | DynamicCodeExecution
  | ExcessivePermissions
  | UncheckedError
  | OtherCategory(string)

/// A single weak point finding from a panic-attack scan.
type weakPoint = {
  file: string,
  line: option<int>,
  category: weakPointCategory,
  severity: weakPointSeverity,
  description: string,
  context: option<string>,
}

/// Summary statistics for a scan.
type scanSummary = {
  totalFindings: int,
  critical: int,
  high: int,
  medium: int,
  low: int,
  info: int,
  filesScanned: int,
  language: string,
}

/// A saved scan report (metadata only — findings loaded on demand).
type scanReport = {
  id: string,
  targetPath: string,
  timestamp: string,
  summary: scanSummary,
}

/// Category filter tabs for the findings view.
type panicCategory =
  | AllFindings
  | BySeverity(weakPointSeverity)
  | ByCategory(weakPointCategory)

/// Root state for the panic-attack panel.
type panicAttackState = {
  /// Panic-attack binary mode (full, fallback, unavailable).
  mode: string,
  /// Path to the panic-attack binary (if available).
  binaryPath: option<string>,
  /// Version string (if available).
  version: option<string>,
  /// Current scan target path.
  targetPath: string,
  /// Whether a scan is in progress.
  scanning: bool,
  /// Current scan findings.
  findings: array<weakPoint>,
  /// Current scan summary.
  summary: option<scanSummary>,
  /// Saved scan reports (metadata).
  reports: array<scanReport>,
  /// Active category filter tab.
  activeCategory: panicCategory,
  /// Text filter for findings.
  filterText: string,
  /// Whether the report comparison view is active.
  showDiff: bool,
  /// Left report ID for comparison.
  diffLeft: option<string>,
  /// Right report ID for comparison.
  diffRight: option<string>,
  /// Loading state indicator.
  loading: bool,
  /// Last error message.
  lastError: option<string>,
}

/// Initial state for the panic-attack panel.
let init: panicAttackState = {
  mode: "unknown",
  binaryPath: None,
  version: None,
  targetPath: "",
  scanning: false,
  findings: [],
  summary: None,
  reports: [],
  activeCategory: AllFindings,
  filterText: "",
  showDiff: false,
  diffLeft: None,
  diffRight: None,
  loading: false,
  lastError: None,
}
