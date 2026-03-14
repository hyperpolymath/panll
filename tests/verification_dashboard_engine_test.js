// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * VerificationDashboardEngine tests — proof/test/benchmark/fuzzing status.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as VD from "../src/core/VerificationDashboardEngine.res.js";

Deno.test("allLanguageStatuses has 16 languages", () => {
  assertEquals(VD.allLanguageStatuses.length, 16);
});

Deno.test("allLanguageStatuses entries have name", () => {
  for (const lang of VD.allLanguageStatuses) {
    assert(lang.name.length > 0);
  }
});

Deno.test("allCategories has entries", () => {
  assert(VD.allCategories.length > 0);
});

Deno.test("categoryLabel covers all categories", () => {
  for (const cat of VD.allCategories) {
    assert(VD.categoryLabel(cat).length > 0);
  }
});

Deno.test("proofSystemLabel covers Idris2Proof", () => {
  assert(VD.proofSystemLabel("Idris2Proof").length > 0);
});

Deno.test("proofSystemCode returns short codes", () => {
  assert(VD.proofSystemCode("Idris2Proof").length > 0);
  assert(VD.proofSystemCode("Idris2Proof").length <= 10);
});

Deno.test("proofSystemColour returns non-empty", () => {
  assert(VD.proofSystemColour("Idris2Proof").length > 0);
});

Deno.test("conformanceLabel covers levels", () => {
  assert(VD.conformanceLabel("FullConformance").length > 0);
  assert(VD.conformanceLabel("PartialConformance").length > 0);
  assert(VD.conformanceLabel("NoConformanceSuite").length > 0);
});

Deno.test("conformanceColour returns non-empty", () => {
  assert(VD.conformanceColour("FullConformance").length > 0);
});

Deno.test("passRate computes percentage", () => {
  const status = VD.allLanguageStatuses[0];
  const rate = VD.passRate(status);
  assert(rate >= 0 && rate <= 100);
});

Deno.test("passRateColour returns emerald for high rate", () => {
  assert(VD.passRateColour(95).includes("emerald"));
});

Deno.test("admittedColour returns emerald for 0", () => {
  assert(VD.admittedColour(0).includes("emerald"));
});

Deno.test("admittedColour returns non-emerald for high count", () => {
  assert(!VD.admittedColour(10).includes("emerald"));
});

Deno.test("progressBar returns 10-char string", () => {
  assertEquals(VD.progressBar(50).length, 10);
});

Deno.test("filterBySearch with empty returns all", () => {
  assertEquals(VD.filterBySearch(VD.allLanguageStatuses, "").length, 16);
});

Deno.test("filterBySearch narrows results", () => {
  const filtered = VD.filterBySearch(VD.allLanguageStatuses, "eclexia");
  assert(filtered.length > 0);
  assert(filtered.length < 16);
});

Deno.test("filterDebtOnly returns languages with debt", () => {
  const debt = VD.filterDebtOnly(VD.allLanguageStatuses);
  for (const l of debt) {
    assert(l.admittedCount > 0 || l.failingTests > 0);
  }
});

Deno.test("sortLanguages returns same count", () => {
  const sorted = VD.sortLanguages(VD.allLanguageStatuses, "VdSortByPassRate");
  assertEquals(sorted.length, 16);
});

Deno.test("sortLabel covers VdSortByName", () => {
  assert(VD.sortLabel("VdSortByName").length > 0);
});

Deno.test("sortLabel covers VdSortByTests", () => {
  assert(VD.sortLabel("VdSortByTests").length > 0);
});

Deno.test("computeSummary returns valid stats", () => {
  const summary = VD.computeSummary(VD.allLanguageStatuses);
  assertEquals(summary.totalLanguages, 16);
  assert(summary.totalTests > 0);
  assert(summary.avgPassRate >= 0 && summary.avgPassRate <= 100);
});

Deno.test("findLanguage returns matching entry", () => {
  const found = VD.findLanguage("Eclexia");
  assert(found !== undefined);
});

Deno.test("findLanguage returns undefined for unknown", () => {
  assertEquals(VD.findLanguage("NonexistentLang"), undefined);
});

Deno.test("allBenchmarks returns array", () => {
  assert(Array.isArray(VD.allBenchmarks()));
});

Deno.test("allFuzzingCoverage returns array", () => {
  assert(Array.isArray(VD.allFuzzingCoverage()));
});
