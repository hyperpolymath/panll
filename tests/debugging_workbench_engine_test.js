// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * DebuggingWorkbenchEngine Tests — default state, tab labels, snapshot counting,
 * and time-travel navigation availability.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  snapshotCount,
  canGoBack,
  canGoForward,
} from "../src/core/DebuggingWorkbenchEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.watches.length, 0);
  assertEquals(defaultState.consoleLog.length, 0);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabTimeTravel"), "Time Travel");
  assertEquals(tabLabel("TabStateInspector"), "State Inspector");
  assertEquals(tabLabel("TabWatchExpressions"), "Watch Expressions");
  assertEquals(tabLabel("TabConsole"), "Console");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- snapshotCount --

Deno.test("snapshotCount returns 0 for default time travel state", () => {
  assertEquals(snapshotCount(defaultState.timeTravel), 0);
});

// -- canGoBack --

Deno.test("canGoBack returns false for default time travel state", () => {
  assertEquals(canGoBack(defaultState.timeTravel), false);
});

// -- canGoForward --

Deno.test("canGoForward returns false for default time travel state", () => {
  assertEquals(canGoForward(defaultState.timeTravel), false);
});
