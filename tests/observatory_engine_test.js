// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * ObservatoryEngine tests — integrative dashboard helpers.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as OE from "../src/core/ObservatoryEngine.res.js";

Deno.test("defaultState has TabOverview", () => {
  assertEquals(OE.defaultState.activeTab, "TabOverview");
});

Deno.test("defaultState has empty snapshots", () => {
  assertEquals(OE.defaultState.snapshots.length, 0);
});

Deno.test("allTabs has 4 entries", () => {
  assertEquals(OE.allTabs.length, 4);
});

Deno.test("tabLabel covers all tabs", () => {
  for (const tab of OE.allTabs) {
    assert(OE.tabLabel(tab).length > 0);
  }
});

Deno.test("healthLabel for Healthy", () => {
  assertEquals(OE.healthLabel("Healthy"), "Healthy");
});

Deno.test("healthLabel for Unreachable", () => {
  assertEquals(OE.healthLabel("Unreachable"), "Unreachable");
});

Deno.test("countByHealth returns 0 for empty", () => {
  assertEquals(OE.countByHealth([], "Healthy"), 0);
});

Deno.test("totalMemory sums bytes", () => {
  const snapshots = [
    { panelId: "a", health: "Healthy", memoryBytes: 100, cpuPercent: 0.1, restartCount: 0, lastCheck: "now" },
    { panelId: "b", health: "Healthy", memoryBytes: 200, cpuPercent: 0.2, restartCount: 0, lastCheck: "now" },
  ];
  assertEquals(OE.totalMemory(snapshots), 300);
});
