// SPDX-License-Identifier: MPL-2.0

/**
 * LanguageForgeEngine tests — language portfolio assessment and filtering.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as LF from "../src/core/LanguageForgeEngine.res.js";

Deno.test("defaultState has loaded field", () => {
  assertEquals(typeof LF.defaultState.loaded, "boolean");
});

Deno.test("allCategories has entries", () => {
  assert(LF.allCategories.length > 0);
});

Deno.test("categoryLabel covers all categories", () => {
  for (const cat of LF.allCategories) {
    assert(LF.categoryLabel(cat).length > 0);
  }
});

Deno.test("languageData returns non-empty array", () => {
  const data = LF.languageData();
  assert(data.length > 0);
});

Deno.test("languageData entries have name and phase", () => {
  const data = LF.languageData();
  for (const lang of data) {
    assert(lang.name.length > 0);
    assert(lang.phase !== undefined);
  }
});

Deno.test("phaseLabel covers all phases", () => {
  const phases = ["Production", "NearProduction", "Alpha", "DesignOnly", "Concept", "Vaporware"];
  for (const p of phases) {
    const label = LF.phaseLabel(p);
    assert(typeof label === "string");
    assert(label.length > 0);
  }
});

Deno.test("phaseColor returns non-empty string", () => {
  assert(LF.phaseColor("Production").length > 0);
});

Deno.test("filterLanguages with AllLanguages and empty query returns all", () => {
  const data = LF.languageData();
  const filtered = LF.filterLanguages(data, "AllLanguages", "");
  assertEquals(filtered.length, data.length);
});

Deno.test("filterLanguages narrows by text", () => {
  const data = LF.languageData();
  const filtered = LF.filterLanguages(data, "AllLanguages", "rescript");
  assert(filtered.length > 0);
  assert(filtered.length < data.length);
});

Deno.test("sortLanguages by name returns same count", () => {
  const data = LF.languageData();
  const sorted = LF.sortLanguages(data, "SortByName");
  assertEquals(sorted.length, data.length);
});

Deno.test("sortLabel covers sort options", () => {
  assert(LF.sortLabel("SortByName").length > 0);
  assert(LF.sortLabel("SortByPhase").length > 0);
  assert(LF.sortLabel("SortByScore").length > 0);
});

Deno.test("phaseRank orders Production before Concept", () => {
  assert(LF.phaseRank("Production") < LF.phaseRank("Concept"));
});
