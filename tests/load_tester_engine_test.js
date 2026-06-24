// SPDX-License-Identifier: MPL-2.0

/**
 * LoadTesterEngine Tests — default state, tab labels, player counting,
 * average latency, and default scenario values.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  connectedCount,
  errorCount,
  avgLatency,
  defaultScenario,
} from "../src/core/LoadTesterEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.scenarios.length, 0);
  assertEquals(defaultState.players.length, 0);
  assertEquals(defaultState.results.length, 0);
  assertEquals(defaultState.running, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabScenarios"), "Scenarios");
  assertEquals(tabLabel("TabLiveTest"), "Live Test");
  assertEquals(tabLabel("TabResults"), "Results");
  assertEquals(tabLabel("TabSaturationCurve"), "Saturation Curve");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- connectedCount with empty array --

Deno.test("connectedCount returns 0 for empty array", () => {
  assertEquals(connectedCount([]), 0);
});

// -- errorCount with empty array --

Deno.test("errorCount returns 0 for empty array", () => {
  assertEquals(errorCount([]), 0);
});

// -- avgLatency with empty array --

Deno.test("avgLatency returns 0 for empty array", () => {
  assertEquals(avgLatency([]), 0.0);
});

// -- defaultScenario --

Deno.test("defaultScenario has expected values", () => {
  assertExists(defaultScenario);
  assertEquals(defaultScenario.name, "Standard Load Test");
  assertEquals(defaultScenario.concurrentPlayers, 10);
  assertEquals(defaultScenario.rampUpSeconds, 5);
  assertEquals(defaultScenario.durationSeconds, 60);
  assertEquals(defaultScenario.channelName, "game:lobby");
});
