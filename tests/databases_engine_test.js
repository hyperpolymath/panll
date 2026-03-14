// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * DatabasesEngine tests — verify pure logic for the unified database panel.
 *
 * Tests default state, module lookup, filtering, history, and display helpers.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as DatabasesEngine from "../src/core/DatabasesEngine.res.js";

Deno.test("DatabasesEngine.defaultState has 3 modules", () => {
  const state = DatabasesEngine.defaultState;
  assertEquals(state.modules.length, 3);
});

Deno.test("DatabasesEngine.defaultState selectedModule is verisimdb", () => {
  assertEquals(DatabasesEngine.defaultState.selectedModule, "verisimdb");
});

Deno.test("DatabasesEngine.defaultState activeCategory is DbDashboard", () => {
  assertEquals(DatabasesEngine.defaultState.activeCategory, "DbDashboard");
});

Deno.test("DatabasesEngine.defaultState has schema entities", () => {
  assert(DatabasesEngine.defaultState.schemaEntities.length > 0);
});

Deno.test("DatabasesEngine.findModule returns Some for verisimdb", () => {
  const result = DatabasesEngine.findModule(DatabasesEngine.defaultState, "verisimdb");
  assertEquals(result !== undefined, true);
});

Deno.test("DatabasesEngine.findModule returns undefined for unknown", () => {
  const result = DatabasesEngine.findModule(DatabasesEngine.defaultState, "nonexistent");
  assertEquals(result, undefined);
});

Deno.test("DatabasesEngine.selectedModuleState returns verisimdb by default", () => {
  const result = DatabasesEngine.selectedModuleState(DatabasesEngine.defaultState);
  assert(result !== undefined);
});

Deno.test("DatabasesEngine.connectedCount is 0 initially", () => {
  assertEquals(DatabasesEngine.connectedCount(DatabasesEngine.defaultState), 0);
});

Deno.test("DatabasesEngine.totalCapabilities counts across all modules", () => {
  const count = DatabasesEngine.totalCapabilities(DatabasesEngine.defaultState);
  assert(count > 0);
});

Deno.test("DatabasesEngine.filteredEntities returns all with empty filter", () => {
  const all = DatabasesEngine.filteredEntities(DatabasesEngine.defaultState);
  assertEquals(all.length, DatabasesEngine.defaultState.schemaEntities.length);
});

Deno.test("DatabasesEngine.filteredEntities filters by name", () => {
  const state = { ...DatabasesEngine.defaultState, filterText: "octad" };
  const filtered = DatabasesEngine.filteredEntities(state);
  assertEquals(filtered.length, 1);
  assertEquals(filtered[0].name, "octads");
});

Deno.test("DatabasesEngine.filteredEntities filters by kind", () => {
  const state = { ...DatabasesEngine.defaultState, filterText: "table" };
  const filtered = DatabasesEngine.filteredEntities(state);
  assertEquals(filtered.length, DatabasesEngine.defaultState.schemaEntities.length);
});

Deno.test("DatabasesEngine.addToHistory prepends entry", () => {
  const entry = { query: "SELECT 1", language: "VQL", timestamp: "2026-03-14T10:00:00Z", success: true, durationMs: 5.0 };
  const newState = DatabasesEngine.addToHistory(DatabasesEngine.defaultState, entry);
  assertEquals(newState.queryHistory.length, 1);
  assertEquals(newState.queryHistory[0].query, "SELECT 1");
});

Deno.test("DatabasesEngine.connectionLabel for Disconnected", () => {
  assertEquals(DatabasesEngine.connectionLabel("Disconnected"), "Disconnected");
});

Deno.test("DatabasesEngine.connectionLabel for Connected", () => {
  const result = DatabasesEngine.connectionLabel({ TAG: "Connected", _0: "http://localhost:4000" });
  assert(result.includes("localhost:4000"));
});

Deno.test("DatabasesEngine.connectionColour for Disconnected", () => {
  assert(DatabasesEngine.connectionColour("Disconnected").includes("gray"));
});

Deno.test("DatabasesEngine.moduleAccent for verisimdb is emerald", () => {
  assertEquals(DatabasesEngine.moduleAccent("verisimdb"), "#34d399");
});

Deno.test("DatabasesEngine.moduleAccent for quandledb is indigo", () => {
  assertEquals(DatabasesEngine.moduleAccent("quandledb"), "#818cf8");
});

Deno.test("DatabasesEngine.moduleIcon for verisimdb", () => {
  assertEquals(DatabasesEngine.moduleIcon("verisimdb"), "VDB");
});

Deno.test("DatabasesEngine.moduleIcon for unknown defaults to DB", () => {
  assertEquals(DatabasesEngine.moduleIcon("unknown"), "DB");
});
