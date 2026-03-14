// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * ProofsBridgeEngine Tests — default state, tab labels, proof coverage,
 * module counting, verification status labels, and result kind labels.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  overallProofCoverage,
  countVerifiedModules,
  countPendingModules,
  countModulesByStatus,
  verificationStatusLabel,
  resultKindLabel,
  countResultsByKind,
  countUnprovedFunctions,
} from "../src/core/ProofsBridgeEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.provenModules.length, 0);
  assertEquals(defaultState.verificationResults.length, 0);
  assertEquals(defaultState.coveragePercent, 0.0);
  assertEquals(defaultState.verifying, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Modules"), "Modules");
  assertEquals(tabLabel("Proofs"), "Proofs");
  assertEquals(tabLabel("Coverage"), "Coverage");
  assertEquals(tabLabel("Verification"), "Verification");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- overallProofCoverage with empty array --

Deno.test("overallProofCoverage returns 100 for empty array", () => {
  assertEquals(overallProofCoverage([]), 100.0);
});

// -- verificationStatusLabel --

Deno.test("verificationStatusLabel returns correct labels", () => {
  assertEquals(verificationStatusLabel("FullyProven"), "Fully Proven");
  assertEquals(verificationStatusLabel("PartiallyProven"), "Partially Proven");
  assertEquals(verificationStatusLabel("Unverified"), "Unverified");
  assertEquals(verificationStatusLabel("Stale"), "Stale");
});

// -- resultKindLabel --

Deno.test("resultKindLabel returns correct labels", () => {
  assertEquals(resultKindLabel("VerificationProved"), "Proved");
  assertEquals(resultKindLabel("VerificationCounterexample"), "Counterexample");
  assertEquals(resultKindLabel("VerificationTimeout"), "Timeout");
  assertEquals(resultKindLabel("VerificationError"), "Error");
});

// -- countVerifiedModules with empty array --

Deno.test("countVerifiedModules returns 0 for empty array", () => {
  assertEquals(countVerifiedModules([]), 0);
});

// -- countUnprovedFunctions with empty array --

Deno.test("countUnprovedFunctions returns 0 for empty array", () => {
  assertEquals(countUnprovedFunctions([]), 0);
});
