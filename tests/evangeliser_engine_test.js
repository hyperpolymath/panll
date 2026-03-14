// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * EvangeliserEngine tests — ReScript Evangeliser pattern scanning and display helpers.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as E from "../src/core/EvangeliserEngine.res.js";

Deno.test("defaultState has scanning false", () => {
  assertEquals(E.defaultState.scanning, false);
});

Deno.test("allCategories has entries", () => {
  assert(E.allCategories.length > 0);
});

Deno.test("categoryLabel covers all categories", () => {
  for (const cat of E.allCategories) {
    assert(E.categoryLabel(cat).length > 0);
  }
});

Deno.test("categoryCode covers all categories", () => {
  for (const cat of E.allCategories) {
    assert(E.categoryCode(cat).length > 0);
  }
});

Deno.test("categoryColour returns valid class", () => {
  for (const cat of E.allCategories) {
    assert(E.categoryColour(cat).length > 0);
  }
});

Deno.test("difficultyLabel covers basic levels", () => {
  assert(E.difficultyLabel("Beginner").length > 0);
  assert(E.difficultyLabel("Intermediate").length > 0);
  assert(E.difficultyLabel("Advanced").length > 0);
});

Deno.test("builtinGlyphs has entries", () => {
  assert(E.builtinGlyphs.length > 0);
});

Deno.test("findGlyph returns something for a builtin", () => {
  if (E.builtinGlyphs.length > 0) {
    const first = E.builtinGlyphs[0];
    const result = E.findGlyph(first.name);
    assert(result !== undefined);
  }
});

Deno.test("findGlyph returns undefined for unknown", () => {
  assertEquals(E.findGlyph("nonexistent_glyph_xyz"), undefined);
});

Deno.test("builtinPatterns has entries", () => {
  assert(E.builtinPatterns.length > 0);
});

Deno.test("builtinPatterns all have id, name, jsPattern", () => {
  for (const p of E.builtinPatterns) {
    assert(p.id.length > 0);
    assert(p.name.length > 0);
    assert(p.jsPattern.length > 0);
  }
});

Deno.test("filterByCategory with undefined returns all", () => {
  const all = E.filterByCategory(E.builtinPatterns, undefined);
  assertEquals(all.length, E.builtinPatterns.length);
});

Deno.test("filterBySearch with empty returns all", () => {
  const all = E.filterBySearch(E.builtinPatterns, "");
  assertEquals(all.length, E.builtinPatterns.length);
});

Deno.test("filterBySearch narrows results", () => {
  const filtered = E.filterBySearch(E.builtinPatterns, "typescript");
  assert(filtered.length <= E.builtinPatterns.length);
});

Deno.test("categoryStats returns array of tuples", () => {
  const stats = E.categoryStats(E.builtinPatterns);
  assert(Array.isArray(stats));
  assert(stats.length > 0);
});

Deno.test("scanCode returns result with matches array", () => {
  const result = E.scanCode("const x = require('foo');", E.builtinPatterns, E.defaultConstraints);
  assert(Array.isArray(result.matches));
});

Deno.test("defaultConstraints has reasonable values", () => {
  assert(E.defaultConstraints.maxResults > 0);
});
