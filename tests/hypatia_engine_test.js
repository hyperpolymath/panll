// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * HypatiaEngine Tests — network labels, stages, categories, parsing, confidence
 */

import { assertEquals } from "jsr:@std/assert";
import {
  netLabel,
  netDescription,
  netStatusColor,
  stageLabel,
  categoryLabel,
  filterScans,
  avgConfidence,
  parseNetworks,
  parseScans,
  defaultState,
} from "../src/core/HypatiaEngine.res.js";

// -- netLabel / netDescription --

Deno.test("netLabel returns correct labels", () => {
  assertEquals(netLabel("GraphOfTrust"), "Graph of Trust");
  assertEquals(netLabel("MixtureOfExperts"), "Mixture of Experts");
  assertEquals(netLabel("LiquidStateMachine"), "Liquid State Machine");
  assertEquals(netLabel("EchoStateNetwork"), "Echo State Network");
  assertEquals(netLabel("RadialNeuralNetwork"), "Radial Neural Network");
});

Deno.test("netDescription returns correct descriptions", () => {
  assertEquals(netDescription("GraphOfTrust"), "PageRank trust over repos/bots/recipes");
  assertEquals(netDescription("MixtureOfExperts"), "Domain-specific confidence (7 experts)");
});

// -- netStatusColor --

Deno.test("netStatusColor returns correct classes", () => {
  assertEquals(netStatusColor("NetActive"), "bg-green-400");
  assertEquals(netStatusColor("NetTraining"), "bg-blue-400 animate-pulse");
  assertEquals(netStatusColor("NetOffline"), "bg-gray-500");
  assertEquals(netStatusColor({ TAG: "NetError", _0: "x" }), "bg-red-400");
});

// -- stageLabel --

Deno.test("stageLabel returns correct labels", () => {
  assertEquals(stageLabel("Ingestion"), "Ingestion");
  assertEquals(stageLabel("Analysis"), "Analysis");
  assertEquals(stageLabel("Routing"), "Routing");
  assertEquals(stageLabel("Dispatch"), "Dispatch");
  assertEquals(stageLabel("Complete"), "Complete");
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("HypatiaDashboard"), "Dashboard");
  assertEquals(categoryLabel("HypatiaScans"), "Scans");
  assertEquals(categoryLabel("HypatiaQuarantine"), "Quarantine");
  assertEquals(categoryLabel("HypatiaNeural"), "Neural");
  assertEquals(categoryLabel("HypatiaRecipes"), "Recipes");
});

// -- filterScans --

Deno.test("filterScans returns all when query empty", () => {
  const scans = [{ repoName: "foo" }];
  assertEquals(filterScans(scans, "").length, 1);
});

Deno.test("filterScans filters by repo name", () => {
  const scans = [{ repoName: "panll" }, { repoName: "other" }];
  assertEquals(filterScans(scans, "panll").length, 1);
});

// -- avgConfidence --

Deno.test("avgConfidence returns 0 for empty", () => {
  assertEquals(avgConfidence([]), 0.0);
});

Deno.test("avgConfidence computes average of active networks", () => {
  const nets = [
    { status: "NetActive", confidence: 0.8 },
    { status: "NetActive", confidence: 0.6 },
    { status: "NetOffline", confidence: 0.9 },
  ];
  assertEquals(avgConfidence(nets), 0.7);
});

// -- parseNetworks --

Deno.test("parseNetworks parses valid JSON", () => {
  const json = JSON.stringify([
    { id: "graph_of_trust", status: "active", confidence: 0.85, inference_count: 100, version: "1.0" },
  ]);
  const result = parseNetworks(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.length, 1);
  assertEquals(result._0[0].id, "GraphOfTrust");
  assertEquals(result._0[0].status, "NetActive");
});

Deno.test("parseNetworks returns error for invalid JSON", () => {
  assertEquals(parseNetworks("bad").TAG, "Error");
});

Deno.test("parseNetworks returns error for non-array", () => {
  assertEquals(parseNetworks('"string"').TAG, "Error");
});

// -- parseScans --

Deno.test("parseScans parses valid JSON", () => {
  const json = JSON.stringify([
    { repo_name: "panll", risk_score: 0.2, finding_count: 3, quarantine_count: 0, last_scanned: "now", passed: true },
  ]);
  const result = parseScans(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0[0].repoName, "panll");
  assertEquals(result._0[0].passed, true);
});

Deno.test("parseScans returns error for invalid JSON", () => {
  assertEquals(parseScans("{bad}").TAG, "Error");
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.loaded, false);
  assertEquals(defaultState.networks.length, 0);
  assertEquals(defaultState.scans.length, 0);
  assertEquals(defaultState.activeCategory, "HypatiaDashboard");
  assertEquals(defaultState.totalRepos, 0);
  assertEquals(defaultState.quarantinedCount, 0);
});
