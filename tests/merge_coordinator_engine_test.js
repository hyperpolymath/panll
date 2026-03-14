// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * MergeCoordinatorEngine Tests — default state, tab labels, conflict counting,
 * stale branch counting, and queue length.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countConflicts,
  countStale,
  queueLength,
} from "../src/core/MergeCoordinatorEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.branches.length, 0);
  assertEquals(defaultState.conflicts.length, 0);
  assertEquals(defaultState.mergeQueue.length, 0);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabBranches"), "Branches");
  assertEquals(tabLabel("TabConflicts"), "Conflicts");
  assertEquals(tabLabel("TabMergeQueue"), "Merge Queue");
  assertEquals(tabLabel("TabHistory"), "History");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- countConflicts with empty array --

Deno.test("countConflicts returns 0 for empty array", () => {
  assertEquals(countConflicts([]), 0);
});

// -- countStale with empty array --

Deno.test("countStale returns 0 for empty array", () => {
  assertEquals(countStale([]), 0);
});

// -- queueLength with empty array --

Deno.test("queueLength returns 0 for empty array", () => {
  assertEquals(queueLength([]), 0);
});
