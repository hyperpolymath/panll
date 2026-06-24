// SPDX-License-Identifier: MPL-2.0

/**
 * PerformanceProfilerEngine Tests — default state, tab labels, frame time
 * averaging, FPS calculation, memory usage, and alert counting.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  avgFrameTime,
  currentFps,
  framesOverBudget,
  latestMemoryMb,
  severityLabel,
  alertCount,
} from "../src/core/PerformanceProfilerEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.frameSamples.length, 0);
  assertEquals(defaultState.memorySnapshots.length, 0);
  assertEquals(defaultState.gcEvents.length, 0);
  assertEquals(defaultState.alerts.length, 0);
  assertEquals(defaultState.profiling, false);
  assertEquals(defaultState.targetFps, 60.0);
  assertEquals(defaultState.frameBudgetMs, 16.67);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabFrameBudget"), "Frame Budget");
  assertEquals(tabLabel("TabMemory"), "Memory");
  assertEquals(tabLabel("TabGcPressure"), "GC Pressure");
  assertEquals(tabLabel("TabAlerts"), "Alerts");
  assertEquals(tabLabel("TabFlamegraph"), "Flamegraph");
});

// -- allTabs --

Deno.test("allTabs contains all five tabs", () => {
  assertEquals(allTabs.length, 5);
});

// -- avgFrameTime with empty array --

Deno.test("avgFrameTime returns 0 for empty array", () => {
  assertEquals(avgFrameTime([]), 0.0);
});

// -- currentFps with empty array --

Deno.test("currentFps returns 0 for empty array", () => {
  assertEquals(currentFps([]), 0.0);
});

// -- framesOverBudget with empty array --

Deno.test("framesOverBudget returns 0 for empty array", () => {
  assertEquals(framesOverBudget([], 16.67), 0);
});

// -- latestMemoryMb with empty array --

Deno.test("latestMemoryMb returns 0 for empty array", () => {
  assertEquals(latestMemoryMb([]), 0.0);
});

// -- severityLabel --

Deno.test("severityLabel returns correct labels", () => {
  assertEquals(severityLabel("PerfInfo"), "Info");
  assertEquals(severityLabel("PerfWarning"), "Warning");
  assertEquals(severityLabel("PerfCritical"), "Critical");
});
