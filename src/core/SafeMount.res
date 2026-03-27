// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// SafeMount.res — Bridge between SafeDOMCore and PanLL's TEA runtime.
//
// Connects the four-layer DOM safety architecture to PanLL's systems:
//
//   1. Mount point validation — ProvenSelector validates "#app" before
//      the TEA runtime queries the DOM.
//
//   2. Audit trail → ObservabilityEngine — MountTracer events become OTEL
//      spans and SARIF findings via formatTraceAsOtelSpans/formatTraceAsSarif.
//
//   3. DOM readiness — SafeDOM.onDOMReady ensures TEA mounts after
//      DOMContentLoaded.
//
//   4. Raw HTML mounting — SafeDOM.mountString/mountParsed for panels
//      that inject pre-rendered HTML (markdown, code highlight, etc.).
//
//   5. Diagnostics — safetyReport for the diagnostics panel.
//
//   6. Trusted Types initialisation — call initSafety() at app startup.

/// Initialise all safety layers. Call once at app startup.
/// Returns the safety diagnostics report.
let initSafety = (): SafeDOMCore.safetyReport => {
  // Initialise Trusted Types policy (idempotent)
  let _ = SafeDOMCore.initTrustedTypes()
  // Log initialisation
  SafeDOMCore.MountTracer.record("safe-mount-init", "all safety layers initialised")
  // Return diagnostics
  SafeDOMCore.safetyDiagnostics()
}

/// Validate a selector and find the corresponding DOM element.
/// Returns Ok(element) if the selector is valid and the element exists,
/// Error(reason) otherwise. All outcomes are traced via MountTracer.
let validateAndFind = (selector: string): result<Tea_Render.domElement, string> => {
  switch SafeDOMCore.ProvenSelector.validate(selector) {
  | Error(reason) => Error(`Invalid mount selector "${selector}": ${reason}`)
  | Ok(validSelector) =>
    let selectorStr = SafeDOMCore.ProvenSelector.toString(validSelector)
    SafeDOMCore.MountTracer.record("tea-mount-lookup", "selector=" ++ selectorStr)
    switch Tea_Render.querySelector(selectorStr) {
    | None =>
      SafeDOMCore.MountTracer.record("tea-mount-missing", "selector=" ++ selectorStr)
      Error(`Mount point not found: ${selectorStr}`)
    | Some(el) =>
      SafeDOMCore.MountTracer.record("tea-mount-found", "selector=" ++ selectorStr)
      Ok(el)
    }
  }
}

/// Record a TEA lifecycle event in the mount trace.
let trace = (event: string, detail: string): unit => {
  SafeDOMCore.MountTracer.record(event, detail)
}

/// Get the full mount audit trail for the ObservabilityEngine.
let getAuditTrail = (): array<SafeDOMCore.MountTracer.entry> => {
  SafeDOMCore.MountTracer.entries()
}

/// Clear the audit trail (e.g. on app restart or hot reload).
let clearAuditTrail = (): unit => {
  SafeDOMCore.MountTracer.clear()
}

/// Mount raw HTML safely into a selector (innerHTML-based, with Trusted Types).
let mountRawHtml = (selector: string, html: string): SafeDOMCore.mountResult => {
  SafeDOMCore.mountString(selector, html)
}

/// Mount raw HTML via DOMParser (no innerHTML sink at all).
/// Safest option for untrusted content.
let mountRawHtmlParsed = (selector: string, html: string): SafeDOMCore.mountResult => {
  SafeDOMCore.mountStringParsed(selector, html)
}

/// Remount raw HTML atomically — validates before unmounting old content.
let remountRawHtml = (selector: string, html: string): SafeDOMCore.mountResult => {
  SafeDOMCore.remount(selector, html)
}

/// Execute a callback once the DOM is ready.
let whenReady = (callback: unit => unit): unit => {
  SafeDOMCore.onDOMReady(callback)
}

/// Get current safety layer diagnostics.
let diagnostics = (): SafeDOMCore.safetyReport => {
  SafeDOMCore.safetyDiagnostics()
}

// ------------------------------------------------------------------
// ObservabilityEngine integration
// ------------------------------------------------------------------

/// Convert MountTracer entries to OTEL-compatible JSON spans.
/// Each trace entry becomes one span with SafeDOM-specific attributes.
/// Returns a JSON string in OTLP ResourceSpans format.
let formatTraceAsOtelSpans = (): string => {
  let entries = SafeDOMCore.MountTracer.entries()
  let spans =
    entries
    ->Array.mapWithIndex((entry, idx) => {
      let spanId = "safedom" ++ String.padStart(Int.toString(idx), 10, "0")
      `{"traceId":"safedom-mount-trace","spanId":"${spanId}","operationName":"${entry.event}","startTimeUnixNano":"${Float.toString(
          entry.timestampMs *. 1_000_000.0,
        )}","attributes":[{"key":"safedom.event","value":{"stringValue":"${entry.event}"}},{"key":"safedom.detail","value":{"stringValue":"${entry.detail}"}}]}`
    })
    ->Array.join(",")
  `{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"panll-safedom"}}]},"scopeSpans":[{"scope":{"name":"panll.safedom","version":"1.0.0"},"spans":[${spans}]}]}]}`
}

/// Convert mount failures in the trace to SARIF findings.
/// Mount failures become error-level results; validation failures
/// become warning-level results.
let formatTraceAsSarif = (): string => {
  let entries = SafeDOMCore.MountTracer.entries()
  let failures =
    entries->Array.filter(e =>
      String.includes(e.event, "failure") ||
      String.includes(e.event, "not_found") ||
      String.includes(e.event, "invalid")
    )
  let results =
    failures
    ->Array.mapWithIndex((entry, idx) => {
      let ruleId = `SAFEDOM${Int.toString(idx + 1)->String.padStart(3, "0")}`
      let level = if String.includes(entry.event, "failure") {
        "error"
      } else {
        "warning"
      }
      `{"ruleId":"${ruleId}","level":"${level}","message":{"text":"[${entry.event}] ${entry.detail}"},"locations":[{"physicalLocation":{"artifactLocation":{"uri":"safedom://mount-trace"}}}]}`
    })
    ->Array.join(",")
  let rules =
    failures
    ->Array.mapWithIndex((_entry, idx) => {
      let ruleId = `SAFEDOM${Int.toString(idx + 1)->String.padStart(3, "0")}`
      `{"id":"${ruleId}","shortDescription":{"text":"SafeDOM mount safety finding"}}`
    })
    ->Array.join(",")
  `{"$schema":"https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json","version":"2.1.0","runs":[{"tool":{"driver":{"name":"panll-safedom","version":"1.0.0","rules":[${rules}]}},"results":[${results}]}]}`
}
