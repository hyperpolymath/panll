// SPDX-License-Identifier: MPL-2.0

/**
 * DatabaseBridgeEngine Tests — default state, tab labels, schema/query counting,
 * proof obligation formatting, and snapshot summaries.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  countSchemas,
  countTotalColumns,
  countQueries,
  countQueriesByStatus,
  formatObligationStatus,
  countObligationsByStatus,
  proofObligationPercent,
  formatSnapshotSummary,
} from "../src/core/DatabaseBridgeEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.schemas.length, 0);
  assertEquals(defaultState.queries.length, 0);
  assertEquals(defaultState.proofObligations.length, 0);
  assertEquals(defaultState.connected, false);
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Schema"), "Schema");
  assertEquals(tabLabel("Queries"), "Queries");
  assertEquals(tabLabel("GameState"), "Game State");
  assertEquals(tabLabel("ProofObligations"), "Proof Obligations");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- formatObligationStatus --

Deno.test("formatObligationStatus returns correct labels", () => {
  assertEquals(formatObligationStatus("ObligationProven"), "Proven");
  assertEquals(formatObligationStatus("ObligationUnproven"), "Unproven");
  assertEquals(formatObligationStatus("ObligationViolated"), "Violated");
  assertEquals(formatObligationStatus("ObligationTimeout"), "Timeout");
});

// -- countSchemas with default state --

Deno.test("countSchemas returns 0 for default state", () => {
  assertEquals(countSchemas(defaultState), 0);
});

// -- countTotalColumns with empty array --

Deno.test("countTotalColumns returns 0 for empty array", () => {
  assertEquals(countTotalColumns([]), 0);
});

// -- proofObligationPercent with empty array --

Deno.test("proofObligationPercent returns 100 for empty array", () => {
  assertEquals(proofObligationPercent([]), 100.0);
});

// -- formatSnapshotSummary with None --

Deno.test("formatSnapshotSummary returns 'No snapshot' for undefined", () => {
  assertEquals(formatSnapshotSummary(undefined), "No snapshot");
});
