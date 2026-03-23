// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// ObservabilityCmd — backend invoke wrappers for the observe-mcp BoJ cartridge.
///
/// Routes SARIF export and OpenTelemetry trace collection through the
/// observe-mcp cartridge backend (src-gossamer/src/observability/commands.rs),
/// enabling BoJ-routed observability when bojRouting is on.
///
/// All commands use `Tea_Cmd.call` for async backend invocations, matching
/// the pattern established in BojCmd.res and PanicAttackCmd.res.

let invoke = RuntimeBridge.invoke

/// Export a panic-attack report as SARIF via the observe-mcp cartridge.
///
/// This routes through the BoJ observe-mcp cartridge rather than directly
/// to the panic-attack backend, enabling centralised observability tracking.
///
/// The backend command `observe_export_sarif` accepts a report ID and
/// returns the SARIF JSON or an error.
let exportSarifViaObserveMcp = (
  reportId: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("observe_export_sarif", {"report_id": reportId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to export SARIF via observe-mcp")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Export OpenTelemetry trace spans via the observe-mcp cartridge.
///
/// The `batch` parameter should be an OTLP JSON string produced by
/// `ObservabilityEngine.exportTraceBatch`.  The backend forwards this
/// to the configured collector endpoint and returns an acceptance count.
let exportOtelTraces = (
  batch: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("observe_export_traces", {"batch": batch})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to export OTLP traces via observe-mcp")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fetch an observability summary from the observe-mcp cartridge.
///
/// Returns JSON with trace count, span count, active exporters, and
/// collector health — used to populate the BoJ observability dashboard.
let fetchObservabilitySummary = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("observe_summary", {"_": true})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to fetch observability summary")))
      Promise.resolve()
    })
    ->ignore
  })
}
