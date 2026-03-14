// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * BalanceAnalyserEngine Tests — default state, tab labels, difficulty
 * averaging, outlier detection, win rate, and recommendation counting.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  avgDifficulty,
  findOutliers,
  avgWinRate,
  highImpactCount,
  difficultyCurve,
} from "../src/core/BalanceAnalyserEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.levelStats.length, 0);
  assertEquals(defaultState.distributions.length, 0);
  assertEquals(defaultState.simulations.length, 0);
  assertEquals(defaultState.recommendations.length, 0);
  assertEquals(defaultState.simulationRuns, 1000);
  assertEquals(defaultState.running, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabOverview"), "Overview");
  assertEquals(tabLabel("TabDistributions"), "Distributions");
  assertEquals(tabLabel("TabSimulations"), "Simulations");
  assertEquals(tabLabel("TabRecommendations"), "Recommendations");
  assertEquals(tabLabel("TabDifficultyCurve"), "Difficulty Curve");
});

// -- allTabs --

Deno.test("allTabs contains all five tabs", () => {
  assertEquals(allTabs.length, 5);
});

// -- avgDifficulty --

Deno.test("avgDifficulty returns 0 for empty array", () => {
  assertEquals(avgDifficulty([]), 0.0);
});

// -- avgWinRate --

Deno.test("avgWinRate returns 0 for empty array", () => {
  assertEquals(avgWinRate([]), 0.0);
});

// -- findOutliers --

Deno.test("findOutliers returns empty for empty array", () => {
  assertEquals(findOutliers([], 1.0).length, 0);
});

// -- highImpactCount --

Deno.test("highImpactCount returns 0 for empty array", () => {
  assertEquals(highImpactCount([]), 0);
});

// -- difficultyCurve --

Deno.test("difficultyCurve returns empty for empty array", () => {
  assertEquals(difficultyCurve([]).length, 0);
});
