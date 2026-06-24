// SPDX-License-Identifier: MPL-2.0

/**
 * AerieEngine Tests — category labels, latency quality/colour classification,
 * average latency computation, and default state validation.
 */

import { assertEquals } from "jsr:@std/assert";
import {
  categoryLabel,
  latencyQuality,
  latencyColor,
  avgLatency,
  defaultState,
} from "../src/core/AerieEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns Dashboard", () => {
  assertEquals(categoryLabel("AerieDashboard"), "Dashboard");
});

Deno.test("categoryLabel returns Speed Tests", () => {
  assertEquals(categoryLabel("AerieSpeedTests"), "Speed Tests");
});

Deno.test("categoryLabel returns BGP Analysis", () => {
  assertEquals(categoryLabel("AerieBgp"), "BGP Analysis");
});

Deno.test("categoryLabel returns Probes", () => {
  assertEquals(categoryLabel("AerieProbes"), "Probes");
});

// -- latencyQuality --

Deno.test("latencyQuality returns Excellent for < 20ms", () => {
  assertEquals(latencyQuality(5.0), "Excellent");
  assertEquals(latencyQuality(0.0), "Excellent");
  assertEquals(latencyQuality(19.9), "Excellent");
});

Deno.test("latencyQuality returns Good for 20-49ms", () => {
  assertEquals(latencyQuality(20.0), "Good");
  assertEquals(latencyQuality(35.0), "Good");
  assertEquals(latencyQuality(49.9), "Good");
});

Deno.test("latencyQuality returns Fair for 50-99ms", () => {
  assertEquals(latencyQuality(50.0), "Fair");
  assertEquals(latencyQuality(75.0), "Fair");
  assertEquals(latencyQuality(99.9), "Fair");
});

Deno.test("latencyQuality returns Poor for >= 100ms", () => {
  assertEquals(latencyQuality(100.0), "Poor");
  assertEquals(latencyQuality(500.0), "Poor");
  assertEquals(latencyQuality(10000.0), "Poor");
});

// -- latencyColor --

Deno.test("latencyColor returns green for < 20ms", () => {
  assertEquals(latencyColor(5.0), "text-green-400");
  assertEquals(latencyColor(19.9), "text-green-400");
});

Deno.test("latencyColor returns emerald for 20-49ms", () => {
  assertEquals(latencyColor(20.0), "text-emerald-400");
  assertEquals(latencyColor(49.9), "text-emerald-400");
});

Deno.test("latencyColor returns amber for 50-99ms", () => {
  assertEquals(latencyColor(50.0), "text-amber-400");
  assertEquals(latencyColor(99.9), "text-amber-400");
});

Deno.test("latencyColor returns red for >= 100ms", () => {
  assertEquals(latencyColor(100.0), "text-red-400");
  assertEquals(latencyColor(999.0), "text-red-400");
});

// -- avgLatency --

Deno.test("avgLatency returns 0 for empty array", () => {
  assertEquals(avgLatency([]), 0.0);
});

Deno.test("avgLatency computes average of single result", () => {
  const results = [{ rttMs: 42.0 }];
  assertEquals(avgLatency(results), 42.0);
});

Deno.test("avgLatency computes average of multiple results", () => {
  const results = [
    { rttMs: 10.0 },
    { rttMs: 20.0 },
    { rttMs: 30.0 },
  ];
  assertEquals(avgLatency(results), 20.0);
});

Deno.test("avgLatency handles varying latencies", () => {
  const results = [
    { rttMs: 5.0 },
    { rttMs: 15.0 },
  ];
  assertEquals(avgLatency(results), 10.0);
});

// -- defaultState --

Deno.test("defaultState loaded is false", () => {
  assertEquals(defaultState.loaded, false);
});

Deno.test("defaultState loading is false", () => {
  assertEquals(defaultState.loading, false);
});

Deno.test("defaultState error is undefined (None)", () => {
  assertEquals(defaultState.error, undefined);
});

Deno.test("defaultState probes is empty", () => {
  assertEquals(defaultState.probes.length, 0);
});

Deno.test("defaultState latencyResults is empty", () => {
  assertEquals(defaultState.latencyResults.length, 0);
});

Deno.test("defaultState speedTests is empty", () => {
  assertEquals(defaultState.speedTests.length, 0);
});

Deno.test("defaultState bgpRoutes is empty", () => {
  assertEquals(defaultState.bgpRoutes.length, 0);
});

Deno.test("defaultState activeCategory is AerieDashboard", () => {
  assertEquals(defaultState.activeCategory, "AerieDashboard");
});

Deno.test("defaultState bgpAnomalyCount is 0", () => {
  assertEquals(defaultState.bgpAnomalyCount, 0);
});
