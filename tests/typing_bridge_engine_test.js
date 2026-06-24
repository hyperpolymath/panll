// SPDX-License-Identifier: MPL-2.0

/**
 * TypingBridgeEngine Tests — default state, tab labels, constraint counting,
 * severity labels, inference formatting, and satisfaction percentage.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countConstraints,
  countViolated,
  countBySeverity,
  severityLabel,
  formatInferenceResult,
  countInferenceByStatus,
  countInvalidFields,
  satisfactionPercent,
} from "../src/core/TypingBridgeEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.constraints.length, 0);
  assertEquals(defaultState.inferenceResults.length, 0);
  assertEquals(defaultState.configFields.length, 0);
  assertEquals(defaultState.running, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Constraints"), "Constraints");
  assertEquals(tabLabel("Inference"), "Inference");
  assertEquals(tabLabel("Editor"), "Editor");
  assertEquals(tabLabel("Diagnostics"), "Diagnostics");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- severityLabel --

Deno.test("severityLabel returns correct labels", () => {
  assertEquals(severityLabel("ConstraintError"), "Error");
  assertEquals(severityLabel("ConstraintWarning"), "Warning");
  assertEquals(severityLabel("ConstraintInfo"), "Info");
});

// -- countConstraints with default state --

Deno.test("countConstraints returns 0 for default state", () => {
  assertEquals(countConstraints(defaultState), 0);
});

// -- countViolated with default state --

Deno.test("countViolated returns 0 for default state", () => {
  assertEquals(countViolated(defaultState), 0);
});

// -- satisfactionPercent with default state (no constraints) --

Deno.test("satisfactionPercent returns 100 when no constraints", () => {
  assertEquals(satisfactionPercent(defaultState), 100.0);
});

// -- countInvalidFields with empty array --

Deno.test("countInvalidFields returns 0 for empty array", () => {
  assertEquals(countInvalidFields([]), 0);
});

// -- countInferenceByStatus with empty array --

Deno.test("countInferenceByStatus returns 0 for empty array", () => {
  assertEquals(countInferenceByStatus([], "InferenceSuccess"), 0);
});
