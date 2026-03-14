// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * AssetManagerEngine Tests — default state, tab labels, file size formatting,
 * asset counting, and filtering.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countByKind,
  totalSizeBytes,
  formatFileSize,
  filterAssets,
} from "../src/core/AssetManagerEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.assets.length, 0);
  assertEquals(defaultState.collections.length, 0);
  assertEquals(defaultState.filter, "");
  assertEquals(defaultState.importing, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Browse"), "Browse");
  assertEquals(tabLabel("Import"), "Import");
  assertEquals(tabLabel("Collections"), "Collections");
  assertEquals(tabLabel("Usage"), "Usage");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- formatFileSize --

Deno.test("formatFileSize formats bytes correctly", () => {
  assertEquals(formatFileSize(500), "500 B");
});

Deno.test("formatFileSize formats kilobytes correctly", () => {
  const result = formatFileSize(2048);
  assertEquals(result, "2.0 KB");
});

Deno.test("formatFileSize formats megabytes correctly", () => {
  const result = formatFileSize(5242880);
  assertEquals(result, "5.0 MB");
});

// -- totalSizeBytes with empty array --

Deno.test("totalSizeBytes returns 0 for empty array", () => {
  assertEquals(totalSizeBytes([]), 0);
});

// -- countByKind with empty array --

Deno.test("countByKind returns 0 for empty array", () => {
  assertEquals(countByKind([], "Sprite"), 0);
});

// -- filterAssets with empty array --

Deno.test("filterAssets returns empty for empty array", () => {
  assertEquals(filterAssets([], "", undefined).length, 0);
});
