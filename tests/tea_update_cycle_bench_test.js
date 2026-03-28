// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * TEA Update Cycle Benchmarks — measures dispatch latency across panel domains,
 * contractiles post-processing overhead, and governance feedback loop performance.
 *
 * Complements engine_bench_test.js with cross-cutting performance measurements:
 *   - Per-domain update dispatch latency
 *   - Contractiles evaluation overhead (M1–M5 pass)
 *   - Governance evaluate + apply cycle
 *   - OrbitalSync sync under load
 *   - Panel Bus event wrapping and batching
 *   - Full round-trip: msg → update → contractiles → governance → bus
 *
 * Run: deno bench tests/tea_update_cycle_bench_test.js
 */

import { init as initModel } from "../src/Model.res.js";
import * as Update from "../src/Update.res.js";
import * as GovernanceEngine from "../src/core/GovernanceEngine.res.js";
import * as Contractiles from "../src/core/Contractiles.res.js";
import * as OrbitalSync from "../src/core/OrbitalSync.res.js";
import * as PanelBus from "../src/core/PanelBus.res.js";
import * as AntiCrashEngine from "../src/core/AntiCrash.res.js";

// ---------------------------------------------------------------------------
// Per-domain update dispatch benchmarks
// ---------------------------------------------------------------------------

Deno.bench("Update dispatch — Governance.Vexometer (RecordCancellation)", () => {
  const m = initModel();
  Update.update(m, { TAG: "Vexometer", _0: "RecordCancellation" });
});

Deno.bench("Update dispatch — Governance.Orbital (RecalculateStability)", () => {
  const m = initModel();
  Update.update(m, { TAG: "Orbital", _0: { TAG: "UpdateStability", _0: 0.5 } });
});

Deno.bench("Update dispatch — View (TogglePaneL)", () => {
  const m = initModel();
  Update.update(m, { TAG: "View", _0: "TogglePaneL" });
});

Deno.bench("Update dispatch — PaneL (AddConstraint)", () => {
  const m = initModel();
  Update.update(m, {
    TAG: "PaneL",
    _0: {
      TAG: "AddConstraint",
      _0: { id: "bench-1", name: "Bench", body: "x > 0", active: true, pinned: false },
    },
  });
});

Deno.bench("Update dispatch — PaneN (ClearTokens)", () => {
  const m = initModel();
  Update.update(m, { TAG: "PaneN", _0: "ClearTokens" });
});

Deno.bench("Update dispatch — AntiCrash ValidationPassed", () => {
  const m = initModel();
  Update.update(m, {
    TAG: "AntiCrash",
    _0: {
      TAG: "ValidationPassed",
      _0: { content: "bench token", timestamp: Date.now(), confidence: 0.95, validated: false },
    },
  });
});

Deno.bench("Update dispatch — TSDM (SetAxisFilter)", () => {
  const m = initModel();
  Update.update(m, { TAG: "Tsdm", _0: { TAG: "SetAxisFilter", _0: "scope" } });
});

Deno.bench("Update dispatch — Boj (RefreshHealth)", () => {
  const m = initModel();
  Update.update(m, { TAG: "Boj", _0: "RefreshHealth" });
});

// ---------------------------------------------------------------------------
// Contractiles post-processing benchmarks (M1–M5 pass)
// ---------------------------------------------------------------------------

Deno.bench("Contractiles — evaluateAll (11 contracts, clean model)", () => {
  const m = initModel();
  const contracts = Contractiles.defaultContractiles();
  Contractiles.evaluateAll(m, contracts);
});

Deno.bench("Contractiles — evaluateAll (11 contracts, stressed model)", () => {
  const m = {
    ...initModel(),
    vexometer: { ...initModel().vexometer, index: 0.85, recentCancellations: 5, antiInflammatoryActive: true },
    antiCrash: { ...initModel().antiCrash, violations: Array.from({ length: 8 }, (_, i) => `v-${i}`) },
    orbital: { ...initModel().orbital, stability: 0.35, divergenceLevel: 0.7 },
  };
  const contracts = Contractiles.defaultContractiles();
  Contractiles.evaluateAll(m, contracts);
});

Deno.bench("Contractiles — adaptContract × 11 (elasticity adjustment)", () => {
  const m = initModel();
  const contracts = Contractiles.defaultContractiles();
  for (const c of contracts) {
    Contractiles.adaptContract(c, m);
  }
});

// ---------------------------------------------------------------------------
// Governance feedback loop benchmarks
// ---------------------------------------------------------------------------

Deno.bench("GovernanceEngine — evaluate (clean model)", () => {
  const m = initModel();
  GovernanceEngine.evaluate(m);
});

Deno.bench("GovernanceEngine — evaluate (stressed model)", () => {
  const m = {
    ...initModel(),
    vexometer: { ...initModel().vexometer, index: 0.85, recentCancellations: 5 },
    antiCrash: { ...initModel().antiCrash, violations: Array.from({ length: 8 }, (_, i) => `v-${i}`) },
    orbital: { ...initModel().orbital, stability: 0.35, divergenceLevel: 0.7 },
  };
  GovernanceEngine.evaluate(m);
});

Deno.bench("GovernanceEngine — govern (evaluate + apply, clean)", () => {
  const m = initModel();
  GovernanceEngine.govern(m);
});

Deno.bench("GovernanceEngine — govern (evaluate + apply, stressed)", () => {
  const m = {
    ...initModel(),
    vexometer: { ...initModel().vexometer, index: 0.9, recentCancellations: 10, inertiaDetected: false },
    antiCrash: { ...initModel().antiCrash, violations: Array.from({ length: 12 }, (_, i) => `v-${i}`) },
    orbital: { ...initModel().orbital, stability: 0.2, divergenceLevel: 0.8 },
  };
  GovernanceEngine.govern(m);
});

Deno.bench("GovernanceEngine — applyAll (6 mixed adjustments)", () => {
  const m = initModel();
  const adjustments = [
    "TightenAntiCrash",
    "LoosenAntiCrash",
    "ResumeInference",
    { TAG: "AdjustHumidity", _0: "Low" },
    { TAG: "IncreaseElasticity", _0: "orbital-stability" },
    { TAG: "DecreaseElasticity", _0: "vexation-ceiling" },
  ];
  GovernanceEngine.applyAll(m, adjustments);
});

// ---------------------------------------------------------------------------
// OrbitalSync under load
// ---------------------------------------------------------------------------

Deno.bench("OrbitalSync — sync after 50 model mutations", () => {
  let m = initModel();
  // Simulate 50 state mutations to accumulate divergence
  for (let i = 0; i < 50; i++) {
    m = {
      ...m,
      paneL: { ...m.paneL, editorContent: `content-${i}` },
      paneN: { ...m.paneN, monologue: `monologue-${i}` },
    };
  }
  OrbitalSync.sync(m, m.orbital);
});

Deno.bench("OrbitalSync — calculateDivergence (large strings)", () => {
  const paneL = { constraints: [], activeConstraintId: undefined, editorContent: "x".repeat(10000) };
  const paneN = { tokens: [], activeTokenId: undefined, monologue: "y".repeat(10000), inferenceStatus: "idle", autonomyLevel: 0.0 };
  OrbitalSync.calculateDivergence(paneL, paneN);
});

// ---------------------------------------------------------------------------
// Panel Bus event wrapping and batching
// ---------------------------------------------------------------------------

Deno.bench("PanelBus — wrapEvent (single event)", () => {
  const reg = PanelBus.defaultRegistry;
  const evt = { TAG: "HypatiaFindingsRouted", _0: {} };
  PanelBus.wrapEvent(reg, "hypatia", evt, Date.now());
});

Deno.bench("PanelBus — wrapEvent × 50 (burst)", () => {
  let reg = PanelBus.defaultRegistry;
  const now = Date.now();
  for (let i = 0; i < 50; i++) {
    const evt = { TAG: "RepoHealthChanged", _0: `repo-${i}`, _1: 0.8 };
    const [_envelope, newReg] = PanelBus.wrapEvent(reg, "fleet", evt, now + i);
    reg = newReg;
  }
});

Deno.bench("PanelBus — subscribersForTopic (12 topics)", () => {
  const reg = PanelBus.defaultRegistry;
  const topics = PanelBus.allTopics;
  for (const t of topics) {
    PanelBus.subscribersForTopic(reg, t);
  }
});

// ---------------------------------------------------------------------------
// Full round-trip: msg → update → contractiles → governance → state
// ---------------------------------------------------------------------------

Deno.bench("Full round-trip — AddConstraint + governance pass", () => {
  const m = initModel();
  const msg = {
    TAG: "PaneL",
    _0: {
      TAG: "AddConstraint",
      _0: { id: "rt-1", name: "RoundTrip", body: "y > 0", active: true, pinned: false },
    },
  };
  Update.update(m, msg);
});

Deno.bench("Full round-trip — 10 mixed messages sequential", () => {
  let m = initModel();
  const messages = [
    { TAG: "PaneL", _0: { TAG: "AddConstraint", _0: { id: "c1", name: "C", body: "x > 0", active: true, pinned: false } } },
    { TAG: "Vexometer", _0: "RecordCancellation" },
    { TAG: "Orbital", _0: { TAG: "UpdateStability", _0: 0.5 } },
    { TAG: "AntiCrash", _0: { TAG: "ValidationPassed", _0: { content: "ok", timestamp: 0, confidence: 0.9, validated: false } } },
    { TAG: "View", _0: "TogglePaneL" },
    "NoOp",
    { TAG: "PaneN", _0: "ClearTokens" },
    { TAG: "Vexometer", _0: "RecordCorrection" },
    { TAG: "View", _0: { TAG: "SetHumidity", _0: "Medium" } },
    "SaveState",
  ];
  for (const msg of messages) {
    const [newM] = Update.update(m, msg);
    m = newM;
  }
});

Deno.bench("Full round-trip — 100 messages sustained load", () => {
  let m = initModel();
  for (let i = 0; i < 100; i++) {
    const msg = i % 3 === 0
      ? { TAG: "Vexometer", _0: "RecordCancellation" }
      : i % 3 === 1
        ? { TAG: "Orbital", _0: { TAG: "UpdateStability", _0: 0.5 } }
        : "NoOp";
    const [newM] = Update.update(m, msg);
    m = newM;
  }
});

// ---------------------------------------------------------------------------
// AntiCrash gate throughput
// ---------------------------------------------------------------------------

Deno.bench("AntiCrash — processToken pipeline × 100", () => {
  const state = AntiCrashEngine.init();
  const constraints = [
    { id: "c1", expression: "type Safe", active: true, pinned: false },
    { id: "c2", expression: "!contains(\"eval\")", active: true, pinned: false },
  ];
  for (let i = 0; i < 100; i++) {
    const token = { content: `output-${i}`, confidence: 0.7 + Math.random() * 0.3, sourcePaneId: "pane-n", inferredType: "code" };
    AntiCrashEngine.processToken(token, constraints, state);
  }
});

Deno.bench("AntiCrash — checkSecurityConstraints × 1000", () => {
  for (let i = 0; i < 1000; i++) {
    const token = { content: `const x${i} = safe_value;`, confidence: 0.9, sourcePaneId: "pane-n", inferredType: "code" };
    AntiCrashEngine.checkSecurityConstraints(token);
  }
});
