// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * WorkspaceEngine Tests — group operations, arrangement management, session
 * lifecycle, workspace mode cycling, protection enforcement, and default state.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  createGroup,
  disbandGroup,
  lockGroup,
  unlockGroup,
  toggleGroupVisibility,
  pushToBack,
  pullToFront,
  addToGroup,
  removeFromGroup,
  shareGroup,
  saveArrangement,
  deleteArrangement,
  builtInArrangements,
  createSession,
  forkSession,
  addCheckpoint,
  deleteSession,
  setSessionProtection,
  setExecutionMode,
  cycleMode,
  visiblePanelsForMode,
  isMutationBlocked,
  isFileBlocked,
  defaultState,
} from "../src/core/WorkspaceEngine.res.js";

// -- createGroup --

Deno.test("createGroup appends a new group", () => {
  const groups = createGroup([], "g1", "Test Group", ["p1", "p2"]);
  assertEquals(groups.length, 1);
  assertEquals(groups[0].id, "g1");
  assertEquals(groups[0].name, "Test Group");
  assertEquals(groups[0].panelIds, ["p1", "p2"]);
  assertEquals(groups[0].locked, false);
  assertEquals(groups[0].visible, true);
  assertEquals(groups[0].zIndex, 1);
  assertEquals(groups[0].sharedWith, []);
});

Deno.test("createGroup assigns incrementing zIndex", () => {
  let groups = createGroup([], "g1", "A", []);
  groups = createGroup(groups, "g2", "B", []);
  assertEquals(groups[1].zIndex, 2);
});

// -- disbandGroup --

Deno.test("disbandGroup removes group by ID", () => {
  const groups = createGroup([], "g1", "A", []);
  const result = disbandGroup(groups, "g1");
  assertEquals(result.length, 0);
});

Deno.test("disbandGroup leaves other groups intact", () => {
  let groups = createGroup([], "g1", "A", []);
  groups = createGroup(groups, "g2", "B", []);
  const result = disbandGroup(groups, "g1");
  assertEquals(result.length, 1);
  assertEquals(result[0].id, "g2");
});

// -- lockGroup / unlockGroup --

Deno.test("lockGroup sets locked to true", () => {
  const groups = createGroup([], "g1", "A", []);
  const result = lockGroup(groups, "g1");
  assertEquals(result[0].locked, true);
});

Deno.test("unlockGroup sets locked to false", () => {
  const groups = lockGroup(createGroup([], "g1", "A", []), "g1");
  const result = unlockGroup(groups, "g1");
  assertEquals(result[0].locked, false);
});

Deno.test("lockGroup does not affect other groups", () => {
  let groups = createGroup([], "g1", "A", []);
  groups = createGroup(groups, "g2", "B", []);
  const result = lockGroup(groups, "g1");
  assertEquals(result[0].locked, true);
  assertEquals(result[1].locked, false);
});

// -- toggleGroupVisibility --

Deno.test("toggleGroupVisibility flips visible state", () => {
  const groups = createGroup([], "g1", "A", []);
  const toggled = toggleGroupVisibility(groups, "g1");
  assertEquals(toggled[0].visible, false);
  const toggledBack = toggleGroupVisibility(toggled, "g1");
  assertEquals(toggledBack[0].visible, true);
});

// -- pushToBack / pullToFront --

Deno.test("pushToBack sets target zIndex to 0", () => {
  let groups = createGroup([], "g1", "A", []);
  groups = createGroup(groups, "g2", "B", []);
  const result = pushToBack(groups, "g2");
  assertEquals(result[1].zIndex, 0);
  assertEquals(result[0].zIndex, 2); // g1 incremented
});

Deno.test("pullToFront sets target to highest zIndex", () => {
  let groups = createGroup([], "g1", "A", []);
  groups = createGroup(groups, "g2", "B", []);
  const result = pullToFront(groups, "g1");
  assertEquals(result[0].zIndex, 3); // maxZ (2) + 1
});

// -- addToGroup / removeFromGroup --

Deno.test("addToGroup adds panel to group", () => {
  const groups = createGroup([], "g1", "A", ["p1"]);
  const result = addToGroup(groups, "g1", "p2");
  assertEquals(result[0].panelIds, ["p1", "p2"]);
});

Deno.test("addToGroup does not duplicate existing panel", () => {
  const groups = createGroup([], "g1", "A", ["p1"]);
  const result = addToGroup(groups, "g1", "p1");
  assertEquals(result[0].panelIds, ["p1"]);
});

Deno.test("removeFromGroup removes panel from group", () => {
  const groups = createGroup([], "g1", "A", ["p1", "p2"]);
  const result = removeFromGroup(groups, "g1", "p1");
  assertEquals(result[0].panelIds, ["p2"]);
});

// -- shareGroup --

Deno.test("shareGroup adds user to sharedWith", () => {
  const groups = createGroup([], "g1", "A", []);
  const result = shareGroup(groups, "g1", "user1");
  assertEquals(result[0].sharedWith, ["user1"]);
});

Deno.test("shareGroup does not duplicate user", () => {
  const groups = shareGroup(createGroup([], "g1", "A", []), "g1", "user1");
  const result = shareGroup(groups, "g1", "user1");
  assertEquals(result[0].sharedWith, ["user1"]);
});

// -- saveArrangement --

Deno.test("saveArrangement creates new arrangement", () => {
  const arrangements = saveArrangement([], "a1", "My Layout", [], [], 1000.0);
  assertEquals(arrangements.length, 1);
  assertEquals(arrangements[0].id, "a1");
  assertEquals(arrangements[0].name, "My Layout");
  assertEquals(arrangements[0].builtIn, false);
  assertEquals(arrangements[0].lastSaved, 1000.0);
});

Deno.test("saveArrangement updates existing arrangement", () => {
  let arr = saveArrangement([], "a1", "Old", [], [], 1000.0);
  arr = saveArrangement(arr, "a1", "New", [], [], 2000.0);
  assertEquals(arr.length, 1);
  assertEquals(arr[0].name, "New");
  assertEquals(arr[0].lastSaved, 2000.0);
});

// -- deleteArrangement --

Deno.test("deleteArrangement removes non-built-in arrangement", () => {
  const arr = saveArrangement([], "a1", "Custom", [], [], 1000.0);
  const result = deleteArrangement(arr, "a1");
  assertEquals(result.length, 0);
});

Deno.test("deleteArrangement preserves built-in arrangements", () => {
  const result = deleteArrangement(builtInArrangements, "default-3-panel");
  assertEquals(result.length, builtInArrangements.length);
});

// -- builtInArrangements --

Deno.test("builtInArrangements has 4 presets", () => {
  assertEquals(builtInArrangements.length, 4);
});

Deno.test("builtInArrangements are all marked builtIn", () => {
  for (const arr of builtInArrangements) {
    assertEquals(arr.builtIn, true);
  }
});

Deno.test("builtInArrangements includes known layout IDs", () => {
  const ids = builtInArrangements.map(a => a.id);
  assert(ids.includes("default-3-panel"));
  assert(ids.includes("ai-focus"));
  assert(ids.includes("debug-layout"));
  assert(ids.includes("teaching-mode"));
});

// -- createSession --

Deno.test("createSession creates a new session with defaults", () => {
  const sessions = createSession([], "s1", "Dev Session", undefined, 1000.0);
  assertEquals(sessions.length, 1);
  assertEquals(sessions[0].id, "s1");
  assertEquals(sessions[0].name, "Dev Session");
  assertEquals(sessions[0].protection, "Open");
  assertEquals(sessions[0].executionMode, "Live");
  assertEquals(sessions[0].workspaceMode, "EverythingMode");
  assertEquals(sessions[0].arrangementId, "default-3-panel");
  assertEquals(sessions[0].checkpoints.length, 0);
  assertEquals(sessions[0].forkedFrom, undefined);
});

// -- forkSession --

Deno.test("forkSession creates copy of existing session", () => {
  let sessions = createSession([], "s1", "Original", undefined, 1000.0);
  sessions = forkSession(sessions, "s1", "s2", "Fork", 2000.0);
  assertEquals(sessions.length, 2);
  assertEquals(sessions[1].id, "s2");
  assertEquals(sessions[1].name, "Fork");
  assertEquals(sessions[1].forkedFrom, "s1");
  assertEquals(sessions[1].created, 2000.0);
});

Deno.test("forkSession returns unchanged when source not found", () => {
  const sessions = createSession([], "s1", "A", undefined, 1000.0);
  const result = forkSession(sessions, "nonexistent", "s2", "Fork", 2000.0);
  assertEquals(result.length, 1);
});

// -- addCheckpoint --

Deno.test("addCheckpoint adds checkpoint to correct session", () => {
  let sessions = createSession([], "s1", "A", undefined, 1000.0);
  sessions = addCheckpoint(sessions, "s1", "cp1", "Before refactor", 1500.0, false);
  assertEquals(sessions[0].checkpoints.length, 1);
  assertEquals(sessions[0].checkpoints[0].id, "cp1");
  assertEquals(sessions[0].checkpoints[0].label, "Before refactor");
  assertEquals(sessions[0].checkpoints[0].automatic, false);
});

// -- deleteSession --

Deno.test("deleteSession removes session by ID", () => {
  let sessions = createSession([], "s1", "A", undefined, 1000.0);
  sessions = createSession(sessions, "s2", "B", undefined, 2000.0);
  const result = deleteSession(sessions, "s1");
  assertEquals(result.length, 1);
  assertEquals(result[0].id, "s2");
});

// -- setSessionProtection --

Deno.test("setSessionProtection updates protection level", () => {
  let sessions = createSession([], "s1", "A", undefined, 1000.0);
  sessions = setSessionProtection(sessions, "s1", "ReadOnly");
  assertEquals(sessions[0].protection, "ReadOnly");
});

// -- setExecutionMode --

Deno.test("setExecutionMode updates execution mode", () => {
  let sessions = createSession([], "s1", "A", undefined, 1000.0);
  sessions = setExecutionMode(sessions, "s1", "DryRun");
  assertEquals(sessions[0].executionMode, "DryRun");
});

// -- cycleMode --

Deno.test("cycleMode cycles through all workspace modes", () => {
  assertEquals(cycleMode("RhodiumMode"), "EverythingMode");
  assertEquals(cycleMode("EverythingMode"), "CodeMode");
  assertEquals(cycleMode("CodeMode"), "BespokeMode");
  assertEquals(cycleMode("BespokeMode"), "RhodiumMode");
});

Deno.test("cycleMode full cycle returns to start", () => {
  let mode = "RhodiumMode";
  mode = cycleMode(mode);
  mode = cycleMode(mode);
  mode = cycleMode(mode);
  mode = cycleMode(mode);
  assertEquals(mode, "RhodiumMode");
});

// -- visiblePanelsForMode --

Deno.test("visiblePanelsForMode returns undefined for EverythingMode (show all)", () => {
  assertEquals(visiblePanelsForMode("EverythingMode"), undefined);
});

Deno.test("visiblePanelsForMode returns undefined for RhodiumMode (show all)", () => {
  assertEquals(visiblePanelsForMode("RhodiumMode"), undefined);
});

Deno.test("visiblePanelsForMode returns undefined for BespokeMode (loaded elsewhere)", () => {
  assertEquals(visiblePanelsForMode("BespokeMode"), undefined);
});

Deno.test("visiblePanelsForMode returns dev-focused panels for CodeMode", () => {
  const panels = visiblePanelsForMode("CodeMode");
  assert(Array.isArray(panels));
  assert(panels.includes("PanelVab"));
  assert(panels.includes("PanelDatabases"));
  assert(panels.includes("PanelPlaygrounds"));
  assert(panels.includes("PanelAi"));
  assert(panels.includes("PanelRepoLoader"));
  assert(panels.includes("PanelWorkspace"));
  assertEquals(panels.length, 9);
});

// -- isMutationBlocked --

Deno.test("isMutationBlocked returns false for Open", () => {
  assertEquals(isMutationBlocked("Open"), false);
});

Deno.test("isMutationBlocked returns true for ReadOnly", () => {
  assertEquals(isMutationBlocked("ReadOnly"), true);
});

Deno.test("isMutationBlocked returns false for Sandboxed", () => {
  assertEquals(isMutationBlocked("Sandboxed"), false);
});

Deno.test("isMutationBlocked returns false for TranspilationGuarded", () => {
  assertEquals(isMutationBlocked("TranspilationGuarded"), false);
});

Deno.test("isMutationBlocked returns false for ProductionGated", () => {
  assertEquals(isMutationBlocked("ProductionGated"), false);
});

Deno.test("isMutationBlocked returns false for LanguageLocked", () => {
  assertEquals(isMutationBlocked({ TAG: "LanguageLocked", _0: [".ts"] }), false);
});

// -- isFileBlocked --

Deno.test("isFileBlocked returns true for LanguageLocked matching extension", () => {
  assertEquals(isFileBlocked({ TAG: "LanguageLocked", _0: [".ts", ".tsx"] }, "src/App.tsx"), true);
});

Deno.test("isFileBlocked returns false for LanguageLocked non-matching extension", () => {
  assertEquals(isFileBlocked({ TAG: "LanguageLocked", _0: [".ts"] }, "src/App.res"), false);
});

Deno.test("isFileBlocked returns false for non-LanguageLocked protection", () => {
  assertEquals(isFileBlocked("Open", "src/App.ts"), false);
  assertEquals(isFileBlocked("ReadOnly", "src/App.ts"), false);
  assertEquals(isFileBlocked("Sandboxed", "src/App.ts"), false);
});

// -- defaultState --

Deno.test("defaultState has EverythingMode", () => {
  assertEquals(defaultState.mode, "EverythingMode");
});

Deno.test("defaultState has Open protection", () => {
  assertEquals(defaultState.protection, "Open");
});

Deno.test("defaultState has Live executionMode", () => {
  assertEquals(defaultState.executionMode, "Live");
});

Deno.test("defaultState has empty groups", () => {
  assertEquals(defaultState.groups.length, 0);
});

Deno.test("defaultState arrangements match builtInArrangements", () => {
  assertEquals(defaultState.arrangements.length, builtInArrangements.length);
});

Deno.test("defaultState activeArrangementId is default-3-panel", () => {
  assertEquals(defaultState.activeArrangementId, "default-3-panel");
});

Deno.test("defaultState has empty sessions", () => {
  assertEquals(defaultState.sessions.length, 0);
});

Deno.test("defaultState activeSessionId is undefined (None)", () => {
  assertEquals(defaultState.activeSessionId, undefined);
});

Deno.test("defaultState has empty polyTools", () => {
  assertEquals(defaultState.polyTools.length, 0);
});

Deno.test("defaultState configuratorOpen is false", () => {
  assertEquals(defaultState.configuratorOpen, false);
});

Deno.test("defaultState configuratorTab is TabArrangements", () => {
  assertEquals(defaultState.configuratorTab, "TabArrangements");
});
