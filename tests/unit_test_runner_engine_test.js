// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * UnitTestRunnerEngine Tests — default state, tab labels, test counting,
 * coverage calculation, result filtering, and sorting.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countPassed,
  countFailed,
  countSkipped,
  overallCoverage,
  filterResults,
  sortResults,
} from "../src/core/UnitTestRunnerEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.results.length, 0);
  assertEquals(defaultState.coverage.length, 0);
  assertEquals(defaultState.history.length, 0);
  assertEquals(defaultState.running, false);
  assertEquals(defaultState.filter, "");
  assertEquals(defaultState.diffAwareOnly, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabTestResults"), "Test Results");
  assertEquals(tabLabel("TabCoverage"), "Coverage");
  assertEquals(tabLabel("TabHistory"), "History");
  assertEquals(tabLabel("TabDiffAware"), "Diff-Aware");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- countPassed with empty array --

Deno.test("countPassed returns 0 for empty array", () => {
  assertEquals(countPassed([]), 0);
});

// -- countFailed with empty array --

Deno.test("countFailed returns 0 for empty array", () => {
  assertEquals(countFailed([]), 0);
});

// -- countSkipped with empty array --

Deno.test("countSkipped returns 0 for empty array", () => {
  assertEquals(countSkipped([]), 0);
});

// -- overallCoverage with empty array --

Deno.test("overallCoverage returns 0 for empty array", () => {
  assertEquals(overallCoverage([]), 0.0);
});

// -- filterResults with empty array --

Deno.test("filterResults returns empty for empty array", () => {
  assertEquals(filterResults([], "test").length, 0);
});

// -- sortResults with empty array --

Deno.test("sortResults returns empty for empty array", () => {
  assertEquals(sortResults([], "SortByName").length, 0);
});
