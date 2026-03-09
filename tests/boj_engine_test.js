// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * BojEngine Tests — category labels, grade helpers, protocol mappings,
 * cartridge filtering, layer progress, peer state display, and default state.
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  categoryLabel,
  gradeLabel,
  gradeColour,
  protocolLabel,
  protocolShort,
  peerStateLabel,
  peerStateColour,
  loadedCount,
  countByGrade,
  filterCartridges,
  hasProtocol,
  allProtocols,
  layerProgress,
  defaultState,
} from "../src/core/BojEngine.res.js";

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

/** Minimal cartridge factory for test data. */
function makeCartridge(overrides = {}) {
  return {
    name: "test-mcp",
    displayName: "Test MCP",
    description: "A test cartridge",
    grade: "GradeD",
    loaded: false,
    protocols: ["ProtoMCP"],
    layers: {
      abiReady: false,
      ffiReady: false,
      adapterReady: false,
      sharedLibReady: false,
    },
    soHash: "abc123",
    restPort: 0,
    grpcPort: 0,
    graphqlPort: 0,
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// categoryLabel
// ---------------------------------------------------------------------------

Deno.test("categoryLabel returns correct strings for all categories", () => {
  assertEquals(categoryLabel("Dashboard"), "Dashboard");
  assertEquals(categoryLabel("Cartridges"), "Cartridges");
  assertEquals(categoryLabel("Topology"), "Topology");
  assertEquals(categoryLabel("Federation"), "Federation");
  assertEquals(categoryLabel("Invoke"), "Invoke");
});

// ---------------------------------------------------------------------------
// gradeLabel
// ---------------------------------------------------------------------------

Deno.test("gradeLabel returns human-readable grade strings", () => {
  assertEquals(gradeLabel("GradeD"), "D (Alpha)");
  assertEquals(gradeLabel("GradeC"), "C (Beta)");
  assertEquals(gradeLabel("GradeB"), "B (RC)");
  assertEquals(gradeLabel("GradeA"), "A (Production)");
});

// ---------------------------------------------------------------------------
// gradeColour
// ---------------------------------------------------------------------------

Deno.test("gradeColour returns Tailwind classes for each grade", () => {
  assertEquals(
    gradeColour("GradeD"),
    "bg-yellow-900/50 text-yellow-300 border-yellow-700",
  );
  assertEquals(
    gradeColour("GradeC"),
    "bg-blue-900/50 text-blue-300 border-blue-700",
  );
  assertEquals(
    gradeColour("GradeB"),
    "bg-emerald-900/50 text-emerald-300 border-emerald-700",
  );
  assertEquals(
    gradeColour("GradeA"),
    "bg-green-900/50 text-green-300 border-green-700",
  );
});

// ---------------------------------------------------------------------------
// protocolLabel
// ---------------------------------------------------------------------------

Deno.test("protocolLabel returns full name for each protocol", () => {
  assertEquals(protocolLabel("ProtoMCP"), "MCP");
  assertEquals(protocolLabel("ProtoLSP"), "LSP");
  assertEquals(protocolLabel("ProtoDAP"), "DAP");
  assertEquals(protocolLabel("ProtoBSP"), "BSP");
  assertEquals(protocolLabel("ProtoNeSy"), "NeSy");
  assertEquals(protocolLabel("ProtoAgentic"), "Agentic");
  assertEquals(protocolLabel("ProtoFleet"), "Fleet");
  assertEquals(protocolLabel("ProtoGRPC"), "gRPC");
  assertEquals(protocolLabel("ProtoREST"), "REST");
  assertEquals(protocolLabel("ProtoGraphQL"), "GraphQL");
});

// ---------------------------------------------------------------------------
// protocolShort
// ---------------------------------------------------------------------------

Deno.test("protocolShort returns abbreviated header labels", () => {
  assertEquals(protocolShort("ProtoMCP"), "MCP");
  assertEquals(protocolShort("ProtoLSP"), "LSP");
  assertEquals(protocolShort("ProtoDAP"), "DAP");
  assertEquals(protocolShort("ProtoBSP"), "BSP");
  assertEquals(protocolShort("ProtoNeSy"), "NeSy");
  assertEquals(protocolShort("ProtoAgentic"), "Agent");
  assertEquals(protocolShort("ProtoFleet"), "Fleet");
  assertEquals(protocolShort("ProtoGRPC"), "gRPC");
  assertEquals(protocolShort("ProtoREST"), "REST");
  assertEquals(protocolShort("ProtoGraphQL"), "GQL");
});

// ---------------------------------------------------------------------------
// peerStateLabel
// ---------------------------------------------------------------------------

Deno.test("peerStateLabel returns human-readable peer state strings", () => {
  assertEquals(peerStateLabel("PeerPending"), "Pending");
  assertEquals(peerStateLabel("PeerExchanged"), "Exchanged");
  assertEquals(peerStateLabel("PeerVerified"), "Verified");
  assertEquals(peerStateLabel("PeerRejected"), "Rejected");
  assertEquals(peerStateLabel("PeerStale"), "Stale");
});

// ---------------------------------------------------------------------------
// peerStateColour
// ---------------------------------------------------------------------------

Deno.test("peerStateColour returns Tailwind text colour classes", () => {
  assertEquals(peerStateColour("PeerPending"), "text-yellow-400");
  assertEquals(peerStateColour("PeerExchanged"), "text-blue-400");
  assertEquals(peerStateColour("PeerVerified"), "text-green-400");
  assertEquals(peerStateColour("PeerRejected"), "text-red-400");
  assertEquals(peerStateColour("PeerStale"), "text-gray-500");
});

// ---------------------------------------------------------------------------
// loadedCount
// ---------------------------------------------------------------------------

Deno.test("loadedCount returns 0 for empty array", () => {
  assertEquals(loadedCount([]), 0);
});

Deno.test("loadedCount counts only loaded cartridges", () => {
  const cartridges = [
    makeCartridge({ name: "a", loaded: true }),
    makeCartridge({ name: "b", loaded: false }),
    makeCartridge({ name: "c", loaded: true }),
  ];
  assertEquals(loadedCount(cartridges), 2);
});

Deno.test("loadedCount returns 0 when none loaded", () => {
  const cartridges = [
    makeCartridge({ name: "a", loaded: false }),
    makeCartridge({ name: "b", loaded: false }),
  ];
  assertEquals(loadedCount(cartridges), 0);
});

// ---------------------------------------------------------------------------
// countByGrade
// ---------------------------------------------------------------------------

Deno.test("countByGrade returns 0 for empty array", () => {
  assertEquals(countByGrade([], "GradeD"), 0);
});

Deno.test("countByGrade counts cartridges matching the given grade", () => {
  const cartridges = [
    makeCartridge({ name: "a", grade: "GradeD" }),
    makeCartridge({ name: "b", grade: "GradeC" }),
    makeCartridge({ name: "c", grade: "GradeD" }),
    makeCartridge({ name: "d", grade: "GradeA" }),
  ];
  assertEquals(countByGrade(cartridges, "GradeD"), 2);
  assertEquals(countByGrade(cartridges, "GradeC"), 1);
  assertEquals(countByGrade(cartridges, "GradeB"), 0);
  assertEquals(countByGrade(cartridges, "GradeA"), 1);
});

// ---------------------------------------------------------------------------
// filterCartridges
// ---------------------------------------------------------------------------

Deno.test("filterCartridges returns all when text is empty", () => {
  const cartridges = [
    makeCartridge({ name: "a" }),
    makeCartridge({ name: "b" }),
  ];
  assertEquals(filterCartridges(cartridges, "").length, 2);
});

Deno.test("filterCartridges matches by name case-insensitively", () => {
  const cartridges = [
    makeCartridge({ name: "database-mcp" }),
    makeCartridge({ name: "proof-mcp" }),
  ];
  const results = filterCartridges(cartridges, "DATABASE");
  assertEquals(results.length, 1);
  assertEquals(results[0].name, "database-mcp");
});

Deno.test("filterCartridges matches by displayName", () => {
  const cartridges = [
    makeCartridge({ name: "db", displayName: "Database Cartridge" }),
    makeCartridge({ name: "pr", displayName: "Proof Cartridge" }),
  ];
  const results = filterCartridges(cartridges, "proof");
  assertEquals(results.length, 1);
  assertEquals(results[0].name, "pr");
});

Deno.test("filterCartridges matches by description", () => {
  const cartridges = [
    makeCartridge({
      name: "a",
      description: "Handles persistence layer",
    }),
    makeCartridge({
      name: "b",
      description: "Network scanning tools",
    }),
  ];
  const results = filterCartridges(cartridges, "persistence");
  assertEquals(results.length, 1);
  assertEquals(results[0].name, "a");
});

Deno.test("filterCartridges returns empty when nothing matches", () => {
  const cartridges = [
    makeCartridge({ name: "a", displayName: "Alpha", description: "First" }),
  ];
  assertEquals(filterCartridges(cartridges, "zzzznotfound").length, 0);
});

// ---------------------------------------------------------------------------
// hasProtocol
// ---------------------------------------------------------------------------

Deno.test("hasProtocol returns true when cartridge supports the protocol", () => {
  const cartridge = makeCartridge({
    protocols: ["ProtoMCP", "ProtoREST"],
  });
  assertEquals(hasProtocol(cartridge, "ProtoMCP"), true);
  assertEquals(hasProtocol(cartridge, "ProtoREST"), true);
});

Deno.test("hasProtocol returns false when protocol not supported", () => {
  const cartridge = makeCartridge({
    protocols: ["ProtoMCP"],
  });
  assertEquals(hasProtocol(cartridge, "ProtoDAP"), false);
  assertEquals(hasProtocol(cartridge, "ProtoGraphQL"), false);
});

Deno.test("hasProtocol returns false for empty protocol list", () => {
  const cartridge = makeCartridge({ protocols: [] });
  assertEquals(hasProtocol(cartridge, "ProtoMCP"), false);
});

// ---------------------------------------------------------------------------
// allProtocols
// ---------------------------------------------------------------------------

Deno.test("allProtocols has 10 entries", () => {
  assertEquals(allProtocols.length, 10);
});

Deno.test("allProtocols contains all protocol variants", () => {
  const expected = [
    "ProtoMCP", "ProtoLSP", "ProtoDAP", "ProtoBSP", "ProtoNeSy",
    "ProtoAgentic", "ProtoFleet", "ProtoGRPC", "ProtoREST", "ProtoGraphQL",
  ];
  assertEquals(allProtocols, expected);
});

// ---------------------------------------------------------------------------
// layerProgress
// ---------------------------------------------------------------------------

Deno.test("layerProgress returns 0/4 when no layers ready", () => {
  const layers = {
    abiReady: false,
    ffiReady: false,
    adapterReady: false,
    sharedLibReady: false,
  };
  assertEquals(layerProgress(layers), "0/4");
});

Deno.test("layerProgress returns 4/4 when all layers ready", () => {
  const layers = {
    abiReady: true,
    ffiReady: true,
    adapterReady: true,
    sharedLibReady: true,
  };
  assertEquals(layerProgress(layers), "4/4");
});

Deno.test("layerProgress returns 2/4 for partial readiness", () => {
  const layers = {
    abiReady: true,
    ffiReady: true,
    adapterReady: false,
    sharedLibReady: false,
  };
  assertEquals(layerProgress(layers), "2/4");
});

Deno.test("layerProgress returns 1/4 for single layer", () => {
  const layers = {
    abiReady: false,
    ffiReady: false,
    adapterReady: false,
    sharedLibReady: true,
  };
  assertEquals(layerProgress(layers), "1/4");
});

Deno.test("layerProgress returns 3/4 for three layers", () => {
  const layers = {
    abiReady: true,
    ffiReady: false,
    adapterReady: true,
    sharedLibReady: true,
  };
  assertEquals(layerProgress(layers), "3/4");
});

// ---------------------------------------------------------------------------
// defaultState
// ---------------------------------------------------------------------------

Deno.test("defaultState has expected server URL", () => {
  assertEquals(defaultState.serverUrl, "http://localhost:7700");
});

Deno.test("defaultState starts disconnected", () => {
  assertEquals(defaultState.connected, false);
});

Deno.test("defaultState has empty cartridges array", () => {
  assertEquals(defaultState.cartridges.length, 0);
});

Deno.test("defaultState has no selected cartridge", () => {
  assertEquals(defaultState.selectedCartridge, undefined);
});

Deno.test("defaultState active category is Dashboard", () => {
  assertEquals(defaultState.activeCategory, "Dashboard");
});

Deno.test("defaultState umoja is inactive with no peers", () => {
  assertEquals(defaultState.umoja.active, false);
  assertEquals(defaultState.umoja.localNodeId, "");
  assertEquals(defaultState.umoja.peers.length, 0);
  assertEquals(defaultState.umoja.currentRound, 0);
});

Deno.test("defaultState invoke fields are empty", () => {
  assertEquals(defaultState.invokeCartridge, "");
  assertEquals(defaultState.invokeTool, "");
  assertEquals(defaultState.invokeArgs.length, 0);
  assertEquals(defaultState.invokeResult, undefined);
});

Deno.test("defaultState loading is false and error is None", () => {
  assertEquals(defaultState.loading, false);
  assertEquals(defaultState.error, undefined);
});

Deno.test("defaultState filterText is empty", () => {
  assertEquals(defaultState.filterText, "");
});

Deno.test("defaultState lastTypeCheck is None", () => {
  assertEquals(defaultState.lastTypeCheck, undefined);
});
