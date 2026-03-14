// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * ScriptingBridgeEngine Tests — default state, tab labels, tier labels,
 * instruction counting, REPL entry formatting, and analysis severity labels.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  defaultState,
  tabLabel,
  allTabs,
  tierLabel,
  countInstructionsByTier,
  countAllowedInstructions,
  countSavedScripts,
  formatReplEntry,
  countReplErrors,
  countFindingsBySeverity,
  analysisSeverityLabel,
} from "../src/core/ScriptingBridgeEngine.res.js";

// -- defaultState --

Deno.test("defaultState exists and has expected shape", () => {
  assertExists(defaultState);
  assertEquals(typeof defaultState, "object");
  assertEquals(defaultState.replHistory.length, 0);
  assertEquals(defaultState.instructions.length, 0);
  assertEquals(defaultState.savedScripts.length, 0);
  assertEquals(defaultState.executing, false);
  assertEquals(defaultState.replInput, "");
  assertEquals(defaultState.error, undefined);
});

// -- tabLabel --

Deno.test("tabLabel returns correct labels", () => {
  assertEquals(tabLabel("Repl"), "REPL");
  assertEquals(tabLabel("Instructions"), "Instructions");
  assertEquals(tabLabel("Scripts"), "Scripts");
  assertEquals(tabLabel("Analysis"), "Analysis");
});

// -- allTabs --

Deno.test("allTabs contains all four tabs", () => {
  assertEquals(allTabs.length, 4);
});

// -- tierLabel --

Deno.test("tierLabel returns correct labels", () => {
  assertEquals(tierLabel("TierSafe"), "Tier 0 (Safe)");
  assertEquals(tierLabel("TierControlled"), "Tier 1 (Controlled)");
  assertEquals(tierLabel("TierPrivileged"), "Tier 2 (Privileged)");
  assertEquals(tierLabel("TierSystem"), "Tier 3 (System)");
});

// -- analysisSeverityLabel --

Deno.test("analysisSeverityLabel returns correct labels", () => {
  assertEquals(analysisSeverityLabel("AnalysisError"), "Error");
  assertEquals(analysisSeverityLabel("AnalysisWarning"), "Warning");
  assertEquals(analysisSeverityLabel("AnalysisInfo"), "Info");
  assertEquals(analysisSeverityLabel("AnalysisOptimisation"), "Optimisation");
});

// -- countSavedScripts with default state --

Deno.test("countSavedScripts returns 0 for default state", () => {
  assertEquals(countSavedScripts(defaultState), 0);
});

// -- countReplErrors with empty array --

Deno.test("countReplErrors returns 0 for empty array", () => {
  assertEquals(countReplErrors([]), 0);
});
