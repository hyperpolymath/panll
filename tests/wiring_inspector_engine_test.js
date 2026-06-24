// SPDX-License-Identifier: MPL-2.0

/**
 * WiringInspectorEngine Tests — default state, status/state labels and colours,
 * distribution computation, health score, bottleneck extraction, and panel
 * verification helpers.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  emptyDistribution,
  statusLabel,
  statusColor,
  failureClassLabel,
  repairabilityLabel,
  repairabilityColor,
  stateLabel,
  stateColor,
  stateBgColor,
  stateBorderColor,
  tabLabel,
  healthScore,
  healthScoreColor,
  healthScoreBgColor,
  computeDistribution,
  extractBottlenecks,
  topBottlenecks,
  totalPanels,
  completePanels,
  incompletePanels,
  isComplete,
  summaryLabel,
  parseState,
} from "../src/core/WiringInspectorEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.loading, false);
  assertEquals(defaultState.results.length, 0);
  assertEquals(defaultState.bottlenecks.length, 0);
  assertEquals(defaultState.sortBy, "blockedCount");
  assertEquals(defaultState.error, undefined);
});

// -- emptyDistribution --

Deno.test("emptyDistribution has all zero counts", () => {
  assertEquals(emptyDistribution.total, 0);
  assertEquals(emptyDistribution.releasable, 0);
  assertEquals(emptyDistribution.viable, 0);
  assertEquals(emptyDistribution.wired, 0);
  assertEquals(emptyDistribution.draft, 0);
  assertEquals(emptyDistribution.broken, 0);
});

// -- statusLabel --

Deno.test("statusLabel returns correct obligation status labels", () => {
  assertEquals(statusLabel("Satisfied"), "Satisfied");
  assertEquals(statusLabel("Unsatisfied"), "Unsatisfied");
  assertEquals(statusLabel("Blocked"), "Blocked");
});

// -- statusColor --

Deno.test("statusColor returns correct Tailwind classes", () => {
  assertEquals(statusColor("Satisfied"), "text-green-400");
  assertEquals(statusColor("Unsatisfied"), "text-red-400");
  assertEquals(statusColor("Blocked"), "text-yellow-400");
});

// -- stateLabel --

Deno.test("stateLabel returns correct uppercase labels", () => {
  assertEquals(stateLabel("Draft"), "DRAFT");
  assertEquals(stateLabel("Wired"), "WIRED");
  assertEquals(stateLabel("Viable"), "VIABLE");
  assertEquals(stateLabel("Releasable"), "RELEASABLE");
  assertEquals(stateLabel("Broken"), "BROKEN");
});

// -- parseState --

Deno.test("parseState parses known state strings", () => {
  assertEquals(parseState("draft"), "Draft");
  assertEquals(parseState("wired"), "Wired");
  assertEquals(parseState("viable"), "Viable");
  assertEquals(parseState("releasable"), "Releasable");
  assertEquals(parseState("broken"), "Broken");
});

Deno.test("parseState defaults to Draft for unknown strings", () => {
  assertEquals(parseState("unknown"), "Draft");
});

// -- tabLabel --

Deno.test("tabLabel returns correct audit tab labels", () => {
  assertEquals(tabLabel("Overview"), "Overview");
  assertEquals(tabLabel("ByState"), "By State");
  assertEquals(tabLabel("Bottlenecks"), "Bottlenecks");
  assertEquals(tabLabel("History"), "History");
});

// -- healthScore --

Deno.test("healthScore returns 0 for empty distribution", () => {
  assertEquals(healthScore(emptyDistribution), 0);
});

// -- healthScoreColor --

Deno.test("healthScoreColor returns correct colours", () => {
  assertEquals(healthScoreColor(90), "text-green-400");
  assertEquals(healthScoreColor(60), "text-yellow-400");
  assertEquals(healthScoreColor(30), "text-red-400");
});

// -- computeDistribution with empty results --

Deno.test("computeDistribution returns zeros for empty results", () => {
  const dist = computeDistribution([]);
  assertEquals(dist.total, 0);
  assertEquals(dist.releasable, 0);
});

// -- extractBottlenecks with empty results --

Deno.test("extractBottlenecks returns empty for empty results", () => {
  assertEquals(extractBottlenecks([]).length, 0);
});

// -- totalPanels with empty results --

Deno.test("totalPanels returns 0 for empty results", () => {
  assertEquals(totalPanels([]), 0);
});
