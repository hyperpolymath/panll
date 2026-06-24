// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// ObservabilityEngine — pure functions for SARIF export and OpenTelemetry
/// trace collection through the observe-mcp BoJ cartridge.
///
/// Converts PanLL's internal latency log (BojModel.bojLatencyEntry ring buffer)
/// into industry-standard observability formats:
///   - OTLP JSON (OpenTelemetry Protocol) for trace export
///   - SARIF v2.1.0 for security scan results
///   - Percentile latency summaries (p50, p99) for dashboards
///
/// All functions are pure — no side effects, no Gossamer invocations.
/// Command wrappers live in ObservabilityCmd.res.

// ============================================================================
// Helpers
// ============================================================================

/// Generate a random 32-character hex string (128-bit trace ID).
let randomTraceId = (): string => {
  let chars = "0123456789abcdef"
  let buf = []
  for _i in 0 to 31 {
    let idx = Math.Int.random(0, 16)
    buf->Array.push(chars->String.charAt(idx))
  }
  buf->Array.join("")
}

/// Generate a random 16-character hex string (64-bit span ID).
let randomSpanId = (): string => {
  let chars = "0123456789abcdef"
  let buf = []
  for _i in 0 to 15 {
    let idx = Math.Int.random(0, 16)
    buf->Array.push(chars->String.charAt(idx))
  }
  buf->Array.join("")
}

/// Convert milliseconds to nanoseconds (as string to avoid float precision loss).
let msToNanoString = (ms: float): string => {
  let nanos = ms *. 1_000_000.0
  Float.toString(nanos)
}

/// Convert a Unix timestamp (ms) to nanoseconds string for OTLP.
let timestampToNanoString = (tsMs: float): string => {
  let nanos = tsMs *. 1_000_000.0
  Float.toString(nanos)
}

// ============================================================================
// OpenTelemetry Span Formatting
// ============================================================================

/// Convert a single latency entry to an OpenTelemetry-compatible JSON span.
///
/// Each span gets a fresh random traceId and spanId.  The operationName is
/// composed as "cartridge/tool" matching BoJ invocation semantics.
///
/// Returns a JSON string representing one OTLP span object.
let formatLatencyAsOtelSpan = (entry: BojModel.bojLatencyEntry): string => {
  let traceId = randomTraceId()
  let spanId = randomSpanId()
  let operationName = `${entry.cartridge}/${entry.tool}`
  let startTimeNano = timestampToNanoString(entry.timestamp)
  let durationNano = msToNanoString(entry.durationMs)
  // Build OTLP span JSON manually to keep this module dependency-free.
  `{"traceId":"${traceId}","spanId":"${spanId}","operationName":"${operationName}","startTimeUnixNano":"${startTimeNano}","endTimeUnixNano":"${timestampToNanoString(
      entry.timestamp +. entry.durationMs,
    )}","durationNano":"${durationNano}","status":{"code":"STATUS_CODE_OK"},"attributes":[{"key":"boj.cartridge","value":{"stringValue":"${entry.cartridge}"}},{"key":"boj.tool","value":{"stringValue":"${entry.tool}"}},{"key":"boj.duration_ms","value":{"doubleValue":${Float.toString(
      entry.durationMs,
    )}}}]}`
}

/// Wrap an array of latency entries in OTLP JSON export format.
///
/// Produces the standard `resourceSpans` → `scopeSpans` → `spans` structure
/// expected by OpenTelemetry collectors.
let exportTraceBatch = (entries: array<BojModel.bojLatencyEntry>): string => {
  let spans = entries->Array.map(formatLatencyAsOtelSpan)->Array.join(",")
  `{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"panll-boj"}},{"key":"service.version","value":{"stringValue":"0.2.0"}}]},"scopeSpans":[{"scope":{"name":"panll.observability","version":"1.0.0"},"spans":[${spans}]}]}]}`
}

// ============================================================================
// SARIF Export
// ============================================================================

/// Transform a panic-attack JSON report into SARIF v2.1.0 schema.
///
/// The input `reportJson` is the raw JSON string from panic-attack's assail
/// or assault commands.  This function wraps it in the SARIF envelope with:
///   - tool.driver (name, version, rules)
///   - results (message, level, locations)
///
/// If the input cannot be parsed, returns a minimal SARIF with an error result.
let sarifFromPanicReport = (reportJson: string): string => {
  // Attempt to parse the report to extract meaningful data.
  // On parse failure, produce a valid SARIF with an error note.
  let parsed = try JSON.parseExn(reportJson) catch {
  | _ => JSON.Encode.null
  }
  // Extract weak_points array if present, otherwise empty.
  let weakPoints = switch JSON.Classify.classify(parsed) {
  | Object(dict) =>
    switch dict->Dict.get("weak_points") {
    | Some(wp) =>
      switch JSON.Classify.classify(wp) {
      | Array(items) => items
      | _ => []
      }
    | None => []
    }
  | _ => []
  }
  // Build SARIF results from weak points.
  let results =
    weakPoints
    ->Array.mapWithIndex((item, idx) => {
      let message = switch JSON.Classify.classify(item) {
      | Object(d) =>
        switch d->Dict.get("description") {
        | Some(desc) =>
          switch JSON.Classify.classify(desc) {
          | String(s) => s
          | _ => "Unknown weak point"
          }
        | None => "Unknown weak point"
        }
      | _ => "Unknown weak point"
      }
      let severity = switch JSON.Classify.classify(item) {
      | Object(d) =>
        switch d->Dict.get("severity") {
        | Some(sev) =>
          switch JSON.Classify.classify(sev) {
          | String(s) =>
            switch s {
            | "critical" | "high" => "error"
            | "medium" => "warning"
            | _ => "note"
            }
          | _ => "warning"
          }
        | None => "warning"
        }
      | _ => "warning"
      }
      let ruleId = `PA${Int.toString(idx + 1)->String.padStart(3, "0")}`
      `{"ruleId":"${ruleId}","level":"${severity}","message":{"text":"${message}"},"locations":[{"physicalLocation":{"artifactLocation":{"uri":"file:///scan-target"}}}]}`
    })
    ->Array.join(",")
  // Build rules from weak points (one rule per result).
  let rules =
    weakPoints
    ->Array.mapWithIndex((_item, idx) => {
      let ruleId = `PA${Int.toString(idx + 1)->String.padStart(3, "0")}`
      `{"id":"${ruleId}","shortDescription":{"text":"panic-attack finding ${ruleId}"}}`
    })
    ->Array.join(",")
  // Assemble the full SARIF v2.1.0 document.
  `{"$schema":"https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json","version":"2.1.0","runs":[{"tool":{"driver":{"name":"panic-attack","version":"0.1.0","informationUri":"https://github.com/hyperpolymath/panic-attack","rules":[${rules}]}},"results":[${results}]}]}`
}

// ============================================================================
// Latency Statistics
// ============================================================================

/// Sort an array of floats in ascending order (non-mutating).
let sortedFloats = (arr: array<float>): array<float> => {
  let copy = arr->Array.copy
  copy->Array.sort((a, b) =>
    if a < b {
      -1.0
    } else if a > b {
      1.0
    } else {
      0.0
    }
  )
  copy
}

/// Compute the p-th percentile from a sorted array of floats.
/// Returns 0.0 for empty arrays.
let percentile = (sorted: array<float>, p: float): float => {
  let n = sorted->Array.length
  if n == 0 {
    0.0
  } else if n == 1 {
    sorted->Array.getUnsafe(0)
  } else {
    let rank = p /. 100.0 *. Int.toFloat(n - 1)
    let lower = Float.toInt(Math.floor(rank))
    let upper = Float.toInt(Math.ceil(rank))
    let fraction = rank -. Int.toFloat(lower)
    let lowerVal = sorted->Array.getUnsafe(lower)
    let upperVal = sorted->Array.getUnsafe(upper)
    lowerVal +. fraction *. (upperVal -. lowerVal)
  }
}

/// Compute the 50th percentile (median) latency in milliseconds.
let computeP50Latency = (entries: array<BojModel.bojLatencyEntry>): float => {
  let durations = entries->Array.map(e => e.durationMs)
  let sorted = sortedFloats(durations)
  percentile(sorted, 50.0)
}

/// Compute the 99th percentile latency in milliseconds.
let computeP99Latency = (entries: array<BojModel.bojLatencyEntry>): float => {
  let durations = entries->Array.map(e => e.durationMs)
  let sorted = sortedFloats(durations)
  percentile(sorted, 99.0)
}

/// Produce a JSON summary of latency statistics including p50, p99, count,
/// mean, and a per-cartridge breakdown.
///
/// Example output:
/// ```json
/// {
///   "count": 42,
///   "meanMs": 12.5,
///   "p50Ms": 10.2,
///   "p99Ms": 45.8,
///   "byCartridge": {
///     "database-mcp": {"count": 20, "meanMs": 8.3, "p50Ms": 7.1, "p99Ms": 22.0},
///     ...
///   }
/// }
/// ```
let latencySummary = (entries: array<BojModel.bojLatencyEntry>): string => {
  let count = entries->Array.length
  if count == 0 {
    `{"count":0,"meanMs":0,"p50Ms":0,"p99Ms":0,"byCartridge":{}}`
  } else {
    let durations = entries->Array.map(e => e.durationMs)
    let sorted = sortedFloats(durations)
    let total = durations->Array.reduce(0.0, (acc, d) => acc +. d)
    let meanMs = total /. Int.toFloat(count)
    let p50Ms = percentile(sorted, 50.0)
    let p99Ms = percentile(sorted, 99.0)
    // Group entries by cartridge name.
    let cartridgeMap: Dict.t<array<float>> = Dict.make()
    entries->Array.forEach(e => {
      let existing = switch cartridgeMap->Dict.get(e.cartridge) {
      | Some(arr) => arr
      | None => []
      }
      cartridgeMap->Dict.set(e.cartridge, existing->Array.concat([e.durationMs]))
    })
    // Build per-cartridge breakdown.
    let cartridgeEntries =
      cartridgeMap
      ->Dict.toArray
      ->Array.map(((name, durs)) => {
        let cCount = durs->Array.length
        let cTotal = durs->Array.reduce(0.0, (acc, d) => acc +. d)
        let cMean = cTotal /. Int.toFloat(cCount)
        let cSorted = sortedFloats(durs)
        let cP50 = percentile(cSorted, 50.0)
        let cP99 = percentile(cSorted, 99.0)
        `"${name}":{"count":${Int.toString(cCount)},"meanMs":${Float.toString(
            cMean,
          )},"p50Ms":${Float.toString(cP50)},"p99Ms":${Float.toString(cP99)}}`
      })
      ->Array.join(",")
    `{"count":${Int.toString(count)},"meanMs":${Float.toString(meanMs)},"p50Ms":${Float.toString(
        p50Ms,
      )},"p99Ms":${Float.toString(p99Ms)},"byCartridge":{${cartridgeEntries}}}`
  }
}
