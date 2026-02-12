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

Deno.test("Storage - default model survives save/load round-trip", () => {
  clear();

  const model = initModel();
  save(model);

  const loaded = load();
  assertEquals(loaded?.paneL.constraints.length, model.paneL.constraints.length);
  assertEquals(loaded?.paneN.tokens.length, model.paneN.tokens.length);
  assertEquals(loaded?.vexometer.index, model.vexometer.index);
  assertEquals(loaded?.humidity, model.humidity);

  clear();
});

Deno.test("Storage - constraints persist correctly", () => {
  clear();

  const model = initModel();
  const withConstraints = {
    ...model,
    paneL: {
      ...model.paneL,
      constraints: [
        { id: "c1", expression: "type User", active: true, pinned: false },
        { id: "c2", expression: "!contains(\"eval(\")", active: true, pinned: true },
        { id: "c3", expression: "length > 0", active: false, pinned: false }
      ]
    }
  };

  save(withConstraints);
  const loaded = load();

  assertEquals(loaded?.paneL.constraints.length, 3);
  assertEquals(loaded?.paneL.constraints[0].id, "c1");
  assertEquals(loaded?.paneL.constraints[0].active, true);
  assertEquals(loaded?.paneL.constraints[1].pinned, true);
  assertEquals(loaded?.paneL.constraints[2].active, false);

  clear();
});

Deno.test("Storage - viewMode persists correctly", () => {
  clear();

  const model = initModel();
  const withZenMode = {
    ...model,
    viewMode: "Zen"
  };

  save(withZenMode);
  const loaded = load();

  assertEquals(loaded?.viewMode, "Zen");

  clear();
});

Deno.test("Storage - humidity persists correctly", () => {
  clear();

  const model = initModel();
  const withLowHumidity = {
    ...model,
    humidity: "Low"
  };

  save(withLowHumidity);
  const loaded = load();

  assertEquals(loaded?.humidity, "Low");

  clear();
});

Deno.test("Storage - clear() then load() returns undefined", () => {
  const model = initModel();
  save(model);

  clear();
  const loaded = load();

  assertEquals(loaded, undefined);
});
