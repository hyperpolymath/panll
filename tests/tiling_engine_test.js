// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * TilingEngine Tests — default state, snap zone labels and CSS, preset labels,
 * detached panel management, and dead-marking logic.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  defaultState,
  snapZoneLabel,
  snapZoneCss,
  presetLabel,
  isDetached,
  addDetachedPanel,
  removeDetachedPanel,
  markDetachedDead,
} from "../src/core/TilingEngine.res.js";

// -- defaultState --

Deno.test("defaultState has expected initial values", () => {
  assert(Array.isArray(defaultState.detachedPanels), "detachedPanels should be an array");
  assertEquals(defaultState.detachedPanels.length, 0);
  assertEquals(defaultState.activePreset, undefined);
  assertEquals(defaultState.snapPreview, undefined);
  assertEquals(defaultState.tilingEnabled, false);
  assertEquals(defaultState.controlsVisible, false);
});

// -- snapZoneLabel --

Deno.test("snapZoneLabel returns correct strings for all zones", () => {
  assertEquals(snapZoneLabel("SnapLeft"), "Left Half");
  assertEquals(snapZoneLabel("SnapRight"), "Right Half");
  assertEquals(snapZoneLabel("SnapTopLeft"), "Top Left Quarter");
  assertEquals(snapZoneLabel("SnapTopRight"), "Top Right Quarter");
  assertEquals(snapZoneLabel("SnapBottomLeft"), "Bottom Left Quarter");
  assertEquals(snapZoneLabel("SnapBottomRight"), "Bottom Right Quarter");
  assertEquals(snapZoneLabel("SnapFull"), "Full Screen");
  assertEquals(snapZoneLabel("SnapCentre"), "Centre Floating");
});

// -- snapZoneCss --

Deno.test("snapZoneCss returns correct Tailwind classes for all zones", () => {
  assertEquals(snapZoneCss("SnapLeft"), "left-0 top-0 w-1/2 h-full");
  assertEquals(snapZoneCss("SnapRight"), "right-0 top-0 w-1/2 h-full");
  assertEquals(snapZoneCss("SnapTopLeft"), "left-0 top-0 w-1/2 h-1/2");
  assertEquals(snapZoneCss("SnapTopRight"), "right-0 top-0 w-1/2 h-1/2");
  assertEquals(snapZoneCss("SnapBottomLeft"), "left-0 bottom-0 w-1/2 h-1/2");
  assertEquals(snapZoneCss("SnapBottomRight"), "right-0 bottom-0 w-1/2 h-1/2");
  assertEquals(snapZoneCss("SnapFull"), "left-0 top-0 w-full h-full");
  assertEquals(snapZoneCss("SnapCentre"), "left-1/4 top-1/4 w-1/2 h-1/2");
});

// -- presetLabel --

Deno.test("presetLabel returns correct strings for named presets", () => {
  assertEquals(presetLabel("SideBySide"), "Side by Side (50/50)");
  assertEquals(presetLabel("TripleColumn"), "Triple Column (33/33/33)");
  assertEquals(presetLabel("QuadGrid"), "Quad Grid (2x2)");
  assertEquals(presetLabel("FocusAndSidebar"), "Focus + Sidebar (75/25)");
});

Deno.test("presetLabel returns custom label for Custom preset", () => {
  const custom = { TAG: undefined, _0: ["a", "b", "c"] };
  // Custom variant is an object with _0 being the panel array
  const result = presetLabel(custom);
  assertEquals(result, "Custom (3 panels)");
});

// -- isDetached --

Deno.test("isDetached returns false when no panels are detached", () => {
  assertEquals(isDetached("panel-l", defaultState), false);
});

Deno.test("isDetached returns true for a detached panel", () => {
  const state = {
    ...defaultState,
    detachedPanels: [{ panelId: "panel-l", windowName: "win1", position: undefined, size: undefined, alive: true }],
  };
  assertEquals(isDetached("panel-l", state), true);
});

Deno.test("isDetached returns false for a non-detached panel", () => {
  const state = {
    ...defaultState,
    detachedPanels: [{ panelId: "panel-l", windowName: "win1", position: undefined, size: undefined, alive: true }],
  };
  assertEquals(isDetached("panel-n", state), false);
});

// -- addDetachedPanel --

Deno.test("addDetachedPanel adds a new detached panel entry", () => {
  const result = addDetachedPanel("panel-l", "win1", defaultState);
  assertEquals(result.detachedPanels.length, 1);
  assertEquals(result.detachedPanels[0].panelId, "panel-l");
  assertEquals(result.detachedPanels[0].windowName, "win1");
  assertEquals(result.detachedPanels[0].alive, true);
  assertEquals(result.detachedPanels[0].position, undefined);
  assertEquals(result.detachedPanels[0].size, undefined);
});

Deno.test("addDetachedPanel replaces existing entry for same panelId", () => {
  const state = addDetachedPanel("panel-l", "win1", defaultState);
  const result = addDetachedPanel("panel-l", "win2", state);
  assertEquals(result.detachedPanels.length, 1);
  assertEquals(result.detachedPanels[0].windowName, "win2");
});

Deno.test("addDetachedPanel preserves other state fields", () => {
  const state = { ...defaultState, tilingEnabled: true, controlsVisible: true };
  const result = addDetachedPanel("panel-l", "win1", state);
  assertEquals(result.tilingEnabled, true);
  assertEquals(result.controlsVisible, true);
});

// -- removeDetachedPanel --

Deno.test("removeDetachedPanel removes by windowName", () => {
  const state = addDetachedPanel("panel-l", "win1", defaultState);
  const result = removeDetachedPanel("win1", state);
  assertEquals(result.detachedPanels.length, 0);
});

Deno.test("removeDetachedPanel leaves other panels intact", () => {
  let state = addDetachedPanel("panel-l", "win1", defaultState);
  state = addDetachedPanel("panel-n", "win2", state);
  const result = removeDetachedPanel("win1", state);
  assertEquals(result.detachedPanels.length, 1);
  assertEquals(result.detachedPanels[0].panelId, "panel-n");
});

Deno.test("removeDetachedPanel is a no-op for unknown windowName", () => {
  const state = addDetachedPanel("panel-l", "win1", defaultState);
  const result = removeDetachedPanel("nonexistent", state);
  assertEquals(result.detachedPanels.length, 1);
});

// -- markDetachedDead --

Deno.test("markDetachedDead sets alive to false for matching window", () => {
  const state = addDetachedPanel("panel-l", "win1", defaultState);
  const result = markDetachedDead("win1", state);
  assertEquals(result.detachedPanels.length, 1);
  assertEquals(result.detachedPanels[0].alive, false);
  assertEquals(result.detachedPanels[0].panelId, "panel-l");
});

Deno.test("markDetachedDead does not affect other windows", () => {
  let state = addDetachedPanel("panel-l", "win1", defaultState);
  state = addDetachedPanel("panel-n", "win2", state);
  const result = markDetachedDead("win1", state);
  assertEquals(result.detachedPanels[0].alive, false);
  assertEquals(result.detachedPanels[1].alive, true);
});
