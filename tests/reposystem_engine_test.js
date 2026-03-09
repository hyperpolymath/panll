// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * ReposystemEngine Tests — requirement labels, categories, filtering, stats, parsing
 */

import { assertEquals } from "jsr:@std/assert";
import {
  requirementLabel,
  categoryLabel,
  filterAudits,
  computeStats,
  parseAudits,
  defaultState,
} from "../src/core/ReposystemEngine.res.js";

// -- requirementLabel --

Deno.test("requirementLabel returns correct strings", () => {
  assertEquals(requirementLabel("EditorConfig"), ".editorconfig");
  assertEquals(requirementLabel("AiManifest"), "AI Manifest");
  assertEquals(requirementLabel("StateMachineReadable"), "STATE.scm");
  assertEquals(requirementLabel("Justfile"), "Justfile");
  assertEquals(requirementLabel("HypatiaScanWorkflow"), "hypatia-scan.yml");
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("RsrDashboard"), "Dashboard");
  assertEquals(categoryLabel("RsrRepoList"), "Repos");
  assertEquals(categoryLabel("RsrRequirements"), "Requirements");
  assertEquals(categoryLabel("RsrLanguagePolicy"), "Language Policy");
});

// -- filterAudits --

Deno.test("filterAudits returns all when query empty", () => {
  const audits = [{ repoName: "foo" }, { repoName: "bar" }];
  assertEquals(filterAudits(audits, "").length, 2);
});

Deno.test("filterAudits filters by repo name", () => {
  const audits = [{ repoName: "panll" }, { repoName: "other" }];
  assertEquals(filterAudits(audits, "panll").length, 1);
});

// -- computeStats --

Deno.test("computeStats returns correct stats for empty", () => {
  const stats = computeStats([]);
  assertEquals(stats.totalRepos, 0);
  assertEquals(stats.avgScore, 0.0);
  assertEquals(stats.fullyCompliant, 0);
});

Deno.test("computeStats computes averages", () => {
  const audits = [
    { score: 1.0, results: [{ requirement: "EditorConfig", met: true }] },
    { score: 0.5, results: [{ requirement: "EditorConfig", met: false }] },
  ];
  const stats = computeStats(audits);
  assertEquals(stats.totalRepos, 2);
  assertEquals(stats.avgScore, 0.75);
  assertEquals(stats.fullyCompliant, 1);
});

// -- parseAudits --

Deno.test("parseAudits parses valid JSON", () => {
  const json = JSON.stringify([
    { repo_name: "panll", score: 0.9, met_count: 8, total_count: 10 },
  ]);
  const result = parseAudits(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.length, 1);
  assertEquals(result._0[0].repoName, "panll");
});

Deno.test("parseAudits returns error for invalid JSON", () => {
  assertEquals(parseAudits("bad").TAG, "Error");
});

Deno.test("parseAudits returns error for non-array", () => {
  assertEquals(parseAudits('"string"').TAG, "Error");
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.loaded, false);
  assertEquals(defaultState.loading, false);
  assertEquals(defaultState.audits.length, 0);
  assertEquals(defaultState.activeCategory, "RsrDashboard");
  assertEquals(defaultState.filterText, "");
});
