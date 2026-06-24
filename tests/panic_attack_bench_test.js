// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/**
 * panic-attack Benchmarks — Deno.bench() performance tests
 *
 * Measures throughput of:
 *   - PanicAttackerCapability.parse (valid, invalid, minimal, large payloads)
 *   - PanicAttackerMode.toneClass / label (mode string formatting)
 *   - MassPanicModel.init (model access baseline)
 *
 * Run: deno bench --no-check --allow-all tests/panic_attack_bench_test.js
 */

import { parse } from "../src/core/PanicAttackerCapability.res.js";
import { toneClass, label } from "../src/core/PanicAttackerMode.res.js";
import { init } from "../src/model/MassPanicModel.res.js";

// ---------------------------------------------------------------------------
// Payload generators
// ---------------------------------------------------------------------------

/** Standard full-mode capability payload. */
function makeFullCapability() {
  return JSON.stringify({
    mode: "full",
    supports_panll: true,
    supports_ambush: true,
    binary: "/usr/local/bin/panic-attack",
    detail: "panic-attack panll export is available",
  });
}

/** Minimal capability payload (only required field). */
function makeMinimalCapability() {
  return JSON.stringify({ detail: "minimal" });
}

/** Invalid JSON string. */
const INVALID_JSON = "{this is not valid json at all!!!";

/** Large capability payload with many extra weak-point entries. */
function makeLargeCapability(weakPointCount) {
  const weakPoints = [];
  for (let i = 0; i < weakPointCount; i++) {
    weakPoints.push({
      id: `wp-${i}`,
      category: i % 2 === 0 ? "memory" : "cpu",
      severity: i % 5 === 0 ? "critical" : "low",
      description: `Weak point ${i} found in function foo_${i} at offset 0x${(i * 16).toString(16)}`,
      file: `/src/module_${i % 50}/handler.rs`,
      line: 100 + i,
    });
  }
  return JSON.stringify({
    mode: "full",
    supports_panll: true,
    supports_ambush: true,
    binary: "/usr/local/bin/panic-attack",
    detail: "panic-attack panll export with large weak-point manifest",
    weak_points: weakPoints,
  });
}

// Pre-build payloads so setup cost does not skew measurements
const FULL_PAYLOAD = makeFullCapability();
const MINIMAL_PAYLOAD = makeMinimalCapability();
const LARGE_50_PAYLOAD = makeLargeCapability(50);
const LARGE_500_PAYLOAD = makeLargeCapability(500);
const LARGE_2000_PAYLOAD = makeLargeCapability(2000);

// All four known modes
const MODES = ["full", "fallback", "unavailable", "unknown"];

// ---------------------------------------------------------------------------
// 1. PanicAttackerCapability parsing benchmarks
// ---------------------------------------------------------------------------

Deno.bench("parse — full capability payload", {
  group: "capability-parse",
  baseline: true,
}, () => {
  parse(FULL_PAYLOAD);
});

Deno.bench("parse — minimal capability payload", {
  group: "capability-parse",
}, () => {
  parse(MINIMAL_PAYLOAD);
});

Deno.bench("parse — invalid JSON (error path)", {
  group: "capability-parse",
}, () => {
  parse(INVALID_JSON);
});

Deno.bench("parse — large payload (50 weak points)", {
  group: "capability-parse-large",
  baseline: true,
}, () => {
  parse(LARGE_50_PAYLOAD);
});

Deno.bench("parse — large payload (500 weak points)", {
  group: "capability-parse-large",
}, () => {
  parse(LARGE_500_PAYLOAD);
});

Deno.bench("parse — large payload (2000 weak points)", {
  group: "capability-parse-large",
}, () => {
  parse(LARGE_2000_PAYLOAD);
});

Deno.bench("parse — empty object", {
  group: "capability-parse",
}, () => {
  parse("{}");
});

Deno.bench("parse — deeply nested irrelevant JSON", {
  group: "capability-parse",
}, () => {
  parse(JSON.stringify({
    mode: "full",
    detail: "nested",
    nested: { a: { b: { c: { d: { e: { f: "deep" } } } } } },
  }));
});

// ---------------------------------------------------------------------------
// 2. PanicAttackerMode benchmarks
// ---------------------------------------------------------------------------

Deno.bench("toneClass — all four modes", {
  group: "mode-presentation",
  baseline: true,
}, () => {
  for (const mode of MODES) {
    toneClass(mode);
  }
});

Deno.bench("label — all four modes", {
  group: "mode-presentation",
}, () => {
  for (const mode of MODES) {
    label(mode);
  }
});

Deno.bench("toneClass — single 'full' mode", {
  group: "mode-single",
  baseline: true,
}, () => {
  toneClass("full");
});

Deno.bench("label — single 'full' mode", {
  group: "mode-single",
}, () => {
  label("full");
});

Deno.bench("toneClass — unknown/default mode", {
  group: "mode-single",
}, () => {
  toneClass("some-unknown-mode");
});

Deno.bench("label — unknown/default mode", {
  group: "mode-single",
}, () => {
  label("some-unknown-mode");
});

// ---------------------------------------------------------------------------
// 3. MassPanicModel benchmarks
// ---------------------------------------------------------------------------

Deno.bench("MassPanicModel.init — access initial state fields", {
  group: "model-init",
  baseline: true,
}, () => {
  // Access key fields to prevent dead-code elimination
  const _dir = init.reposDirectory;
  const _scanning = init.scanning;
  const _progress = init.progress;
  const _view = init.activeView;
});

Deno.bench("MassPanicModel.init — shallow clone (simulating model update)", {
  group: "model-init",
}, () => {
  const updated = { ...init, scanning: true, progress: 0.5 };
  const _s = updated.scanning;
});

Deno.bench("MassPanicModel.init — deep field access chain", {
  group: "model-init",
}, () => {
  const _incr = init.incremental;
  const _sort = init.sortMode;
  const _filter = init.filterMode;
  const _notify = init.notifyEnabled;
  const _crit = init.notifyCriticalOnly;
  const _img = init.currentImage;
  const _diff = init.currentDiff;
  const _snap = init.snapshots;
});

// ---------------------------------------------------------------------------
// 4. End-to-end: parse + mode lookup
// ---------------------------------------------------------------------------

Deno.bench("E2E — parse capability then format mode label", {
  group: "end-to-end",
  baseline: true,
}, () => {
  const result = parse(FULL_PAYLOAD);
  if (result.TAG === "Ok") {
    label(result._0.mode);
    toneClass(result._0.mode);
  }
});

Deno.bench("E2E — parse minimal then format mode label", {
  group: "end-to-end",
}, () => {
  const result = parse(MINIMAL_PAYLOAD);
  if (result.TAG === "Ok") {
    label(result._0.mode);
    toneClass(result._0.mode);
  }
});

Deno.bench("E2E — parse error then fallback label", {
  group: "end-to-end",
}, () => {
  const result = parse(INVALID_JSON);
  if (result.TAG === "Error") {
    label("unavailable");
    toneClass("unavailable");
  }
});
