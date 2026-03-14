// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * NeurosymBridgeEngine Tests — default state, tab labels, rule/node counting,
 * status labels, and simulation status formatting.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countRules,
  countRulesByStatus,
  countBehaviourNodes,
  countLeafNodes,
  ruleStatusLabel,
  nodeTypeLabel,
  simulationStatus,
} from "../src/core/NeurosymBridgeEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.guardRules.length, 0);
  assertEquals(defaultState.behaviourNodes.length, 0);
  assertEquals(defaultState.simulating, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Rules"), "Rules");
  assertEquals(tabLabel("BehaviourTree"), "Behaviour Tree");
  assertEquals(tabLabel("Simulation"), "Simulation");
  assertEquals(tabLabel("Analysis"), "Analysis");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- ruleStatusLabel --

Deno.test("ruleStatusLabel returns correct labels", () => {
  assertEquals(ruleStatusLabel("RuleVerified"), "Verified");
  assertEquals(ruleStatusLabel("RuleUnverified"), "Unverified");
  assertEquals(ruleStatusLabel("RuleViolated"), "Violated");
  assertEquals(ruleStatusLabel("RuleConflict"), "Conflict");
});

// -- nodeTypeLabel --

Deno.test("nodeTypeLabel returns correct labels", () => {
  assertEquals(nodeTypeLabel("NodeSequence"), "Sequence");
  assertEquals(nodeTypeLabel("NodeSelector"), "Selector");
  assertEquals(nodeTypeLabel("NodeAction"), "Action");
  assertEquals(nodeTypeLabel("NodeCondition"), "Condition");
});

// -- countRules with default state --

Deno.test("countRules returns 0 for default state", () => {
  assertEquals(countRules(defaultState), 0);
});

// -- countBehaviourNodes with default state --

Deno.test("countBehaviourNodes returns 0 for default state", () => {
  assertEquals(countBehaviourNodes(defaultState), 0);
});

// -- simulationStatus with default state --

Deno.test("simulationStatus returns 'No simulation' for default state", () => {
  assertEquals(simulationStatus(defaultState), "No simulation");
});
