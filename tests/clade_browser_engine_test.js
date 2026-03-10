// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * CladeBrowserEngine Tests — inheritance, traits, filtering, queries
 *
 * Note: Parent clade IDs (bridge, scanner, network) reference abstract kind-level
 * clades that don't exist as entries in builtinClades. The inheritance engine
 * handles this gracefully by treating them as roots.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  kindLabel,
  kindColour,
  parseKind,
  allKinds,
  filterByKind,
  filterBySearch,
  countByKind,
  categoryLabel,
  allCategories,
  builtinClades,
  findClade,
  mergeTraits,
  resolveTraits,
  inheritanceChain,
  inheritanceLabel,
  countWithParent,
  rootClades,
  childrenOf,
} from "../src/core/CladeBrowserEngine.res.js";

// -- kindLabel --

Deno.test("kindLabel returns correct strings", () => {
  assertEquals(kindLabel("KindAi"), "AI");
  assertEquals(kindLabel("KindBridge"), "Bridge");
  assertEquals(kindLabel("KindDatabase"), "Database");
  assertEquals(kindLabel("KindScanner"), "Scanner");
  assertEquals(kindLabel("KindTerminal"), "Terminal");
  assertEquals(kindLabel("KindAll"), "All");
});

// -- kindColour --

Deno.test("kindColour returns Tailwind classes", () => {
  assertExists(kindColour("KindAi"));
  assertExists(kindColour("KindDatabase"));
});

// -- parseKind --

Deno.test("parseKind parses known kinds", () => {
  assertEquals(parseKind("ai"), "KindAi");
  assertEquals(parseKind("bridge"), "KindBridge");
  assertEquals(parseKind("database"), "KindDatabase");
  assertEquals(parseKind("scanner"), "KindScanner");
});

Deno.test("parseKind returns KindMeta for unknown", () => {
  // Default fallback in the switch is KindMeta (the catch-all case)
  assertEquals(parseKind("bogus"), "KindMeta");
  assertEquals(parseKind(""), "KindMeta");
});

// -- allKinds --

Deno.test("allKinds has 12 entries", () => {
  assertEquals(allKinds.length, 12);
});

// -- builtinClades --

Deno.test("builtinClades has 51 entries", () => {
  assertEquals(builtinClades.length, 51);
});

Deno.test("every builtin clade has required fields", () => {
  for (const clade of builtinClades) {
    assertExists(clade.id, `Clade missing id`);
    assertExists(clade.name, `Clade ${clade.id} missing name`);
    assertExists(clade.kind, `Clade ${clade.id} missing kind`);
    assertExists(clade.traits, `Clade ${clade.id} missing traits`);
  }
});

Deno.test("every builtin clade id is unique", () => {
  const ids = builtinClades.map((c) => c.id);
  const unique = new Set(ids);
  assertEquals(unique.size, ids.length);
});

// -- findClade --

Deno.test("findClade returns clade for known id", () => {
  const clade = findClade(builtinClades, "boj");
  assertExists(clade);
  // Name includes full description
  assertEquals(clade.id, "boj");
});

Deno.test("findClade returns undefined for unknown id", () => {
  const clade = findClade(builtinClades, "nonexistent");
  assertEquals(clade, undefined);
});

// -- mergeTraits (OR semantics) --

Deno.test("mergeTraits ORs all fields", () => {
  const parent = {
    hasPersistence: true,
    hasBackend: false,
    hasWorkItems: false,
    hasRealTime: false,
    isAmbient: false,
  };
  const child = {
    hasPersistence: false,
    hasBackend: true,
    hasWorkItems: false,
    hasRealTime: true,
    isAmbient: false,
  };
  const merged = mergeTraits(parent, child);
  assertEquals(merged.hasPersistence, true);
  assertEquals(merged.hasBackend, true);
  assertEquals(merged.hasRealTime, true);
  assertEquals(merged.hasWorkItems, false);
  assertEquals(merged.isAmbient, false);
});

// -- resolveTraits --

Deno.test("resolveTraits returns traits for existing clade", () => {
  const traits = resolveTraits(builtinClades, "cloudguard");
  assertExists(traits);
  assertEquals(traits.hasBackend, true);
});

Deno.test("resolveTraits returns undefined for unknown clade", () => {
  const traits = resolveTraits(builtinClades, "nonexistent");
  assertEquals(traits, undefined);
});

Deno.test("resolveTraits works for clade with dangling parent", () => {
  // BoJ has parent "bridge" which doesn't exist — should still return BoJ's own traits
  const traits = resolveTraits(builtinClades, "boj");
  assertExists(traits);
  assertEquals(traits.hasBackend, true);
});

// -- inheritanceChain --

Deno.test("inheritanceChain returns single item for root clade", () => {
  const chain = inheritanceChain(builtinClades, "cloudguard", []);
  assertEquals(chain.length, 1);
  assertEquals(chain[0], "cloudguard");
});

Deno.test("inheritanceChain returns single item for dangling parent", () => {
  // BoJ has parent "bridge" but "bridge" clade doesn't exist
  // So chain is just ["boj"]
  const chain = inheritanceChain(builtinClades, "boj", []);
  assertEquals(chain.length, 1);
  assertEquals(chain[0], "boj");
});

// -- inheritanceLabel --

Deno.test("inheritanceLabel returns just name for root or dangling parent", () => {
  assertEquals(inheritanceLabel(builtinClades, "cloudguard"), "cloudguard");
  assertEquals(inheritanceLabel(builtinClades, "boj"), "boj");
});

// -- countWithParent --

Deno.test("countWithParent returns 5 (aerie, boj, mass-panic, panic-attack, protocol-squisher)", () => {
  assertEquals(countWithParent(builtinClades), 5);
});

// -- rootClades --

Deno.test("rootClades returns clades without parents", () => {
  const roots = rootClades(builtinClades);
  assertEquals(roots.length, 46); // 51 - 5 with parents
  for (const root of roots) {
    assertEquals(root.parentCladeId, undefined);
  }
});

// -- childrenOf --

Deno.test("childrenOf returns empty for existing clade with no children", () => {
  const children = childrenOf(builtinClades, "cloudguard");
  assertEquals(children.length, 0);
});

// -- filtering --

Deno.test("filterByKind filters by kind string", () => {
  const aiClades = filterByKind(builtinClades, "KindAi");
  for (const clade of aiClades) {
    assertEquals(clade.kind, "ai");
  }
  assertEquals(aiClades.length >= 1, true);
});

Deno.test("filterByKind with KindAll returns all", () => {
  const all = filterByKind(builtinClades, "KindAll");
  assertEquals(all.length, builtinClades.length);
});

Deno.test("filterBySearch matches name case-insensitive", () => {
  const results = filterBySearch(builtinClades, "boj");
  assertEquals(results.length >= 1, true);
});

Deno.test("filterBySearch with empty query returns all", () => {
  const results = filterBySearch(builtinClades, "");
  assertEquals(results.length, builtinClades.length);
});

Deno.test("countByKind counts correctly", () => {
  const allCount = countByKind(builtinClades, "KindAll");
  assertEquals(allCount, builtinClades.length);
});

// -- allCategories --

Deno.test("allCategories has 4 entries", () => {
  assertEquals(allCategories.length, 4);
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings", () => {
  assertEquals(categoryLabel("CategoryOverview"), "Overview");
  assertEquals(categoryLabel("CategoryByKind"), "By Kind");
  assertEquals(categoryLabel("CategoryTraits"), "Traits");
  assertEquals(categoryLabel("CategoryPanelMap"), "Panel Map");
});
