// SPDX-License-Identifier: MPL-2.0

/**
 * AutomationRouterEngine Tests — category labels, trigger helpers, approval
 * mode mappings, rule filtering, success rate computation, formatting
 * utilities, priority labels, and default state validation.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  categoryLabel,
  triggerLabel,
  triggerKindLabel,
  triggerColour,
  approvalLabel,
  approvalColour,
  enabledCount,
  pendingCount,
  filterRules,
  successRate,
  formatRelativeTime,
  formatSuccessRate,
  priorityLabel,
  defaultState,
} from "../src/core/AutomationRouterEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct tab labels", () => {
  assertEquals(categoryLabel("RouterDashboard"), "Dashboard");
  assertEquals(categoryLabel("RouterRules"), "Rules");
  assertEquals(categoryLabel("RouterPending"), "Pending");
  assertEquals(categoryLabel("RouterHistory"), "History");
  assertEquals(categoryLabel("RouterSettings"), "Settings");
});

// -- triggerLabel --

Deno.test("triggerLabel formats FileChanged trigger", () => {
  assertEquals(triggerLabel({ TAG: "FileChanged", _0: "*.res" }), "File: *.res");
});

Deno.test("triggerLabel formats PanelMessage trigger", () => {
  assertEquals(triggerLabel({ TAG: "PanelMessage", _0: "PanelVab", _1: "assemble" }), "PanelVab.assemble");
});

Deno.test("triggerLabel formats Timer trigger", () => {
  assertEquals(triggerLabel({ TAG: "Timer", _0: 30 }), "Every 30s");
});

Deno.test("triggerLabel formats Manual trigger", () => {
  assertEquals(triggerLabel("Manual"), "Manual");
});

Deno.test("triggerLabel formats PanelStateChange trigger", () => {
  assertEquals(triggerLabel({ TAG: "PanelStateChange", _0: "PanelAi", _1: "status" }), "PanelAi.status changed");
});

// -- triggerKindLabel --

Deno.test("triggerKindLabel returns short kind labels", () => {
  assertEquals(triggerKindLabel({ TAG: "FileChanged", _0: "*.js" }), "File");
  assertEquals(triggerKindLabel({ TAG: "PanelMessage", _0: "P", _1: "m" }), "Message");
  assertEquals(triggerKindLabel({ TAG: "Timer", _0: 60 }), "Timer");
  assertEquals(triggerKindLabel("Manual"), "Manual");
  assertEquals(triggerKindLabel({ TAG: "PanelStateChange", _0: "P", _1: "f" }), "State");
});

// -- triggerColour --

Deno.test("triggerColour returns Tailwind classes for each trigger type", () => {
  assertEquals(triggerColour({ TAG: "FileChanged", _0: "" }), "text-cyan-400");
  assertEquals(triggerColour({ TAG: "PanelMessage", _0: "", _1: "" }), "text-purple-400");
  assertEquals(triggerColour({ TAG: "Timer", _0: 0 }), "text-amber-400");
  assertEquals(triggerColour("Manual"), "text-gray-400");
  assertEquals(triggerColour({ TAG: "PanelStateChange", _0: "", _1: "" }), "text-emerald-400");
});

// -- approvalLabel --

Deno.test("approvalLabel returns correct labels", () => {
  assertEquals(approvalLabel("AutoFire"), "Auto");
  assertEquals(approvalLabel("RequireApproval"), "Approval Required");
  assertEquals(approvalLabel("ApproveOnce"), "Approve Once");
  assertEquals(approvalLabel("DryRunFirst"), "Dry Run");
});

// -- approvalColour --

Deno.test("approvalColour returns Tailwind classes", () => {
  assertEquals(approvalColour("AutoFire"), "text-emerald-400");
  assertEquals(approvalColour("RequireApproval"), "text-amber-400");
  assertEquals(approvalColour("ApproveOnce"), "text-cyan-400");
  assertEquals(approvalColour("DryRunFirst"), "text-purple-400");
});

// -- enabledCount --

Deno.test("enabledCount counts only enabled rules", () => {
  const rules = [
    { enabled: true, name: "a", description: "" },
    { enabled: false, name: "b", description: "" },
    { enabled: true, name: "c", description: "" },
  ];
  assertEquals(enabledCount(rules), 2);
});

Deno.test("enabledCount returns 0 for empty array", () => {
  assertEquals(enabledCount([]), 0);
});

Deno.test("enabledCount returns 0 when all disabled", () => {
  const rules = [{ enabled: false, name: "a", description: "" }];
  assertEquals(enabledCount(rules), 0);
});

// -- pendingCount --

Deno.test("pendingCount returns array length", () => {
  assertEquals(pendingCount([{}, {}, {}]), 3);
  assertEquals(pendingCount([]), 0);
});

// -- filterRules --

Deno.test("filterRules returns all rules with empty text and showDisabled", () => {
  const rules = [
    { name: "Build", description: "Run build", enabled: true },
    { name: "Lint", description: "Run linter", enabled: false },
  ];
  assertEquals(filterRules(rules, "", true).length, 2);
});

Deno.test("filterRules filters by name text", () => {
  const rules = [
    { name: "Build ReScript", description: "", enabled: true },
    { name: "Run Tests", description: "", enabled: true },
  ];
  const result = filterRules(rules, "build", true);
  assertEquals(result.length, 1);
  assertEquals(result[0].name, "Build ReScript");
});

Deno.test("filterRules filters by description text", () => {
  const rules = [
    { name: "CI", description: "Continuous integration pipeline", enabled: true },
    { name: "Deploy", description: "Push to production", enabled: true },
  ];
  const result = filterRules(rules, "pipeline", true);
  assertEquals(result.length, 1);
  assertEquals(result[0].name, "CI");
});

Deno.test("filterRules is case-insensitive", () => {
  const rules = [{ name: "BUILD", description: "", enabled: true }];
  assertEquals(filterRules(rules, "build", true).length, 1);
});

Deno.test("filterRules hides disabled when showDisabled is false", () => {
  const rules = [
    { name: "A", description: "", enabled: true },
    { name: "B", description: "", enabled: false },
  ];
  assertEquals(filterRules(rules, "", false).length, 1);
  assertEquals(filterRules(rules, "", false)[0].name, "A");
});

Deno.test("filterRules combines text and enabled filters", () => {
  const rules = [
    { name: "Build", description: "", enabled: true },
    { name: "Build Legacy", description: "", enabled: false },
    { name: "Test", description: "", enabled: true },
  ];
  const result = filterRules(rules, "build", false);
  assertEquals(result.length, 1);
  assertEquals(result[0].name, "Build");
});

// -- successRate --

Deno.test("successRate returns 100.0 for empty log", () => {
  assertEquals(successRate([]), 100.0);
});

Deno.test("successRate computes correct percentage", () => {
  const log = [
    { success: true },
    { success: true },
    { success: false },
    { success: true },
  ];
  assertEquals(successRate(log), 75.0);
});

Deno.test("successRate returns 0 for all failures", () => {
  const log = [{ success: false }, { success: false }];
  assertEquals(successRate(log), 0.0);
});

Deno.test("successRate returns 100 for all successes", () => {
  const log = [{ success: true }, { success: true }];
  assertEquals(successRate(log), 100.0);
});

// -- formatSuccessRate --

Deno.test("formatSuccessRate formats as integer percentage", () => {
  assertEquals(formatSuccessRate(100.0), "100%");
  assertEquals(formatSuccessRate(75.0), "75%");
  assertEquals(formatSuccessRate(0.0), "0%");
});

Deno.test("formatSuccessRate truncates decimals", () => {
  assertEquals(formatSuccessRate(99.9), "99%");
  assertEquals(formatSuccessRate(33.3), "33%");
});

// -- formatRelativeTime --

Deno.test("formatRelativeTime returns 'just now' for recent timestamps", () => {
  const now = Date.now();
  assertEquals(formatRelativeTime(now), "just now");
  assertEquals(formatRelativeTime(now - 30000), "just now");
});

Deno.test("formatRelativeTime returns minutes for < 1 hour", () => {
  const fiveMinAgo = Date.now() - 5 * 60 * 1000;
  const result = formatRelativeTime(fiveMinAgo);
  assert(result.endsWith("m ago"), `Expected minutes format, got: ${result}`);
});

Deno.test("formatRelativeTime returns hours for < 1 day", () => {
  const twoHoursAgo = Date.now() - 2 * 60 * 60 * 1000;
  const result = formatRelativeTime(twoHoursAgo);
  assert(result.endsWith("h ago"), `Expected hours format, got: ${result}`);
});

Deno.test("formatRelativeTime returns days for >= 1 day", () => {
  const threeDaysAgo = Date.now() - 3 * 24 * 60 * 60 * 1000;
  const result = formatRelativeTime(threeDaysAgo);
  assert(result.endsWith("d ago"), `Expected days format, got: ${result}`);
});

// -- priorityLabel --

Deno.test("priorityLabel returns capitalised labels for known values", () => {
  assertEquals(priorityLabel("before"), "Before");
  assertEquals(priorityLabel("after"), "After");
  assertEquals(priorityLabel("parallel"), "Parallel");
});

Deno.test("priorityLabel returns input unchanged for unknown values", () => {
  assertEquals(priorityLabel("custom"), "custom");
  assertEquals(priorityLabel(""), "");
});

// -- defaultState --

Deno.test("defaultState has RouterDashboard activeCategory", () => {
  assertEquals(defaultState.activeCategory, "RouterDashboard");
});

Deno.test("defaultState has empty rules", () => {
  assertEquals(defaultState.rules.length, 0);
});

Deno.test("defaultState has empty pendingActions", () => {
  assertEquals(defaultState.pendingActions.length, 0);
});

Deno.test("defaultState has empty executionLog", () => {
  assertEquals(defaultState.executionLog.length, 0);
});

Deno.test("defaultState globalEnabled is true", () => {
  assertEquals(defaultState.globalEnabled, true);
});

Deno.test("defaultState filterText is empty", () => {
  assertEquals(defaultState.filterText, "");
});

Deno.test("defaultState showDisabled is true", () => {
  assertEquals(defaultState.showDisabled, true);
});

Deno.test("defaultState editingRuleId is undefined (None)", () => {
  assertEquals(defaultState.editingRuleId, undefined);
});

Deno.test("defaultState configSource is local", () => {
  assertEquals(defaultState.configSource, "local");
});

Deno.test("defaultState loading is false", () => {
  assertEquals(defaultState.loading, false);
});

Deno.test("defaultState error is undefined (None)", () => {
  assertEquals(defaultState.error, undefined);
});
