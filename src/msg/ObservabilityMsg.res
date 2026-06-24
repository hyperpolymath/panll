// SPDX-License-Identifier: MPL-2.0

/// Observability messages -- SARIF export and OpenTelemetry trace collection
/// via the observe-mcp BoJ cartridge.

type observabilityMsg =
  /// Export a panic-attack report as SARIF via observe-mcp.
  | ExportSarifViaObserveMcp(string)
  /// SARIF export result.
  | SarifExportResult(result<string, string>)
  /// Export BoJ latency entries as OpenTelemetry traces.
  | ExportOtelTraces
  /// OTEL trace export result.
  | OtelExportResult(result<string, string>)
  /// Fetch observability summary (active exporters, trace counts).
  | FetchObservabilitySummary
  /// Observability summary result.
  | ObservabilitySummaryResult(result<string, string>)
  /// TypeLL cross-panel type check result for observability types.
  | TypeCheckResult(result<string, string>)
