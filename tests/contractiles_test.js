// SPDX-License-Identifier: MPL-2.0

/**
 * Contractiles module tests
 *
 * ReScript compiles zero-arg variants to strings:
 *   Satisfied -> "Satisfied"
 *   Pending -> "Pending"
 * Payload variants compile to objects:
 *   Violated(msg) -> { TAG: "Violated", _0: msg }
 */

import { assertEquals } from "jsr:@std/assert";
import * as Contractiles from "../src/core/Contractiles.res.js";

Deno.test("Contractiles.defaultContractiles - returns 11 contracts", () => {
  const contracts = Contractiles.defaultContractiles();
  assertEquals(contracts.length, 11);
});

Deno.test("Contractiles.orbitalStabilityContract - above threshold is Satisfied", () => {
  const orbital = { stability: 0.8, divergenceLevel: 0.1, driftAuraColour: "indigo" };
  const result = Contractiles.orbitalStabilityContract(orbital, 0.7);

  // Satisfied is a zero-arg variant -> compiles to string "Satisfied"
  assertEquals(result, "Satisfied");
});

Deno.test("Contractiles.orbitalStabilityContract - below threshold is Violated", () => {
  const orbital = { stability: 0.5, divergenceLevel: 0.4, driftAuraColour: "amber" };
  const result = Contractiles.orbitalStabilityContract(orbital, 0.7);

  // Violated(msg) is a payload variant -> compiles to { TAG: "Violated", _0: msg }
  assertEquals(result.TAG, "Violated");
  assertEquals(typeof result._0, "string");
});

Deno.test("Contractiles.vexationCeilingContract - below ceiling is Satisfied", () => {
  const vexometer = {
    index: 0.3,
    recentCancellations: 0,
    recentCorrections: 0,
    antiInflammatoryActive: false,
    inertiaDetected: false
  };
  const result = Contractiles.vexationCeilingContract(vexometer, 0.7);

  assertEquals(result, "Satisfied");
});

Deno.test("Contractiles.vexationCeilingContract - above ceiling is Violated", () => {
  const vexometer = {
    index: 0.9,
    recentCancellations: 5,
    recentCorrections: 3,
    antiInflammatoryActive: true,
    inertiaDetected: false
  };
  const result = Contractiles.vexationCeilingContract(vexometer, 0.7);

  assertEquals(result.TAG, "Violated");
});
