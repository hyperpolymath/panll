// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * AgenticBridgeEngine Tests — default state, tab labels, agent status counting,
 * finding aggregation, and OODA phase formatting.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  agentStatusLabel,
  findingSeverityLabel,
  formatOodaPhase,
  oodaPhaseLabel,
  countAgentsByStatus,
  countFindings,
  countFindingsBySeverity,
  countTotalActions,
} from "../src/core/AgenticBridgeEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.running, false);
  assertEquals(defaultState.agents.length, 0);
  assertEquals(defaultState.agentConfigs.length, 0);
  assertEquals(defaultState.selectedAgent, undefined);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Agents"), "Agents");
  assertEquals(tabLabel("Config"), "Config");
  assertEquals(tabLabel("Execution"), "Execution");
  assertEquals(tabLabel("Results"), "Results");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- agentStatusLabel --

Deno.test("agentStatusLabel returns correct labels", () => {
  assertEquals(agentStatusLabel("AgentIdle"), "Idle");
  assertEquals(agentStatusLabel("AgentRunning"), "Running");
  assertEquals(agentStatusLabel("AgentPaused"), "Paused");
  assertEquals(agentStatusLabel("AgentCompleted"), "Completed");
  assertEquals(agentStatusLabel("AgentFailed"), "Failed");
});

// -- findingSeverityLabel --

Deno.test("findingSeverityLabel returns correct labels", () => {
  assertEquals(findingSeverityLabel("FindingCritical"), "Critical");
  assertEquals(findingSeverityLabel("FindingMajor"), "Major");
  assertEquals(findingSeverityLabel("FindingMinor"), "Minor");
  assertEquals(findingSeverityLabel("FindingObservation"), "Observation");
});

// -- oodaPhaseLabel --

Deno.test("oodaPhaseLabel returns short labels", () => {
  assertEquals(oodaPhaseLabel("Observe"), "Observe");
  assertEquals(oodaPhaseLabel("Orient"), "Orient");
  assertEquals(oodaPhaseLabel("Decide"), "Decide");
  assertEquals(oodaPhaseLabel("Act"), "Act");
});

// -- countAgentsByStatus with empty array --

Deno.test("countAgentsByStatus returns 0 for empty array", () => {
  assertEquals(countAgentsByStatus([], "AgentIdle"), 0);
});

// -- countFindings with empty array --

Deno.test("countFindings returns 0 for empty array", () => {
  assertEquals(countFindings([]), 0);
});

// -- countTotalActions with empty array --

Deno.test("countTotalActions returns 0 for empty array", () => {
  assertEquals(countTotalActions([]), 0);
});
