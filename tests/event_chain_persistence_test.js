// SPDX-License-Identifier: MPL-2.0

/**
 * Event chain persistence tests
 *
 * Verifies that eventChain, eventChainSummary, and eventChainTimeline
 * survive save/load round-trips through Storage.
 */

import { assertEquals } from "jsr:@std/assert";
import { init as initModel } from "../src/Model.res.js";
import { clear, load, save } from "../src/Storage.res.js";

Deno.test("Storage - eventChain events survive round-trip", () => {
  clear();

  const model = initModel();
  const withEventChain = {
    ...model,
    paneW: {
      ...model.paneW,
      eventChain: [
        {
          id: "ev1",
          axis: "cpu",
          startMs: 0.0,
          durationMs: 1500.0,
          intensity: "high",
          status: "completed",
          peakMemory: 256.0,
          notes: "CPU spike test",
        },
        {
          id: "ev2",
          axis: "memory",
          startMs: undefined,
          durationMs: 3000.0,
          intensity: "medium",
          status: "running",
          peakMemory: undefined,
          notes: undefined,
        },
      ],
    },
  };

  save(withEventChain);
  const loaded = load();

  assertEquals(loaded?.paneW.eventChain.length, 2);
  assertEquals(loaded?.paneW.eventChain[0].id, "ev1");
  assertEquals(loaded?.paneW.eventChain[0].axis, "cpu");
  assertEquals(loaded?.paneW.eventChain[0].durationMs, 1500.0);
  assertEquals(loaded?.paneW.eventChain[0].intensity, "high");
  assertEquals(loaded?.paneW.eventChain[0].peakMemory, 256.0);
  assertEquals(loaded?.paneW.eventChain[0].notes, "CPU spike test");
  assertEquals(loaded?.paneW.eventChain[1].id, "ev2");
  assertEquals(loaded?.paneW.eventChain[1].peakMemory, undefined);
  assertEquals(loaded?.paneW.eventChain[1].notes, undefined);

  clear();
});

Deno.test("Storage - eventChainSummary survives round-trip", () => {
  clear();

  const model = initModel();
  const withSummary = {
    ...model,
    paneW: {
      ...model.paneW,
      eventChainSummary: {
        program: "echidna",
        weakPoints: 15,
        criticalWeakPoints: 3,
        totalCrashes: 2,
        robustnessScore: 0.87,
      },
    },
  };

  save(withSummary);
  const loaded = load();

  assertEquals(loaded?.paneW.eventChainSummary?.program, "echidna");
  assertEquals(loaded?.paneW.eventChainSummary?.weakPoints, 15);
  assertEquals(loaded?.paneW.eventChainSummary?.criticalWeakPoints, 3);
  assertEquals(loaded?.paneW.eventChainSummary?.totalCrashes, 2);
  assertEquals(loaded?.paneW.eventChainSummary?.robustnessScore, 0.87);

  clear();
});

Deno.test("Storage - eventChainTimeline survives round-trip", () => {
  clear();

  const model = initModel();
  const withTimeline = {
    ...model,
    paneW: {
      ...model.paneW,
      eventChainTimeline: {
        durationMs: 45000.0,
        events: 12,
      },
    },
  };

  save(withTimeline);
  const loaded = load();

  assertEquals(loaded?.paneW.eventChainTimeline?.durationMs, 45000.0);
  assertEquals(loaded?.paneW.eventChainTimeline?.events, 12);

  clear();
});

Deno.test("Storage - absent eventChain data loads as empty/undefined", () => {
  clear();

  const model = initModel();
  save(model);
  const loaded = load();

  assertEquals(loaded?.paneW.eventChain.length, 0);
  assertEquals(loaded?.paneW.eventChainSummary, undefined);
  assertEquals(loaded?.paneW.eventChainTimeline, undefined);

  clear();
});

Deno.test("Storage - full event chain + summary + timeline round-trip", () => {
  clear();

  const model = initModel();
  const full = {
    ...model,
    paneW: {
      ...model.paneW,
      eventChain: [
        {
          id: "e1",
          axis: "concurrency",
          startMs: 100.0,
          durationMs: 500.0,
          intensity: "low",
          status: "pass",
          peakMemory: undefined,
          notes: undefined,
        },
      ],
      eventChainSummary: {
        program: "panll",
        weakPoints: 5,
        criticalWeakPoints: 0,
        totalCrashes: 0,
        robustnessScore: 0.95,
      },
      eventChainTimeline: {
        durationMs: 10000.0,
        events: 1,
      },
    },
  };

  save(full);
  const loaded = load();

  // Event chain
  assertEquals(loaded?.paneW.eventChain.length, 1);
  assertEquals(loaded?.paneW.eventChain[0].axis, "concurrency");

  // Summary
  assertEquals(loaded?.paneW.eventChainSummary?.program, "panll");
  assertEquals(loaded?.paneW.eventChainSummary?.robustnessScore, 0.95);

  // Timeline
  assertEquals(loaded?.paneW.eventChainTimeline?.durationMs, 10000.0);
  assertEquals(loaded?.paneW.eventChainTimeline?.events, 1);

  clear();
});
