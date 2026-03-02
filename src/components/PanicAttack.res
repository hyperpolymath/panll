// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Panic-Attack Panel — stress testing and weak point analysis.
///
/// Displays scan results from panic-attack across 20 weak point categories,
/// with severity-based filtering, scan controls, report history, and
/// report comparison. Connects to the panic-attack binary via Tauri.

open PanicAttackModel

/// Severity badge colour class.
let severityClass = (sev: weakPointSeverity): string =>
  switch sev {
  | Critical => "bg-red-600 text-white"
  | High => "bg-orange-500 text-white"
  | Medium => "bg-amber-400 text-gray-900"
  | Low => "bg-blue-400 text-white"
  | Info => "bg-gray-400 text-white"
  }

/// Severity display label.
let severityLabel = (sev: weakPointSeverity): string =>
  switch sev {
  | Critical => "CRITICAL"
  | High => "HIGH"
  | Medium => "MEDIUM"
  | Low => "LOW"
  | Info => "INFO"
  }

/// Category display label.
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

/// Mode indicator badge.
let modeView = (mode: string): Tea_Vdom.t<'msg> => {
  let (colour, label) = switch mode {
  | "full" => ("text-emerald-400", "FULL")
  | "fallback" => ("text-amber-400", "FALLBACK")
  | "unavailable" => ("text-red-400", "UNAVAILABLE")
  | _ => ("text-gray-500", "PROBING...")
  }
  <span className={`text-xs font-mono px-2 py-0.5 rounded ${colour} bg-gray-800`}>
    {Tea_Html.text(label)}
  </span>
}

/// Summary bar showing severity counts.
let summaryBar = (summary: option<scanSummary>): Tea_Vdom.t<'msg> => {
  switch summary {
  | None =>
    <div className="text-gray-500 text-sm italic py-2">
      {Tea_Html.text("No scan results. Select a target and run assail.")}
    </div>
  | Some(s) =>
    <div className="flex gap-3 items-center py-2">
      <span className="text-sm text-gray-400">
        {Tea_Html.text(`${Int.toString(s.totalFindings)} findings in ${Int.toString(s.filesScanned)} files (${s.language})`)}
      </span>
      <div className="flex gap-1">
        {if s.critical > 0 {
          <span className="px-2 py-0.5 text-xs rounded bg-red-600 text-white font-mono">
            {Tea_Html.text(`${Int.toString(s.critical)} critical`)}
          </span>
        } else {
          Tea_Html.noNode
        }}
        {if s.high > 0 {
          <span className="px-2 py-0.5 text-xs rounded bg-orange-500 text-white font-mono">
            {Tea_Html.text(`${Int.toString(s.high)} high`)}
          </span>
        } else {
          Tea_Html.noNode
        }}
        {if s.medium > 0 {
          <span className="px-2 py-0.5 text-xs rounded bg-amber-400 text-gray-900 font-mono">
            {Tea_Html.text(`${Int.toString(s.medium)} medium`)}
          </span>
        } else {
          Tea_Html.noNode
        }}
        {if s.low > 0 {
          <span className="px-2 py-0.5 text-xs rounded bg-blue-400 text-white font-mono">
            {Tea_Html.text(`${Int.toString(s.low)} low`)}
          </span>
        } else {
          Tea_Html.noNode
        }}
      </div>
    </div>
  }
}

/// Render a single finding row.
let findingRow = (wp: weakPoint): Tea_Vdom.t<'msg> => {
  <div className="flex items-start gap-3 py-2 px-3 border-b border-gray-700 hover:bg-gray-800/50">
    <span className={`px-1.5 py-0.5 text-xs rounded font-mono whitespace-nowrap ${severityClass(wp.severity)}`}>
      {Tea_Html.text(severityLabel(wp.severity))}
    </span>
    <span className="text-xs text-cyan-400 font-mono whitespace-nowrap min-w-[140px]">
      {Tea_Html.text(categoryLabel(wp.category))}
    </span>
    <div className="flex-1 min-w-0">
      <div className="text-sm text-gray-200 truncate">
        {Tea_Html.text(wp.description)}
      </div>
      {switch wp.file {
      | "" => Tea_Html.noNode
      | file =>
        <div className="text-xs text-gray-500 font-mono truncate">
          {Tea_Html.text(
            switch wp.line {
            | Some(line) => `${file}:${Int.toString(line)}`
            | None => file
            },
          )}
        </div>
      }}
    </div>
  </div>
}

/// Filter findings by the active category.
let filterFindings = (
  findings: array<weakPoint>,
  category: panicCategory,
  filterText: string,
): array<weakPoint> => {
  findings
  ->Array.filter(wp => {
    let catMatch = switch category {
    | AllFindings => true
    | BySeverity(sev) => wp.severity == sev
    | ByCategory(cat) => wp.category == cat
    }
    let textMatch =
      filterText == "" ||
      String.includes(String.toLowerCase(wp.description), String.toLowerCase(filterText)) ||
      String.includes(String.toLowerCase(wp.file), String.toLowerCase(filterText))
    catMatch && textMatch
  })
}

/// Main panel view.
let view = (state: panicAttackState, dispatch: Msg.msg => unit): Tea_Vdom.t<Msg.msg> => {
  let _dispatch = dispatch

  <div className="flex flex-col h-full bg-gray-900 text-gray-100 overflow-hidden">
    // Header bar
    <div className="flex items-center justify-between px-4 py-3 bg-gray-800 border-b border-gray-700">
      <div className="flex items-center gap-3">
        <span className="text-lg font-bold text-amber-400">
          {Tea_Html.text("panic-attack")}
        </span>
        {modeView(state.mode)}
        {switch state.version {
        | Some(v) =>
          <span className="text-xs text-gray-500 font-mono">
            {Tea_Html.text(`v${v}`)}
          </span>
        | None => Tea_Html.noNode
        }}
      </div>
      <div className="flex items-center gap-2">
        {if state.scanning {
          <span className="text-xs text-amber-400 animate-pulse">
            {Tea_Html.text("Scanning...")}
          </span>
        } else {
          Tea_Html.noNode
        }}
        <button
          className="px-3 py-1 text-xs rounded bg-amber-600 hover:bg-amber-500 text-white font-mono disabled:opacity-50"
          disabled={state.scanning || state.mode == "unavailable"}
          onClick={_evt => dispatch(PanicAttack(RunAssail))}>
          {Tea_Html.text("assail")}
        </button>
        <button
          className="px-3 py-1 text-xs rounded bg-red-700 hover:bg-red-600 text-white font-mono disabled:opacity-50"
          disabled={state.scanning || state.mode == "unavailable"}
          onClick={_evt => dispatch(PanicAttack(RunAssault))}>
          {Tea_Html.text("assault")}
        </button>
      </div>
    </div>

    // Target path and filter bar
    <div className="flex items-center gap-2 px-4 py-2 bg-gray-850 border-b border-gray-700">
      <span className="text-xs text-gray-500"> {Tea_Html.text("Target:")} </span>
      <input
        type_="text"
        className="flex-1 bg-gray-800 text-sm text-gray-200 px-2 py-1 rounded border border-gray-600 font-mono"
        placeholder="/path/to/project"
        value={state.targetPath}
        onChange={evt => {
          let value = (evt->ReactEvent.Form.target)["value"]
          dispatch(PanicAttack(SetTargetPath(value)))
        }}
      />
      <input
        type_="text"
        className="w-48 bg-gray-800 text-sm text-gray-200 px-2 py-1 rounded border border-gray-600"
        placeholder="Filter findings..."
        value={state.filterText}
        onChange={evt => {
          let value = (evt->ReactEvent.Form.target)["value"]
          dispatch(PanicAttack(SetPanicFilter(value)))
        }}
      />
    </div>

    // Summary bar
    <div className="px-4 border-b border-gray-700">
      {summaryBar(state.summary)}
    </div>

    // Error display
    {switch state.lastError {
    | Some(err) =>
      <div className="px-4 py-2 bg-red-900/30 border-b border-red-700 text-red-300 text-sm">
        {Tea_Html.text(err)}
      </div>
    | None => Tea_Html.noNode
    }}

    // Findings list
    <div className="flex-1 overflow-y-auto">
      {
        let filtered = filterFindings(state.findings, state.activeCategory, state.filterText)
        if Array.length(filtered) == 0 && !state.scanning {
          <div className="flex items-center justify-center h-32 text-gray-500 text-sm">
            {Tea_Html.text(
              if Array.length(state.findings) == 0 {
                "No findings yet. Run a scan to analyse your code."
              } else {
                "No findings match the current filter."
              },
            )}
          </div>
        } else {
          <div>
            {filtered->Array.map(findingRow)->React.array}
          </div>
        }
      }
    </div>

    // Footer with report count
    <div className="flex items-center justify-between px-4 py-2 bg-gray-800 border-t border-gray-700 text-xs text-gray-500">
      <span>
        {Tea_Html.text(`${Int.toString(Array.length(state.reports))} saved reports`)}
      </span>
      <span>
        {Tea_Html.text("panic-attack 2.0.0 — 47 languages, 20 categories")}
      </span>
    </div>
  </div>
}
