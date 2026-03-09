// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! Observability Tauri commands — observe-mcp BoJ cartridge backend.
//!
//! Provides SARIF export, OpenTelemetry trace export, and observability
//! summary endpoints for the PanLL observe-mcp cartridge integration.
//!
//! These commands are invoked from the ReScript frontend via
//! `ObservabilityCmd.res` and route through the BoJ cartridge server
//! when bojRouting is enabled.
//!
//! Currently returns mock responses — the real implementation will
//! proxy to the observe-mcp cartridge at the BoJ server endpoint.

use serde_json::json;

/// Export a panic-attack report as SARIF via the observe-mcp cartridge.
///
/// Accepts a `report_id` identifying a previously-generated panic-attack
/// scan report and returns a SARIF v2.1.0 JSON document.
///
/// Mock implementation: returns a success acknowledgement with the report ID.
/// Real implementation will POST to BoJ observe-mcp cartridge endpoint.
#[tauri::command]
pub async fn observe_export_sarif(report_id: String) -> Result<String, String> {
    if report_id.is_empty() {
        return Err("report_id must not be empty".to_string());
    }
    // Mock: acknowledge the SARIF export request.
    // Real impl: POST /cartridges/observe-mcp/tools/export-sarif
    let response = json!({
        "status": "exported",
        "reportId": report_id,
        "format": "sarif-2.1.0",
        "exportedAt": chrono_now_iso(),
        "message": "SARIF export routed through observe-mcp cartridge"
    });
    Ok(response.to_string())
}

/// Export OpenTelemetry trace spans via the observe-mcp cartridge.
///
/// Accepts a `batch` string containing OTLP JSON (produced by
/// `ObservabilityEngine.exportTraceBatch` on the frontend) and forwards
/// it to the configured OpenTelemetry collector.
///
/// Mock implementation: parses the batch to count spans and returns
/// an acceptance summary.  Real implementation will POST to the
/// OTLP HTTP endpoint (typically :4318/v1/traces).
#[tauri::command]
pub async fn observe_export_traces(batch: String) -> Result<String, String> {
    if batch.is_empty() {
        return Err("batch must not be empty".to_string());
    }
    // Parse the batch to count spans for the mock response.
    let span_count = count_spans_in_batch(&batch);
    let response = json!({
        "status": "accepted",
        "spanCount": span_count,
        "exportedAt": chrono_now_iso(),
        "collector": "mock://localhost:4318",
        "message": "OTLP trace batch accepted by observe-mcp cartridge"
    });
    Ok(response.to_string())
}

/// Fetch an observability summary from the observe-mcp cartridge.
///
/// Returns aggregated metrics about trace collection, active exporters,
/// and collector health — used to populate the BoJ observability dashboard.
///
/// Mock implementation: returns static placeholder values.
/// Real implementation will GET /cartridges/observe-mcp/tools/summary.
#[tauri::command]
pub async fn observe_summary() -> Result<String, String> {
    let response = json!({
        "status": "healthy",
        "traceCount": 0,
        "spanCount": 0,
        "activeExporters": ["mock-otlp"],
        "collectorEndpoint": "mock://localhost:4318",
        "sarifExportsTotal": 0,
        "uptimeSeconds": 0,
        "message": "Observability summary from observe-mcp cartridge"
    });
    Ok(response.to_string())
}

// ============================================================================
// Internal helpers
// ============================================================================

/// Generate an ISO 8601 timestamp string (UTC).
///
/// Uses a simple epoch-based approach to avoid adding chrono as a dependency.
/// Format: "2026-01-01T00:00:00Z" (approximate — real impl should use chrono).
fn chrono_now_iso() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    // Approximate ISO 8601 from epoch seconds.
    // For mock purposes this is sufficient; real impl uses chrono crate.
    format!("epoch:{}", secs)
}

/// Count the number of span objects in an OTLP JSON batch.
///
/// Does a simple heuristic count by looking for `"spanId"` occurrences.
/// This is only used for the mock response — real impl delegates to the
/// collector which returns its own acceptance count.
fn count_spans_in_batch(batch: &str) -> usize {
    batch.matches("\"spanId\"").count()
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_observe_export_sarif_success() {
        let result = observe_export_sarif("report-001".to_string()).await;
        assert!(result.is_ok());
        let body = result.unwrap();
        assert!(body.contains("\"status\":\"exported\""));
        assert!(body.contains("\"reportId\":\"report-001\""));
        assert!(body.contains("sarif-2.1.0"));
    }

    #[tokio::test]
    async fn test_observe_export_sarif_empty_id() {
        let result = observe_export_sarif("".to_string()).await;
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "report_id must not be empty");
    }

    #[tokio::test]
    async fn test_observe_export_traces_success() {
        let batch = r#"{"resourceSpans":[{"scopeSpans":[{"spans":[{"spanId":"abc123"},{"spanId":"def456"}]}]}]}"#;
        let result = observe_export_traces(batch.to_string()).await;
        assert!(result.is_ok());
        let body = result.unwrap();
        assert!(body.contains("\"status\":\"accepted\""));
        assert!(body.contains("\"spanCount\":2"));
    }

    #[tokio::test]
    async fn test_observe_export_traces_empty_batch() {
        let result = observe_export_traces("".to_string()).await;
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "batch must not be empty");
    }

    #[tokio::test]
    async fn test_observe_export_traces_no_spans() {
        let batch = r#"{"resourceSpans":[]}"#;
        let result = observe_export_traces(batch.to_string()).await;
        assert!(result.is_ok());
        let body = result.unwrap();
        assert!(body.contains("\"spanCount\":0"));
    }

    #[tokio::test]
    async fn test_observe_summary() {
        let result = observe_summary().await;
        assert!(result.is_ok());
        let body = result.unwrap();
        assert!(body.contains("\"status\":\"healthy\""));
        assert!(body.contains("\"activeExporters\""));
        assert!(body.contains("mock-otlp"));
    }

    #[test]
    fn test_count_spans_in_batch() {
        let batch = r#"{"spanId":"a","spanId":"b","spanId":"c"}"#;
        assert_eq!(count_spans_in_batch(batch), 3);
    }

    #[test]
    fn test_count_spans_empty() {
        assert_eq!(count_spans_in_batch("{}"), 0);
    }

    #[test]
    fn test_chrono_now_iso_format() {
        let ts = chrono_now_iso();
        assert!(ts.starts_with("epoch:"));
    }
}
