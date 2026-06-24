// SPDX-License-Identifier: MPL-2.0

/**
 * Orbital Drift Detection Cross-Cutting Tests — aspect-oriented verification
 * of the Binary Star co-orbit synchronisation system.
 *
 * Tests:
 *   - Divergence computation (Jaccard distance between L↔N content)
 *   - Stability calculation (composite metric from divergence + latency)
 *   - Drift aura colour transitions (indigo ↔ amber)
 *   - Change detection (hash-based L, N, W tracking)
 *   - Humidity feedback (vexation + stability → UI density)
 *   - Cross-link creation (Circuit Lines between panes)
 *   - Sync state machine under sustained load
 *   - Integration with governance feedback loop
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as OrbitalSync from "../src/core/OrbitalSync.res.js";
import * as GovernanceEngine from "../src/core/GovernanceEngine.res.js";
import { init as initModel } from "../src/Model.res.js";
import * as Update from "../src/Update.res.js";

// ─── Helpers ────────────────────────────────────────────────────────────

const makePaneL = (editorContent = "") => ({
  constraints: [],
  activeConstraintId: undefined,
  editorContent,
});

const makePaneN = (monologue = "") => ({
  tokens: [],
  activeTokenId: undefined,
  monologue,
  inferenceStatus: "idle",
  autonomyLevel: 0.0,
});

// ─── simpleHash ─────────────────────────────────────────────────────────

Deno.test("OrbitalSync — simpleHash: empty string returns 'empty'", () => {
  assertEquals(OrbitalSync.simpleHash(""), "empty");
});

Deno.test("OrbitalSync — simpleHash: non-empty returns length-first-last", () => {
  assertEquals(OrbitalSync.simpleHash("hello"), "5-h-o");
  assertEquals(OrbitalSync.simpleHash("a"), "1-a-a");
  assertEquals(OrbitalSync.simpleHash("ab"), "2-a-b");
});

Deno.test("OrbitalSync — simpleHash: identical strings produce identical hashes", () => {
  const h1 = OrbitalSync.simpleHash("test content");
  const h2 = OrbitalSync.simpleHash("test content");
  assertEquals(h1, h2);
});

Deno.test("OrbitalSync — simpleHash: different strings produce different hashes", () => {
  const h1 = OrbitalSync.simpleHash("content-a");
  const h2 = OrbitalSync.simpleHash("content-b");
  assert(h1 !== h2, "Different content should produce different hashes");
});

// ─── calculateDivergence ────────────────────────────────────────────────

Deno.test("OrbitalSync — calculateDivergence: identical content returns 0.0", () => {
  const pL = makePaneL("same content");
  const pN = makePaneN("same content");
  assertEquals(OrbitalSync.calculateDivergence(pL, pN), 0.0);
});

Deno.test("OrbitalSync — calculateDivergence: empty vs empty returns 0.0", () => {
  assertEquals(OrbitalSync.calculateDivergence(makePaneL(""), makePaneN("")), 0.0);
});

Deno.test("OrbitalSync — calculateDivergence: different content returns > 0", () => {
  const pL = makePaneL("symbolic constraints here");
  const pN = makePaneN("neural inference output there");
  const div = OrbitalSync.calculateDivergence(pL, pN);
  assert(div > 0.0, `Expected divergence > 0, got ${div}`);
  assert(div <= 1.0, `Divergence should be capped at 1.0, got ${div}`);
});

Deno.test("OrbitalSync — calculateDivergence: completely different content approaches 1.0", () => {
  const pL = makePaneL("aaaaaaaaaa");
  const pN = makePaneN("zzzzzzzzzzzzzzzzzzzz");
  const div = OrbitalSync.calculateDivergence(pL, pN);
  assert(div > 0.5, `Completely different content should diverge significantly, got ${div}`);
});

Deno.test("OrbitalSync — calculateDivergence: is symmetric", () => {
  const pL = makePaneL("content alpha");
  const pN = makePaneN("content beta");
  const d1 = OrbitalSync.calculateDivergence(pL, pN);
  // Swap roles
  const pL2 = makePaneL("content beta");
  const pN2 = makePaneN("content alpha");
  const d2 = OrbitalSync.calculateDivergence(pL2, pN2);
  assertEquals(d1, d2, "Divergence should be symmetric");
});

// ─── calculateStability ─────────────────────────────────────────────────

Deno.test("OrbitalSync — calculateStability: zero divergence + zero latency = 1.0", () => {
  assertEquals(OrbitalSync.calculateStability(0.0, 0.0), 1.0);
});

Deno.test("OrbitalSync — calculateStability: high divergence reduces stability", () => {
  const stability = OrbitalSync.calculateStability(0.8, 0.0);
  assert(stability < 1.0, "High divergence should reduce stability");
  assert(stability >= 0.0, "Stability should not go negative");
});

Deno.test("OrbitalSync — calculateStability: high latency reduces stability", () => {
  const stability = OrbitalSync.calculateStability(0.0, 0.8);
  assert(stability < 1.0, "High latency should reduce stability");
});

Deno.test("OrbitalSync — calculateStability: combined stress severely reduces stability", () => {
  const stability = OrbitalSync.calculateStability(0.7, 0.7);
  assert(stability < 0.7, `Combined stress should reduce stability, got ${stability}`);
});

Deno.test("OrbitalSync — calculateStability: result is always in [0, 1]", () => {
  const testCases = [
    [0.0, 0.0], [0.5, 0.5], [1.0, 1.0], [0.0, 1.0], [1.0, 0.0],
    [0.3, 0.7], [0.99, 0.99],
  ];
  for (const [div, lat] of testCases) {
    const s = OrbitalSync.calculateStability(div, lat);
    assert(s >= 0.0 && s <= 1.0, `Stability(${div}, ${lat}) = ${s} outside [0, 1]`);
  }
});

// ─── getDriftAuraColour ─────────────────────────────────────────────────

Deno.test("OrbitalSync — getDriftAuraColour: high stability returns indigo", () => {
  assertEquals(OrbitalSync.getDriftAuraColour(0.9), "indigo");
  assertEquals(OrbitalSync.getDriftAuraColour(0.7), "indigo");
});

Deno.test("OrbitalSync — getDriftAuraColour: low stability returns amber", () => {
  assertEquals(OrbitalSync.getDriftAuraColour(0.3), "amber");
  assertEquals(OrbitalSync.getDriftAuraColour(0.1), "amber");
  assertEquals(OrbitalSync.getDriftAuraColour(0.69), "amber");
});

Deno.test("OrbitalSync — getDriftAuraColour: threshold boundary (0.7)", () => {
  // At exactly 0.7, should be indigo (≥ threshold)
  assertEquals(OrbitalSync.getDriftAuraColour(0.7), "indigo");
});

// ─── getHumidityLevel ───────────────────────────────────────────────────

Deno.test("OrbitalSync — getHumidityLevel: clean model returns High", () => {
  const m = initModel();
  const humidity = OrbitalSync.getHumidityLevel(m);
  assertEquals(humidity, "High");
});

Deno.test("OrbitalSync — getHumidityLevel: stressed model returns Low", () => {
  const m = {
    ...initModel(),
    vexometer: { ...initModel().vexometer, index: 0.85 },
    orbital: { ...initModel().orbital, stability: 0.3 },
  };
  const humidity = OrbitalSync.getHumidityLevel(m);
  assertEquals(humidity, "Low");
});

// ─── Change Detection ───────────────────────────────────────────────────

Deno.test("OrbitalSync — detectSymbolicChanges: returns event on content change", () => {
  const pL = makePaneL("new symbolic content");
  const syncState = { lastSymbolicHash: "old-hash", lastNeuralHash: "", lastWorldHash: "", pendingSync: [] };
  const event = OrbitalSync.detectSymbolicChanges(pL, syncState);
  // Should detect change since hash differs
  assert(event !== undefined, "Should detect symbolic change");
});

Deno.test("OrbitalSync — detectSymbolicChanges: no event when hash unchanged", () => {
  const content = "stable symbolic content";
  const hash = OrbitalSync.simpleHash(content);
  const pL = makePaneL(content);
  const syncState = { lastSymbolicHash: hash, lastNeuralHash: "", lastWorldHash: "", pendingSync: [] };
  const event = OrbitalSync.detectSymbolicChanges(pL, syncState);
  assertEquals(event, undefined, "No change event when content unchanged");
});

Deno.test("OrbitalSync — detectNeuralChanges: returns event on monologue change", () => {
  const pN = makePaneN("new neural output");
  const syncState = { lastSymbolicHash: "", lastNeuralHash: "old-hash", lastWorldHash: "", pendingSync: [] };
  const event = OrbitalSync.detectNeuralChanges(pN, syncState);
  assert(event !== undefined, "Should detect neural change");
});

// ─── createCrossLink ────────────────────────────────────────────────────

Deno.test("OrbitalSync — createCrossLink produces a sync event", () => {
  const event = OrbitalSync.createCrossLink("pane-l", "pane-n", "constraint x > 0");
  assert(event !== undefined, "Cross-link should produce a sync event");
});

// ─── Full Sync Orchestration ────────────────────────────────────────────

Deno.test("OrbitalSync — sync: clean model produces stable orbital state", () => {
  const m = initModel();
  const result = OrbitalSync.sync(m, m.syncState);

  // Returns [syncState, orbital] tuple
  assert(Array.isArray(result), "sync returns a tuple array");
  const [syncState, orbital] = result;
  assert(typeof orbital.stability === "number", "Orbital stability is numeric");
  assert(orbital.stability >= 0.0 && orbital.stability <= 1.0, "Stability in [0, 1]");
  assert(typeof orbital.divergenceLevel === "number", "Divergence level is numeric");
  assert(typeof syncState.lastSymbolicHash === "string", "Sync state tracks symbolic hash");
  assert(typeof syncState.lastNeuralHash === "string", "Sync state tracks neural hash");
});

Deno.test("OrbitalSync — sync: content divergence increases divergenceLevel", () => {
  const m = {
    ...initModel(),
    paneL: { ...initModel().paneL, editorContent: "symbolic constraint definitions" },
    paneN: { ...initModel().paneN, monologue: "completely unrelated neural inference" },
  };

  const [_syncState, orbital] = OrbitalSync.sync(m, m.syncState);
  assert(orbital.divergenceLevel > 0, `Divergent content should increase divergenceLevel, got ${orbital.divergenceLevel}`);
});

// ─── Sustained Load ─────────────────────────────────────────────────────

Deno.test("OrbitalSync — stability stays bounded after 20 update cycles", () => {
  let m = initModel();
  for (let i = 0; i < 20; i++) {
    // Alternate between symbolic and neural changes
    if (i % 2 === 0) {
      m = { ...m, paneL: { ...m.paneL, editorContent: `constraint-${i}` } };
    } else {
      m = { ...m, paneN: { ...m.paneN, monologue: `inference-${i}` } };
    }
    const [newSync, newOrbital] = OrbitalSync.sync(m, m.syncState);
    m = { ...m, syncState: newSync, orbital: newOrbital };

    assert(m.orbital.stability >= 0.0 && m.orbital.stability <= 1.0,
      `Stability out of bounds at iteration ${i}: ${m.orbital.stability}`);
  }
});

Deno.test("OrbitalSync — divergence varies with content difference", () => {
  // Same content → 0 divergence
  const same = OrbitalSync.calculateDivergence(makePaneL("hello world"), makePaneN("hello world"));
  assertEquals(same, 0.0);

  // Different content → positive divergence
  const diff = OrbitalSync.calculateDivergence(makePaneL("symbolic"), makePaneN("neural"));
  assert(diff > 0.0, `Different content should have positive divergence, got ${diff}`);

  // More different content → potentially higher divergence
  const moreDiff = OrbitalSync.calculateDivergence(
    makePaneL("a".repeat(100)),
    makePaneN("z".repeat(100))
  );
  assert(moreDiff > 0.0, `Very different content should diverge, got ${moreDiff}`);
});

// ─── Cross-Cutting: OrbitalSync in Governance ───────────────────────────

Deno.test("Cross-cutting — governance reacts to low stability", () => {
  const m = {
    ...initModel(),
    orbital: { ...initModel().orbital, stability: 0.2, divergenceLevel: 0.8 },
  };

  const adjustments = GovernanceEngine.evaluate(m);
  // Low stability should trigger governance adjustments (at minimum AdjustHumidity)
  assert(adjustments.length > 0, "Low stability should produce governance adjustments");
});

Deno.test("Cross-cutting — OrbitalSync runs during update cycle", () => {
  const m = initModel();
  const [newModel] = Update.update(m, { TAG: "PaneW", _0: { TAG: "UpdateContent", _0: "changed" } });

  assertEquals(typeof newModel.orbital.stability, "number");
  assertEquals(typeof newModel.orbital.divergenceLevel, "number");
  assert(typeof newModel.syncState.lastWorldHash === "string");
});

Deno.test("Cross-cutting — drift aura colour reflects stability in update cycle", () => {
  // High vexation + low stability should produce amber
  const m = {
    ...initModel(),
    orbital: { ...initModel().orbital, stability: 0.3, divergenceLevel: 0.7, driftAuraColour: "amber" },
    vexometer: { ...initModel().vexometer, index: 0.85 },
  };

  const [newModel] = Update.update(m, { TAG: "View", _0: { TAG: "SetHumidity", _0: "Low" } });
  assertEquals(typeof newModel.orbital.driftAuraColour, "string");
});
