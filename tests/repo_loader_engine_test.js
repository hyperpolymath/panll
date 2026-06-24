// SPDX-License-Identifier: MPL-2.0

/**
 * RepoLoaderEngine Tests — categories, filtering, suggestions, parsing
 */

import { assertEquals } from "jsr:@std/assert";
import {
  categoryLabel,
  allCategories,
  priorityColour,
  enabledSuggestions,
  enabledCount,
  filterRecent,
  defaultState,
  parseScanResult,
  parseRecentPaths,
} from "../src/core/RepoLoaderEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("Browse"), "Browse");
  assertEquals(categoryLabel("Configure"), "Configure");
  assertEquals(categoryLabel("Recent"), "Recent");
  assertEquals(categoryLabel("FarmSearch"), "Farm Search");
});

// -- allCategories --

Deno.test("allCategories has 4 entries", () => {
  assertEquals(allCategories.length, 4);
});

// -- priorityColour --

Deno.test("priorityColour returns correct classes", () => {
  assertEquals(priorityColour("critical"), "bg-red-500/20 text-red-300");
  assertEquals(priorityColour("high"), "bg-orange-500/20 text-orange-300");
  assertEquals(priorityColour("medium"), "bg-amber-500/20 text-amber-300");
  assertEquals(priorityColour("low"), "bg-gray-500/20 text-gray-300");
});

// -- enabledSuggestions / enabledCount --

Deno.test("enabledSuggestions filters enabled", () => {
  const suggestions = [{ enabled: true }, { enabled: false }, { enabled: true }];
  assertEquals(enabledSuggestions(suggestions).length, 2);
});

Deno.test("enabledCount counts enabled", () => {
  const suggestions = [{ enabled: true }, { enabled: false }];
  assertEquals(enabledCount(suggestions), 1);
});

// -- filterRecent --

Deno.test("filterRecent returns all when query empty", () => {
  const paths = ["/a/b", "/c/d"];
  assertEquals(filterRecent(paths, "").length, 2);
});

Deno.test("filterRecent filters by path", () => {
  const paths = ["/repos/panll", "/repos/other"];
  assertEquals(filterRecent(paths, "panll").length, 1);
});

// -- parseScanResult --

Deno.test("parseScanResult parses valid JSON", () => {
  const json = JSON.stringify({
    repo: {
      path: "/repos/panll",
      name: "panll",
      description: "PanLL",
      languages: ["ReScript"],
      has_machine_readable: true,
      has_panels_manifest: false,
      has_ai_manifest: true,
      has_state: true,
    },
    suggestions: [
      { panel_name: "Farm", reason: "repo detected", priority: "high", enabled: true },
    ],
  });
  const result = parseScanResult(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0[0].name, "panll");
  assertEquals(result._0[1].length, 1);
  assertEquals(result._0[1][0].panelName, "Farm");
});

Deno.test("parseScanResult returns error for invalid JSON", () => {
  assertEquals(parseScanResult("bad").TAG, "Error");
});

Deno.test("parseScanResult returns error for non-object", () => {
  assertEquals(parseScanResult('"string"').TAG, "Error");
});

// -- parseRecentPaths --

Deno.test("parseRecentPaths parses valid JSON", () => {
  const json = JSON.stringify({
    repos: [{ path: "/repos/panll" }, { path: "/repos/other" }],
  });
  const result = parseRecentPaths(json);
  assertEquals(result.length, 2);
  assertEquals(result[0], "/repos/panll");
});

Deno.test("parseRecentPaths returns empty for invalid JSON", () => {
  assertEquals(parseRecentPaths("bad").length, 0);
});

Deno.test("parseRecentPaths returns empty for missing repos key", () => {
  assertEquals(parseRecentPaths("{}").length, 0);
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.currentRepo, undefined);
  assertEquals(defaultState.suggestions.length, 0);
  assertEquals(defaultState.recentPaths.length, 0);
  assertEquals(defaultState.activeCategory, "Browse");
  assertEquals(defaultState.scanning, false);
  assertEquals(defaultState.saved, true);
});
