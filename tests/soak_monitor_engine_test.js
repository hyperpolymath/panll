// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * SoakMonitorEngine Tests — default state, tab labels, memory growth rate,
 * session duration formatting, and session status labels.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  memoryGrowthRate,
  sessionDuration,
  sessionStatusLabel,
} from "../src/core/SoakMonitorEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.trendData.length, 0);
  assertEquals(defaultState.leakSuspects.length, 0);
  assertEquals(defaultState.sessions.length, 0);
  assertEquals(defaultState.monitoring, false);
  assertEquals(defaultState.sampleIntervalMs, 5000);
  assertEquals(defaultState.leakThresholdBytes, 1048576);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabLiveMonitor"), "Live Monitor");
  assertEquals(tabLabel("TabTrends"), "Trends");
  assertEquals(tabLabel("TabLeakDetection"), "Leak Detection");
  assertEquals(tabLabel("TabHistory"), "History");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- memoryGrowthRate with empty array --

Deno.test("memoryGrowthRate returns 0 for empty array", () => {
  assertEquals(memoryGrowthRate([]), 0.0);
});

// -- memoryGrowthRate with single point --

Deno.test("memoryGrowthRate returns 0 for single point", () => {
  assertEquals(memoryGrowthRate([{ timestamp: 1000, heapUsedBytes: 500 }]), 0.0);
});

// -- sessionStatusLabel --

Deno.test("sessionStatusLabel returns correct labels", () => {
  assertEquals(sessionStatusLabel("SoakRunning"), "Running");
  assertEquals(sessionStatusLabel("SoakCompleted"), "Completed");
});
