// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * InterfacesEngine Tests — category labels, ABI totals, verification, coverage
 */

import { assertEquals } from "jsr:@std/assert";
import {
  categoryLabel,
  totalAbiExports,
  totalBelieveMe,
  verificationRate,
  avgCoverage,
  defaultState,
} from "../src/core/InterfacesEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns Dashboard", () => {
  assertEquals(categoryLabel("IfaceDashboard"), "Dashboard");
});

Deno.test("categoryLabel returns ABI (Idris2)", () => {
  assertEquals(categoryLabel("IfaceAbi"), "ABI (Idris2)");
});

Deno.test("categoryLabel returns FFI (Zig)", () => {
  assertEquals(categoryLabel("IfaceFfi"), "FFI (Zig)");
});

Deno.test("categoryLabel returns Bindings", () => {
  assertEquals(categoryLabel("IfaceBindings"), "Bindings");
});

// -- totalAbiExports --

Deno.test("totalAbiExports sums export counts", () => {
  const defs = [{ exportCount: 10 }, { exportCount: 20 }];
  assertEquals(totalAbiExports(defs), 30);
});

Deno.test("totalAbiExports returns 0 for empty", () => {
  assertEquals(totalAbiExports([]), 0);
});

// -- totalBelieveMe --

Deno.test("totalBelieveMe sums believe_me counts", () => {
  const defs = [{ believeMeCount: 5 }, { believeMeCount: 3 }];
  assertEquals(totalBelieveMe(defs), 8);
});

// -- verificationRate --

Deno.test("verificationRate returns 0 for empty", () => {
  assertEquals(verificationRate([]), 0.0);
});

Deno.test("verificationRate returns correct ratio", () => {
  const defs = [{ verified: true }, { verified: false }, { verified: true }];
  const rate = verificationRate(defs);
  assertEquals(rate, 2 / 3);
});

// -- avgCoverage --

Deno.test("avgCoverage returns 0 for empty", () => {
  assertEquals(avgCoverage([]), 0.0);
});

Deno.test("avgCoverage computes average", () => {
  const bindings = [{ coverage: 0.8 }, { coverage: 0.6 }];
  assertEquals(avgCoverage(bindings), 0.7);
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.loaded, false);
  assertEquals(defaultState.loading, false);
  assertEquals(defaultState.abiDefs.length, 0);
  assertEquals(defaultState.ffiImpls.length, 0);
  assertEquals(defaultState.bindings.length, 0);
  assertEquals(defaultState.activeCategory, "IfaceDashboard");
  assertEquals(defaultState.totalBelieveMe, 0);
});
