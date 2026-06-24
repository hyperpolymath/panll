// SPDX-License-Identifier: MPL-2.0

/**
 * OrbitalSync module tests
 */

import { assertEquals } from "jsr:@std/assert";
import * as OrbitalSync from "../src/core/OrbitalSync.res.js";

Deno.test("OrbitalSync.simpleHash - empty string returns 'empty'", () => {
  const result = OrbitalSync.simpleHash("");
  assertEquals(result, "empty");
});

Deno.test("OrbitalSync.simpleHash - non-empty returns length-first-last format", () => {
  const result = OrbitalSync.simpleHash("hello");
  assertEquals(result, "5-h-o");
});

Deno.test("OrbitalSync.calculateDivergence - equal strings return 0.0", () => {
  const paneL = { constraints: [], activeConstraintId: undefined, editorContent: "test" };
  const paneN = { tokens: [], activeTokenId: undefined, monologue: "test", inferenceStatus: "idle", autonomyLevel: 0.0 };

  const result = OrbitalSync.calculateDivergence(paneL, paneN);
  assertEquals(result, 0.0);
});

Deno.test("OrbitalSync.calculateDivergence - different strings return proportional value", () => {
  const paneL = { constraints: [], activeConstraintId: undefined, editorContent: "short" };
  const paneN = { tokens: [], activeTokenId: undefined, monologue: "much longer content", inferenceStatus: "idle", autonomyLevel: 0.0 };

  const result = OrbitalSync.calculateDivergence(paneL, paneN);
  assertEquals(result > 0.0 && result <= 1.0, true);
});

Deno.test("OrbitalSync.calculateStability - zero divergence returns 1.0", () => {
  const result = OrbitalSync.calculateStability(0.0, 0.0);
  assertEquals(result, 1.0);
});

Deno.test("OrbitalSync.getDriftAuraColour - high stability returns indigo", () => {
  const result = OrbitalSync.getDriftAuraColour(0.9);
  assertEquals(result, "indigo");
});

Deno.test("OrbitalSync.getDriftAuraColour - low stability returns amber", () => {
  const result = OrbitalSync.getDriftAuraColour(0.3);
  assertEquals(result, "amber");
});
