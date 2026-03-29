// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Panic-Attack Panel — stress testing and weak point analysis.
///
/// Displays scan results from panic-attack across 20 weak point categories,
/// with severity-based filtering, scan controls, report history, and
/// report comparison. Connects to the panic-attack binary via Gossamer.

open Msg
open PanicAttackModel
open Tea.Html

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
let modeView = (mode: string): Tea_Vdom.t<msg> => {
  let (colour, lbl) = switch mode {
  | "full" => ("text-emerald-400", "FULL")
  | "fallback" => ("text-amber-400", "FALLBACK")
  | "unavailable" => ("text-red-400", "UNAVAILABLE")
  | _ => ("text-gray-500", "PROBING...")
  }
  span(
    list{Attrs.class_(`text-xs font-mono px-2 py-0.5 rounded ${colour} bg-gray-800`)},
    list{text(lbl)},
  )
}

/// Summary bar showing severity counts.
let summaryBar = (summary: option<scanSummary>): Tea_Vdom.t<msg> => {
  switch summary {
  | None =>
    div(
      list{Attrs.class_("text-gray-500 text-sm italic py-2")},
      list{text("No scan results. Select a target and run assail.")},
    )
  | Some(s) =>
    div(
      list{Attrs.class_("flex gap-3 items-center py-2")},
      list{
        span(
          list{Attrs.class_("text-sm text-gray-400")},
          list{
            text(
              `${Int.toString(s.totalFindings)} findings in ${Int.toString(
                  s.filesScanned,
                )} files (${s.language})`,
            ),
          },
        ),
        div(
          list{Attrs.class_("flex gap-1")},
          list{
            if s.critical > 0 {
              span(
                list{Attrs.class_("px-2 py-0.5 text-xs rounded bg-red-600 text-white font-mono")},
                list{text(`${Int.toString(s.critical)} critical`)},
              )
            } else {
              noNode
            },
            if s.high > 0 {
              span(
                list{
                  Attrs.class_("px-2 py-0.5 text-xs rounded bg-orange-500 text-white font-mono"),
                },
                list{text(`${Int.toString(s.high)} high`)},
              )
            } else {
              noNode
            },
            if s.medium > 0 {
              span(
                list{
                  Attrs.class_("px-2 py-0.5 text-xs rounded bg-amber-400 text-gray-900 font-mono"),
                },
                list{text(`${Int.toString(s.medium)} medium`)},
              )
            } else {
              noNode
            },
            if s.low > 0 {
              span(
                list{Attrs.class_("px-2 py-0.5 text-xs rounded bg-blue-400 text-white font-mono")},
                list{text(`${Int.toString(s.low)} low`)},
              )
            } else {
              noNode
            },
          },
        ),
      },
    )
  }
}

/// Render a single finding row.
let findingRow = (wp: weakPoint): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "flex items-start gap-3 py-2 px-3 border-b border-gray-700 hover:bg-gray-800/50",
      ),
    },
    list{
      span(
        list{
          Attrs.class_(
            `px-1.5 py-0.5 text-xs rounded font-mono whitespace-nowrap ${severityClass(
                wp.severity,
              )}`,
          ),
        },
        list{text(severityLabel(wp.severity))},
      ),
      span(
        list{Attrs.class_("text-xs text-cyan-400 font-mono whitespace-nowrap min-w-[140px]")},
        list{text(categoryLabel(wp.category))},
      ),
      div(
        list{Attrs.class_("flex-1 min-w-0")},
        list{
          div(list{Attrs.class_("text-sm text-gray-200 truncate")}, list{text(wp.description)}),
          switch wp.file {
          | "" => noNode
          | file =>
            div(
              list{Attrs.class_("text-xs text-gray-500 font-mono truncate")},
              list{
                text(
                  switch wp.line {
                  | Some(line) => `${file}:${Int.toString(line)}`
                  | None => file
                  },
                ),
              },
            )
          },
        },
      ),
    },
  )
}

/// Filter findings by the active category.
let filterFindings = (
  findings: array<weakPoint>,
  category: panicCategory,
  filterText: string,
): array<weakPoint> => {
  findings->Array.filter(wp => {
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
let view = (state: panicAttackState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col h-full bg-gray-900 text-gray-100 overflow-hidden")},
    list{
      // Header bar
      div(
        list{
          Attrs.class_(
            "flex items-center justify-between px-4 py-3 bg-gray-800 border-b border-gray-700",
          ),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-lg font-bold text-amber-400")},
                list{text("panic-attack")},
              ),
              modeView(state.mode),
              switch state.version {
              | Some(v) =>
                span(list{Attrs.class_("text-xs text-gray-500 font-mono")}, list{text(`v${v}`)})
              | None => noNode
              },
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              if state.scanning {
                span(
                  list{Attrs.class_("text-xs text-amber-400 animate-pulse")},
                  list{text("Scanning...")},
                )
              } else {
                noNode
              },
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs rounded bg-amber-600 hover:bg-amber-500 text-white font-mono disabled:opacity-50",
                  ),
                  Attrs.disabled(state.scanning || state.mode == "unavailable"),
                  Events.onClick(PanicAttack(RunAssail)),
                },
                list{text("assail")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs rounded bg-red-700 hover:bg-red-600 text-white font-mono disabled:opacity-50",
                  ),
                  Attrs.disabled(state.scanning || state.mode == "unavailable"),
                  Events.onClick(PanicAttack(RunAssault)),
                },
                list{text("assault")},
              ),
            },
          ),
        },
      ),
      // Target path and filter bar
      div(
        list{
          Attrs.class_("flex items-center gap-2 px-4 py-2 bg-gray-850 border-b border-gray-700"),
        },
        list{
          span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Target:")}),
          input(
            list{
              Attrs.type_("text"),
              Attrs.class_(
                "flex-1 bg-gray-800 text-sm text-gray-200 px-2 py-1 rounded border border-gray-600 font-mono",
              ),
              Attrs.placeholder("/path/to/project"),
              Attrs.value(state.targetPath),
              Events.onInput(v => PanicAttack(SetTargetPath(v))),
            },
            list{},
          ),
          input(
            list{
              Attrs.type_("text"),
              Attrs.class_(
                "w-48 bg-gray-800 text-sm text-gray-200 px-2 py-1 rounded border border-gray-600",
              ),
              Attrs.placeholder("Filter findings..."),
              Attrs.value(state.filterText),
              Events.onInput(v => PanicAttack(SetPanicFilter(v))),
            },
            list{},
          ),
        },
      ),
      // Summary bar
      div(list{Attrs.class_("px-4 border-b border-gray-700")}, list{summaryBar(state.summary)}),
      // Error display
      switch state.lastError {
      | Some(err) =>
        div(
          list{
            Attrs.class_("px-4 py-2 bg-red-900/30 border-b border-red-700 text-red-300 text-sm"),
          },
          list{text(err)},
        )
      | None => noNode
      },
      // Findings list
      div(
        list{Attrs.class_("flex-1 overflow-y-auto")},
        {
          let filtered = filterFindings(state.findings, state.activeCategory, state.filterText)
          if Array.length(filtered) == 0 && !state.scanning {
            list{
              div(
                list{Attrs.class_("flex items-center justify-center h-32 text-gray-500 text-sm")},
                list{
                  text(
                    if Array.length(state.findings) == 0 {
                      "No findings yet. Run a scan to analyse your code."
                    } else {
                      "No findings match the current filter."
                    },
                  ),
                },
              ),
            }
          } else {
            filtered->Array.map(findingRow)->List.fromArray
          }
        },
      ),
      // Footer with report count
      div(
        list{
          Attrs.class_(
            "flex items-center justify-between px-4 py-2 bg-gray-800 border-t border-gray-700 text-xs text-gray-500",
          ),
        },
        list{
          span(list{}, list{text(`${Int.toString(Array.length(state.reports))} saved reports`)}),
          span(list{}, list{text("panic-attack 2.0.0 — 47 languages, 20 categories")}),
        },
      ),
    },
  )
}
