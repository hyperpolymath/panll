// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * TeamDashboardEngine Tests — default state, tab labels, online member counting,
 * recent activity slicing, and member filtering.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countOnline,
  recentActivity,
  filterMembers,
} from "../src/core/TeamDashboardEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.members.length, 0);
  assertEquals(defaultState.activity.length, 0);
  assertEquals(defaultState.filter, "");
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabTeam"), "Team");
  assertEquals(tabLabel("TabActivity"), "Activity");
  assertEquals(tabLabel("TabProgress"), "Progress");
  assertEquals(tabLabel("TabSchedule"), "Schedule");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- countOnline with empty array --

Deno.test("countOnline returns 0 for empty array", () => {
  assertEquals(countOnline([]), 0);
});

// -- recentActivity with empty array --

Deno.test("recentActivity returns empty for empty array", () => {
  assertEquals(recentActivity([], 5).length, 0);
});

// -- filterMembers with empty query --

Deno.test("filterMembers returns all when query is empty", () => {
  const members = [{ name: "Alice", role: "dev" }];
  assertEquals(filterMembers(members, "").length, 1);
});

// -- filterMembers with no matches --

Deno.test("filterMembers returns empty for no matches", () => {
  const members = [{ name: "Alice", role: "dev" }];
  assertEquals(filterMembers(members, "zzz").length, 0);
});
