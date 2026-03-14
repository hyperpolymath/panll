// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * FunctionalTesterEngine Tests — default state, tab labels, workflow step
 * counting, progress calculation, and current step extraction.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  completedSteps,
  workflowProgress,
  currentStep,
  countByStatus,
} from "../src/core/FunctionalTesterEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.workflows.length, 0);
  assertEquals(defaultState.editing, false);
  assertEquals(defaultState.running, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("TabWorkflows"), "Workflows");
  assertEquals(tabLabel("TabEditor"), "Editor");
  assertEquals(tabLabel("TabResults"), "Results");
  assertEquals(tabLabel("TabTemplates"), "Templates");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- completedSteps with empty workflow --

Deno.test("completedSteps returns 0 for workflow with no steps", () => {
  assertEquals(completedSteps({ steps: [] }), 0);
});

// -- workflowProgress with empty workflow --

Deno.test("workflowProgress returns 0 for workflow with no steps", () => {
  assertEquals(workflowProgress({ steps: [] }), 0.0);
});

// -- currentStep --

Deno.test("currentStep returns undefined for non-running status", () => {
  assertEquals(currentStep("WorkflowPending"), undefined);
});
