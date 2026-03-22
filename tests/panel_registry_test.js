// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * PanelRegistry Tests — panel lookup, clade queries, registry integrity
 *
 * ReScript option<T>: Some(x) → x, None → undefined
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  allPanels,
  findPanel,
  panelName,
  defaultOrder,
  panelCladeId,
  panelsInClade,
  init,
} from "../src/modules/PanelRegistry.res.js";

Deno.test("allPanels has 88 entries", () => {
  assertEquals(allPanels.length, 88);
});

Deno.test("every panel has required fields", () => {
  for (const panel of allPanels) {
    assertExists(panel.id, `Panel missing id`);
    assertExists(panel.name, `Panel ${panel.id} missing name`);
    assertExists(panel.shortName, `Panel ${panel.id} missing shortName`);
    assertExists(panel.description, `Panel ${panel.id} missing description`);
    assertExists(panel.icon, `Panel ${panel.id} missing icon`);
  }
});

Deno.test("every panel id is unique", () => {
  const ids = allPanels.map((p) => p.id);
  const unique = new Set(ids);
  assertEquals(unique.size, ids.length);
});

Deno.test("findPanel returns panel for known id", () => {
  const result = findPanel("PanelBoj");
  assertExists(result);
  assertEquals(result.name, "BoJ");
});

Deno.test("findPanel returns undefined for unknown panel", () => {
  const result = findPanel("PanelNonexistent");
  assertEquals(result, undefined);
});

Deno.test("panelName returns name for known panel", () => {
  assertEquals(panelName("PanelCloudGuard"), "CloudGuard");
  assertEquals(panelName("PanelVab"), "VAB");
  assertEquals(panelName("PanelBoj"), "BoJ");
});

Deno.test("panelName returns Unknown for missing panel", () => {
  assertEquals(panelName("PanelFake"), "Unknown");
});

Deno.test("defaultOrder has same length as allPanels", () => {
  assertEquals(defaultOrder.length, allPanels.length);
});

Deno.test("panelCladeId returns clade ID for known panel", () => {
  const cladeId = panelCladeId("PanelBoj");
  assertEquals(cladeId, "boj");
});

Deno.test("panelCladeId returns undefined for unknown panel", () => {
  const cladeId = panelCladeId("PanelNonExistent");
  assertEquals(cladeId, undefined);
});

Deno.test("panelsInClade returns panels for known clade", () => {
  const panels = panelsInClade("boj");
  assertEquals(panels.length, 1);
  assertEquals(panels[0].id, "PanelBoj");
});

Deno.test("panelsInClade returns empty for unknown clade", () => {
  const panels = panelsInClade("nonexistent");
  assertEquals(panels.length, 0);
});

Deno.test("init has correct structure", () => {
  assertExists(init);
  assertEquals(init.activePanel, undefined);
  assertEquals(init.panelOrder.length, allPanels.length);
  assertEquals(init.panels.length, allPanels.length);
});

Deno.test("BoJ panel metadata is correct", () => {
  const boj = findPanel("PanelBoj");
  assertEquals(boj.shortName, "BoJ");
  assertEquals(boj.icon, "box");
  assertEquals(boj.hasBackend, true);
  assertEquals(boj.cladeId, "boj");
});

// ════════════════════════════════════════════════════════════════════════
// Game Server Admin panel tests
// ════════════════════════════════════════════════════════════════════════

Deno.test("GSA Server Browser panel exists", () => {
  const panel = findPanel("PanelGsaServerBrowser");
  assertExists(panel);
  assertEquals(panel.shortName, "Servers");
  assertEquals(panel.icon, "radar");
  assertEquals(panel.hasBackend, true);
  assertEquals(panel.cladeId, "gsa-browser");
});

Deno.test("GSA has 7 panels in gsa-* clades", () => {
  const gsaPanels = allPanels.filter(
    (p) => p.cladeId && p.cladeId.startsWith("gsa-"),
  );
  assertEquals(gsaPanels.length, 7);
});

Deno.test("panelsInClade returns GSA config editor", () => {
  const panels = panelsInClade("gsa-config");
  assertEquals(panels.length, 1);
  assertEquals(panels[0].id, "PanelGsaConfigEditor");
});
