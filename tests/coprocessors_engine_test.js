// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * CoprocessorsEngine Tests — label helpers, colour mappings, backend
 * enumeration, call-log filtering, and default state validation.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  categoryLabel,
  backendLabel,
  backendShortLabel,
  backendColour,
  healthLabel,
  healthColour,
  allBackends,
  filterByBackend,
  defaultState,
} from "../src/core/CoprocessorsEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings", () => {
  assertEquals(categoryLabel("CoprocDashboard"), "Dashboard");
  assertEquals(categoryLabel("CoprocCallLog"), "Call Log");
  assertEquals(categoryLabel("CoprocHeatmap"), "Heatmap");
  assertEquals(categoryLabel("CoprocSettings"), "Settings");
});

// -- backendLabel --

Deno.test("backendLabel returns correct strings for all backends", () => {
  assertEquals(backendLabel("CoprocMaths"), "Maths");
  assertEquals(backendLabel("CoprocVector"), "Vector");
  assertEquals(backendLabel("CoprocTensor"), "Tensor");
  assertEquals(backendLabel("CoprocPhysics"), "Physics");
  assertEquals(backendLabel("CoprocCrypto"), "Crypto");
  assertEquals(backendLabel("CoprocNeural"), "Neural");
  assertEquals(backendLabel("CoprocQuantum"), "Quantum");
  assertEquals(backendLabel("CoprocAudio"), "Audio");
  assertEquals(backendLabel("CoprocGraphics"), "Graphics");
  assertEquals(backendLabel("CoprocIO"), "I/O");
});

// -- backendShortLabel --

Deno.test("backendShortLabel returns three-char codes", () => {
  assertEquals(backendShortLabel("CoprocMaths"), "MAT");
  assertEquals(backendShortLabel("CoprocVector"), "VEC");
  assertEquals(backendShortLabel("CoprocTensor"), "TEN");
  assertEquals(backendShortLabel("CoprocPhysics"), "PHY");
  assertEquals(backendShortLabel("CoprocCrypto"), "CRY");
  assertEquals(backendShortLabel("CoprocNeural"), "NEU");
  assertEquals(backendShortLabel("CoprocQuantum"), "QUA");
  assertEquals(backendShortLabel("CoprocAudio"), "AUD");
  assertEquals(backendShortLabel("CoprocGraphics"), "GFX");
  assertEquals(backendShortLabel("CoprocIO"), "I/O");
});

// -- backendColour --

Deno.test("backendColour returns Tailwind text-colour classes", () => {
  assertEquals(backendColour("CoprocMaths"), "text-blue-400");
  assertEquals(backendColour("CoprocVector"), "text-cyan-400");
  assertEquals(backendColour("CoprocTensor"), "text-indigo-400");
  assertEquals(backendColour("CoprocPhysics"), "text-amber-400");
  assertEquals(backendColour("CoprocCrypto"), "text-red-400");
  assertEquals(backendColour("CoprocNeural"), "text-emerald-400");
  assertEquals(backendColour("CoprocQuantum"), "text-purple-400");
  assertEquals(backendColour("CoprocAudio"), "text-pink-400");
  assertEquals(backendColour("CoprocGraphics"), "text-orange-400");
  assertEquals(backendColour("CoprocIO"), "text-gray-400");
});

// -- healthLabel --

Deno.test("healthLabel returns correct strings", () => {
  assertEquals(healthLabel("CoprocHealthy"), "Healthy");
  assertEquals(healthLabel("CoprocDegraded"), "Degraded");
  assertEquals(healthLabel("CoprocFailed"), "Failed");
  assertEquals(healthLabel("CoprocDisabled"), "Disabled");
});

// -- healthColour --

Deno.test("healthColour returns correct Tailwind classes", () => {
  assertEquals(healthColour("CoprocHealthy"), "text-emerald-400");
  assertEquals(healthColour("CoprocDegraded"), "text-amber-400");
  assertEquals(healthColour("CoprocFailed"), "text-red-400");
  assertEquals(healthColour("CoprocDisabled"), "text-gray-500");
});

// -- allBackends --

Deno.test("allBackends has 10 entries", () => {
  assertEquals(allBackends.length, 10);
});

Deno.test("allBackends contains every backend variant", () => {
  const expected = [
    "CoprocMaths",
    "CoprocVector",
    "CoprocTensor",
    "CoprocPhysics",
    "CoprocCrypto",
    "CoprocNeural",
    "CoprocQuantum",
    "CoprocAudio",
    "CoprocGraphics",
    "CoprocIO",
  ];
  assertEquals(allBackends, expected);
});

Deno.test("allBackends entries all have valid labels", () => {
  for (const backend of allBackends) {
    const label = backendLabel(backend);
    assert(typeof label === "string" && label.length > 0, `Missing label for ${backend}`);
  }
});

// -- filterByBackend --

Deno.test("filterByBackend returns only matching entries", () => {
  const log = [
    { id: 1, backend: "CoprocMaths", operation: "add", inputSummary: "", outputSummary: "", durationMs: 1.0, timestamp: 0.0, success: true },
    { id: 2, backend: "CoprocCrypto", operation: "hash", inputSummary: "", outputSummary: "", durationMs: 2.0, timestamp: 0.0, success: true },
    { id: 3, backend: "CoprocMaths", operation: "mul", inputSummary: "", outputSummary: "", durationMs: 0.5, timestamp: 0.0, success: false },
  ];
  const result = filterByBackend(log, "CoprocMaths");
  assertEquals(result.length, 2);
  assertEquals(result[0].id, 1);
  assertEquals(result[1].id, 3);
});

Deno.test("filterByBackend returns empty array when no matches", () => {
  const log = [
    { id: 1, backend: "CoprocAudio", operation: "play", inputSummary: "", outputSummary: "", durationMs: 5.0, timestamp: 0.0, success: true },
  ];
  const result = filterByBackend(log, "CoprocQuantum");
  assertEquals(result.length, 0);
});

Deno.test("filterByBackend returns empty array for empty log", () => {
  const result = filterByBackend([], "CoprocMaths");
  assertEquals(result.length, 0);
});

// -- defaultState --

Deno.test("defaultState has correct activeCategory", () => {
  assertEquals(defaultState.activeCategory, "CoprocDashboard");
});

Deno.test("defaultState has empty metrics, callLog, and heatmap", () => {
  assertEquals(defaultState.metrics.length, 0);
  assertEquals(defaultState.callLog.length, 0);
  assertEquals(defaultState.heatmap.length, 0);
});

Deno.test("defaultState enabledBackends matches allBackends", () => {
  assertEquals(defaultState.enabledBackends, allBackends);
});

Deno.test("defaultState selectedBackend is undefined (None)", () => {
  assertEquals(defaultState.selectedBackend, undefined);
});

Deno.test("defaultState has empty filterText", () => {
  assertEquals(defaultState.filterText, "");
});

Deno.test("defaultState autoRefresh is true", () => {
  assertEquals(defaultState.autoRefresh, true);
});

Deno.test("defaultState refreshIntervalMs is 2000", () => {
  assertEquals(defaultState.refreshIntervalMs, 2000);
});

Deno.test("defaultState loading is false", () => {
  assertEquals(defaultState.loading, false);
});

Deno.test("defaultState error is undefined (None)", () => {
  assertEquals(defaultState.error, undefined);
});
