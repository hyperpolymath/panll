// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * EditorBridgeEngine Tests — categories, editors, connections, diagnostics
 */

import { assertEquals } from "jsr:@std/assert";
import {
  categoryLabel,
  editorLabel,
  allEditors,
  connectionLabel,
  connectionColour,
  severityColour,
  filterDiagnostics,
  filterSymbols,
  countBySeverity,
  defaultState,
} from "../src/core/EditorBridgeEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("BridgeOverview"), "Overview");
  assertEquals(categoryLabel("BridgeDiagnostics"), "Diagnostics");
  assertEquals(categoryLabel("BridgeSymbols"), "Symbols");
  assertEquals(categoryLabel("BridgeActivity"), "Activity");
  assertEquals(categoryLabel("BridgeSettings"), "Settings");
});

// -- editorLabel --

Deno.test("editorLabel returns correct labels", () => {
  assertEquals(editorLabel("EditorVSCodium"), "VSCodium");
  assertEquals(editorLabel("EditorZed"), "Zed");
  assertEquals(editorLabel("EditorNeovim"), "Neovim");
  assertEquals(editorLabel("EditorEmacs"), "Emacs");
  assertEquals(editorLabel({ _0: "Custom Editor" }), "Custom Editor");
});

// -- allEditors --

Deno.test("allEditors has 7 entries", () => {
  assertEquals(allEditors.length, 7);
});

// -- connectionLabel / connectionColour --

Deno.test("connectionLabel returns correct strings", () => {
  assertEquals(connectionLabel("EditorDisconnected"), "Disconnected");
  assertEquals(connectionLabel("EditorConnecting"), "Connecting...");
  assertEquals(connectionLabel({ TAG: "EditorConnected", _0: "v1.2" }), "Connected (v1.2)");
  assertEquals(connectionLabel({ TAG: "EditorError", _0: "timeout" }), "Error: timeout");
});

Deno.test("connectionColour returns correct classes", () => {
  assertEquals(connectionColour("EditorDisconnected"), "text-gray-500");
  assertEquals(connectionColour("EditorConnecting"), "text-amber-400");
  assertEquals(connectionColour({ TAG: "EditorConnected", _0: "v1" }), "text-emerald-400");
  assertEquals(connectionColour({ TAG: "EditorError", _0: "x" }), "text-red-400");
});

// -- severityColour --

Deno.test("severityColour returns correct classes", () => {
  assertEquals(severityColour("error"), "text-red-400");
  assertEquals(severityColour("warning"), "text-amber-400");
  assertEquals(severityColour("info"), "text-blue-400");
  assertEquals(severityColour("hint"), "text-gray-400");
});

// -- filterDiagnostics --

Deno.test("filterDiagnostics filters by severity", () => {
  const diags = [
    { severity: "error", message: "err", filePath: "a.res" },
    { severity: "warning", message: "warn", filePath: "b.res" },
    { severity: "info", message: "info", filePath: "c.res" },
  ];
  assertEquals(filterDiagnostics(diags, true, false, false, "").length, 1);
  assertEquals(filterDiagnostics(diags, false, true, false, "").length, 1);
  assertEquals(filterDiagnostics(diags, true, true, true, "").length, 3);
});

Deno.test("filterDiagnostics filters by text", () => {
  const diags = [
    { severity: "error", message: "type mismatch", filePath: "a.res" },
    { severity: "error", message: "unused var", filePath: "b.res" },
  ];
  assertEquals(filterDiagnostics(diags, true, true, true, "type").length, 1);
});

// -- filterSymbols --

Deno.test("filterSymbols returns all when filter empty", () => {
  const symbols = [{ name: "foo", containerName: "Bar" }];
  assertEquals(filterSymbols(symbols, "").length, 1);
});

Deno.test("filterSymbols filters by name", () => {
  const symbols = [{ name: "foo", containerName: "A" }, { name: "bar", containerName: "B" }];
  assertEquals(filterSymbols(symbols, "foo").length, 1);
});

// -- countBySeverity --

Deno.test("countBySeverity counts correctly", () => {
  const diags = [{ severity: "error" }, { severity: "error" }, { severity: "warning" }];
  assertEquals(countBySeverity(diags, "error"), 2);
  assertEquals(countBySeverity(diags, "warning"), 1);
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.activeCategory, "BridgeOverview");
  assertEquals(defaultState.editorKind, "EditorVSCodium");
  assertEquals(defaultState.connection, "EditorDisconnected");
  assertEquals(defaultState.lspPort, 6008);
  assertEquals(defaultState.autoSync, true);
  assertEquals(defaultState.bojRouting, false);
});
