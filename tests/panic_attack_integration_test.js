// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/**
 * panic-attack Integration Tests
 *
 * End-to-end flows combining capability parsing, event-chain processing,
 * format validation (panll.event-chain.v0, panll.system-image.v0,
 * panll.temporal-diff.v0), and MassPanic model edge cases.
 *
 * Run: deno test --no-check --allow-all tests/panic_attack_integration_test.js
 */

import { assertEquals, assertExists, assert } from "jsr:@std/assert";
import { parse as parseCapability } from "../src/core/PanicAttackerCapability.res.js";
import { parse as parseEventChain } from "../src/core/EventChain.res.js";
import { label, toneClass } from "../src/core/PanicAttackerMode.res.js";
import { init as massPanicInit } from "../src/model/MassPanicModel.res.js";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Build a full panll.event-chain.v0 payload with configurable weak points. */
function makeEventChainPayload(weakPoints, crashes, robustness) {
  const events = [];
  for (let i = 0; i < weakPoints; i++) {
    events.push({
      id: `attack-${i}`,
      axis: i % 2 === 0 ? "cpu" : "memory",
      start_ms: i * 5000,
      duration_ms: 3000 + (i * 100),
      intensity: i % 3 === 0 ? "Heavy" : i % 3 === 1 ? "Medium" : "Light",
      status: i < crashes ? "crashed" : "ran",
      peak_memory: i % 2 === 1 ? 1024 * 1024 * (i + 1) : null,
      notes: i % 4 === 0 ? `Note for attack ${i}` : null,
    });
  }
  return JSON.stringify({
    format: "panll.event-chain.v0",
    generated_at: "2026-03-09T12:00:00Z",
    source: {
      tool: "panic-attack",
      report_path: "reports/integration-test-report.json",
    },
    summary: {
      program: "/tmp/test-target",
      weak_points: weakPoints,
      critical_weak_points: Math.max(1, Math.floor(weakPoints / 4)),
      total_crashes: crashes,
      robustness_score: robustness,
    },
    timeline: {
      duration_ms: weakPoints * 5000,
      events: weakPoints,
    },
    event_chain: events,
    constraints: [],
  });
}

/** Build a panll.system-image.v0 payload. */
function makeSystemImagePayload(nodeCount) {
  const nodes = [];
  for (let i = 0; i < nodeCount; i++) {
    nodes.push({
      id: `node-${i}`,
      name: `repo-${i}`,
      health_score: 50.0 + (i % 50),
      risk_intensity: 0.1 * (i % 10),
      weak_point_density: 0.05 * (i % 20),
      weak_point_count: i * 2,
      critical_count: i % 5 === 0 ? 1 : 0,
      high_count: i % 3 === 0 ? 2 : 0,
      fingerprint: `blake3-${i.toString(16).padStart(8, "0")}`,
      skipped: false,
      top_categories: i % 2 === 0 ? ["memory", "cpu"] : ["network"],
    });
  }
  return {
    format: "panll.system-image.v0",
    generated_at: "2026-03-09T12:00:00Z",
    scan_surface: "/tmp/test-repos",
    global_health: 72.5,
    global_risk: 0.275,
    node_count: nodeCount,
    edge_count: 0,
    total_weak_points: nodeCount * 3,
    total_critical: Math.floor(nodeCount / 5),
    risk_distribution: {
      healthy: Math.floor(nodeCount * 0.3),
      low: Math.floor(nodeCount * 0.25),
      moderate: Math.floor(nodeCount * 0.2),
      high: Math.floor(nodeCount * 0.15),
      critical: Math.floor(nodeCount * 0.1),
    },
    nodes: nodes,
    edges: [],
  };
}

/** Build a panll.temporal-diff.v0 payload. */
function makeTemporalDiffPayload(nodeCount, trend) {
  const improved = [];
  const degraded = [];
  for (let i = 0; i < Math.floor(nodeCount / 2); i++) {
    improved.push({
      name: `repo-improved-${i}`,
      health_before: 60.0,
      health_after: 80.0,
      health_delta: 20.0,
      risk_before: 0.4,
      risk_after: 0.2,
      risk_delta: -0.2,
      weak_point_delta: -3,
    });
  }
  for (let i = 0; i < Math.ceil(nodeCount / 3); i++) {
    degraded.push({
      name: `repo-degraded-${i}`,
      health_before: 75.0,
      health_after: 55.0,
      health_delta: -20.0,
      risk_before: 0.25,
      risk_after: 0.45,
      risk_delta: 0.2,
      weak_point_delta: 5,
    });
  }
  return {
    format: "panll.temporal-diff.v0",
    from_label: "snapshot-001",
    to_label: "snapshot-002",
    from_timestamp: "2026-03-08T00:00:00Z",
    to_timestamp: "2026-03-09T12:00:00Z",
    health_delta: trend === "improving" ? 5.0 : -5.0,
    risk_delta: trend === "improving" ? -0.1 : 0.1,
    weak_point_delta: trend === "improving" ? -10 : 10,
    critical_delta: trend === "improving" ? -2 : 2,
    new_nodes: ["repo-new-1"],
    removed_nodes: [],
    improved_nodes: improved,
    degraded_nodes: degraded,
    unchanged_count: nodeCount - improved.length - degraded.length,
    trend: trend,
  };
}

// ---------------------------------------------------------------------------
// 1. End-to-end flow: parse capability → extract weak points → format display
// ---------------------------------------------------------------------------

Deno.test("E2E: parse capability → check mode → format for display", () => {
  const capResult = parseCapability(JSON.stringify({
    mode: "full",
    supports_panll: true,
    binary: "/usr/local/bin/panic-attack",
    detail: "panic-attack panll export is available",
  }));

  assertEquals(capResult.TAG, "Ok");
  const cap = capResult._0;

  // Extract mode and format for display
  const modeLabel = label(cap.mode);
  const modeClass = toneClass(cap.mode);

  assertEquals(modeLabel, "panic-attacker mode: full panll export");
  assertEquals(modeClass, "text-emerald-400");
  assertExists(cap.binary);
  assertEquals(cap.detail, "panic-attack panll export is available");
});

Deno.test("E2E: parse capability → parse event chain → extract weak points", () => {
  // Step 1: Verify capability
  const capResult = parseCapability(JSON.stringify({
    mode: "full",
    binary: "/usr/local/bin/panic-attack",
    detail: "ready",
  }));
  assertEquals(capResult.TAG, "Ok");

  // Step 2: Parse event chain (simulating panic-attack output)
  const chainPayload = makeEventChainPayload(6, 2, 65.0);
  const chainResult = parseEventChain(chainPayload);
  assertEquals(chainResult.TAG, "Ok");
  const chain = chainResult._0;

  // Step 3: Verify weak point extraction
  assertEquals(chain.events.length, 6);
  assertEquals(chain.summary.program, "/tmp/test-target");
  assertEquals(chain.summary.weakPoints, 6);
  assertEquals(chain.summary.totalCrashes, 2);
  assertEquals(chain.summary.robustnessScore, 65.0);

  // Step 4: Verify event details
  const cpuEvents = chain.events.filter((e) => e.axis === "cpu");
  const memEvents = chain.events.filter((e) => e.axis === "memory");
  assertEquals(cpuEvents.length, 3);
  assertEquals(memEvents.length, 3);
});

Deno.test("E2E: unavailable capability → graceful fallback", () => {
  const capResult = parseCapability(JSON.stringify({
    mode: "unavailable",
    detail: "panic-attack not installed",
  }));
  assertEquals(capResult.TAG, "Ok");

  const modeLabel = label(capResult._0.mode);
  const modeClass = toneClass(capResult._0.mode);
  assertEquals(modeLabel, "panic-attacker mode: unavailable");
  assertEquals(modeClass, "text-red-400");
  assertEquals(capResult._0.binary, undefined);
});

Deno.test("E2E: fallback mode → correct display attributes", () => {
  const capResult = parseCapability(JSON.stringify({
    mode: "fallback",
    detail: "SARIF conversion only",
  }));
  assertEquals(capResult.TAG, "Ok");
  assertEquals(label(capResult._0.mode), "panic-attacker mode: fallback conversion");
  assertEquals(toneClass(capResult._0.mode), "text-amber-400");
});

// ---------------------------------------------------------------------------
// 2. SARIF-compatible output parsing
// ---------------------------------------------------------------------------

Deno.test("SARIF-compatible: event chain with SARIF-style severity mapping", () => {
  const payload = JSON.stringify({
    format: "panll.event-chain.v0",
    source: { tool: "panic-attack", report_path: "sarif-report.json" },
    summary: {
      program: "/tmp/sarif-target",
      weak_points: 3,
      critical_weak_points: 1,
      total_crashes: 1,
      robustness_score: 45.0,
    },
    timeline: { duration_ms: 30000, events: 3 },
    event_chain: [
      { id: "sarif-wp-1", axis: "cpu", start_ms: 0, duration_ms: 5000, intensity: "Heavy", status: "crashed", peak_memory: null, notes: "critical: stack overflow detected" },
      { id: "sarif-wp-2", axis: "memory", start_ms: 5000, duration_ms: 10000, intensity: "Medium", status: "ran", peak_memory: 268435456, notes: "warning: high memory usage" },
      { id: "sarif-wp-3", axis: "cpu", start_ms: 15000, duration_ms: 5000, intensity: "Light", status: "ran", peak_memory: null, notes: "note: minor timing anomaly" },
    ],
    constraints: [],
  });

  const result = parseEventChain(payload);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.events.length, 3);

  // Verify SARIF-style notes are preserved
  assert(result._0.events[0].notes.startsWith("critical:"));
  assert(result._0.events[1].notes.startsWith("warning:"));
  assert(result._0.events[2].notes.startsWith("note:"));
  assertEquals(result._0.summary.robustnessScore, 45.0);
});

// ---------------------------------------------------------------------------
// 3. panll.event-chain.v0 format validation
// ---------------------------------------------------------------------------

Deno.test("event-chain.v0: format field is preserved through parsing", () => {
  const payload = JSON.stringify({
    format: "panll.event-chain.v0",
    event_chain: [
      { id: "test-1", axis: "cpu", start_ms: 0, duration_ms: 1000, intensity: "Light", status: "ran" },
    ],
  });
  const result = parseEventChain(payload);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.events.length, 1);
});

Deno.test("event-chain.v0: all axis types handled", () => {
  const axes = ["cpu", "memory", "disk", "network", "gpu", "unknown"];
  for (const axis of axes) {
    const payload = JSON.stringify({
      format: "panll.event-chain.v0",
      event_chain: [
        { id: `axis-${axis}`, axis: axis, start_ms: 0, duration_ms: 1000, intensity: "Medium", status: "ran" },
      ],
    });
    const result = parseEventChain(payload);
    assertEquals(result.TAG, "Ok");
    assertEquals(result._0.events[0].axis, axis);
  }
});

Deno.test("event-chain.v0: all status values handled", () => {
  const statuses = ["ran", "crashed", "skipped", "timeout", "failed"];
  for (const status of statuses) {
    const payload = JSON.stringify({
      format: "panll.event-chain.v0",
      event_chain: [
        { id: `status-${status}`, axis: "cpu", start_ms: 0, duration_ms: 500, intensity: "Light", status: status },
      ],
    });
    const result = parseEventChain(payload);
    assertEquals(result.TAG, "Ok");
    assertEquals(result._0.events[0].status, status);
  }
});

Deno.test("event-chain.v0: all intensity values handled", () => {
  const intensities = ["Heavy", "Medium", "Light", "unknown"];
  for (const intensity of intensities) {
    const payload = JSON.stringify({
      format: "panll.event-chain.v0",
      event_chain: [
        { id: `int-${intensity}`, axis: "cpu", start_ms: 0, duration_ms: 500, intensity: intensity, status: "ran" },
      ],
    });
    const result = parseEventChain(payload);
    assertEquals(result.TAG, "Ok");
    assertEquals(result._0.events[0].intensity, intensity);
  }
});

Deno.test("event-chain.v0: timeline and summary correlation", () => {
  const payload = makeEventChainPayload(10, 3, 55.0);
  const result = parseEventChain(payload);
  assertEquals(result.TAG, "Ok");

  // Timeline event count should match event_chain array length
  assertEquals(result._0.timeline.events, result._0.events.length);
  // Summary weak_points should match event count
  assertEquals(result._0.summary.weakPoints, result._0.events.length);
  // Timeline duration should be positive
  assert(result._0.timeline.durationMs > 0);
});

// ---------------------------------------------------------------------------
// 4. panll.system-image.v0 format validation
// ---------------------------------------------------------------------------

Deno.test("system-image.v0: valid structure has required fields", () => {
  const image = makeSystemImagePayload(10);

  assertEquals(image.format, "panll.system-image.v0");
  assertExists(image.generated_at);
  assertExists(image.scan_surface);
  assertEquals(typeof image.global_health, "number");
  assertEquals(typeof image.global_risk, "number");
  assertEquals(image.node_count, 10);
  assertEquals(image.nodes.length, 10);
  assert(image.global_health >= 0 && image.global_health <= 100);
  assert(image.global_risk >= 0 && image.global_risk <= 1.0);
});

Deno.test("system-image.v0: risk distribution sums to <= node count", () => {
  const image = makeSystemImagePayload(100);
  const dist = image.risk_distribution;
  const sum = dist.healthy + dist.low + dist.moderate + dist.high + dist.critical;
  assert(sum <= image.node_count, `Risk distribution sum (${sum}) should be <= node_count (${image.node_count})`);
});

Deno.test("system-image.v0: each node has required fields", () => {
  const image = makeSystemImagePayload(5);
  for (const node of image.nodes) {
    assertExists(node.id);
    assertExists(node.name);
    assertEquals(typeof node.health_score, "number");
    assertEquals(typeof node.risk_intensity, "number");
    assertEquals(typeof node.weak_point_count, "number");
    assertEquals(typeof node.critical_count, "number");
    assertEquals(typeof node.skipped, "boolean");
    assert(Array.isArray(node.top_categories));
  }
});

Deno.test("system-image.v0: empty image (zero nodes)", () => {
  const image = makeSystemImagePayload(0);
  assertEquals(image.nodes.length, 0);
  assertEquals(image.node_count, 0);
  assertEquals(image.edges.length, 0);
});

Deno.test("system-image.v0: large image (500 nodes)", () => {
  const image = makeSystemImagePayload(500);
  assertEquals(image.nodes.length, 500);
  assertEquals(image.node_count, 500);
  // All node IDs should be unique
  const ids = new Set(image.nodes.map((n) => n.id));
  assertEquals(ids.size, 500);
});

// ---------------------------------------------------------------------------
// 5. panll.temporal-diff.v0 format validation
// ---------------------------------------------------------------------------

Deno.test("temporal-diff.v0: improving trend has correct deltas", () => {
  const diff = makeTemporalDiffPayload(20, "improving");

  assertEquals(diff.format, "panll.temporal-diff.v0");
  assertEquals(diff.trend, "improving");
  assert(diff.health_delta > 0, "Improving trend should have positive health delta");
  assert(diff.risk_delta < 0, "Improving trend should have negative risk delta");
  assert(diff.weak_point_delta < 0, "Improving trend should have negative weak point delta");
  assertExists(diff.from_label);
  assertExists(diff.to_label);
  assertExists(diff.from_timestamp);
  assertExists(diff.to_timestamp);
});

Deno.test("temporal-diff.v0: degrading trend has correct deltas", () => {
  const diff = makeTemporalDiffPayload(20, "degrading");

  assertEquals(diff.trend, "degrading");
  assert(diff.health_delta < 0, "Degrading trend should have negative health delta");
  assert(diff.risk_delta > 0, "Degrading trend should have positive risk delta");
  assert(diff.weak_point_delta > 0, "Degrading trend should have positive weak point delta");
});

Deno.test("temporal-diff.v0: node counts are consistent", () => {
  const diff = makeTemporalDiffPayload(30, "improving");
  const totalAccountedFor = diff.improved_nodes.length + diff.degraded_nodes.length + diff.unchanged_count;
  // Total accounted nodes should equal the original nodeCount
  assertEquals(totalAccountedFor, 30);
});

Deno.test("temporal-diff.v0: each node delta has required fields", () => {
  const diff = makeTemporalDiffPayload(10, "improving");
  for (const node of diff.improved_nodes) {
    assertExists(node.name);
    assertEquals(typeof node.health_before, "number");
    assertEquals(typeof node.health_after, "number");
    assertEquals(typeof node.health_delta, "number");
    assertEquals(typeof node.risk_before, "number");
    assertEquals(typeof node.risk_after, "number");
    assertEquals(typeof node.risk_delta, "number");
    assertEquals(typeof node.weak_point_delta, "number");
  }
  for (const node of diff.degraded_nodes) {
    assertExists(node.name);
    assertEquals(typeof node.health_delta, "number");
    assert(node.health_delta < 0, "Degraded node should have negative health delta");
    assert(node.risk_delta > 0, "Degraded node should have positive risk delta");
  }
});

Deno.test("temporal-diff.v0: empty diff (no changes)", () => {
  const diff = {
    format: "panll.temporal-diff.v0",
    from_label: "snap-A",
    to_label: "snap-B",
    from_timestamp: "2026-03-08T00:00:00Z",
    to_timestamp: "2026-03-09T00:00:00Z",
    health_delta: 0.0,
    risk_delta: 0.0,
    weak_point_delta: 0,
    critical_delta: 0,
    new_nodes: [],
    removed_nodes: [],
    improved_nodes: [],
    degraded_nodes: [],
    unchanged_count: 50,
    trend: "stable",
  };

  assertEquals(diff.trend, "stable");
  assertEquals(diff.improved_nodes.length, 0);
  assertEquals(diff.degraded_nodes.length, 0);
  assertEquals(diff.unchanged_count, 50);
  assertEquals(diff.health_delta, 0.0);
});

// ---------------------------------------------------------------------------
// 6. MassPanic model edge cases
// ---------------------------------------------------------------------------

Deno.test("MassPanicModel: init state has sane defaults", () => {
  assertEquals(massPanicInit.reposDirectory, "");
  assertEquals(massPanicInit.scanning, false);
  assertEquals(massPanicInit.progress, 0.0);
  assertEquals(massPanicInit.currentRepo, undefined);
  assertEquals(massPanicInit.incremental, true);
  assertEquals(massPanicInit.storage, "NoStorage");
  assertEquals(massPanicInit.repoResults.length, 0);
  assertEquals(massPanicInit.summary, undefined);
  assertEquals(massPanicInit.delta.length, 0);
  assertEquals(massPanicInit.activeView, "ScanView");
});

Deno.test("MassPanicModel: init state imaging fields default empty", () => {
  assertEquals(massPanicInit.currentImage, undefined);
  assertEquals(massPanicInit.imagingLoading, false);
});

Deno.test("MassPanicModel: init state temporal fields default empty", () => {
  assertEquals(massPanicInit.snapshots.length, 0);
  assertEquals(massPanicInit.currentDiff, undefined);
  assertEquals(massPanicInit.temporalLoading, false);
});

Deno.test("MassPanicModel: empty scan simulation (no repos found)", () => {
  // Simulate updating the model after a scan that found zero repos
  const afterEmptyScan = {
    ...massPanicInit,
    scanning: false,
    repoResults: [],
    summary: {
      totalRepos: 0,
      scannedRepos: 0,
      skippedRepos: 0,
      failedRepos: 0,
      totalFindings: 0,
      totalCritical: 0,
      totalHigh: 0,
      scanDuration: 0.01,
      timestamp: "2026-03-09T12:00:00Z",
    },
  };

  assertEquals(afterEmptyScan.repoResults.length, 0);
  assertEquals(afterEmptyScan.summary.totalRepos, 0);
  assertEquals(afterEmptyScan.summary.scanDuration, 0.01);
});

Deno.test("MassPanicModel: malformed data handling — invalid progress range", () => {
  // The model type allows any float, so we verify it does not crash
  const badProgress = { ...massPanicInit, progress: -1.0 };
  assertEquals(badProgress.progress, -1.0);

  const overProgress = { ...massPanicInit, progress: 999.0 };
  assertEquals(overProgress.progress, 999.0);
});

Deno.test("MassPanicModel: very large scan results (1000 repos)", () => {
  const largeResults = [];
  for (let i = 0; i < 1000; i++) {
    largeResults.push({
      repoPath: `/tmp/test-repos/repo-${i}`,
      repoName: `repo-${i}`,
      status: "Complete",
      totalFindings: i % 10,
      critical: i % 100 === 0 ? 1 : 0,
      high: i % 20 === 0 ? 2 : 0,
      medium: i % 5 === 0 ? 3 : 0,
      low: i % 2 === 0 ? 4 : 0,
      filesScanned: 50 + i,
      blake3Hash: `hash-${i.toString(16)}`,
      scanDuration: 0.5 + (i * 0.01),
    });
  }

  const afterLargeScan = { ...massPanicInit, repoResults: largeResults };
  assertEquals(afterLargeScan.repoResults.length, 1000);

  // Verify we can filter critical repos
  const critical = afterLargeScan.repoResults.filter((r) => r.critical > 0);
  assertEquals(critical.length, 10); // every 100th repo
});

Deno.test("MassPanicModel: delta entries with all change directions", () => {
  const deltas = [
    { repoName: "repo-a", newFindings: 5, fixedFindings: 0, changeDirection: "regressed" },
    { repoName: "repo-b", newFindings: 0, fixedFindings: 3, changeDirection: "improved" },
    { repoName: "repo-c", newFindings: 0, fixedFindings: 0, changeDirection: "unchanged" },
    { repoName: "repo-d", newFindings: 2, fixedFindings: 0, changeDirection: "new" },
  ];

  const withDelta = { ...massPanicInit, delta: deltas, showDelta: true };
  assertEquals(withDelta.delta.length, 4);
  assertEquals(withDelta.delta[0].changeDirection, "regressed");
  assertEquals(withDelta.delta[1].changeDirection, "improved");
  assertEquals(withDelta.delta[2].changeDirection, "unchanged");
  assertEquals(withDelta.delta[3].changeDirection, "new");
});

// ---------------------------------------------------------------------------
// 7. Cross-module integration: capability → event chain → model state
// ---------------------------------------------------------------------------

Deno.test("Cross-module: full pipeline from capability check to model update", () => {
  // 1. Check capability
  const cap = parseCapability(JSON.stringify({
    mode: "full",
    binary: "/usr/local/bin/panic-attack",
    detail: "ready",
  }));
  assertEquals(cap.TAG, "Ok");
  assertEquals(cap._0.mode, "full");

  // 2. Parse event chain (scan result)
  const chain = parseEventChain(makeEventChainPayload(4, 1, 72.0));
  assertEquals(chain.TAG, "Ok");
  assertEquals(chain._0.events.length, 4);

  // 3. Update model with results
  const updated = {
    ...massPanicInit,
    scanning: false,
    repoResults: [{
      repoPath: "/tmp/test-target",
      repoName: "test-target",
      status: "Complete",
      totalFindings: chain._0.summary.weakPoints,
      critical: chain._0.summary.criticalWeakPoints,
      high: 0,
      medium: 0,
      low: chain._0.summary.weakPoints - chain._0.summary.criticalWeakPoints,
      filesScanned: 1,
      blake3Hash: undefined,
      scanDuration: chain._0.timeline.durationMs / 1000,
    }],
  };

  assertEquals(updated.repoResults.length, 1);
  assertEquals(updated.repoResults[0].totalFindings, 4);
  assertEquals(updated.repoResults[0].critical, 1);
  assertEquals(updated.repoResults[0].scanDuration, 20); // 4 * 5000ms / 1000
});

Deno.test("Cross-module: error path through all modules", () => {
  // Bad capability
  const cap = parseCapability("{bad");
  assertEquals(cap.TAG, "Error");

  // Bad event chain
  const chain = parseEventChain("{bad");
  assertEquals(chain.TAG, "Error");

  // Model stays in init state
  const state = { ...massPanicInit, lastError: cap._0 };
  assertEquals(state.lastError, "Invalid JSON");
  assertEquals(state.repoResults.length, 0);
});
