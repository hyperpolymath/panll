// SPDX-License-Identifier: MPL-2.0

/**
 * Panel Bus Event Propagation Tests — aspect-oriented verification of
 * cross-panel event routing, subscriber management, and event lifecycle.
 *
 * Tests the pub/sub topology:
 *   - Subscriber registration and deactivation
 *   - Event wrapping with metadata envelopes
 *   - Topic-based routing and filtering
 *   - Event batching for bulk dispatch
 *   - Recent event ring buffer behaviour
 *   - Default subscriber topology (38 subscribers)
 *   - Cross-panel event delivery paths
 */

import { assertEquals, assert, assertNotEquals } from "jsr:@std/assert";

const PanelBus = await import("../src/core/PanelBus.res.js");

// ─── Subscriber Registration ────────────────────────────────────────────

Deno.test("PanelBus — subscribe adds a new subscriber to registry", () => {
  const reg = PanelBus.emptyRegistry;
  const newReg = PanelBus.subscribe(reg, "test-panel", ["TopicScan", "TopicHealth"]);

  const subscriber = newReg.subscribers.find(s => s.cladeId === "test-panel");
  assert(subscriber !== undefined, "Subscriber should be added");
  assertEquals(subscriber.active, true);
  assert(subscriber.topics.includes("TopicScan"));
  assert(subscriber.topics.includes("TopicHealth"));
});

Deno.test("PanelBus — unsubscribe deactivates a subscriber", () => {
  let reg = PanelBus.emptyRegistry;
  reg = PanelBus.subscribe(reg, "test-panel", ["TopicScan"]);
  reg = PanelBus.unsubscribe(reg, "test-panel");

  const subscriber = reg.subscribers.find(s => s.cladeId === "test-panel");
  assert(subscriber !== undefined, "Subscriber entry should still exist");
  assertEquals(subscriber.active, false);
});

Deno.test("PanelBus — subscribersForTopic returns only active subscribers on that topic", () => {
  let reg = PanelBus.emptyRegistry;
  reg = PanelBus.subscribe(reg, "panel-a", ["TopicScan"]);
  reg = PanelBus.subscribe(reg, "panel-b", ["TopicHealth"]);
  reg = PanelBus.subscribe(reg, "panel-c", ["TopicScan", "TopicHealth"]);

  const scanSubs = PanelBus.subscribersForTopic(reg, "TopicScan");
  const scanIds = scanSubs.map(s => s.cladeId);
  assert(scanIds.includes("panel-a"), "panel-a subscribes to Scan");
  assert(!scanIds.includes("panel-b"), "panel-b does not subscribe to Scan");
  assert(scanIds.includes("panel-c"), "panel-c subscribes to Scan");
});

Deno.test("PanelBus — subscribersForTopic excludes deactivated subscribers", () => {
  let reg = PanelBus.emptyRegistry;
  reg = PanelBus.subscribe(reg, "active-panel", ["TopicScan"]);
  reg = PanelBus.subscribe(reg, "inactive-panel", ["TopicScan"]);
  reg = PanelBus.unsubscribe(reg, "inactive-panel");

  const subs = PanelBus.subscribersForTopic(reg, "TopicScan");
  const ids = subs.map(s => s.cladeId);
  assert(ids.includes("active-panel"), "active subscriber found");
  assert(!ids.includes("inactive-panel"), "inactive subscriber excluded");
});

// ─── Event Wrapping ─────────────────────────────────────────────────────

Deno.test("PanelBus — wrapEvent produces envelope with metadata", () => {
  const reg = PanelBus.defaultRegistry;
  const evt = { TAG: "HypatiaFindingsRouted", _0: { findings: [] } };
  const [envelope, _newReg] = PanelBus.wrapEvent(reg, "hypatia", evt, 1711500000000);

  assert(typeof envelope.eventId === "number", "Envelope has numeric eventId");
  assertEquals(envelope.sourceCladeId, "hypatia");
  assertEquals(envelope.timestampMs, 1711500000000);
});

Deno.test("PanelBus — wrapEvent increments nextEventId", () => {
  const reg = PanelBus.defaultRegistry;
  const evt = { TAG: "HypatiaFindingsRouted", _0: {} };
  const [_env1, reg2] = PanelBus.wrapEvent(reg, "hypatia", evt, Date.now());
  const [_env2, reg3] = PanelBus.wrapEvent(reg2, "fleet", evt, Date.now());

  assert(reg3.nextEventId > reg2.nextEventId, "Event ID should increment");
});

Deno.test("PanelBus — wrapEvent adds to recentEvents", () => {
  const reg = PanelBus.emptyRegistry;
  const evt = { TAG: "RepoHealthChanged", _0: "test", _1: 0.9 };
  const [_env, newReg] = PanelBus.wrapEvent(reg, "fleet", evt, Date.now());

  assertEquals(newReg.recentEvents.length, 1);
});

// ─── Topic Routing ──────────────────────────────────────────────────────

Deno.test("PanelBus — eventTopic correctly classifies all topic types", () => {
  const topicAssertions = [
    [{ TAG: "HypatiaFindingsRouted", _0: {} }, "TopicScan"],
    [{ TAG: "RepoHealthChanged", _0: "r", _1: 0.8 }, "TopicHealth"],
    [{ TAG: "RsrComplianceChanged", _0: "c", _1: true }, "TopicGovernance"],
    [{ TAG: "DatabaseConnectionChanged", _0: true }, "TopicDatabase"],
    [{ TAG: "TestSuiteCompleted", _0: {} }, "TopicTesting"],
  ];

  for (const [evt, expectedTopic] of topicAssertions) {
    const topic = PanelBus.eventTopic(evt);
    assertEquals(topic, expectedTopic, `Event ${evt.TAG} should route to ${expectedTopic}`);
  }
});

Deno.test("PanelBus — subscribersForEvent routes through eventTopic", () => {
  const reg = PanelBus.defaultRegistry;
  const evt = { TAG: "HypatiaFindingsRouted", _0: {} };
  const subs = PanelBus.subscribersForEvent(reg, evt);

  // At least one default subscriber should listen to Scan events
  assert(subs.length > 0, "Default registry should have Scan subscribers");
});

// ─── Default Topology ───────────────────────────────────────────────────

Deno.test("PanelBus — defaultSubscribers has 38 subscribers", () => {
  assertEquals(PanelBus.defaultSubscribers.length, 38);
});

Deno.test("PanelBus — defaultRegistry has 38 pre-registered subscribers", () => {
  assertEquals(PanelBus.defaultRegistry.subscribers.length, 38);
});

Deno.test("PanelBus — all default subscribers are active", () => {
  for (const sub of PanelBus.defaultSubscribers) {
    assertEquals(sub.active, true, `Subscriber ${sub.cladeId} should be active`);
  }
});

Deno.test("PanelBus — all default subscribers have at least one topic", () => {
  for (const sub of PanelBus.defaultSubscribers) {
    assert(sub.topics.length > 0, `Subscriber ${sub.cladeId} should subscribe to at least one topic`);
  }
});

Deno.test("PanelBus — defaultSubscribers have unique cladeIds", () => {
  const ids = PanelBus.defaultSubscribers.map(s => s.cladeId);
  const unique = new Set(ids);
  assertEquals(unique.size, ids.length, `Duplicate subscriber clade ids detected`);
});

// ─── Recent Event Query ─────────────────────────────────────────────────

Deno.test("PanelBus — recentByTopic filters by event topic", () => {
  let reg = PanelBus.emptyRegistry;
  const scanEvt = { TAG: "HypatiaFindingsRouted", _0: {} };
  const healthEvt = { TAG: "RepoHealthChanged", _0: "r", _1: 0.8 };
  const now = Date.now();

  const [_e1, reg2] = PanelBus.wrapEvent(reg, "hypatia", scanEvt, now);
  const [_e2, reg3] = PanelBus.wrapEvent(reg2, "fleet", healthEvt, now + 1);
  const [_e3, reg4] = PanelBus.wrapEvent(reg3, "hypatia", scanEvt, now + 2);

  const scanRecent = PanelBus.recentByTopic(reg4, "TopicScan");
  const healthRecent = PanelBus.recentByTopic(reg4, "TopicHealth");

  assertEquals(scanRecent.length, 2, "Should have 2 scan events");
  assertEquals(healthRecent.length, 1, "Should have 1 health event");
});

Deno.test("PanelBus — recentFromClade filters by source clade", () => {
  let reg = PanelBus.emptyRegistry;
  const evt = { TAG: "HypatiaFindingsRouted", _0: {} };
  const now = Date.now();

  const [_e1, reg2] = PanelBus.wrapEvent(reg, "hypatia", evt, now);
  const [_e2, reg3] = PanelBus.wrapEvent(reg2, "fleet", evt, now + 1);
  const [_e3, reg4] = PanelBus.wrapEvent(reg3, "hypatia", evt, now + 2);

  const hypatiaRecent = PanelBus.recentFromClade(reg4, "hypatia");
  const fleetRecent = PanelBus.recentFromClade(reg4, "fleet");

  assertEquals(hypatiaRecent.length, 2);
  assertEquals(fleetRecent.length, 1);
});

// ─── Active Subscriber Count ────────────────────────────────────────────

Deno.test("PanelBus — activeSubscriberCount on empty registry is 0", () => {
  assertEquals(PanelBus.activeSubscriberCount(PanelBus.emptyRegistry), 0);
});

Deno.test("PanelBus — activeSubscriberCount reflects subscribe/unsubscribe", () => {
  let reg = PanelBus.emptyRegistry;
  reg = PanelBus.subscribe(reg, "a", ["TopicScan"]);
  assertEquals(PanelBus.activeSubscriberCount(reg), 1);

  reg = PanelBus.subscribe(reg, "b", ["TopicHealth"]);
  assertEquals(PanelBus.activeSubscriberCount(reg), 2);

  reg = PanelBus.unsubscribe(reg, "a");
  assertEquals(PanelBus.activeSubscriberCount(reg), 1);
});

// ─── Event Batching ─────────────────────────────────────────────────────

Deno.test("PanelBus — batchEvents groups envelopes by topic", () => {
  let reg = PanelBus.emptyRegistry;
  const now = Date.now();

  const [e1, reg2] = PanelBus.wrapEvent(reg, "hypatia", { TAG: "HypatiaFindingsRouted", _0: {} }, now);
  const [e2, reg3] = PanelBus.wrapEvent(reg2, "fleet", { TAG: "RepoHealthChanged", _0: "r", _1: 0.8 }, now + 1);
  const [e3, _reg4] = PanelBus.wrapEvent(reg3, "hypatia", { TAG: "HypatiaFindingsRouted", _0: {} }, now + 2);

  const batches = PanelBus.batchEvents([e1, e2, e3]);
  assert(Array.isArray(batches), "batchEvents returns array");
  // Should have at least 2 batches (Scan and Health topics)
  assert(batches.length >= 2, `Expected at least 2 topic batches, got ${batches.length}`);
});

// ─── Bus Configuration ──────────────────────────────────────────────────

Deno.test("PanelBus — defaultBusConfig has 500-event ring buffer", () => {
  assertEquals(PanelBus.defaultBusConfig.maxEvents, 500);
});

Deno.test("PanelBus — allTopics contains 12 topics", () => {
  assertEquals(PanelBus.allTopics.length, 12);
});

Deno.test("PanelBus — every topic has a non-empty label", () => {
  for (const topic of PanelBus.allTopics) {
    const label = PanelBus.topicLabel(topic);
    assert(typeof label === "string" && label.length > 0, `Topic ${topic} should have a label`);
  }
});

// ─── Governance-to-Panel Event Conversion ───────────────────────────────

Deno.test("PanelBus — governanceToPanel converts governance events", () => {
  const evt = { TAG: "ComplianceChanged", _0: true };
  const panelEvt = PanelBus.governanceToPanel(evt);
  assert(panelEvt !== undefined, "Should produce a panel event");
  assertEquals(panelEvt.TAG, "RsrComplianceChanged");
});
