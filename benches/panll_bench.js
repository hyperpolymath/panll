// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/**
 * PanLL Benchmarks — standalone bench entry point for CRG C baseline.
 *
 * Covers the four high-value benchmark categories:
 *   1. TEA update cycle latency (model → update → view pipeline)
 *   2. Panel creation and destruction time
 *   3. IPC message throughput (serialise/deserialise round-trip)
 *   4. Layout algorithm time vs panel count
 *
 * Run:
 *   deno bench --no-check --allow-read --allow-env benches/panll_bench.js
 *
 * Results are reported in ns/iter by Deno's built-in bench harness.
 * Throughput ops/sec can be derived from ns/iter: ops_sec = 1e9 / ns_per_iter
 *
 * Naming rule: always "panels" — never "panes" in code or docs.
 */

import { init as initModel } from "../src/Model.res.js";
import * as Update from "../src/Update.res.js";
import * as TilingEngine from "../src/core/TilingEngine.res.js";
import * as PanelBus from "../src/core/PanelBus.res.js";
import * as PanelRegistry from "../src/modules/PanelRegistry.res.js";
import * as AntiCrash from "../src/core/AntiCrash.res.js";
import * as Contractiles from "../src/core/Contractiles.res.js";

// ============================================================================
// 1. TEA Update Cycle Latency
//    Measures the critical path: model snapshot → dispatch → new model
// ============================================================================

Deno.bench({
  name: "TEA cycle — NoOp baseline (pure dispatch overhead)",
  group: "tea-cycle",
  baseline: true,
  fn() {
    const m = initModel();
    Update.update(m, "NoOp");
  },
});

Deno.bench({
  name: "TEA cycle — PaneL.AddConstraint (state mutation)",
  group: "tea-cycle",
  fn() {
    const m = initModel();
    Update.update(m, {
      TAG: "PaneL",
      _0: {
        TAG: "AddConstraint",
        _0: { id: "b-1", expression: "x > 0", active: true, pinned: false, kind: "Invariant", source: "bench" },
      },
    });
  },
});

Deno.bench({
  name: "TEA cycle — AntiCrash.ValidationPassed (token + paneN mutation)",
  group: "tea-cycle",
  fn() {
    const m = initModel();
    Update.update(m, {
      TAG: "AntiCrash",
      _0: {
        TAG: "ValidationPassed",
        _0: { content: "bench token", timestamp: 0, confidence: 0.95, validated: false },
      },
    });
  },
});

Deno.bench({
  name: "TEA cycle — 10 sequential updates (sustained throughput)",
  group: "tea-cycle",
  fn() {
    let m = initModel();
    for (let i = 0; i < 10; i++) {
      const [nm] = Update.update(m, "NoOp");
      m = nm;
    }
  },
});

Deno.bench({
  name: "TEA cycle — 100 sequential updates (load test)",
  group: "tea-cycle",
  fn() {
    let m = initModel();
    for (let i = 0; i < 100; i++) {
      const [nm] = Update.update(m, "NoOp");
      m = nm;
    }
  },
});

Deno.bench({
  name: "TEA cycle — mixed 20-message workload",
  group: "tea-cycle",
  fn() {
    let m = initModel();
    const msgs = [
      { TAG: "Vexometer", _0: "RecordCancellation" },
      { TAG: "Vexometer", _0: "RecordCorrection" },
      { TAG: "PaneN", _0: "ClearTokens" },
      { TAG: "View", _0: "TogglePaneL" },
      "SaveState",
      { TAG: "Orbital", _0: { TAG: "UpdateStability", _0: 0.6 } },
      { TAG: "TypeLL", _0: { TAG: "SetTlCategory", _0: "TlExplorer" } },
      { TAG: "AntiCrash", _0: { TAG: "ValidationPassed", _0: { content: "ok", timestamp: 0, confidence: 0.9, validated: false } } },
      "NoOp",
      { TAG: "View", _0: { TAG: "SetHumidity", _0: "Low" } },
      { TAG: "Workspace", _0: "ResetAllPanels" },
      "NoOp",
      { TAG: "PaneL", _0: { TAG: "AddConstraint", _0: { id: "c1", expression: "y > 0", active: true, pinned: false, kind: "Invariant", source: "bench" } } },
      { TAG: "Tsdm", _0: { TAG: "SetAxisFilter", _0: "scope" } },
      { TAG: "Boj", _0: "RefreshHealth" },
      { TAG: "Vexometer", _0: "RecordCancellation" },
      "NoOp",
      { TAG: "TypeLL", _0: "ToggleTypellBojRouting" },
      { TAG: "View", _0: "TogglePaneN" },
      "SaveState",
    ];
    for (const msg of msgs) {
      const [nm] = Update.update(m, msg);
      m = nm;
    }
  },
});

// ============================================================================
// 2. Panel Creation / Destruction Time
//    Measures how long it takes to initialise panel state and reset it.
//    "Panel creation" in TEA = initialising the sub-model field.
//    "Panel destruction" = resetting state via ResetAllPanels or targeted reset.
// ============================================================================

Deno.bench({
  name: "Panel lifecycle — Model.init() (108-panel state creation)",
  group: "panel-lifecycle",
  baseline: true,
  fn() {
    initModel();
  },
});

Deno.bench({
  name: "Panel lifecycle — ResetAllPanels (full state reset)",
  group: "panel-lifecycle",
  fn() {
    const m = initModel();
    Update.update(m, { TAG: "Workspace", _0: "ResetAllPanels" });
  },
});

Deno.bench({
  name: "Panel lifecycle — PanelRegistry.allPanels lookup",
  group: "panel-lifecycle",
  fn() {
    void PanelRegistry.allPanels.length;
  },
});

Deno.bench({
  name: "Panel lifecycle — findPanel × 20 (sequential lookups)",
  group: "panel-lifecycle",
  fn() {
    const ids = PanelRegistry.allPanels.slice(0, 20).map((p) => p.id);
    for (const id of ids) {
      PanelRegistry.findPanel(id);
    }
  },
});

Deno.bench({
  name: "Panel lifecycle — panelName × 108 (all panels)",
  group: "panel-lifecycle",
  fn() {
    for (const p of PanelRegistry.allPanels) {
      PanelRegistry.panelName(p.id);
    }
  },
});

Deno.bench({
  name: "Panel lifecycle — TogglePanel × 10 (open/close simulation)",
  group: "panel-lifecycle",
  fn() {
    let m = initModel();
    const panels = PanelRegistry.allPanels.slice(0, 10).map((p) => p.id);
    for (const id of panels) {
      const [nm] = Update.update(m, { TAG: "PanelSwitcher", _0: { TAG: "TogglePanel", _0: id } });
      m = nm;
    }
  },
});

// ============================================================================
// 3. IPC Message Throughput
//    Measures serialise/deserialise overhead of message objects.
//    PanelBus wraps + routes events; JSON round-trips model slices.
// ============================================================================

Deno.bench({
  name: "IPC — PanelBus.wrapEvent single event",
  group: "ipc-throughput",
  baseline: true,
  fn() {
    const reg = PanelBus.defaultRegistry;
    PanelBus.wrapEvent(reg, "hypatia", { TAG: "HypatiaFindingsRouted", _0: {} }, Date.now());
  },
});

Deno.bench({
  name: "IPC — PanelBus.wrapEvent × 50 burst",
  group: "ipc-throughput",
  fn() {
    let reg = PanelBus.defaultRegistry;
    const now = Date.now();
    for (let i = 0; i < 50; i++) {
      const [_env, newReg] = PanelBus.wrapEvent(reg, "fleet", { TAG: "RepoHealthChanged", _0: `repo-${i}`, _1: 0.8 }, now + i);
      reg = newReg;
    }
  },
});

Deno.bench({
  name: "IPC — JSON.stringify model slice (paneL)",
  group: "ipc-throughput",
  fn() {
    const m = initModel();
    JSON.stringify(m.paneL);
  },
});

Deno.bench({
  name: "IPC — JSON round-trip full model snapshot",
  group: "ipc-throughput",
  fn() {
    const m = initModel();
    const serialised = JSON.stringify(m);
    JSON.parse(serialised);
  },
});

Deno.bench({
  name: "IPC — AntiCrash token pipeline × 100 messages",
  group: "ipc-throughput",
  fn() {
    const state = AntiCrash.init();
    const constraints = [
      { id: "c1", expression: "type Safe", active: true, pinned: false },
    ];
    for (let i = 0; i < 100; i++) {
      const token = { content: `output-${i}`, confidence: 0.8, sourcePaneId: "panel-n", inferredType: "text" };
      AntiCrash.processToken(token, constraints, state);
    }
  },
});

Deno.bench({
  name: "IPC — PanelBus.subscribersForTopic all topics",
  group: "ipc-throughput",
  fn() {
    const reg = PanelBus.defaultRegistry;
    for (const t of PanelBus.allTopics) {
      PanelBus.subscribersForTopic(reg, t);
    }
  },
});

// ============================================================================
// 4. Layout Algorithm Time vs Panel Count
//    Measures TilingEngine tiling computation for 1, 4, 9, 16, and 36 panels.
//    Layout should be O(n) or O(n log n) — test verifies no pathological growth.
// ============================================================================

/** Build a fake panel list of the given size for layout benchmarking. */
function makePanels(count) {
  return Array.from({ length: count }, (_, i) => ({
    id: `panel-${i}`,
    name: `Panel ${i}`,
    width: 400,
    height: 300,
    x: 0,
    y: 0,
    visible: true,
    zIndex: i,
  }));
}

Deno.bench({
  name: "Layout — TilingEngine.tile 1 panel (minimum)",
  group: "layout-scaling",
  baseline: true,
  fn() {
    const panels = makePanels(1);
    TilingEngine.tile(panels, 1920, 1080);
  },
});

Deno.bench({
  name: "Layout — TilingEngine.tile 4 panels (2×2 grid)",
  group: "layout-scaling",
  fn() {
    const panels = makePanels(4);
    TilingEngine.tile(panels, 1920, 1080);
  },
});

Deno.bench({
  name: "Layout — TilingEngine.tile 9 panels (3×3 grid)",
  group: "layout-scaling",
  fn() {
    const panels = makePanels(9);
    TilingEngine.tile(panels, 1920, 1080);
  },
});

Deno.bench({
  name: "Layout — TilingEngine.tile 16 panels (4×4 grid)",
  group: "layout-scaling",
  fn() {
    const panels = makePanels(16);
    TilingEngine.tile(panels, 1920, 1080);
  },
});

Deno.bench({
  name: "Layout — TilingEngine.tile 36 panels (6×6 grid)",
  group: "layout-scaling",
  fn() {
    const panels = makePanels(36);
    TilingEngine.tile(panels, 1920, 1080);
  },
});

Deno.bench({
  name: "Layout — TilingEngine.tile 108 panels (full registry)",
  group: "layout-scaling",
  fn() {
    const panels = makePanels(108);
    TilingEngine.tile(panels, 1920, 1080);
  },
});

Deno.bench({
  name: "Layout — TilingEngine.computeLayout (explicit mode, 9 panels)",
  group: "layout-scaling",
  fn() {
    const panels = makePanels(9);
    TilingEngine.computeLayout(panels, "grid", 1920, 1080);
  },
});

Deno.bench({
  name: "Layout — TilingEngine.computeLayout (explicit mode, 36 panels)",
  group: "layout-scaling",
  fn() {
    const panels = makePanels(36);
    TilingEngine.computeLayout(panels, "grid", 1920, 1080);
  },
});

// ============================================================================
// 5. Contractiles Evaluation (governance overhead per TEA cycle)
// ============================================================================

Deno.bench({
  name: "Contractiles — evaluateAll 11 contracts (clean model)",
  group: "contractiles",
  baseline: true,
  fn() {
    const m = initModel();
    const contracts = Contractiles.defaultContractiles();
    Contractiles.evaluateAll(m, contracts);
  },
});

Deno.bench({
  name: "Contractiles — evaluateAll 11 contracts (stressed model)",
  group: "contractiles",
  fn() {
    const base = initModel();
    const m = {
      ...base,
      vexometer: { ...base.vexometer, index: 0.9, recentCancellations: 8, antiInflammatoryActive: true },
      antiCrash: { ...base.antiCrash, violations: Array.from({ length: 12 }, (_, i) => `v-${i}`) },
      orbital: { ...base.orbital, stability: 0.2, divergenceLevel: 0.8 },
    };
    const contracts = Contractiles.defaultContractiles();
    Contractiles.evaluateAll(m, contracts);
  },
});
