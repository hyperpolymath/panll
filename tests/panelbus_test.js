// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// PanelBus tests — topic routing, labels, registry, subscribers

import { assertEquals, assert, assertNotEquals } from "jsr:@std/assert";

const PanelBus = await import("../src/core/PanelBus.res.js");

// ─── Topic Label Tests ───────────────────────────────────────────────────

Deno.test("PanelBus - topicLabel returns human-readable names", () => {
  assertEquals(PanelBus.topicLabel("TopicScan"), "Scan");
  assertEquals(PanelBus.topicLabel("TopicHealth"), "Health");
  assertEquals(PanelBus.topicLabel("TopicBuild"), "Build");
  assertEquals(PanelBus.topicLabel("TopicGovernance"), "Governance");
  assertEquals(PanelBus.topicLabel("TopicDatabase"), "Database");
  assertEquals(PanelBus.topicLabel("TopicSecurity"), "Security");
  assertEquals(PanelBus.topicLabel("TopicWorkflow"), "Workflow");
  assertEquals(PanelBus.topicLabel("TopicUI"), "UI");
  assertEquals(PanelBus.topicLabel("TopicTesting"), "Testing");
  assertEquals(PanelBus.topicLabel("TopicSimulation"), "Simulation");
});

// ─── All Topics ──────────────────────────────────────────────────────────

Deno.test("PanelBus - allTopics contains 12 topics", () => {
  assertEquals(PanelBus.allTopics.length, 12);
});

Deno.test("PanelBus - allTopics has no duplicates", () => {
  const unique = new Set(PanelBus.allTopics);
  assertEquals(unique.size, PanelBus.allTopics.length);
});

Deno.test("PanelBus - every topic has a label", () => {
  for (const topic of PanelBus.allTopics) {
    const label = PanelBus.topicLabel(topic);
    assert(typeof label === "string" && label.length > 0,
      `Topic ${topic} should have a non-empty label`);
  }
});

// ─── Event Topic Routing ─────────────────────────────────────────────────

Deno.test("PanelBus - eventTopic routes scan events", () => {
  const evt = { TAG: "HypatiaFindingsRouted", _0: {} };
  assertEquals(PanelBus.eventTopic(evt), "TopicScan");
});

Deno.test("PanelBus - eventTopic routes health events", () => {
  const evt = { TAG: "RepoHealthChanged", _0: "test-repo", _1: 0.8 };
  assertEquals(PanelBus.eventTopic(evt), "TopicHealth");
});

Deno.test("PanelBus - eventTopic routes governance events", () => {
  const evt = { TAG: "RsrComplianceChanged", _0: "contractiles", _1: true };
  assertEquals(PanelBus.eventTopic(evt), "TopicGovernance");
});

Deno.test("PanelBus - eventTopic routes database events", () => {
  const evt = { TAG: "DatabaseConnectionChanged", _0: true };
  assertEquals(PanelBus.eventTopic(evt), "TopicDatabase");
});

Deno.test("PanelBus - eventTopic routes testing events", () => {
  const evt = { TAG: "TestSuiteCompleted", _0: {} };
  assertEquals(PanelBus.eventTopic(evt), "TopicTesting");
});

// ─── Registry ────────────────────────────────────────────────────────────

Deno.test("PanelBus - emptyRegistry starts with no subscribers", () => {
  assertEquals(PanelBus.emptyRegistry.subscribers.length, 0);
});

Deno.test("PanelBus - emptyRegistry starts with nextEventId 1", () => {
  assertEquals(PanelBus.emptyRegistry.nextEventId, 1);
});

Deno.test("PanelBus - emptyRegistry has empty recent events", () => {
  assertEquals(PanelBus.emptyRegistry.recentEvents.length, 0);
});

Deno.test("PanelBus - emptyRegistry has maxRecentEvents 500", () => {
  assertEquals(PanelBus.emptyRegistry.maxRecentEvents, 500);
});

// ─── Default Subscribers ─────────────────────────────────────────────────

Deno.test("PanelBus - defaultSubscribers has fleet subscriber", () => {
  const fleet = PanelBus.defaultSubscribers.find(s => s.cladeId === "fleet");
  assert(fleet !== undefined, "fleet subscriber should exist");
  assert(fleet.active, "fleet subscriber should be active");
  assert(fleet.topics.includes("TopicScan"), "fleet should subscribe to scans");
  assert(fleet.topics.includes("TopicHealth"), "fleet should subscribe to health");
});

// ─── No Events Constant ─────────────────────────────────────────────────

Deno.test("PanelBus - noEvents is empty array", () => {
  assertEquals(PanelBus.noEvents.length, 0);
  assert(Array.isArray(PanelBus.noEvents));
});
