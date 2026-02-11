// SPDX-License-Identifier: PMPL-1.0-or-later

import { assertEquals } from "jsr:@std/assert";
import { init as initModel } from "../src/Model.res.js";
import { clear, load, save, storageKey } from "../src/Storage.res.js";

Deno.test("Storage - timeline metadata survives save/load round-trip", () => {
  clear();

  const model = initModel();
  const withTimeline = {
    ...model,
    paneW: {
      ...model.paneW,
      eventChain: [
        {
          id: "cpu-quick",
          axis: "cpu",
          startMs: 200,
          durationMs: 800,
          intensity: "Light",
          status: "ran",
          peakMemory: undefined,
          notes: undefined
        }
      ],
      eventChainSummary: {
        program: "/tmp/panll-ambush-target.sh",
        weakPoints: 3,
        criticalWeakPoints: 0,
        totalCrashes: 0,
        robustnessScore: 90
      },
      eventChainTimeline: {
        durationMs: 2000,
        events: 2
      }
    }
  };

  save(withTimeline);
  assertEquals(typeof globalThis.localStorage.getItem(storageKey), "string");

  const loaded = load();
  assertEquals(loaded?.paneW.eventChain.length, 1);
  assertEquals(loaded?.paneW.eventChainSummary?.program, "/tmp/panll-ambush-target.sh");
  assertEquals(loaded?.paneW.eventChainTimeline?.durationMs, 2000);
  assertEquals(loaded?.paneW.eventChainTimeline?.events, 2);

  clear();
});
