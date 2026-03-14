// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * CompatibilityMatrixEngine Tests — default state, tab labels, cell counting,
 * result labels, and resolution formatting.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countPassing,
  countFailing,
  countUntested,
  resultLabel,
  resolutionLabel,
} from "../src/core/CompatibilityMatrixEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.browsers.length, 3);
  assertEquals(defaultState.devices.length, 4);
  assertEquals(defaultState.cells.length, 0);
  assertEquals(defaultState.running, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabMatrix"), "Matrix");
  assertEquals(tabLabel("TabFailures"), "Failures");
  assertEquals(tabLabel("TabScreenshots"), "Screenshots");
  assertEquals(tabLabel("TabTargets"), "Targets");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- countPassing with empty array --

Deno.test("countPassing returns 0 for empty array", () => {
  assertEquals(countPassing([]), 0);
});

// -- countFailing with empty array --

Deno.test("countFailing returns 0 for empty array", () => {
  assertEquals(countFailing([]), 0);
});

// -- countUntested with empty array --

Deno.test("countUntested returns 0 for empty array", () => {
  assertEquals(countUntested([]), 0);
});

// -- resultLabel --

Deno.test("resultLabel returns correct labels", () => {
  assertEquals(resultLabel("CompatPassing"), "Pass");
  assertEquals(resultLabel("CompatUntested"), "Untested");
});
