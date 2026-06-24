// SPDX-License-Identifier: MPL-2.0

/**
 * StatusBarEngine Tests — widgets, formatting, positioning, default state
 */

import { assertEquals } from "jsr:@std/assert";
import {
  defaultWidgets,
  toggleWidget,
  moveWidget,
  widgetsForPosition,
  formatBytes,
  formatUptime,
  defaultState,
} from "../src/core/StatusBarEngine.res.js";

// -- defaultWidgets --

Deno.test("defaultWidgets has 13 entries", () => {
  assertEquals(defaultWidgets.length, 13);
});

Deno.test("defaultWidgets first is active-panel", () => {
  assertEquals(defaultWidgets[0].id, "active-panel");
  assertEquals(defaultWidgets[0].position, "Left");
});

// -- toggleWidget --

Deno.test("toggleWidget flips visibility", () => {
  const result = toggleWidget(defaultState, "disk-usage");
  const widget = result.widgets.find(w => w.id === "disk-usage");
  assertEquals(widget.visible, true);
});

// -- moveWidget --

Deno.test("moveWidget changes position", () => {
  const result = moveWidget(defaultState, "cpu-usage", "Left");
  const widget = result.widgets.find(w => w.id === "cpu-usage");
  assertEquals(widget.position, "Left");
});

// -- widgetsForPosition --

Deno.test("widgetsForPosition returns visible Left widgets sorted", () => {
  const left = widgetsForPosition(defaultWidgets, "Left");
  assertEquals(left.length, 4);
  assertEquals(left[0].id, "active-panel");
});

Deno.test("widgetsForPosition returns visible Right widgets", () => {
  const right = widgetsForPosition(defaultWidgets, "Right");
  assertEquals(right.length, 3);
});

// -- formatBytes --

Deno.test("formatBytes formats bytes", () => {
  assertEquals(formatBytes(500.0), "500 B");
});

Deno.test("formatBytes formats kilobytes", () => {
  assertEquals(formatBytes(2048.0), "2 KB");
});

Deno.test("formatBytes formats megabytes", () => {
  assertEquals(formatBytes(5242880.0), "5 MB");
});

Deno.test("formatBytes formats gigabytes", () => {
  assertEquals(formatBytes(1073741824.0), "1.0 GB");
});

// -- formatUptime --

Deno.test("formatUptime minutes only", () => {
  assertEquals(formatUptime(300.0), "5m");
});

Deno.test("formatUptime hours and minutes", () => {
  assertEquals(formatUptime(3660.0), "1h 1m");
});

// -- defaultState --

Deno.test("defaultState visible is true", () => {
  assertEquals(defaultState.visible, true);
});

Deno.test("defaultState systemInfo is undefined", () => {
  assertEquals(defaultState.systemInfo, undefined);
});

Deno.test("defaultState perPanelBars is false", () => {
  assertEquals(defaultState.perPanelBars, false);
});
