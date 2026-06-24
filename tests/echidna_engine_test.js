// SPDX-License-Identifier: MPL-2.0

/**
 * EchidnaEngine Tests — default state, enterprise model state, tab labels.
 *
 * Tests the pure helper functions exported by EchidnaEngine.res.
 * For ECHIDNA update/dispatch logic, see echidna_update_test.js.
 *
 * ReScript variant compilation rules:
 * - Zero-arg variants compile to STRINGS (e.g., "EchidnaProofTab")
 * - Payload variants compile to objects with TAG (e.g., { TAG: "...", _0: ... })
 * - option<T> compiles to T | undefined (None = undefined, Some(x) = x)
 */

import { assertEquals } from "jsr:@std/assert";
import {
  defaultEnterpriseModelState,
  defaultState,
  tabLabel,
} from "../src/core/EchidnaEngine.res.js";

// ===========================================================================
// tabLabel — maps echidnaTab variants to display strings
// ===========================================================================

Deno.test("tabLabel returns 'Proof Workbench' for EchidnaProofTab", () => {
  assertEquals(tabLabel("EchidnaProofTab"), "Proof Workbench");
});

Deno.test("tabLabel returns 'Enterprise Model' for EchidnaEnterpriseTab", () => {
  assertEquals(tabLabel("EchidnaEnterpriseTab"), "Enterprise Model");
});

Deno.test("tabLabel returns distinct strings for different tabs", () => {
  const proof = tabLabel("EchidnaProofTab");
  const enterprise = tabLabel("EchidnaEnterpriseTab");
  assertEquals(proof !== enterprise, true);
});

// ===========================================================================
// defaultEnterpriseModelState — initial enterprise model checking state
// ===========================================================================

Deno.test("defaultEnterpriseModelState has empty elements array", () => {
  assertEquals(defaultEnterpriseModelState.elements.length, 0);
  assertEquals(Array.isArray(defaultEnterpriseModelState.elements), true);
});

Deno.test("defaultEnterpriseModelState has empty constraints array", () => {
  assertEquals(defaultEnterpriseModelState.constraints.length, 0);
  assertEquals(Array.isArray(defaultEnterpriseModelState.constraints), true);
});

Deno.test("defaultEnterpriseModelState has empty checkResults array", () => {
  assertEquals(defaultEnterpriseModelState.checkResults.length, 0);
  assertEquals(Array.isArray(defaultEnterpriseModelState.checkResults), true);
});

Deno.test("defaultEnterpriseModelState has checking set to false", () => {
  assertEquals(defaultEnterpriseModelState.checking, false);
});

Deno.test("defaultEnterpriseModelState has activeMetamodel as None (undefined)", () => {
  assertEquals(defaultEnterpriseModelState.activeMetamodel, undefined);
});

Deno.test("defaultEnterpriseModelState has activeLayer as None (undefined)", () => {
  assertEquals(defaultEnterpriseModelState.activeLayer, undefined);
});

Deno.test("defaultEnterpriseModelState has lastXmiImport as None (undefined)", () => {
  assertEquals(defaultEnterpriseModelState.lastXmiImport, undefined);
});

// ===========================================================================
// defaultState — initial ECHIDNA panel state
// ===========================================================================

// -- Connection / endpoint --

Deno.test("defaultState has connected set to false", () => {
  assertEquals(defaultState.connected, false);
});

Deno.test("defaultState has correct default endpoint", () => {
  assertEquals(defaultState.endpoint, "http://localhost:9000/api/v1");
});

Deno.test("defaultState has version as None (undefined)", () => {
  assertEquals(defaultState.version, undefined);
});

// -- Prover catalog --

Deno.test("defaultState has empty provers array", () => {
  assertEquals(defaultState.provers.length, 0);
  assertEquals(Array.isArray(defaultState.provers), true);
});

Deno.test("defaultState has selectedProver as None (undefined)", () => {
  assertEquals(defaultState.selectedProver, undefined);
});

// -- Proof lifecycle --

Deno.test("defaultState has lastProofResult as None (undefined)", () => {
  assertEquals(defaultState.lastProofResult, undefined);
});

Deno.test("defaultState has proofError as None (undefined)", () => {
  assertEquals(defaultState.proofError, undefined);
});

Deno.test("defaultState has proofLoading set to false", () => {
  assertEquals(defaultState.proofLoading, false);
});

Deno.test("defaultState has empty proofInput string", () => {
  assertEquals(defaultState.proofInput, "");
});

// -- Interactive session --

Deno.test("defaultState has session as None (undefined)", () => {
  assertEquals(defaultState.session, undefined);
});

Deno.test("defaultState has empty tacticSuggestions array", () => {
  assertEquals(defaultState.tacticSuggestions.length, 0);
  assertEquals(Array.isArray(defaultState.tacticSuggestions), true);
});

Deno.test("defaultState has empty tacticInput string", () => {
  assertEquals(defaultState.tacticInput, "");
});

Deno.test("defaultState has sessionLoading set to false", () => {
  assertEquals(defaultState.sessionLoading, false);
});

// -- UI state --

Deno.test("defaultState has menuExpanded set to false", () => {
  assertEquals(defaultState.menuExpanded, false);
});

Deno.test("defaultState has activeTab set to EchidnaProofTab", () => {
  assertEquals(defaultState.activeTab, "EchidnaProofTab");
});

// -- Cross-panel intelligence --

Deno.test("defaultState has lastProofObligations as None (undefined)", () => {
  assertEquals(defaultState.lastProofObligations, undefined);
});

Deno.test("defaultState has bojRouting set to false", () => {
  assertEquals(defaultState.bojRouting, false);
});

// -- Enterprise model sub-state --

Deno.test("defaultState embeds defaultEnterpriseModelState", () => {
  assertEquals(defaultState.enterpriseModel.elements.length, 0);
  assertEquals(defaultState.enterpriseModel.constraints.length, 0);
  assertEquals(defaultState.enterpriseModel.checkResults.length, 0);
  assertEquals(defaultState.enterpriseModel.checking, false);
  assertEquals(defaultState.enterpriseModel.activeMetamodel, undefined);
  assertEquals(defaultState.enterpriseModel.activeLayer, undefined);
  assertEquals(defaultState.enterpriseModel.lastXmiImport, undefined);
});

Deno.test("defaultState.enterpriseModel is structurally equal to defaultEnterpriseModelState", () => {
  assertEquals(
    JSON.stringify(defaultState.enterpriseModel),
    JSON.stringify(defaultEnterpriseModelState),
  );
});
