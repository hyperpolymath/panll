// SPDX-License-Identifier: MPL-2.0

/**
 * MigrationEngine Tests — version brackets, labels, health, filtering, sorting
 */

import { assertEquals } from "jsr:@std/assert";
import {
  versionBracketLabel,
  versionBracketColor,
  configFormatLabel,
  trendLabel,
  trendIndicator,
  categoryLabel,
  reportTypeLabel,
  submissionStatusLabel,
  submissionStatusColor,
  healthColor,
  healthPercent,
  filterRepos,
  sortByHealth,
  computeAvgHealth,
  countReady,
  countBlocked,
  defaultState,
} from "../src/core/MigrationEngine.res.js";

// -- versionBracketLabel / versionBracketColor --

Deno.test("versionBracketLabel returns correct labels", () => {
  assertEquals(versionBracketLabel("BuckleScript"), "BuckleScript");
  assertEquals(versionBracketLabel("V12Current"), "v12-current");
  assertEquals(versionBracketLabel("V13PreRelease"), "v13-prerelease");
  assertEquals(versionBracketLabel("VersionUnknown"), "unknown");
});

Deno.test("versionBracketColor returns correct classes", () => {
  assertEquals(versionBracketColor("BuckleScript"), "bg-red-500");
  assertEquals(versionBracketColor("V12Current"), "bg-green-400");
});

// -- configFormatLabel --

Deno.test("configFormatLabel returns correct labels", () => {
  assertEquals(configFormatLabel("BsConfig"), "bsconfig.json");
  assertEquals(configFormatLabel("RescriptJson"), "rescript.json");
});

// -- trendLabel / trendIndicator --

Deno.test("trendLabel returns correct strings", () => {
  assertEquals(trendLabel("Improving"), "Improving");
  assertEquals(trendLabel("Stable"), "Stable");
  assertEquals(trendLabel("Regressing"), "Regressing");
});

Deno.test("trendIndicator returns correct colours", () => {
  assertEquals(trendIndicator("Improving"), "text-green-400");
  assertEquals(trendIndicator("Regressing"), "text-red-400");
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("MigrationDashboard"), "Dashboard");
  assertEquals(categoryLabel("MigrationTimeline"), "Timeline");
  assertEquals(categoryLabel("MigrationMergeResolver"), "Merge Resolver");
});

// -- reportTypeLabel --

Deno.test("reportTypeLabel returns correct labels", () => {
  assertEquals(reportTypeLabel("PerRepoReport"), "Per-Repo");
  assertEquals(reportTypeLabel("V13TrialReport"), "v13 Trial");
});

// -- submissionStatusLabel / submissionStatusColor --

Deno.test("submissionStatusLabel returns correct labels", () => {
  assertEquals(submissionStatusLabel("SubmissionPending"), "Pending");
  assertEquals(submissionStatusLabel("SubmissionApproved"), "Approved");
});

Deno.test("submissionStatusColor returns correct colours", () => {
  assertEquals(submissionStatusColor("SubmissionPending"), "text-yellow-400");
  assertEquals(submissionStatusColor("SubmissionApproved"), "text-green-400");
});

// -- healthColor / healthPercent --

Deno.test("healthColor returns green for >= 0.8", () => {
  assertEquals(healthColor(0.9), "text-green-400");
});

Deno.test("healthColor returns yellow for 0.5-0.79", () => {
  assertEquals(healthColor(0.6), "text-yellow-400");
});

Deno.test("healthColor returns red for < 0.5", () => {
  assertEquals(healthColor(0.3), "text-red-400");
});

Deno.test("healthPercent formats correctly", () => {
  assertEquals(healthPercent(0.85), "85%");
});

// -- filterRepos --

Deno.test("filterRepos returns all when query is empty", () => {
  const repos = [{ name: "foo" }, { name: "bar" }];
  assertEquals(filterRepos(repos, "").length, 2);
});

Deno.test("filterRepos filters by name", () => {
  const repos = [{ name: "panll" }, { name: "other" }];
  assertEquals(filterRepos(repos, "panll").length, 1);
});

// -- sortByHealth --

Deno.test("sortByHealth sorts ascending", () => {
  const repos = [{ healthScore: 0.9 }, { healthScore: 0.3 }];
  const sorted = sortByHealth(repos);
  assertEquals(sorted[0].healthScore, 0.3);
});

// -- computeAvgHealth --

Deno.test("computeAvgHealth returns 0 for empty", () => {
  assertEquals(computeAvgHealth([]), 0.0);
});

Deno.test("computeAvgHealth computes average", () => {
  const repos = [{ healthScore: 0.8 }, { healthScore: 0.6 }];
  assertEquals(computeAvgHealth(repos), 0.7);
});

// -- countReady / countBlocked --

Deno.test("countReady counts ready repos", () => {
  const repos = [
    { healthScore: 0.9, blocked: false },
    { healthScore: 0.9, blocked: true },
    { healthScore: 0.3, blocked: false },
  ];
  assertEquals(countReady(repos), 1);
});

Deno.test("countBlocked counts blocked repos", () => {
  const repos = [{ blocked: true }, { blocked: false }, { blocked: true }];
  assertEquals(countBlocked(repos), 2);
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.loaded, false);
  assertEquals(defaultState.activeCategory, "MigrationDashboard");
  assertEquals(defaultState.activeReportType, "PerRepoReport");
  assertEquals(defaultState.totalRepos, 0);
  assertEquals(defaultState.avgHealth, 0.0);
});
