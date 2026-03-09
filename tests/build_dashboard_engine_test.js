// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * BuildDashboardEngine Tests — targets, statuses, message counts, test counts
 */

import { assertEquals } from "jsr:@std/assert";
import {
  categoryLabel,
  targetLabel,
  targetColour,
  statusLabel,
  statusColour,
  defaultTargets,
  errorCount,
  warningCount,
  passedTestCount,
  failedTestCount,
  defaultState,
} from "../src/core/BuildDashboardEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("BuildOverview"), "Overview");
  assertEquals(categoryLabel("BuildErrors"), "Errors");
  assertEquals(categoryLabel("BuildTests"), "Tests");
  assertEquals(categoryLabel("BuildHistory"), "History");
});

// -- targetLabel / targetColour --

Deno.test("targetLabel returns correct labels", () => {
  assertEquals(targetLabel("TargetGame"), "Game");
  assertEquals(targetLabel("TargetVm"), "VM");
  assertEquals(targetLabel("TargetDlc"), "DLC");
  assertEquals(targetLabel("TargetSyncServer"), "Sync Server");
  assertEquals(targetLabel("TargetShared"), "Shared");
  assertEquals(targetLabel("TargetCoprocessors"), "Coprocessors");
  assertEquals(targetLabel({ _0: "Custom" }), "Custom");
});

Deno.test("targetColour returns correct classes", () => {
  assertEquals(targetColour("TargetGame"), "text-cyan-400");
  assertEquals(targetColour("TargetVm"), "text-purple-400");
  assertEquals(targetColour({ _0: "x" }), "text-gray-400");
});

// -- statusLabel / statusColour --

Deno.test("statusLabel returns correct strings", () => {
  assertEquals(statusLabel("BuildIdle"), "Idle");
  assertEquals(statusLabel("BuildRunning"), "Building...");
  assertEquals(statusLabel("BuildCancelled"), "Cancelled");
  assertEquals(statusLabel({ TAG: "BuildSuccess", _0: 5000 }), "Success");
  assertEquals(statusLabel({ TAG: "BuildFailed", _0: "OOM" }), "Failed");
});

Deno.test("statusColour returns correct classes", () => {
  assertEquals(statusColour("BuildIdle"), "text-gray-500");
  assertEquals(statusColour("BuildRunning"), "text-amber-400");
  assertEquals(statusColour({ TAG: "BuildSuccess", _0: 1 }), "text-emerald-400");
  assertEquals(statusColour({ TAG: "BuildFailed", _0: "x" }), "text-red-400");
});

// -- defaultTargets --

Deno.test("defaultTargets has 6 entries all idle", () => {
  assertEquals(defaultTargets.length, 6);
  assertEquals(defaultTargets.every(t => t[1] === "BuildIdle"), true);
});

// -- errorCount / warningCount --

Deno.test("errorCount counts error messages", () => {
  const msgs = [{ severity: "error" }, { severity: "warning" }, { severity: "error" }];
  assertEquals(errorCount(msgs), 2);
});

Deno.test("warningCount counts warning messages", () => {
  const msgs = [{ severity: "error" }, { severity: "warning" }, { severity: "warning" }];
  assertEquals(warningCount(msgs), 2);
});

// -- passedTestCount / failedTestCount --

Deno.test("passedTestCount counts passed tests", () => {
  const results = [{ passed: true }, { passed: false }, { passed: true }];
  assertEquals(passedTestCount(results), 2);
});

Deno.test("failedTestCount counts failed tests", () => {
  const results = [{ passed: true }, { passed: false }];
  assertEquals(failedTestCount(results), 1);
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.activeCategory, "BuildOverview");
  assertEquals(defaultState.autoRebuild, false);
  assertEquals(defaultState.watchMode, false);
  assertEquals(defaultState.showPassedTests, true);
  assertEquals(defaultState.loading, false);
  assertEquals(defaultState.bojRouting, false);
});
