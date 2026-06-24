// SPDX-License-Identifier: MPL-2.0

/**
 * CodeReviewEngine Tests — default state, tab labels, PR status counting,
 * unresolved comment counting, and PR filtering.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countByStatus,
  countUnresolved,
  filterPrs,
} from "../src/core/CodeReviewEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.pullRequests.length, 0);
  assertEquals(defaultState.comments.length, 0);
  assertEquals(defaultState.filter, "");
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabPullRequests"), "Pull Requests");
  assertEquals(tabLabel("TabFileChanges"), "File Changes");
  assertEquals(tabLabel("TabComments"), "Comments");
  assertEquals(tabLabel("TabApprovalGate"), "Approval Gate");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- countByStatus with empty array --

Deno.test("countByStatus returns 0 for empty array", () => {
  assertEquals(countByStatus([], "Open"), 0);
});

// -- countUnresolved with empty array --

Deno.test("countUnresolved returns 0 for empty array", () => {
  assertEquals(countUnresolved([]), 0);
});

// -- filterPrs with empty query --

Deno.test("filterPrs returns all PRs when query is empty", () => {
  const prs = [{ title: "Fix bug", author: "alice" }];
  assertEquals(filterPrs(prs, "").length, 1);
});

Deno.test("filterPrs returns empty for no matches", () => {
  const prs = [{ title: "Fix bug", author: "alice" }];
  assertEquals(filterPrs(prs, "zzz").length, 0);
});
