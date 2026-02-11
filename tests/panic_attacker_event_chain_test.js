// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * panic-attacker PanLL import tests
 *
 * Verifies that PanLL can parse panic-attacker event-chain exports.
 */

import { assertEquals } from "jsr:@std/assert";
import { parse } from "../src/core/EventChain.res.js";

Deno.test("EventChain.parse - accepts panic-attacker panll export payload", () => {
  const payload = JSON.stringify({
    format: "panll.event-chain.v0",
    generated_at: "2026-02-11T00:00:00Z",
    source: {
      tool: "panic-attack",
      report_path: "reports/panic-attack-report.json"
    },
    summary: {
      program: "/tmp/demo-target",
      weak_points: 4,
      critical_weak_points: 1,
      total_crashes: 2,
      robustness_score: 61.5
    },
    timeline: {
      duration_ms: 60000,
      events: 2
    },
    event_chain: [
      {
        id: "cpu-1",
        axis: "cpu",
        start_ms: 0,
        duration_ms: 15000,
        intensity: "Heavy",
        status: "ran",
        peak_memory: null,
        notes: null
      },
      {
        id: "memory-1",
        axis: "memory",
        start_ms: 15000,
        duration_ms: 25000,
        intensity: "Medium",
        status: "ran",
        peak_memory: 536870912,
        notes: "memory pressure spike"
      }
    ],
    constraints: []
  });

  const result = parse(payload);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.events.length, 2);
  assertEquals(result._0.summary.program, "/tmp/demo-target");
  assertEquals(result._0.summary.criticalWeakPoints, 1);
  assertEquals(result._0.timeline.events, 2);
  assertEquals(result._0.timeline.durationMs, 60000);
  assertEquals(result._0.events[1].axis, "memory");
  assertEquals(result._0.events[1].peakMemory, 536870912);
});

Deno.test("EventChain.parse - returns error for malformed JSON", () => {
  const result = parse("{ this is not valid json");
  assertEquals(result.TAG, "Error");
  assertEquals(result._0, "Invalid event-chain JSON");
});

Deno.test("EventChain.parse - tolerates missing summary with event chain", () => {
  const payload = JSON.stringify({
    event_chain: [
      {
        id: "attack-cpu-1",
        axis: "cpu",
        start_ms: null,
        duration_ms: 1200,
        intensity: "unknown",
        status: "failed",
        peak_memory: 1024,
        notes: "fallback conversion path"
      }
    ]
  });

  const result = parse(payload);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.summary, undefined);
  assertEquals(result._0.timeline, undefined);
  assertEquals(result._0.events.length, 1);
  assertEquals(result._0.events[0].status, "failed");
});
