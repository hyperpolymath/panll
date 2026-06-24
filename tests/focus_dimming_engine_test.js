// SPDX-License-Identifier: MPL-2.0

/**
 * FocusDimmingEngine Tests — default state, mode labels, override labels,
 * opacity conversion, panel opacity classes, throttle logic, interaction
 * recording, and override management.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  defaultState,
  modeLabel,
  overrideLabel,
  opacityToTailwind,
  getOverride,
  panelOpacityClass,
  shouldThrottle,
  recordInteraction,
  setOverride,
} from "../src/core/FocusDimmingEngine.res.js";

// -- defaultState --

Deno.test("defaultState has expected initial values", () => {
  assertEquals(defaultState.mode, "DimmingOff");
  assertEquals(defaultState.focusedPane, undefined);
  assertEquals(defaultState.dimOpacity, 0.4);
  assert(Array.isArray(defaultState.overrides), "overrides should be an array");
  assertEquals(defaultState.overrides.length, 0);
  assert(
    Array.isArray(defaultState.lastInteractionTimestamps),
    "lastInteractionTimestamps should be an array",
  );
  assertEquals(defaultState.lastInteractionTimestamps.length, 0);
});

// -- modeLabel --

Deno.test("modeLabel returns correct strings for all modes", () => {
  assertEquals(modeLabel("DimmingOff"), "Off");
  assertEquals(modeLabel("DimmingSubtle"), "Subtle (70% opacity)");
  assertEquals(modeLabel("DimmingStrong"), "Strong (40% opacity)");
  assertEquals(modeLabel("SmartMemory"), "Smart Memory (dim + throttle)");
});

// -- overrideLabel --

Deno.test("overrideLabel returns correct strings for all overrides", () => {
  assertEquals(overrideLabel("Default"), "Follow Global Mode");
  assertEquals(overrideLabel("AlwaysActive"), "Always Active");
  assertEquals(overrideLabel("AlwaysDimmed"), "Always Dimmed");
});

// -- opacityToTailwind --

Deno.test("opacityToTailwind converts 0.4 to opacity-40", () => {
  assertEquals(opacityToTailwind(0.4), "opacity-40");
});

Deno.test("opacityToTailwind converts 0.7 to opacity-70", () => {
  assertEquals(opacityToTailwind(0.7), "opacity-70");
});

Deno.test("opacityToTailwind returns empty string for full opacity", () => {
  assertEquals(opacityToTailwind(1.0), "");
});

Deno.test("opacityToTailwind returns opacity-0 for zero opacity", () => {
  assertEquals(opacityToTailwind(0.0), "opacity-0");
});

// -- getOverride --

Deno.test("getOverride returns Default when no overrides set", () => {
  assertEquals(getOverride("panel-l", defaultState), "Default");
});

Deno.test("getOverride returns the matching override", () => {
  const state = {
    ...defaultState,
    overrides: [["panel-l", "AlwaysActive"]],
  };
  assertEquals(getOverride("panel-l", state), "AlwaysActive");
});

Deno.test("getOverride returns Default for non-matching panel", () => {
  const state = {
    ...defaultState,
    overrides: [["panel-l", "AlwaysActive"]],
  };
  assertEquals(getOverride("panel-n", state), "Default");
});

// -- panelOpacityClass --

Deno.test("panelOpacityClass returns empty string when DimmingOff", () => {
  assertEquals(panelOpacityClass(defaultState, "panel-l"), "");
});

Deno.test("panelOpacityClass returns opacity-70 for DimmingSubtle on unfocused panel", () => {
  const state = { ...defaultState, mode: "DimmingSubtle", focusedPane: "panel-n" };
  assertEquals(panelOpacityClass(state, "panel-l"), "opacity-70");
});

Deno.test("panelOpacityClass returns empty string for focused panel", () => {
  const state = { ...defaultState, mode: "DimmingStrong", focusedPane: "panel-l" };
  assertEquals(panelOpacityClass(state, "panel-l"), "");
});

Deno.test("panelOpacityClass returns opacity-40 for DimmingStrong on unfocused panel", () => {
  const state = { ...defaultState, mode: "DimmingStrong", focusedPane: "panel-n" };
  assertEquals(panelOpacityClass(state, "panel-l"), "opacity-40");
});

// -- shouldThrottle --

Deno.test("shouldThrottle returns false when mode is not SmartMemory", () => {
  assertEquals(shouldThrottle(defaultState, "panel-l"), false);
  assertEquals(
    shouldThrottle({ ...defaultState, mode: "DimmingSubtle" }, "panel-l"),
    false,
  );
});

Deno.test("shouldThrottle returns false for focused panel in SmartMemory", () => {
  const state = { ...defaultState, mode: "SmartMemory", focusedPane: "panel-l" };
  assertEquals(shouldThrottle(state, "panel-l"), false);
});

Deno.test("shouldThrottle returns true for unfocused panel in SmartMemory", () => {
  const state = { ...defaultState, mode: "SmartMemory", focusedPane: "panel-n" };
  assertEquals(shouldThrottle(state, "panel-l"), true);
});

// -- recordInteraction --

Deno.test("recordInteraction sets focusedPane and adds timestamp", () => {
  const result = recordInteraction(defaultState, "panel-l", 12345.0);
  assertEquals(result.focusedPane, "panel-l");
  assertEquals(result.lastInteractionTimestamps.length, 1);
  assertEquals(result.lastInteractionTimestamps[0][0], "panel-l");
  assertEquals(result.lastInteractionTimestamps[0][1], 12345.0);
});

Deno.test("recordInteraction replaces existing timestamp for same panel", () => {
  const state = {
    ...defaultState,
    lastInteractionTimestamps: [["panel-l", 100.0]],
  };
  const result = recordInteraction(state, "panel-l", 200.0);
  assertEquals(result.lastInteractionTimestamps.length, 1);
  assertEquals(result.lastInteractionTimestamps[0][1], 200.0);
});

Deno.test("recordInteraction preserves timestamps for other panels", () => {
  const state = {
    ...defaultState,
    lastInteractionTimestamps: [["panel-n", 100.0]],
  };
  const result = recordInteraction(state, "panel-l", 200.0);
  assertEquals(result.lastInteractionTimestamps.length, 2);
});

// -- setOverride --

Deno.test("setOverride adds AlwaysActive override", () => {
  const result = setOverride("panel-l", "AlwaysActive", defaultState);
  assertEquals(result.overrides.length, 1);
  assertEquals(result.overrides[0][0], "panel-l");
  assertEquals(result.overrides[0][1], "AlwaysActive");
});

Deno.test("setOverride removes override when set to Default", () => {
  const state = {
    ...defaultState,
    overrides: [["panel-l", "AlwaysActive"]],
  };
  const result = setOverride("panel-l", "Default", state);
  assertEquals(result.overrides.length, 0);
});

Deno.test("setOverride replaces existing override for same panel", () => {
  const state = {
    ...defaultState,
    overrides: [["panel-l", "AlwaysActive"]],
  };
  const result = setOverride("panel-l", "AlwaysDimmed", state);
  assertEquals(result.overrides.length, 1);
  assertEquals(result.overrides[0][1], "AlwaysDimmed");
});

Deno.test("setOverride preserves other panel overrides", () => {
  const state = {
    ...defaultState,
    overrides: [["panel-n", "AlwaysActive"]],
  };
  const result = setOverride("panel-l", "AlwaysDimmed", state);
  assertEquals(result.overrides.length, 2);
});
