// SPDX-License-Identifier: MPL-2.0

/**
 * Storage round-trip tests
 *
 * Note: eventChain, eventChainSummary, eventChainTimeline are NOT persisted
 * (they are not part of the persistedState type). Only core state is persisted:
 * constraints, editorContent, neuralTokens, worldContent, viewMode,
 * paneLVisible, paneNVisible, paneWVisible, humidity, vexometerIndex,
 * orbitalStability.
 *
 * ReScript viewMode/humidity are variant types that compile to strings in JS.
 * Storage serializes them as strings and deserializes back.
 */

import { assertEquals } from "jsr:@std/assert";
import { init as initModel } from "../src/Model.res.js";
import { clear, load, save, storageKey } from "../src/Storage.res.js";

Deno.test("Storage - core state survives save/load round-trip", () => {
  clear();

  const model = initModel();
  const withData = {
    ...model,
    paneL: {
      ...model.paneL,
      constraints: [
        { id: "c1", expression: "type User", active: true, pinned: false }
      ],
      editorContent: "test editor content"
    },
    paneW: {
      ...model.paneW,
      content: "world content here"
    }
  };

  save(withData);
  const stored = globalThis.localStorage.getItem(storageKey);
  assertEquals(typeof stored, "string");

  const loaded = load();
  assertEquals(loaded?.paneL.constraints.length, 1);
  assertEquals(loaded?.paneL.constraints[0].id, "c1");
  assertEquals(loaded?.paneL.editorContent, "test editor content");
  assertEquals(loaded?.paneW.content, "world content here");

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
  // viewMode variants compile to strings: "Standard", "Ambient", "Zen", "DarkStart"
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
  // humidity variants compile to strings: "High", "Medium", "Low"
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
