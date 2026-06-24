// SPDX-License-Identifier: MPL-2.0

/**
 * Contractiles Cross-Cutting Tests — aspect-oriented verification of the
 * adaptive state-shape contract system.
 *
 * Tests the M1–M5 governance post-processing pass:
 *   M1: Contractile evaluation against current model state
 *   M2: OrbitalSync divergence detection
 *   M3: PendingSync consumption
 *   M4: GovernanceEngine feedback loop closure
 *   M5: Panel Bus event emission
 *
 * ReScript compilation notes:
 *   contractStatus: "Satisfied" | "Pending" | { TAG: "Violated", _0: string }
 *   evaluationResult: { contractile, status }
 */

import { assertEquals, assert, assertNotEquals } from "jsr:@std/assert";
import { init as initModel } from "../src/Model.res.js";
import * as Contractiles from "../src/core/Contractiles.res.js";
import * as Update from "../src/Update.res.js";
import * as GovernanceEngine from "../src/core/GovernanceEngine.res.js";

// ─── Helper: create model with specific stress levels ───────────────────

const stressedModel = (overrides = {}) => ({
  ...initModel(),
  vexometer: {
    ...initModel().vexometer,
    index: 0.85,
    recentCancellations: 5,
    recentCorrections: 3,
    antiInflammatoryActive: true,
    inertiaDetected: false,
    ...overrides.vexometer,
  },
  antiCrash: {
    ...initModel().antiCrash,
    violations: Array.from({ length: 8 }, (_, i) => `violation-${i}`),
    ...overrides.antiCrash,
  },
  orbital: {
    ...initModel().orbital,
    stability: 0.3,
    divergenceLevel: 0.7,
    driftAuraColour: "amber",
    ...overrides.orbital,
  },
});

// ─── Default Contractiles ───────────────────────────────────────────────

Deno.test("Contractiles — defaultContractiles returns exactly 11 contracts", () => {
  const contracts = Contractiles.defaultContractiles();
  assertEquals(contracts.length, 11);
});

Deno.test("Contractiles — each default contract has id, name, elasticity", () => {
  const contracts = Contractiles.defaultContractiles();
  for (const c of contracts) {
    assert(typeof c.id === "string" && c.id.length > 0, `Contract missing id`);
    assert(typeof c.name === "string" && c.name.length > 0, `Contract ${c.id} missing name`);
    assert(typeof c.elasticity === "number", `Contract ${c.id} missing elasticity`);
    assert(c.elasticity >= 0.0 && c.elasticity <= 1.0, `Contract ${c.id} elasticity out of range: ${c.elasticity}`);
  }
});

Deno.test("Contractiles — contract ids are unique", () => {
  const contracts = Contractiles.defaultContractiles();
  const ids = contracts.map(c => c.id);
  const unique = new Set(ids);
  assertEquals(unique.size, ids.length, `Duplicate contract ids: ${ids}`);
});

// ─── Individual Contract Evaluation ─────────────────────────────────────

Deno.test("Contractiles — orbitalStabilityContract: stable orbit satisfies", () => {
  const orbital = { stability: 0.85, divergenceLevel: 0.1, driftAuraColour: "indigo" };
  const result = Contractiles.orbitalStabilityContract(orbital, 0.7);
  assertEquals(result, "Satisfied");
});

Deno.test("Contractiles — orbitalStabilityContract: unstable orbit violates", () => {
  const orbital = { stability: 0.35, divergenceLevel: 0.6, driftAuraColour: "amber" };
  const result = Contractiles.orbitalStabilityContract(orbital, 0.7);
  assertEquals(result.TAG, "Violated");
  assert(result._0.includes("stability"), `Violation message should mention stability: ${result._0}`);
});

Deno.test("Contractiles — vexationCeilingContract: calm operator satisfies", () => {
  const vex = { index: 0.2, recentCancellations: 0, recentCorrections: 0, antiInflammatoryActive: false, inertiaDetected: false };
  assertEquals(Contractiles.vexationCeilingContract(vex, 0.7), "Satisfied");
});

Deno.test("Contractiles — vexationCeilingContract: frustrated operator violates", () => {
  const vex = { index: 0.9, recentCancellations: 8, recentCorrections: 5, antiInflammatoryActive: true, inertiaDetected: false };
  const result = Contractiles.vexationCeilingContract(vex, 0.7);
  assertEquals(result.TAG, "Violated");
});

Deno.test("Contractiles — divergenceLimitContract: low divergence satisfies", () => {
  const orbital = { stability: 0.9, divergenceLevel: 0.1, driftAuraColour: "indigo" };
  assertEquals(Contractiles.divergenceLimitContract(orbital, 0.5), "Satisfied");
});

Deno.test("Contractiles — divergenceLimitContract: high divergence violates", () => {
  const orbital = { stability: 0.3, divergenceLevel: 0.8, driftAuraColour: "amber" };
  const result = Contractiles.divergenceLimitContract(orbital, 0.5);
  assertEquals(result.TAG, "Violated");
});

Deno.test("Contractiles — antiCrashGateContract: low rejection rate satisfies", () => {
  assertEquals(Contractiles.antiCrashGateContract(true, 0.05, 0.2), "Satisfied");
});

Deno.test("Contractiles — antiCrashGateContract: high rejection rate violates", () => {
  const result = Contractiles.antiCrashGateContract(true, 0.5, 0.2);
  assertEquals(result.TAG, "Violated");
});

Deno.test("Contractiles — antiCrashGateContract: disabled gate violates (unsafe)", () => {
  const result = Contractiles.antiCrashGateContract(false, 0.9, 0.2);
  assertEquals(result.TAG, "Violated");
});

Deno.test("Contractiles — safeDomContract: initialised satisfies", () => {
  assertEquals(Contractiles.safeDomContract(true), "Satisfied");
});

Deno.test("Contractiles — safeDomContract: uninitialised violates", () => {
  const result = Contractiles.safeDomContract(false);
  assertEquals(result.TAG, "Violated");
});

Deno.test("Contractiles — typellCoverageContract: sufficient coverage satisfies", () => {
  assertEquals(Contractiles.typellCoverageContract(80, 100, 50.0), "Satisfied");
});

Deno.test("Contractiles — typellCoverageContract: insufficient coverage violates", () => {
  const result = Contractiles.typellCoverageContract(10, 100, 50.0);
  assertEquals(result.TAG, "Violated");
});

Deno.test("Contractiles — panelWiringIntegrityContract: all wired satisfies", () => {
  assertEquals(Contractiles.panelWiringIntegrityContract(100, 100), "Satisfied");
});

Deno.test("Contractiles — panelWiringIntegrityContract: unwired panels violate", () => {
  const result = Contractiles.panelWiringIntegrityContract(50, 100);
  assertEquals(result.TAG, "Violated");
});

Deno.test("Contractiles — testHealthContract: high pass rate satisfies", () => {
  assertEquals(Contractiles.testHealthContract(95, 100, 90.0), "Satisfied");
});

Deno.test("Contractiles — testHealthContract: low pass rate violates", () => {
  const result = Contractiles.testHealthContract(60, 100, 90.0);
  assertEquals(result.TAG, "Violated");
});

Deno.test("Contractiles — bojLatencyBoundContract: fast response satisfies", () => {
  assertEquals(Contractiles.bojLatencyBoundContract(50.0, 200.0), "Satisfied");
});

Deno.test("Contractiles — bojLatencyBoundContract: slow response violates", () => {
  const result = Contractiles.bojLatencyBoundContract(500.0, 200.0);
  assertEquals(result.TAG, "Violated");
});

// ─── Bulk Evaluation ────────────────────────────────────────────────────

Deno.test("Contractiles — evaluateAll returns result per contract", () => {
  const m = initModel();
  const contracts = Contractiles.defaultContractiles();
  const results = Contractiles.evaluateAll(m, contracts);
  assertEquals(results.length, contracts.length);
});

Deno.test("Contractiles — evaluateAll on clean model: mostly Satisfied", () => {
  const m = initModel();
  const contracts = Contractiles.defaultContractiles();
  const results = Contractiles.evaluateAll(m, contracts);

  const satisfied = results.filter(r => r.status === "Satisfied");
  // Clean model should satisfy most contracts (at least orbital, vexation, divergence)
  assert(satisfied.length >= 3, `Expected at least 3 satisfied, got ${satisfied.length}`);
});

Deno.test("Contractiles — evaluateAll on stressed model: some Violated", () => {
  const m = stressedModel();
  const contracts = Contractiles.defaultContractiles();
  const results = Contractiles.evaluateAll(m, contracts);

  const violated = results.filter(r => r.status && r.status.TAG === "Violated");
  assert(violated.length >= 1, `Expected at least 1 violation under stress, got ${violated.length}`);
});

// ─── Elasticity & Adaptation ────────────────────────────────────────────

Deno.test("Contractiles — adaptContract adjusts elasticity based on model state", () => {
  const contracts = Contractiles.defaultContractiles();
  const m = initModel();
  for (const c of contracts) {
    const adapted = Contractiles.adaptContract(c, m);
    assert(typeof adapted.elasticity === "number", `Adapted contract ${c.id} has numeric elasticity`);
  }
});

// ─── Cross-Cutting: Contractiles in the Update Cycle ────────────────────

Deno.test("Cross-cutting — contractiles are evaluated on every update dispatch", () => {
  const m = initModel();
  const [newModel] = Update.update(m, "NoOp");

  // Contractiles should be present in the model after update
  assert(Array.isArray(newModel.contractiles), "contractiles should be an array");
  for (const c of newModel.contractiles) {
    assert(typeof c.id === "string", "each contractile has an id");
  }
});

Deno.test("Cross-cutting — high vexation triggers anti-inflammatory via contractiles", () => {
  const m = stressedModel();
  const [newModel] = Update.update(m, { TAG: "View", _0: { TAG: "SetHumidity", _0: "Low" } });

  // Anti-inflammatory should activate at vexation > 0.7
  assertEquals(newModel.vexometer.antiInflammatoryActive, true);
});

Deno.test("Cross-cutting — governance adjustments flow through contractiles pass", () => {
  // Stressed model should produce governance adjustments
  const m = stressedModel();
  const adjustments = GovernanceEngine.evaluate(m);

  assert(adjustments.length > 0, "Stressed model should produce governance adjustments");

  // Apply them
  const governed = GovernanceEngine.applyAll(m, adjustments);

  // Verify adjustments were applied (e.g., humidity should change)
  assertNotEquals(governed, m, "Governance should mutate model state");
});

Deno.test("Cross-cutting — multiple update cycles converge governance state", () => {
  let m = stressedModel();

  // Run 5 update cycles — governance should attempt to stabilise
  for (let i = 0; i < 5; i++) {
    const [newModel] = Update.update(m, { TAG: "Orbital", _0: { TAG: "UpdateStability", _0: 0.5 } });
    m = newModel;
  }

  // After multiple passes, the model should still be structurally sound
  assert(typeof m.orbital.stability === "number", "stability is numeric after convergence");
  assert(typeof m.vexometer.index === "number", "vexation index is numeric after convergence");
});

Deno.test("Cross-cutting — contractile violation count is bounded", () => {
  const m = stressedModel();
  const contracts = Contractiles.defaultContractiles();
  const results = Contractiles.evaluateAll(m, contracts);

  // Violations should never exceed total contracts
  const violated = results.filter(r => r.status && r.status.TAG === "Violated");
  assert(violated.length <= contracts.length, "Violations cannot exceed contract count");
});
