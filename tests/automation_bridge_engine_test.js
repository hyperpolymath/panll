// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * AutomationBridgeEngine Tests — default state, tab labels, pipeline status
 * counting, trigger aggregation, and build success rate.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countActivePipelines,
  countPipelinesByStatus,
  countPendingTriggers,
  countDisabledTriggers,
  pipelineStatusLabel,
  triggerEventLabel,
  buildSuccessRate,
} from "../src/core/AutomationBridgeEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.pipelines.length, 0);
  assertEquals(defaultState.triggers.length, 0);
  assertEquals(defaultState.buildHistory.length, 0);
  assertEquals(defaultState.running, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Pipelines"), "Pipelines");
  assertEquals(tabLabel("Triggers"), "Triggers");
  assertEquals(tabLabel("Status"), "Status");
  assertEquals(tabLabel("History"), "History");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- pipelineStatusLabel --

Deno.test("pipelineStatusLabel returns correct labels", () => {
  assertEquals(pipelineStatusLabel("PipelineIdle"), "Idle");
  assertEquals(pipelineStatusLabel("PipelineRunning"), "Running");
  assertEquals(pipelineStatusLabel("PipelineSucceeded"), "Succeeded");
  assertEquals(pipelineStatusLabel("PipelineFailed"), "Failed");
  assertEquals(pipelineStatusLabel("PipelineCancelled"), "Cancelled");
});

// -- triggerEventLabel --

Deno.test("triggerEventLabel returns correct labels", () => {
  assertEquals(triggerEventLabel("TriggerPush"), "Push");
  assertEquals(triggerEventLabel("TriggerPullRequest"), "Pull Request");
  assertEquals(triggerEventLabel("TriggerManual"), "Manual");
});

// -- countActivePipelines with empty array --

Deno.test("countActivePipelines returns 0 for empty array", () => {
  assertEquals(countActivePipelines([]), 0);
});

// -- buildSuccessRate with empty history --

Deno.test("buildSuccessRate returns 100 for empty history", () => {
  assertEquals(buildSuccessRate([]), 100.0);
});
