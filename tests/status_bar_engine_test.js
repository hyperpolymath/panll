// SPDX-License-Identifier: MPL-2.0

/**
 * StatusBarEngine tests — widget registry, layout, formatting.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as SB from "../src/core/StatusBarEngine.res.js";

Deno.test("defaultState has widgets array", () => {
  assert(SB.defaultState.widgets.length > 0);
});

Deno.test("defaultState visible is true", () => {
  assertEquals(SB.defaultState.visible, true);
});

Deno.test("defaultWidgets has 13 widgets", () => {
  assertEquals(SB.defaultWidgets.length, 13);
});

Deno.test("defaultWidgets all have id and label", () => {
  for (const w of SB.defaultWidgets) {
    assert(w.id.length > 0);
    assert(w.label.length > 0);
  }
});

Deno.test("toggleWidget flips visibility", () => {
  const toggled = SB.toggleWidget(SB.defaultState, "cpu-usage");
  const widget = toggled.widgets.find(w => w.id === "cpu-usage");
  assertEquals(widget.visible, false);
});

Deno.test("toggleWidget twice restores original", () => {
  const once = SB.toggleWidget(SB.defaultState, "cpu-usage");
  const twice = SB.toggleWidget(once, "cpu-usage");
  const widget = twice.widgets.find(w => w.id === "cpu-usage");
  assertEquals(widget.visible, true);
});

Deno.test("moveWidget changes position", () => {
  const moved = SB.moveWidget(SB.defaultState, "cpu-usage", "Left");
  const widget = moved.widgets.find(w => w.id === "cpu-usage");
  assertEquals(widget.position, "Left");
});

Deno.test("reorderWidget changes order", () => {
  const reordered = SB.reorderWidget(SB.defaultState, "cpu-usage", 99);
  const widget = reordered.widgets.find(w => w.id === "cpu-usage");
  assertEquals(widget.order, 99);
});

Deno.test("widgetsForPosition returns sorted visible widgets", () => {
  const left = SB.widgetsForPosition(SB.defaultWidgets, "Left");
  assert(left.length > 0);
  for (const w of left) {
    assertEquals(w.position, "Left");
    assertEquals(w.visible, true);
  }
  for (let i = 1; i < left.length; i++) {
    assert(left[i].order >= left[i - 1].order);
  }
});

Deno.test("widgetsForPosition excludes hidden widgets", () => {
  const right = SB.widgetsForPosition(SB.defaultWidgets, "Right");
  for (const w of right) {
    assertEquals(w.visible, true);
  }
});

Deno.test("formatBytes formats GB", () => {
  assert(SB.formatBytes(2147483648.0).includes("GB"));
});

Deno.test("formatBytes formats MB", () => {
  assert(SB.formatBytes(52428800.0).includes("MB"));
});

Deno.test("formatBytes formats KB", () => {
  assert(SB.formatBytes(4096.0).includes("KB"));
});

Deno.test("formatBytes formats bytes", () => {
  assert(SB.formatBytes(512.0).includes("B"));
});

Deno.test("formatUptime hours and minutes", () => {
  assertEquals(SB.formatUptime(3660.0), "1h 1m");
});

Deno.test("formatUptime minutes only", () => {
  assertEquals(SB.formatUptime(300.0), "5m");
});

Deno.test("formatUptime zero", () => {
  assertEquals(SB.formatUptime(0.0), "0m");
});

Deno.test("updateSystemInfo stores info", () => {
  const info = { cpuUsage: 0.5, memoryUsed: 4096, memoryTotal: 8192, diskUsed: 100000, diskTotal: 500000, uptime: 3600.0 };
  const updated = SB.updateSystemInfo(SB.defaultState, info);
  assert(updated.systemInfo !== undefined);
});
