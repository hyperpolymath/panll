// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * GuardAiTunerEngine Tests — default state, tab labels, spawn rate averaging,
 * alert threshold averaging, patrol point counting, and pattern formatting.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  avgSpawnRate,
  avgAlertThreshold,
  countPatrolPoints,
  formatPatrolPattern,
} from "../src/core/GuardAiTunerEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.guards.length, 0);
  assertEquals(defaultState.routes.length, 0);
  assertEquals(defaultState.presets.length, 0);
  assertEquals(defaultState.editing, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Profiles"), "Profiles");
  assertEquals(tabLabel("PatrolEditor"), "Patrol Editor");
  assertEquals(tabLabel("Thresholds"), "Thresholds");
  assertEquals(tabLabel("Presets"), "Presets");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- avgSpawnRate with empty array --

Deno.test("avgSpawnRate returns 0 for empty array", () => {
  assertEquals(avgSpawnRate([]), 0.0);
});

// -- avgAlertThreshold with empty array --

Deno.test("avgAlertThreshold returns 0 for empty array", () => {
  assertEquals(avgAlertThreshold([]), 0.0);
});

// -- countPatrolPoints with empty array --

Deno.test("countPatrolPoints returns 0 for empty array", () => {
  assertEquals(countPatrolPoints([]), 0);
});

// -- formatPatrolPattern --

Deno.test("formatPatrolPattern returns correct labels", () => {
  assertEquals(formatPatrolPattern("loop"), "Loop");
  assertEquals(formatPatrolPattern("pingpong"), "Ping-Pong");
  assertEquals(formatPatrolPattern("random"), "Random");
  assertEquals(formatPatrolPattern("stationary"), "Stationary");
  assertEquals(formatPatrolPattern("custom"), "custom");
});
