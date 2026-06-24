// SPDX-License-Identifier: MPL-2.0

/**
 * ValenceShellEngine Tests — category labels, icons, backend labels,
 * approval-gate labels, command completions, filtering, and default state.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  categoryLabel,
  categoryIcon,
  backendLabel,
  gateLabel,
  idaptikCompletions,
  filterCompletions,
  defaultState,
} from "../src/core/ValenceShellEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings", () => {
  assertEquals(categoryLabel("ShellTerminal"), "Terminal");
  assertEquals(categoryLabel("ShellRecordings"), "Recordings");
  assertEquals(categoryLabel("ShellCheckpoints"), "Checkpoints");
  assertEquals(categoryLabel("ShellHistory"), "History");
  assertEquals(categoryLabel("ShellSettings"), "Settings");
});

// -- categoryIcon --

Deno.test("categoryIcon returns correct icon identifiers", () => {
  assertEquals(categoryIcon("ShellTerminal"), "terminal");
  assertEquals(categoryIcon("ShellRecordings"), "video");
  assertEquals(categoryIcon("ShellCheckpoints"), "save");
  assertEquals(categoryIcon("ShellHistory"), "clock");
  assertEquals(categoryIcon("ShellSettings"), "settings");
});

// -- backendLabel --

Deno.test("backendLabel returns label for ValenceShell", () => {
  assertEquals(backendLabel("ValenceShell"), "Valence Shell (formally verified)");
});

Deno.test("backendLabel returns label for SystemShell with name", () => {
  assertEquals(backendLabel({ TAG: "SystemShell", _0: "bash" }), "System Shell (bash)");
  assertEquals(backendLabel({ TAG: "SystemShell", _0: "zsh" }), "System Shell (zsh)");
});

// -- gateLabel --

Deno.test("gateLabel returns correct strings", () => {
  assertEquals(gateLabel("GateDisabled"), "Disabled");
  assertEquals(gateLabel("GateEnabled"), "Enabled (review all)");
  assertEquals(gateLabel("GateLearning"), "Learning (builds whitelist)");
});

// -- idaptikCompletions --

Deno.test("idaptikCompletions has 23 entries", () => {
  assertEquals(idaptikCompletions.length, 23);
});

Deno.test("idaptikCompletions starts with deno task dev", () => {
  assertEquals(idaptikCompletions[0], "deno task dev");
});

Deno.test("idaptikCompletions ends with valence audit", () => {
  assertEquals(idaptikCompletions[idaptikCompletions.length - 1], "valence audit");
});

Deno.test("idaptikCompletions contains claude entry", () => {
  assert(idaptikCompletions.includes("claude"), "Should include 'claude'");
});

// -- filterCompletions --

Deno.test("filterCompletions returns empty array for empty input", () => {
  const result = filterCompletions("", idaptikCompletions);
  assertEquals(result.length, 0);
});

Deno.test("filterCompletions matches prefix case-insensitively", () => {
  const result = filterCompletions("deno", idaptikCompletions);
  assert(result.length > 0, "Should match deno commands");
  for (const item of result) {
    assert(item.toLowerCase().startsWith("deno"), `${item} should start with deno`);
  }
});

Deno.test("filterCompletions matches 'git' commands", () => {
  const result = filterCompletions("git", idaptikCompletions);
  assertEquals(result.length, 4);
});

Deno.test("filterCompletions matches 'valence' commands", () => {
  const result = filterCompletions("valence", idaptikCompletions);
  assertEquals(result.length, 6);
});

Deno.test("filterCompletions is case-insensitive", () => {
  const lower = filterCompletions("deno", idaptikCompletions);
  const upper = filterCompletions("DENO", idaptikCompletions);
  assertEquals(lower.length, upper.length);
});

Deno.test("filterCompletions returns empty for non-matching prefix", () => {
  const result = filterCompletions("zzz-no-match", idaptikCompletions);
  assertEquals(result.length, 0);
});

// -- defaultState --

Deno.test("defaultState has SystemShell bash backend", () => {
  assertEquals(defaultState.backend.TAG, "SystemShell");
  assertEquals(defaultState.backend._0, "bash");
});

Deno.test("defaultState valenceAvailable is false", () => {
  assertEquals(defaultState.valenceAvailable, false);
});

Deno.test("defaultState ptyConnected is false", () => {
  assertEquals(defaultState.ptyConnected, false);
});

Deno.test("defaultState cwd points to idaptik", () => {
  assertEquals(defaultState.cwd, ".");
});

Deno.test("defaultState has empty outputBuffer", () => {
  assertEquals(defaultState.outputBuffer.length, 0);
});

Deno.test("defaultState inputLine is empty", () => {
  assertEquals(defaultState.inputLine, "");
});

Deno.test("defaultState has empty commandHistory", () => {
  assertEquals(defaultState.commandHistory.length, 0);
});

Deno.test("defaultState historyIndex is -1", () => {
  assertEquals(defaultState.historyIndex, -1);
});

Deno.test("defaultState activeCategory is ShellTerminal", () => {
  assertEquals(defaultState.activeCategory, "ShellTerminal");
});

Deno.test("defaultState recording is RecordingIdle", () => {
  assertEquals(defaultState.recording, "RecordingIdle");
});

Deno.test("defaultState has empty recordings", () => {
  assertEquals(defaultState.recordings.length, 0);
});

Deno.test("defaultState approvalGate is GateDisabled", () => {
  assertEquals(defaultState.approvalGate, "GateDisabled");
});

Deno.test("defaultState has empty pendingCommands and approvedCommands", () => {
  assertEquals(defaultState.pendingCommands.length, 0);
  assertEquals(defaultState.approvedCommands.length, 0);
});

Deno.test("defaultState has empty checkpoints", () => {
  assertEquals(defaultState.checkpoints.length, 0);
});

Deno.test("defaultState claudeCodeActive is false", () => {
  assertEquals(defaultState.claudeCodeActive, false);
});

Deno.test("defaultState error is undefined (None)", () => {
  assertEquals(defaultState.error, undefined);
});

Deno.test("defaultState loading is false", () => {
  assertEquals(defaultState.loading, false);
});

Deno.test("defaultState splitView is false", () => {
  assertEquals(defaultState.splitView, false);
});

Deno.test("defaultState completions matches idaptikCompletions", () => {
  assertEquals(defaultState.completions, idaptikCompletions);
});

Deno.test("defaultState completionsVisible is false", () => {
  assertEquals(defaultState.completionsVisible, false);
});
