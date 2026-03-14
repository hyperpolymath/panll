// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * TangleVizEngine tests — verify braid word computation, invariants, and display helpers.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as TangleVizEngine from "../src/core/TangleVizEngine.res.js";

// ---- Default State ----

Deno.test("TangleVizEngine.defaultState has empty braidWord", () => {
  assertEquals(TangleVizEngine.defaultState.braidWord.length, 0);
});

Deno.test("TangleVizEngine.defaultState strandCount is 2", () => {
  assertEquals(TangleVizEngine.defaultState.strandCount, 2);
});

Deno.test("TangleVizEngine.defaultState viewMode is BraidDiagram", () => {
  assertEquals(TangleVizEngine.defaultState.viewMode, "BraidDiagram");
});

// ---- Braid Word Operations ----

Deno.test("braidWordToString of empty array is identity 'e'", () => {
  assertEquals(TangleVizEngine.braidWordToString([]), "e");
});

Deno.test("braidWordToString of single positive generator", () => {
  const result = TangleVizEngine.braidWordToString([{ index: 1, exponent: 1 }]);
  assert(result.length > 0);
  assert(result !== "e");
});

Deno.test("strandCountFromWord empty defaults to 2", () => {
  assertEquals(TangleVizEngine.strandCountFromWord([]), 2);
});

Deno.test("strandCountFromWord with index 3 gives 4 strands", () => {
  const gens = [{ index: 3, exponent: 1 }];
  assertEquals(TangleVizEngine.strandCountFromWord(gens), 4);
});

Deno.test("strandCountFromWord with mixed indices uses max", () => {
  const gens = [
    { index: 1, exponent: 1 },
    { index: 2, exponent: -1 },
    { index: 1, exponent: 1 },
  ];
  assertEquals(TangleVizEngine.strandCountFromWord(gens), 3);
});

// ---- Writhe Computation ----

Deno.test("computeWrithe of empty braid is 0", () => {
  assertEquals(TangleVizEngine.computeWrithe([]), 0);
});

Deno.test("computeWrithe of all positive generators sums to count", () => {
  const gens = [
    { index: 1, exponent: 1 },
    { index: 2, exponent: 1 },
    { index: 1, exponent: 1 },
  ];
  assertEquals(TangleVizEngine.computeWrithe(gens), 3);
});

Deno.test("computeWrithe with mixed signs cancels", () => {
  const gens = [
    { index: 1, exponent: 1 },
    { index: 1, exponent: -1 },
  ];
  assertEquals(TangleVizEngine.computeWrithe(gens), 0);
});

// ---- Invariant Computation ----

Deno.test("computeInvariant Writhe returns w = N", () => {
  const gens = [{ index: 1, exponent: 1 }, { index: 2, exponent: 1 }];
  const result = TangleVizEngine.computeInvariant("Writhe", gens);
  assert(result.includes("w = 2"));
});

Deno.test("computeInvariant Linking returns lk from writhe/2", () => {
  const gens = [{ index: 1, exponent: 1 }, { index: 1, exponent: 1 }];
  const result = TangleVizEngine.computeInvariant("Linking", gens);
  assert(result.includes("lk = 1"));
});

Deno.test("computeInvariant Jones includes crossing count", () => {
  const gens = [{ index: 1, exponent: 1 }];
  const result = TangleVizEngine.computeInvariant("Jones", gens);
  assert(result.includes("V(t)"));
});

// ---- Display Helpers ----

Deno.test("viewModeLabel covers all modes", () => {
  assertEquals(TangleVizEngine.viewModeLabel("BraidDiagram"), "Braid");
  assertEquals(TangleVizEngine.viewModeLabel("KnotDiagram"), "Knot");
  assertEquals(TangleVizEngine.viewModeLabel("AlgebraicView"), "Algebraic");
});

Deno.test("allViewModes has 3 entries", () => {
  assertEquals(TangleVizEngine.allViewModes.length, 3);
});

Deno.test("invariantLabel covers all 6 invariants", () => {
  assertEquals(TangleVizEngine.allInvariants.length, 6);
  for (const inv of TangleVizEngine.allInvariants) {
    const label = TangleVizEngine.invariantLabel(inv);
    assert(label.length > 0);
  }
});

Deno.test("strandColour wraps around for high indices", () => {
  const c0 = TangleVizEngine.strandColour(0);
  const c8 = TangleVizEngine.strandColour(8);
  assertEquals(c0, c8); // wraps at 8
});

Deno.test("strandColour returns valid hex colours", () => {
  for (let i = 0; i < 8; i++) {
    assert(TangleVizEngine.strandColour(i).startsWith("#"));
  }
});

// ---- Example Braids ----

Deno.test("exampleBraids returns non-empty array", () => {
  const examples = TangleVizEngine.exampleBraids();
  assert(examples.length > 0);
});

Deno.test("exampleBraids entries have name, generators, description", () => {
  const examples = TangleVizEngine.exampleBraids();
  for (const ex of examples) {
    assert(ex.name.length > 0);
    assert(Array.isArray(ex.generators));
    assert(ex.description.length > 0);
  }
});

// ---- SVG Constants ----

Deno.test("SVG constants are positive", () => {
  assert(TangleVizEngine.crossingWidth > 0);
  assert(TangleVizEngine.strandSpacing > 0);
  assert(TangleVizEngine.svgLeftMargin > 0);
  assert(TangleVizEngine.svgTopMargin > 0);
});
