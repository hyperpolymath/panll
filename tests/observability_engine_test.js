// SPDX-License-Identifier: MPL-2.0

/**
 * ObservabilityEngine Tests — OTel formatting, SARIF, percentiles, latency
 */

import { assertEquals } from "jsr:@std/assert";
import {
  msToNanoString,
  timestampToNanoString,
  sortedFloats,
  percentile,
  computeP50Latency,
  computeP99Latency,
  latencySummary,
  exportTraceBatch,
  sarifFromPanicReport,
} from "../src/core/ObservabilityEngine.res.js";

// -- msToNanoString --

Deno.test("msToNanoString converts ms to nanoseconds string", () => {
  assertEquals(msToNanoString(1.0), "1000000");
});

Deno.test("msToNanoString handles zero", () => {
  assertEquals(msToNanoString(0.0), "0");
});

// -- timestampToNanoString --

Deno.test("timestampToNanoString converts timestamp", () => {
  assertEquals(timestampToNanoString(1000.0), "1000000000");
});

// -- sortedFloats --

Deno.test("sortedFloats sorts ascending", () => {
  const result = sortedFloats([3.0, 1.0, 2.0]);
  assertEquals(result, [1.0, 2.0, 3.0]);
});

Deno.test("sortedFloats handles empty", () => {
  assertEquals(sortedFloats([]).length, 0);
});

// -- percentile --

Deno.test("percentile returns 0 for empty array", () => {
  assertEquals(percentile([], 50.0), 0.0);
});

Deno.test("percentile returns single value for single element", () => {
  assertEquals(percentile([42.0], 50.0), 42.0);
});

Deno.test("percentile p50 of even distribution", () => {
  const sorted = [10.0, 20.0, 30.0, 40.0, 50.0];
  assertEquals(percentile(sorted, 50.0), 30.0);
});

// -- computeP50Latency / computeP99Latency --

Deno.test("computeP50Latency computes median", () => {
  const entries = [
    { durationMs: 10.0 },
    { durationMs: 20.0 },
    { durationMs: 30.0 },
  ];
  assertEquals(computeP50Latency(entries), 20.0);
});

Deno.test("computeP99Latency with single entry", () => {
  const entries = [{ durationMs: 50.0 }];
  assertEquals(computeP99Latency(entries), 50.0);
});

// -- latencySummary --

Deno.test("latencySummary returns zero summary for empty", () => {
  const result = latencySummary([]);
  assertEquals(result.includes('"count":0'), true);
});

Deno.test("latencySummary includes cartridge breakdown", () => {
  const entries = [
    { durationMs: 10.0, cartridge: "echo", tool: "ping", timestamp: 1000.0 },
    { durationMs: 20.0, cartridge: "echo", tool: "pong", timestamp: 2000.0 },
  ];
  const result = latencySummary(entries);
  assertEquals(result.includes('"count":2'), true);
  assertEquals(result.includes('"echo"'), true);
});

// -- exportTraceBatch --

Deno.test("exportTraceBatch produces valid OTLP JSON", () => {
  const entries = [
    { durationMs: 5.0, cartridge: "echo", tool: "ping", timestamp: 1000.0 },
  ];
  const result = exportTraceBatch(entries);
  assertEquals(result.includes("resourceSpans"), true);
  assertEquals(result.includes("panll-boj"), true);
  assertEquals(result.includes("echo/ping"), true);
});

// -- sarifFromPanicReport --

Deno.test("sarifFromPanicReport produces SARIF from valid report", () => {
  const report = JSON.stringify({
    weak_points: [
      { description: "XSS vulnerability", severity: "high" },
      { description: "Missing header", severity: "low" },
    ],
  });
  const result = sarifFromPanicReport(report);
  assertEquals(result.includes("sarif-schema-2.1.0"), true);
  assertEquals(result.includes("panic-attack"), true);
  assertEquals(result.includes("XSS vulnerability"), true);
  assertEquals(result.includes('"level":"error"'), true);
  assertEquals(result.includes('"level":"note"'), true);
});

Deno.test("sarifFromPanicReport handles invalid JSON", () => {
  const result = sarifFromPanicReport("not json");
  assertEquals(result.includes("sarif-schema-2.1.0"), true);
  assertEquals(result.includes("results"), true);
});
