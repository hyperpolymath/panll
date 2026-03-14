// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * ArchitectModeEngine Tests — default state, tab labels, tool labels,
 * entity counting, undo/redo availability.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  toolLabel,
  countSelectedEntities,
  countEntitiesByKind,
  canUndo,
  canRedo,
} from "../src/core/ArchitectModeEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.entities.length, 0);
  assertEquals(defaultState.zones.length, 0);
  assertEquals(defaultState.gridVisible, true);
  assertEquals(defaultState.snapToGrid, true);
  assertEquals(defaultState.gridSize, 32);
  assertEquals(defaultState.zoom, 1.0);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Canvas"), "Canvas");
  assertEquals(tabLabel("Properties"), "Properties");
  assertEquals(tabLabel("AiSuggestions"), "AI Suggestions");
  assertEquals(tabLabel("Validation"), "Validation");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- toolLabel --

Deno.test("toolLabel returns correct labels for simple tools", () => {
  assertEquals(toolLabel("SelectTool"), "Select");
  assertEquals(toolLabel("EraseTool"), "Erase");
  assertEquals(toolLabel("WireTool"), "Wire");
  assertEquals(toolLabel("ZoneTool"), "Zone");
  assertEquals(toolLabel("PanTool"), "Pan");
});

// -- countSelectedEntities with empty array --

Deno.test("countSelectedEntities returns 0 for empty array", () => {
  assertEquals(countSelectedEntities([]), 0);
});

// -- canUndo / canRedo --

Deno.test("canUndo returns false for default state", () => {
  assertEquals(canUndo(defaultState), false);
});

Deno.test("canRedo returns false for default state", () => {
  assertEquals(canRedo(defaultState), false);
});
