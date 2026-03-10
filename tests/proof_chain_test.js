// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * ProofChain Tests — graph building, status helpers, node type icons,
 * count by status, and view/viewCompact exports.
 */

import { assertEquals, assert, assertExists } from "jsr:@std/assert";
import {
  buildGraph,
  statusClasses,
  statusIcon,
  statusLabel,
  nodeTypeIcon,
  countByStatus,
  view,
  viewCompact,
} from "../src/components/ProofChain.res.js";

// -- Helper: minimal proof session --

function makeSession(overrides) {
  return {
    goal: "Prove P -> Q",
    goals: [],
    proofScript: [],
    status: "Pending",
    complete: false,
    ...overrides,
  };
}

// -- buildGraph --

Deno.test("buildGraph creates root node for empty session", () => {
  const session = makeSession({});
  const graph = buildGraph(session);
  assertExists(graph.rootId);
  assertEquals(graph.rootId, "goal-root");
  assert(graph.nodes.length >= 1);
  const root = graph.nodes.find(n => n.id === "goal-root");
  assertExists(root);
  assertEquals(root.nodeType, "GoalNode");
});

Deno.test("buildGraph marks root as Discharged when complete", () => {
  const session = makeSession({ complete: true });
  const graph = buildGraph(session);
  const root = graph.nodes.find(n => n.id === "goal-root");
  assertEquals(root.status, "Discharged");
});

Deno.test("buildGraph adds tactic nodes from proofScript", () => {
  const session = makeSession({
    proofScript: ["intro h", "apply h"],
    status: "InProgress",
  });
  const graph = buildGraph(session);
  const tacticNodes = graph.nodes.filter(n => n.nodeType === "TacticNode");
  assert(tacticNodes.length >= 2);
  assertEquals(tacticNodes[0].label, "intro h");
  assertEquals(tacticNodes[1].label, "apply h");
});

Deno.test("buildGraph adds QED node when complete", () => {
  const session = makeSession({
    proofScript: ["intro h"],
    complete: true,
  });
  const graph = buildGraph(session);
  const qed = graph.nodes.find(n => n.id === "qed");
  assertExists(qed);
  assertEquals(qed.nodeType, "QedNode");
  assertEquals(qed.status, "Discharged");
});

Deno.test("buildGraph adds subgoal nodes from goals array", () => {
  const session = makeSession({
    goals: ["A : Type", "B : Type"],
    proofScript: ["intro"],
    status: "InProgress",
  });
  const graph = buildGraph(session);
  const subgoals = graph.nodes.filter(n => n.id.startsWith("subgoal-"));
  assertEquals(subgoals.length, 2);
  assertEquals(subgoals[0].status, "Active");
  assertEquals(subgoals[1].status, "Pending");
});

// -- statusClasses --

Deno.test("statusClasses returns 3-element array for each status", () => {
  const statuses = ["Discharged", "Active", "Pending", "Failed", "Gap"];
  for (const s of statuses) {
    const classes = statusClasses(s);
    assertEquals(classes.length, 3);
    assert(typeof classes[0] === "string");
    assert(typeof classes[1] === "string");
    assert(typeof classes[2] === "string");
  }
});

// -- statusIcon --

Deno.test("statusIcon returns distinct icons for each status", () => {
  const icons = new Set([
    statusIcon("Discharged"),
    statusIcon("Active"),
    statusIcon("Pending"),
    statusIcon("Failed"),
    statusIcon("Gap"),
  ]);
  assertEquals(icons.size, 5, "Each status should have a unique icon");
});

// -- statusLabel --

Deno.test("statusLabel returns human-readable labels", () => {
  assertEquals(statusLabel("Discharged"), "Discharged");
  assertEquals(statusLabel("Active"), "In progress");
  assertEquals(statusLabel("Pending"), "Pending");
  assertEquals(statusLabel("Failed"), "Failed");
  assertEquals(statusLabel("Gap"), "Gap detected");
});

// -- nodeTypeIcon --

Deno.test("nodeTypeIcon returns distinct icons for each node type", () => {
  const icons = new Set([
    nodeTypeIcon("GoalNode"),
    nodeTypeIcon("TacticNode"),
    nodeTypeIcon("QedNode"),
  ]);
  assertEquals(icons.size, 3);
});

// -- countByStatus --

Deno.test("countByStatus counts nodes correctly", () => {
  const session = makeSession({
    proofScript: ["intro", "apply"],
    goals: ["A"],
    status: "InProgress",
  });
  const graph = buildGraph(session);
  const activeCount = countByStatus(graph, "Active");
  assert(activeCount >= 1, "Should have at least one active node");
  const total = graph.nodes.length;
  assert(total > 0);
});

// -- view / viewCompact --

Deno.test("view produces vdom from session", () => {
  const session = makeSession({ proofScript: ["intro"], status: "InProgress" });
  const result = view(session);
  assertExists(result);
  assertEquals(typeof result, "object");
});

Deno.test("viewCompact produces vdom from session", () => {
  const session = makeSession({ complete: true, proofScript: ["intro", "exact"] });
  const result = viewCompact(session);
  assertExists(result);
  assertEquals(typeof result, "object");
});
