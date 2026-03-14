// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * SpecBrowserEngine tests — language specification browsing and comparison.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as SB from "../src/core/SpecBrowserEngine.res.js";

Deno.test("allLanguageSpecs has 16 languages", () => {
  assertEquals(SB.allLanguageSpecs.length, 16);
});

Deno.test("allLanguageSpecs entries have name and files", () => {
  for (const lang of SB.allLanguageSpecs) {
    assert(lang.name.length > 0);
    assert(Array.isArray(lang.files));
    assert(lang.files.length > 0);
  }
});

Deno.test("allLanguageNames has 16 entries", () => {
  assertEquals(SB.allLanguageNames.length, 16);
});

Deno.test("allFileKinds has entries", () => {
  assert(SB.allFileKinds.length > 0);
});

Deno.test("fileKindLabel covers all kinds", () => {
  for (const kind of SB.allFileKinds) {
    assert(SB.fileKindLabel(kind).length > 0);
  }
});

Deno.test("fileKindCode covers all kinds", () => {
  for (const kind of SB.allFileKinds) {
    assert(SB.fileKindCode(kind).length > 0);
  }
});

Deno.test("fileKindPath covers all kinds", () => {
  for (const kind of SB.allFileKinds) {
    assert(SB.fileKindPath(kind).length > 0);
  }
});

Deno.test("allCategories has entries", () => {
  assert(SB.allCategories.length > 0);
});

Deno.test("categoryLabel covers all categories", () => {
  for (const cat of SB.allCategories) {
    assert(SB.categoryLabel(cat).length > 0);
  }
});

Deno.test("presenceColour returns emerald for true", () => {
  assert(SB.presenceColour(true).includes("emerald"));
});

Deno.test("presenceColour returns non-emerald for false", () => {
  assert(!SB.presenceColour(false).includes("emerald"));
});

Deno.test("completenessColour returns emerald for high pct", () => {
  assert(SB.completenessColour(90).includes("emerald"));
});

Deno.test("completenessColour returns red for low pct", () => {
  assert(SB.completenessColour(20).includes("red"));
});

Deno.test("progressBar returns 10-char string", () => {
  const bar = SB.progressBar(50);
  assertEquals(bar.length, 10); // 10 unicode chars
});

Deno.test("filterBySearch with empty returns all", () => {
  assertEquals(SB.filterBySearch(SB.allLanguageSpecs, "").length, 16);
});

Deno.test("filterBySearch narrows results", () => {
  const filtered = SB.filterBySearch(SB.allLanguageSpecs, "eclexia");
  assert(filtered.length > 0);
  assert(filtered.length < 16);
});

Deno.test("filterIncomplete returns only incomplete langs", () => {
  const incomplete = SB.filterIncomplete(SB.allLanguageSpecs);
  for (const l of incomplete) {
    assert(l.taxonomyCompleteness < 100);
  }
});

Deno.test("sortByCompleteness sorts ascending", () => {
  const sorted = SB.sortByCompleteness(SB.allLanguageSpecs);
  for (let i = 1; i < sorted.length; i++) {
    assert(sorted[i].taxonomyCompleteness >= sorted[i - 1].taxonomyCompleteness);
  }
});

Deno.test("sortByName sorts alphabetically", () => {
  const sorted = SB.sortByName(SB.allLanguageSpecs);
  for (let i = 1; i < sorted.length; i++) {
    assert(sorted[i].name.toLowerCase() >= sorted[i - 1].name.toLowerCase());
  }
});

Deno.test("findLanguage returns matching entry", () => {
  const found = SB.findLanguage("Eclexia");
  assert(found !== undefined);
});

Deno.test("findLanguage returns undefined for unknown", () => {
  assertEquals(SB.findLanguage("NonexistentLang"), undefined);
});

Deno.test("portfolioSummary returns valid stats", () => {
  const stats = SB.portfolioSummary();
  assertEquals(stats.totalLanguages, 16);
  assert(stats.avgCompleteness >= 0 && stats.avgCompleteness <= 100);
  assert(stats.totalTests > 0);
});

Deno.test("computeTaxonomyCompleteness returns 0-100", () => {
  const files = [
    SB.mkFile("GrammarEbnf", true, 100),
    SB.mkFile("SpecCoreScm", false, 0),
  ];
  const pct = SB.computeTaxonomyCompleteness(files);
  assert(pct >= 0 && pct <= 100);
});

Deno.test("emptyVerification has all zeros", () => {
  assertEquals(SB.emptyVerification.totalTests, 0);
  assertEquals(SB.emptyVerification.admittedCount, 0);
});
