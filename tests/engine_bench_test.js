// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * Engine Benchmarks — Deno.bench() performance tests for core engines
 *
 * Measures throughput of:
 *   - Model initialisation (full 41-panel state)
 *   - Update cycle (message dispatch + state transition)
 *   - TypeLL type checking across panels
 *   - AntiCrash token validation
 *   - OrbitalSync computation
 *   - Contractiles evaluation
 *   - SeamEngine audit
 *   - VabEngine dependency checking
 *   - Panel switching
 *
 * Run: deno bench tests/engine_bench_test.js
 */

import { init as initModel } from "../src/Model.res.js";
import * as Update from "../src/Update.res.js";
import * as AntiCrashEngine from "../src/core/AntiCrash.res.js";
import * as OrbitalSync from "../src/core/OrbitalSync.res.js";
import * as Contractiles from "../src/core/Contractiles.res.js";
import * as SeamEngine from "../src/core/SeamEngine.res.js";
import * as VabEngine from "../src/core/VabEngine.res.js";
import * as VabCatalog from "../src/core/VabCatalog.res.js";
import * as TypeLLEngine from "../src/core/TypeLLEngine.res.js";

// ---------------------------------------------------------------------------
// Model initialisation benchmarks
// ---------------------------------------------------------------------------

Deno.bench("Model.init() — full 41-panel state", () => {
  initModel();
});

Deno.bench("Model.init() — access all panel fields", () => {
  const m = initModel();
  // Touch each major submodel to measure field access
  void m.paneL;
  void m.paneN;
  void m.paneW;
  void m.antiCrash;
  void m.vexometer;
  void m.orbital;
  void m.contractiles;
  void m.vab;
  void m.typell;
  void m.boj;
  void m.automation;
});

// ---------------------------------------------------------------------------
// Update cycle benchmarks
// ---------------------------------------------------------------------------

Deno.bench("Update — NoOp (baseline overhead)", () => {
  const m = initModel();
  Update.update(m, "NoOp");
});

Deno.bench("Update — SaveState", () => {
  const m = initModel();
  Update.update(m, "SaveState");
});

Deno.bench("Update — PaneL.AddConstraint", () => {
  const m = initModel();
  const msg = {
    TAG: "PaneL",
    _0: {
      TAG: "AddConstraint",
      _0: { id: "bench-c1", name: "Bench", body: "x > 0", active: true, pinned: false },
    },
  };
  Update.update(m, msg);
});

Deno.bench("Update — PaneN.IngestToken (via AntiCrash)", () => {
  const m = initModel();
  const msg = {
    TAG: "AntiCrash",
    _0: {
      TAG: "ValidationPassed",
      _0: { content: "bench token", timestamp: Date.now(), confidence: 0.9, validated: false },
    },
  };
  Update.update(m, msg);
});

Deno.bench("Update — 10 sequential messages", () => {
  let m = initModel();
  for (let i = 0; i < 10; i++) {
    const [newM] = Update.update(m, "NoOp");
    m = newM;
  }
});

Deno.bench("Update — 100 sequential messages", () => {
  let m = initModel();
  for (let i = 0; i < 100; i++) {
    const [newM] = Update.update(m, "NoOp");
    m = newM;
  }
});

Deno.bench("Update — ResetAllPanels", () => {
  const m = initModel();
  Update.update(m, "ResetAllPanels");
});

// ---------------------------------------------------------------------------
// AntiCrash benchmarks
// ---------------------------------------------------------------------------

Deno.bench("AntiCrash — validate safe token (with constraints)", () => {
  const token = { content: "safe output", timestamp: Date.now(), confidence: 0.95, validated: false };
  const constraints = [{ id: "c1", name: "Test", body: "x > 0", active: true, pinned: false }];
  AntiCrashEngine.validate(token, constraints);
});

Deno.bench("AntiCrash — validate 100 tokens", () => {
  const constraints = [{ id: "c1", name: "Test", body: "x > 0", active: true, pinned: false }];
  for (let i = 0; i < 100; i++) {
    const token = { content: `token-${i}`, timestamp: Date.now(), confidence: 0.5 + Math.random() * 0.5, validated: false };
    AntiCrashEngine.validate(token, constraints);
  }
});

// ---------------------------------------------------------------------------
// OrbitalSync benchmarks
// ---------------------------------------------------------------------------

Deno.bench("OrbitalSync — sync computation", () => {
  const m = initModel();
  OrbitalSync.sync(m, m.orbital);
});

// ---------------------------------------------------------------------------
// Contractiles benchmarks
// ---------------------------------------------------------------------------

Deno.bench("Contractiles — evaluateAll", () => {
  const m = initModel();
  Contractiles.evaluateAll(m, m.contractiles);
});

// ---------------------------------------------------------------------------
// SeamEngine benchmarks
// ---------------------------------------------------------------------------

Deno.bench("SeamEngine — buildRegister", () => {
  SeamEngine.buildRegister("2026-03-09");
});

Deno.bench("SeamEngine — auditRegister", () => {
  const register = SeamEngine.buildRegister("2026-03-09");
  SeamEngine.auditRegister(register, "2026-03-09");
});

Deno.bench("SeamEngine — generateA2mlRegister", () => {
  const register = SeamEngine.buildRegister("2026-03-09");
  SeamEngine.generateA2mlRegister(register);
});

Deno.bench("SeamEngine — summariseRegister", () => {
  const register = SeamEngine.buildRegister("2026-03-09");
  SeamEngine.summariseRegister(register, "2026-03-09");
});

Deno.bench("SeamEngine — scanForDriftIndicators (50 files)", () => {
  const files = Array.from({ length: 50 }, (_, i) => `src/core/Engine${i}.res`);
  SeamEngine.scanForDriftIndicators(files);
});

Deno.bench("SeamEngine — scanForDriftIndicators (500 files)", () => {
  const files = Array.from({ length: 500 }, (_, i) => `src/components/Panel${i}.res`);
  SeamEngine.scanForDriftIndicators(files);
});

Deno.bench("SeamEngine — fullScan (100 files)", () => {
  const files = Array.from({ length: 100 }, (_, i) => `src/model/Model${i}.res`);
  SeamEngine.fullScan(files, "2026-03-09");
});

// ---------------------------------------------------------------------------
// VabEngine benchmarks
// ---------------------------------------------------------------------------

Deno.bench("VabEngine — checkDependencies (5 components)", () => {
  const components = VabCatalog.catalog.slice(0, 5);
  VabEngine.checkDependencies(components);
});

Deno.bench("VabEngine — checkDependencies (50 components)", () => {
  const components = VabCatalog.catalog.slice(0, 50);
  VabEngine.checkDependencies(components);
});

Deno.bench("VabEngine — computeCapabilities (full catalog)", () => {
  VabEngine.computeCapabilities(VabCatalog.catalog);
});

// ---------------------------------------------------------------------------
// TypeLL benchmarks
// ---------------------------------------------------------------------------

Deno.bench("TypeLLEngine — parseCheckResult (valid)", () => {
  TypeLLEngine.parseCheckResult('{"valid":true,"type":"string","value":"hello"}');
});

Deno.bench("TypeLLEngine — parseCheckResult (100 parses)", () => {
  for (let i = 0; i < 100; i++) {
    TypeLLEngine.parseCheckResult(`{"valid":true,"type":"int","value":${i}}`);
  }
});

Deno.bench("TypeLLEngine — categoryLabel all categories", () => {
  const cats = ["TlChecker", "TlInference", "TlRefinement", "TlMonitor", "TlSearch"];
  for (const c of cats) {
    TypeLLEngine.categoryLabel(c);
  }
});

// ---------------------------------------------------------------------------
// Panel switching benchmarks
// ---------------------------------------------------------------------------

Deno.bench("Update — TogglePanel (20 switches)", () => {
  let m = initModel();
  const panels = [
    "panel-l", "panel-n", "panel-w", "vab", "cloudguard",
    "farm", "plaza", "reposystem", "aerie", "interfaces",
    "playgrounds", "hypatia", "fleet", "minter", "protocol-squisher",
    "my-lang", "boj", "tentacles", "clade-browser", "automation",
  ];
  for (const p of panels) {
    const [newM] = Update.update(m, { TAG: "PanelSwitcher", _0: { TAG: "TogglePanel", _0: p } });
    m = newM;
  }
});
