// SPDX-License-Identifier: MPL-2.0

/**
 * VmInspectorEngine Tests — category labels, tier labels, tier colours,
 * connection labels, stack formatting, and default state validation.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  categoryLabel,
  tierLabel,
  tierShortLabel,
  tierColour,
  connectionLabel,
  formatStack,
  defaultState,
} from "../src/core/VmInspectorEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings", () => {
  assertEquals(categoryLabel("InspectorDebugger"), "Debugger");
  assertEquals(categoryLabel("InspectorTimeline"), "Timeline");
  assertEquals(categoryLabel("InspectorCallGraph"), "Call Graph");
  assertEquals(categoryLabel("InspectorPortIO"), "Port I/O");
  assertEquals(categoryLabel("InspectorStatistics"), "Statistics");
});

// -- tierLabel --

Deno.test("tierLabel returns correct strings for all tiers", () => {
  assertEquals(tierLabel("TierArithmetic"), "Tier 0: Arithmetic");
  assertEquals(tierLabel("TierConditionals"), "Tier 1: Conditionals");
  assertEquals(tierLabel("TierStackMemory"), "Tier 2: Stack/Memory");
  assertEquals(tierLabel("TierSubroutines"), "Tier 3: Subroutines");
  assertEquals(tierLabel("TierIO"), "Tier 4: I/O");
});

// -- tierShortLabel --

Deno.test("tierShortLabel returns two-char codes", () => {
  assertEquals(tierShortLabel("TierArithmetic"), "T0");
  assertEquals(tierShortLabel("TierConditionals"), "T1");
  assertEquals(tierShortLabel("TierStackMemory"), "T2");
  assertEquals(tierShortLabel("TierSubroutines"), "T3");
  assertEquals(tierShortLabel("TierIO"), "T4");
});

// -- tierColour --

Deno.test("tierColour returns Tailwind text-colour classes", () => {
  assertEquals(tierColour("TierArithmetic"), "text-blue-400");
  assertEquals(tierColour("TierConditionals"), "text-amber-400");
  assertEquals(tierColour("TierStackMemory"), "text-emerald-400");
  assertEquals(tierColour("TierSubroutines"), "text-purple-400");
  assertEquals(tierColour("TierIO"), "text-red-400");
});

// -- connectionLabel --

Deno.test("connectionLabel returns label for VmLiveConnection", () => {
  assertEquals(connectionLabel("VmLiveConnection"), "Live (inter-webview)");
});

Deno.test("connectionLabel returns label for VmDisconnected", () => {
  assertEquals(connectionLabel("VmDisconnected"), "Disconnected");
});

Deno.test("connectionLabel returns label for VmFileConnection with path", () => {
  assertEquals(
    connectionLabel({ TAG: "VmFileConnection", _0: "/tmp/snapshot.bin" }),
    "File: /tmp/snapshot.bin",
  );
});

// -- formatStack --

Deno.test("formatStack returns (empty) for empty stack", () => {
  assertEquals(formatStack([]), "(empty)");
});

Deno.test("formatStack formats single-element stack", () => {
  assertEquals(formatStack([42]), "42");
});

Deno.test("formatStack formats multi-element stack", () => {
  assertEquals(formatStack([1, 2, 3]), "1, 2, 3");
});

Deno.test("formatStack handles negative values", () => {
  assertEquals(formatStack([-1, 0, 255]), "-1, 0, 255");
});

// -- defaultState --

Deno.test("defaultState connection is VmDisconnected", () => {
  assertEquals(defaultState.connection, "VmDisconnected");
});

Deno.test("defaultState activeCategory is InspectorDebugger", () => {
  assertEquals(defaultState.activeCategory, "InspectorDebugger");
});

Deno.test("defaultState pc is 0", () => {
  assertEquals(defaultState.pc, 0);
});

Deno.test("defaultState has empty stack", () => {
  assertEquals(defaultState.stack.length, 0);
});

Deno.test("defaultState has empty memory", () => {
  assertEquals(defaultState.memory.length, 0);
});

Deno.test("defaultState has empty instructions", () => {
  assertEquals(defaultState.instructions.length, 0);
});

Deno.test("defaultState has empty history", () => {
  assertEquals(defaultState.history.length, 0);
});

Deno.test("defaultState timelinePosition is 0", () => {
  assertEquals(defaultState.timelinePosition, 0);
});

Deno.test("defaultState has empty breakpoints", () => {
  assertEquals(defaultState.breakpoints.length, 0);
});

Deno.test("defaultState has empty portLog", () => {
  assertEquals(defaultState.portLog.length, 0);
});

Deno.test("defaultState running is false", () => {
  assertEquals(defaultState.running, false);
});

Deno.test("defaultState totalSteps is 0", () => {
  assertEquals(defaultState.totalSteps, 0);
});

Deno.test("defaultState has empty instructionCounts", () => {
  assertEquals(defaultState.instructionCounts.length, 0);
});

Deno.test("defaultState tierCounts has 5 zeroes", () => {
  assertEquals(defaultState.tierCounts, [0, 0, 0, 0, 0]);
});

Deno.test("defaultState error is undefined (None)", () => {
  assertEquals(defaultState.error, undefined);
});

Deno.test("defaultState loading is false", () => {
  assertEquals(defaultState.loading, false);
});

Deno.test("defaultState multiVmView is false", () => {
  assertEquals(defaultState.multiVmView, false);
});
