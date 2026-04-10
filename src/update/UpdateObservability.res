// SPDX-License-Identifier: PMPL-1.0-or-later

/// Observability — SARIF export, OTEL traces, and summary sub-updater.

open Model
open Msg

let updateObservability = (model: model, obsMsg: observabilityMsg): (model, Tea_Cmd.t<msg>) => {
  switch obsMsg {
  | ExportSarifViaObserveMcp(reportId) =>
    let cmd = ObservabilityCmd.exportSarifViaObserveMcp(reportId, r => Observability(
      SarifExportResult(r),
    ))
    (model, cmd)
  | SarifExportResult(_result) => (model, Tea_Cmd.none)
  | ExportOtelTraces =>
    let batch = ObservabilityEngine.exportTraceBatch(model.boj.latencyLog)
    let cmd = ObservabilityCmd.exportOtelTraces(batch, r => Observability(OtelExportResult(r)))
    (model, cmd)
  | OtelExportResult(_result) => (model, Tea_Cmd.none)
  | FetchObservabilitySummary =>
    let cmd = ObservabilityCmd.fetchObservabilitySummary(r => Observability(
      ObservabilitySummaryResult(r),
    ))
    (model, cmd)
  | ObservabilitySummaryResult(_result) => (model, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "observability", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => (model, Tea_Cmd.none)
  }
}
