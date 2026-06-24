// SPDX-License-Identifier: MPL-2.0

/**
 * RegressionGuardEngine Tests — default state, tab labels, mismatch counting,
 * review counting, kind labels, and snapshot filtering.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  mismatchCount,
  needsReview,
  kindLabel,
  filterSnapshots,
} from "../src/core/RegressionGuardEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.snapshots.length, 0);
  assertEquals(defaultState.results.length, 0);
  assertEquals(defaultState.running, false);
  assertEquals(defaultState.autoUpdate, false);
  assertEquals(defaultState.filter, "");
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabSnapshots"), "Snapshots");
  assertEquals(tabLabel("TabDiffs"), "Diffs");
  assertEquals(tabLabel("TabHistory"), "History");
  assertEquals(tabLabel("TabSettings"), "Settings");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- kindLabel --

Deno.test("kindLabel returns correct labels", () => {
  assertEquals(kindLabel("SnapshotGameState"), "Game State");
  assertEquals(kindLabel("SnapshotRenderOutput"), "Render");
  assertEquals(kindLabel("SnapshotApiResponse"), "API Response");
  assertEquals(kindLabel("SnapshotTestOutput"), "Test Output");
});

// -- mismatchCount with empty array --

Deno.test("mismatchCount returns 0 for empty array", () => {
  assertEquals(mismatchCount([]), 0);
});

// -- needsReview with empty array --

Deno.test("needsReview returns 0 for empty array", () => {
  assertEquals(needsReview([]), 0);
});

// -- filterSnapshots with empty array --

Deno.test("filterSnapshots returns empty for empty array", () => {
  assertEquals(filterSnapshots([], "test").length, 0);
});

// -- filterSnapshots with empty filter --

Deno.test("filterSnapshots returns all when filter is empty", () => {
  const snapshots = [{ name: "test" }];
  assertEquals(filterSnapshots(snapshots, "").length, 1);
});
