// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Panic-Attack Engine — pure functions for single-repo stress testing
/// and weak point analysis.
///
/// Provides severity/category classification, finding filtering and sorting,
/// summary computation, and SARIF-compatible output helpers. All functions
/// are side-effect-free; Tauri commands live in PanicAttackCmd.

open PanicAttackModel

// =========================================================================
// Default state
// =========================================================================

/// Initial state for the Panic-Attack panel.
let defaultState: panicAttackState = init

// =========================================================================
// Severity helpers
// =========================================================================

/// Numeric weight for sorting by severity (higher = more severe).
let severityWeight = (sev: weakPointSeverity): int =>
  switch sev {
  | Critical => 5
  | High => 4
  | Medium => 3
  | Low => 2
  | Info => 1
  }

/// Human-readable severity label.
let severityLabel = (sev: weakPointSeverity): string =>
  switch sev {
  | Critical => "Critical"
  | High => "High"
  | Medium => "Medium"
  | Low => "Low"
  | Info => "Info"
  }

/// CSS colour class for severity badge rendering.
let severityColourClass = (sev: weakPointSeverity): string =>
  switch sev {
  | Critical => "bg-red-600 text-white"
  | High => "bg-orange-500 text-white"
  | Medium => "bg-amber-400 text-gray-900"
  | Low => "bg-blue-400 text-white"
  | Info => "bg-gray-400 text-white"
  }

/// All severity levels in descending order.
let allSeverities: array<weakPointSeverity> = [Critical, High, Medium, Low, Info]

// =========================================================================
// Category helpers
// =========================================================================

/// Human-readable category label. Maps all 20 panic-attack categories
/// plus the escape-hatch OtherCategory variant.
let categoryLabel = (cat: weakPointCategory): string =>
  switch cat {
  | UnsafeCode => "Unsafe Code"
  | PanicPath => "Panic Path"
  | CommandInjection => "Command Injection"
  | UnsafeDeserialization => "Unsafe Deserialization"
  | DOMInjection => "DOM Injection"
  | HardcodedSecret => "Hardcoded Secret"
  | PathTraversal => "Path Traversal"
  | InsecureProtocol => "Insecure Protocol"
  | AtomExhaustion => "Atom Exhaustion"
  | UnsafeFFI => "Unsafe FFI"
  | ResourceLeak => "Resource Leak"
  | DeadlockPotential => "Deadlock Potential"
  | RaceCondition => "Race Condition"
  | ErrorHandling => "Error Handling"
  | MemoryManagement => "Memory Management"
  | TypeUnsafety => "Type Unsafety"
  | ExceptionHandling => "Exception Handling"
  | ConcurrencyIssues => "Concurrency Issues"
  | DeprecatedAPIs => "Deprecated APIs"
  | MissingValidation => "Missing Validation"
  | DynamicCodeExecution => "Dynamic Code Execution"
  | ExcessivePermissions => "Excessive Permissions"
  | UncheckedError => "Unchecked Error"
  | OtherCategory(name) => name
  }

/// Short icon-style label for compact views.
let categoryIcon = (cat: weakPointCategory): string =>
  switch cat {
  | UnsafeCode => "UNSAFE"
  | PanicPath => "PANIC"
  | CommandInjection => "CMDINJ"
  | UnsafeDeserialization => "DESER"
  | DOMInjection => "DOM"
  | HardcodedSecret => "SECRET"
  | PathTraversal => "PATH"
  | InsecureProtocol => "PROTO"
  | AtomExhaustion => "ATOM"
  | UnsafeFFI => "FFI"
  | ResourceLeak => "LEAK"
  | DeadlockPotential => "DEAD"
  | RaceCondition => "RACE"
  | ErrorHandling => "ERR"
  | MemoryManagement => "MEM"
  | TypeUnsafety => "TYPE"
  | ExceptionHandling => "EXCEPT"
  | ConcurrencyIssues => "CONC"
  | DeprecatedAPIs => "DEPR"
  | MissingValidation => "VALID"
  | DynamicCodeExecution => "DYNEX"
  | ExcessivePermissions => "PERMS"
  | UncheckedError => "UNCHECK"
  | OtherCategory(_) => "OTHER"
  }

// =========================================================================
// Filtering
// =========================================================================

/// Filter findings by active category tab.
let filterByCategory = (findings: array<weakPoint>, cat: panicCategory): array<weakPoint> =>
  switch cat {
  | AllFindings => findings
  | BySeverity(sev) => findings->Array.filter(wp => wp.severity == sev)
  | ByCategory(c) => findings->Array.filter(wp => wp.category == c)
  }

/// Filter findings by text query across description + file path.
let filterByText = (findings: array<weakPoint>, query: string): array<weakPoint> =>
  if query == "" {
    findings
  } else {
    let q = String.toLowerCase(query)
    findings->Array.filter(wp =>
      String.includes(String.toLowerCase(wp.description), q) ||
      String.includes(String.toLowerCase(wp.file), q)
    )
  }

/// Composite filter: category + text in one pass.
let applyFilters = (findings: array<weakPoint>, category: panicCategory, filterText: string): array<
  weakPoint,
> => findings->filterByCategory(category)->filterByText(filterText)

// =========================================================================
// Sorting
// =========================================================================

/// Sort findings by severity (most severe first), stable within severity.
let sortBySeverity = (findings: array<weakPoint>): array<weakPoint> => {
  let sorted = Array.copy(findings)
  sorted->Array.sort((a, b) => Int.compare(severityWeight(b.severity), severityWeight(a.severity)))
  sorted
}

/// Sort findings by file path then line number (for code-review flow).
let sortByLocation = (findings: array<weakPoint>): array<weakPoint> => {
  let sorted = Array.copy(findings)
  sorted->Array.sort((a, b) => {
    let fileCmp = String.compare(a.file, b.file)
    if fileCmp != 0.0 {
      fileCmp
    } else {
      let la = a.line->Option.getOr(0)
      let lb = b.line->Option.getOr(0)
      Int.compare(la, lb)
    }
  })
  sorted
}

// =========================================================================
// Summary computation
// =========================================================================

/// Build a scan summary from an array of findings.
let computeSummary = (findings: array<weakPoint>, language: string): scanSummary => {
  let files = findings->Array.map(wp => wp.file)->Array.filter(f => f != "")
  let uniqueFiles = files->Array.reduce([], (acc, f) =>
    if acc->Array.some(x => x == f) {
      acc
    } else {
      Array.concat(acc, [f])
    }
  )
  {
    totalFindings: Array.length(findings),
    critical: findings->Array.filter(wp => wp.severity == Critical)->Array.length,
    high: findings->Array.filter(wp => wp.severity == High)->Array.length,
    medium: findings->Array.filter(wp => wp.severity == Medium)->Array.length,
    low: findings->Array.filter(wp => wp.severity == Low)->Array.length,
    info: findings->Array.filter(wp => wp.severity == Info)->Array.length,
    filesScanned: Array.length(uniqueFiles),
    language,
  }
}

/// Count findings at a given severity level.
let countBySeverity = (findings: array<weakPoint>, sev: weakPointSeverity): int =>
  findings->Array.filter(wp => wp.severity == sev)->Array.length

/// Group findings by category, returning (category, count) pairs sorted
/// by count descending.
let groupByCategory = (findings: array<weakPoint>): array<(string, int)> => {
  let groups: array<(string, int)> = []
  findings->Array.forEach(wp => {
    let label = categoryLabel(wp.category)
    let found = groups->Array.findIndex(((l, _)) => l == label)
    if found >= 0 {
      let (l, c) = groups->Array.getUnsafe(found)
      ignore(groups->Array.splice(~start=found, ~remove=1, ~insert=[(l, c + 1)]))
    } else {
      ignore(groups->Array.push((label, 1)))
    }
  })
  groups->Array.sort(((_, a), (_, b)) => Int.compare(b, a))
  groups
}

// =========================================================================
// Report helpers
// =========================================================================

/// Check whether a report ID exists in the saved reports list.
let reportExists = (reports: array<scanReport>, id: string): bool =>
  reports->Array.some(r => r.id == id)

/// Find a report by ID.
let findReport = (reports: array<scanReport>, id: string): option<scanReport> =>
  reports->Array.find(r => r.id == id)

/// Format a file:line reference string.
let locationLabel = (file: string, line: option<int>): string =>
  switch line {
  | Some(l) => file ++ ":" ++ Int.toString(l)
  | None => file
  }

/// Mode display label.
let modeLabel = (mode: string): string =>
  switch mode {
  | "full" => "Full"
  | "fallback" => "Fallback"
  | "unavailable" => "Unavailable"
  | _ => "Probing..."
  }

/// Whether the panel is in a scannable state.
let canScan = (state: panicAttackState): bool =>
  !state.scanning && state.mode != "unavailable" && state.targetPath != ""
