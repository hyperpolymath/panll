// SPDX-License-Identifier: MPL-2.0

/**
 * FleetEngine Tests — bot labels, status, tiers, categories, parsing, health
 */

import { assertEquals } from "jsr:@std/assert";
import {
  botLabel,
  botDescription,
  botIcon,
  statusLabel,
  statusColor,
  tierLabel,
  tierColor,
  categoryLabel,
  computeHealth,
  filterFindings,
  parseBots,
  parseFindings,
  defaultState,
} from "../src/core/FleetEngine.res.js";

// -- botLabel --

Deno.test("botLabel returns correct names", () => {
  assertEquals(botLabel("Rhodibot"), "Rhodibot");
  assertEquals(botLabel("Echidnabot"), "Echidnabot");
  assertEquals(botLabel("Finishbot"), "Finishbot");
});

// -- botDescription --

Deno.test("botDescription returns correct descriptions", () => {
  assertEquals(botDescription("Rhodibot"), "Code quality & style enforcement");
  assertEquals(botDescription("Echidnabot"), "Security vulnerability detection");
});

// -- botIcon --

Deno.test("botIcon returns correct icons", () => {
  assertEquals(botIcon("Rhodibot"), "shield-check");
  assertEquals(botIcon("Echidnabot"), "bug");
  assertEquals(botIcon("Glambot"), "sparkles");
});

// -- statusLabel / statusColor --

Deno.test("statusLabel returns correct strings", () => {
  assertEquals(statusLabel("BotActive"), "Active");
  assertEquals(statusLabel("BotIdle"), "Idle");
  assertEquals(statusLabel("BotOffline"), "Offline");
  assertEquals(statusLabel({ TAG: "BotError", _0: "timeout" }), "Error: timeout");
});

Deno.test("statusColor returns correct classes", () => {
  assertEquals(statusColor("BotActive"), "bg-green-400");
  assertEquals(statusColor("BotOffline"), "bg-gray-500");
  assertEquals(statusColor({ TAG: "BotError", _0: "x" }), "bg-red-400");
});

// -- tierLabel / tierColor --

Deno.test("tierLabel returns correct strings", () => {
  assertEquals(tierLabel("Eliminate"), "Eliminate");
  assertEquals(tierLabel("Substitute"), "Substitute");
  assertEquals(tierLabel("Control"), "Control");
});

Deno.test("tierColor returns correct classes", () => {
  assertEquals(tierColor("Eliminate"), "bg-red-600 text-red-100");
  assertEquals(tierColor("Control"), "bg-blue-600 text-blue-100");
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("FleetDashboard"), "Dashboard");
  assertEquals(categoryLabel("FleetFindings"), "Findings");
  assertEquals(categoryLabel("FleetDispatch"), "Dispatch");
});

// -- computeHealth --

Deno.test("computeHealth with empty inputs", () => {
  const h = computeHealth([], []);
  assertEquals(h.activeBots, 0);
  assertEquals(h.totalQueued, 0);
  assertEquals(h.totalProcessed, 0);
  assertEquals(h.avgConfidence, 0.0);
});

// -- filterFindings --

Deno.test("filterFindings returns all when query empty", () => {
  const findings = [{ repoName: "foo", summary: "bar", resolved: false }];
  assertEquals(filterFindings(findings, "").length, 1);
});

Deno.test("filterFindings filters by repo name", () => {
  const findings = [
    { repoName: "panll", summary: "test", resolved: false },
    { repoName: "other", summary: "test", resolved: false },
  ];
  assertEquals(filterFindings(findings, "panll").length, 1);
});

// -- parseBots --

Deno.test("parseBots parses valid JSON", () => {
  const json = JSON.stringify([{ id: "rhodibot", status: "active", queued: 5, processed: 10, confidence_threshold: 0.8, last_activity: "now" }]);
  const result = parseBots(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.length, 1);
  assertEquals(result._0[0].id, "Rhodibot");
  assertEquals(result._0[0].status, "BotActive");
});

Deno.test("parseBots returns error for invalid JSON", () => {
  const result = parseBots("not json");
  assertEquals(result.TAG, "Error");
});

Deno.test("parseBots returns error for non-array", () => {
  const result = parseBots('"hello"');
  assertEquals(result.TAG, "Error");
});

// -- parseFindings --

Deno.test("parseFindings parses valid JSON", () => {
  const json = JSON.stringify([{ id: "f1", repo_name: "panll", summary: "issue", tier: "eliminate", confidence: 0.9, assigned_bot: "rhodibot", resolved: false }]);
  const result = parseFindings(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0[0].tier, "Eliminate");
  assertEquals(result._0[0].assignedBot, "Rhodibot");
});

Deno.test("parseFindings returns error for invalid JSON", () => {
  assertEquals(parseFindings("{bad}").TAG, "Error");
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.loaded, false);
  assertEquals(defaultState.loading, false);
  assertEquals(defaultState.bots.length, 0);
  assertEquals(defaultState.findings.length, 0);
  assertEquals(defaultState.activeCategory, "FleetDashboard");
  assertEquals(defaultState.filterText, "");
});
