// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * GovernanceEngine Tests — threshold constants, analysis functions
 * (violationCount, shouldLoosenForVexation, shouldTightenForStability,
 * computeHumidity), evaluate, applyAdjustment, applyAll, and govern.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  violationSpikeThreshold,
  vexationHighThreshold,
  vexationLowThreshold,
  stabilityDangerThreshold,
  stabilityHealthyThreshold,
  divergenceHighThreshold,
  elasticityIncrement,
  elasticityDecrement,
  violationCount,
  shouldLoosenForVexation,
  shouldTightenForStability,
  computeHumidity,
  evaluate,
  applyAdjustment,
  applyAll,
  govern,
} from "../src/core/GovernanceEngine.res.js";

// -- Threshold constants --

Deno.test("threshold constants have expected values", () => {
  assertEquals(violationSpikeThreshold, 5);
  assertEquals(vexationHighThreshold, 0.7);
  assertEquals(vexationLowThreshold, 0.3);
  assertEquals(stabilityDangerThreshold, 0.4);
  assertEquals(stabilityHealthyThreshold, 0.7);
  assertEquals(divergenceHighThreshold, 0.6);
  assertEquals(elasticityIncrement, 0.05);
  assertEquals(elasticityDecrement, 0.03);
});

// -- violationCount --

Deno.test("violationCount returns 0 for empty violations", () => {
  assertEquals(violationCount({ violations: [] }), 0);
});

Deno.test("violationCount returns correct count", () => {
  assertEquals(violationCount({ violations: ["a", "b", "c"] }), 3);
});

// -- shouldLoosenForVexation --

Deno.test("shouldLoosenForVexation returns true when vexation high, violations low, no inertia", () => {
  const vex = { index: 0.8, inertiaDetected: false };
  const antiCrash = { violations: [1, 2, 3] }; // 3 < 5
  assertEquals(shouldLoosenForVexation(vex, antiCrash), true);
});

Deno.test("shouldLoosenForVexation returns false when vexation low", () => {
  const vex = { index: 0.5, inertiaDetected: false };
  const antiCrash = { violations: [] };
  assertEquals(shouldLoosenForVexation(vex, antiCrash), false);
});

Deno.test("shouldLoosenForVexation returns false when too many violations", () => {
  const vex = { index: 0.8, inertiaDetected: false };
  const antiCrash = { violations: [1, 2, 3, 4, 5, 6] }; // 6 >= 5
  assertEquals(shouldLoosenForVexation(vex, antiCrash), false);
});

Deno.test("shouldLoosenForVexation returns false when inertia detected", () => {
  const vex = { index: 0.8, inertiaDetected: true };
  const antiCrash = { violations: [] };
  assertEquals(shouldLoosenForVexation(vex, antiCrash), false);
});

// -- shouldTightenForStability --

Deno.test("shouldTightenForStability returns true when stable + violations spike + low vexation", () => {
  const orbital = { stability: 0.8 };
  const antiCrash = { violations: [1, 2, 3, 4, 5, 6] }; // > 5
  const vex = { index: 0.2 }; // < 0.3
  assertEquals(shouldTightenForStability(orbital, antiCrash, vex), true);
});

Deno.test("shouldTightenForStability returns false when stability is low", () => {
  const orbital = { stability: 0.5 };
  const antiCrash = { violations: [1, 2, 3, 4, 5, 6] };
  const vex = { index: 0.2 };
  assertEquals(shouldTightenForStability(orbital, antiCrash, vex), false);
});

Deno.test("shouldTightenForStability returns false when violations are low", () => {
  const orbital = { stability: 0.8 };
  const antiCrash = { violations: [1, 2] };
  const vex = { index: 0.2 };
  assertEquals(shouldTightenForStability(orbital, antiCrash, vex), false);
});

Deno.test("shouldTightenForStability returns false when vexation is high", () => {
  const orbital = { stability: 0.8 };
  const antiCrash = { violations: [1, 2, 3, 4, 5, 6] };
  const vex = { index: 0.5 };
  assertEquals(shouldTightenForStability(orbital, antiCrash, vex), false);
});

// -- computeHumidity --

Deno.test("computeHumidity returns Low when vexation is high", () => {
  assertEquals(computeHumidity({ index: 0.8 }, { stability: 0.9 }), "Low");
});

Deno.test("computeHumidity returns Low when stability is critically low", () => {
  assertEquals(computeHumidity({ index: 0.1 }, { stability: 0.3 }), "Low");
});

Deno.test("computeHumidity returns Medium for moderate stress", () => {
  assertEquals(computeHumidity({ index: 0.5 }, { stability: 0.8 }), "Medium");
});

Deno.test("computeHumidity returns Medium when stability is moderate", () => {
  assertEquals(computeHumidity({ index: 0.1 }, { stability: 0.5 }), "Medium");
});

Deno.test("computeHumidity returns High when stress is low", () => {
  assertEquals(computeHumidity({ index: 0.2 }, { stability: 0.9 }), "High");
});

// -- Helper: minimal model factory --

function makeModel(overrides = {}) {
  return {
    vexometer: { index: 0.5, inertiaDetected: false },
    antiCrash: { enabled: true, strictMode: false, violations: [], halted: false, pendingReview: [] },
    orbital: { stability: 0.8, divergenceLevel: 0.2 },
    contractiles: [],
    paneN: { tokens: 0, inferenceActive: true, monologue: "", agency: "" },
    hypatia: { networks: [] },
    humidity: "Medium",
    syncState: { lastSymbolicHash: "", lastNeuralHash: "", lastWorldHash: "", pendingSync: [], syncLatency: 0 },
    ...overrides,
  };
}

// -- applyAdjustment --

Deno.test("applyAdjustment TightenAntiCrash sets strictMode true", () => {
  const model = makeModel();
  const result = applyAdjustment(model, "TightenAntiCrash");
  assertEquals(result.antiCrash.strictMode, true);
});

Deno.test("applyAdjustment LoosenAntiCrash sets strictMode false", () => {
  const model = makeModel({ antiCrash: { enabled: true, strictMode: true, violations: [], halted: false, pendingReview: [] } });
  const result = applyAdjustment(model, "LoosenAntiCrash");
  assertEquals(result.antiCrash.strictMode, false);
});

Deno.test("applyAdjustment ResumeInference enables inference and clears halt", () => {
  const model = makeModel({
    paneN: { tokens: 0, inferenceActive: false, monologue: "", agency: "" },
    antiCrash: { enabled: true, strictMode: false, violations: [], halted: true, pendingReview: [] },
  });
  const result = applyAdjustment(model, "ResumeInference");
  assertEquals(result.paneN.inferenceActive, true);
  assertEquals(result.antiCrash.halted, false);
});

Deno.test("applyAdjustment IncreaseElasticity increases matching contractile", () => {
  const model = makeModel({
    contractiles: [
      { id: "c1", name: "test", description: "", enforcement: "Adaptive", status: "Active", elasticity: 0.5, lastEvaluated: 0 },
    ],
  });
  const result = applyAdjustment(model, { TAG: "IncreaseElasticity", _0: "c1" });
  assertEquals(result.contractiles[0].elasticity, 0.55);
});

Deno.test("applyAdjustment IncreaseElasticity does not exceed 1.0", () => {
  const model = makeModel({
    contractiles: [
      { id: "c1", name: "test", description: "", enforcement: "Adaptive", status: "Active", elasticity: 0.98, lastEvaluated: 0 },
    ],
  });
  const result = applyAdjustment(model, { TAG: "IncreaseElasticity", _0: "c1" });
  assertEquals(result.contractiles[0].elasticity, 1.0);
});

Deno.test("applyAdjustment DecreaseElasticity decreases matching contractile", () => {
  const model = makeModel({
    contractiles: [
      { id: "c1", name: "test", description: "", enforcement: "Adaptive", status: "Active", elasticity: 0.5, lastEvaluated: 0 },
    ],
  });
  const result = applyAdjustment(model, { TAG: "DecreaseElasticity", _0: "c1" });
  assertEquals(result.contractiles[0].elasticity, 0.47);
});

Deno.test("applyAdjustment DecreaseElasticity does not go below 0.0", () => {
  const model = makeModel({
    contractiles: [
      { id: "c1", name: "test", description: "", enforcement: "Adaptive", status: "Active", elasticity: 0.01, lastEvaluated: 0 },
    ],
  });
  const result = applyAdjustment(model, { TAG: "DecreaseElasticity", _0: "c1" });
  assertEquals(result.contractiles[0].elasticity, 0.0);
});

Deno.test("applyAdjustment HaltInference stops inference and adds violation", () => {
  const model = makeModel();
  const result = applyAdjustment(model, { TAG: "HaltInference", _0: "critical failure" });
  assertEquals(result.paneN.inferenceActive, false);
  assertEquals(result.antiCrash.halted, true);
  assertEquals(result.antiCrash.violations.length, 1);
  assertEquals(result.antiCrash.violations[0].TAG, "BoundaryViolation");
  assertEquals(result.antiCrash.violations[0]._0, "critical failure");
});

Deno.test("applyAdjustment AdjustHumidity changes humidity level", () => {
  const model = makeModel({ humidity: "Medium" });
  const result = applyAdjustment(model, { TAG: "AdjustHumidity", _0: "Low" });
  assertEquals(result.humidity, "Low");
});

Deno.test("applyAdjustment EmitSyncEvent appends to pendingSync", () => {
  const model = makeModel();
  const event = { TAG: "CrossPaneLink", _0: "test:event", _1: "target" };
  const result = applyAdjustment(model, { TAG: "EmitSyncEvent", _0: event });
  assertEquals(result.syncState.pendingSync.length, 1);
  assertEquals(result.syncState.pendingSync[0].TAG, "CrossPaneLink");
});

// -- applyAll --

Deno.test("applyAll applies multiple adjustments in sequence", () => {
  const model = makeModel();
  const result = applyAll(model, ["TightenAntiCrash", { TAG: "AdjustHumidity", _0: "Low" }]);
  assertEquals(result.antiCrash.strictMode, true);
  assertEquals(result.humidity, "Low");
});

Deno.test("applyAll returns unchanged model for empty adjustments", () => {
  const model = makeModel();
  const result = applyAll(model, []);
  assertEquals(result.antiCrash.strictMode, model.antiCrash.strictMode);
  assertEquals(result.humidity, model.humidity);
});

// -- evaluate --

Deno.test("evaluate produces LoosenAntiCrash when vexation high + few violations", () => {
  const model = makeModel({
    vexometer: { index: 0.8, inertiaDetected: false },
    antiCrash: { enabled: true, strictMode: false, violations: [1, 2], halted: false, pendingReview: [] },
    humidity: "Medium", // Matches computeHumidity(0.8, 0.8) => Low, so AdjustHumidity also fires
  });
  const adjustments = evaluate(model);
  assert(adjustments.includes("LoosenAntiCrash"));
});

Deno.test("evaluate produces TightenAntiCrash when stable + violations spike + low vexation", () => {
  const model = makeModel({
    vexometer: { index: 0.2, inertiaDetected: false },
    antiCrash: { enabled: true, strictMode: false, violations: [1, 2, 3, 4, 5, 6], halted: false, pendingReview: [] },
    orbital: { stability: 0.8, divergenceLevel: 0.2 },
    humidity: "High",
  });
  const adjustments = evaluate(model);
  assert(adjustments.includes("TightenAntiCrash"));
});

Deno.test("evaluate produces AdjustHumidity when current differs from computed", () => {
  const model = makeModel({
    vexometer: { index: 0.2, inertiaDetected: false },
    orbital: { stability: 0.9, divergenceLevel: 0.1 },
    humidity: "Low", // computeHumidity(0.2, 0.9) => High, so should adjust
  });
  const adjustments = evaluate(model);
  const humAdj = adjustments.find(a => typeof a === "object" && a.TAG === "AdjustHumidity");
  assert(humAdj !== undefined);
  assertEquals(humAdj._0, "High");
});

Deno.test("evaluate produces EmitSyncEvent when divergence is high", () => {
  const model = makeModel({
    orbital: { stability: 0.8, divergenceLevel: 0.7 },
    humidity: "High",
  });
  const adjustments = evaluate(model);
  const syncAdj = adjustments.find(a => typeof a === "object" && a.TAG === "EmitSyncEvent");
  assert(syncAdj !== undefined);
});

Deno.test("evaluate produces HaltInference when divergence high + stability critically low", () => {
  const model = makeModel({
    orbital: { stability: 0.3, divergenceLevel: 0.7 },
    vexometer: { index: 0.5, inertiaDetected: false },
    humidity: "Low",
  });
  const adjustments = evaluate(model);
  const haltAdj = adjustments.find(a => typeof a === "object" && a.TAG === "HaltInference");
  assert(haltAdj !== undefined);
  assert(haltAdj._0.includes("critically low"));
});

Deno.test("evaluate produces ResumeInference for idle system with stable conditions", () => {
  const model = makeModel({
    vexometer: { index: 0.5, inertiaDetected: true },
    paneN: { tokens: 0, inferenceActive: false, monologue: "", agency: "" },
    orbital: { stability: 0.8, divergenceLevel: 0.1 },
    antiCrash: { enabled: true, strictMode: false, violations: [], halted: false, pendingReview: [] },
    humidity: "Medium",
  });
  const adjustments = evaluate(model);
  assert(adjustments.includes("ResumeInference"));
});

Deno.test("evaluate produces IncreaseElasticity for Adaptive contractiles when vexation high", () => {
  const model = makeModel({
    vexometer: { index: 0.8, inertiaDetected: false },
    antiCrash: { enabled: true, strictMode: false, violations: [1, 2], halted: false, pendingReview: [] },
    contractiles: [
      { id: "c1", name: "test", description: "", enforcement: "Adaptive", status: "Active", elasticity: 0.5, lastEvaluated: 0 },
      { id: "c2", name: "strict", description: "", enforcement: "Strict", status: "Active", elasticity: 0.5, lastEvaluated: 0 },
    ],
    humidity: "Medium",
  });
  const adjustments = evaluate(model);
  const incAdj = adjustments.filter(a => typeof a === "object" && a.TAG === "IncreaseElasticity");
  assertEquals(incAdj.length, 1);
  assertEquals(incAdj[0]._0, "c1");
});

// -- govern --

Deno.test("govern evaluates and applies adjustments in one pass", () => {
  const model = makeModel({
    vexometer: { index: 0.2, inertiaDetected: false },
    orbital: { stability: 0.9, divergenceLevel: 0.1 },
    humidity: "Low", // Should become High
  });
  const result = govern(model);
  assertEquals(result.humidity, "High");
});

Deno.test("govern returns unchanged model when no adjustments needed", () => {
  const model = makeModel({
    vexometer: { index: 0.5, inertiaDetected: false },
    orbital: { stability: 0.8, divergenceLevel: 0.2 },
    humidity: "Medium", // computeHumidity(0.5, 0.8) => Medium, no change
  });
  const result = govern(model);
  assertEquals(result.humidity, "Medium");
  assertEquals(result.antiCrash.strictMode, false);
});
