// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * UndoEngine Tests — push, undo, redo, significance, capacity
 *
 * ReScript option<T> compiles as: Some(x) → x, None → undefined
 * Tuples compile as arrays: (a, b, c) → [a, b, c]
 */

import { assertEquals } from "jsr:@std/assert";
import {
  maxHistory,
  isSignificant,
  pushUndo,
  undo,
  redo,
  canUndo,
  canRedo,
} from "../src/core/UndoEngine.res.js";

Deno.test("maxHistory is 50", () => {
  assertEquals(maxHistory, 50);
});

// -- isSignificant tests --

Deno.test("isSignificant - NoOp is NOT significant", () => {
  assertEquals(isSignificant("NoOp"), false);
});

Deno.test("isSignificant - SaveState is NOT significant", () => {
  assertEquals(isSignificant("SaveState"), false);
});

Deno.test("isSignificant - View toggles are significant", () => {
  assertEquals(isSignificant({ TAG: "View", _0: "TogglePaneL" }), true);
});

Deno.test("isSignificant - Orbital is NOT significant", () => {
  assertEquals(
    isSignificant({ TAG: "Orbital", _0: "SyncComplete" }),
    false,
  );
});

Deno.test("isSignificant - PaneL messages are significant", () => {
  assertEquals(
    isSignificant({
      TAG: "PaneL",
      _0: { TAG: "AddConstraint", _0: "test" },
    }),
    true,
  );
});

// -- pushUndo tests --

Deno.test("pushUndo adds snapshot to stack", () => {
  const [newUndo, newRedo] = pushUndo([], [], "state-1");
  assertEquals(newUndo.length, 1);
  assertEquals(newUndo[0], "state-1");
  assertEquals(newRedo.length, 0);
});

Deno.test("pushUndo clears redo stack", () => {
  const [_newUndo, newRedo] = pushUndo(
    ["state-1"],
    ["redo-1", "redo-2"],
    "state-2",
  );
  assertEquals(newRedo.length, 0);
});

Deno.test("pushUndo trims at maxHistory", () => {
  const fullStack = Array.from({ length: 50 }, (_, i) => `state-${i}`);
  const [newUndo, _] = pushUndo(fullStack, [], "state-50");
  assertEquals(newUndo.length, 50);
  assertEquals(newUndo[49], "state-50");
  assertEquals(newUndo[0], "state-1");
});

// -- undo tests --
// undo returns: Some((snapshot, newUndo, newRedo)) → [snapshot, newUndo, newRedo]
// or None → undefined

Deno.test("undo pops last snapshot", () => {
  const result = undo(["state-1", "state-2"], [], "current");
  assertEquals(Array.isArray(result), true);
  const [snapshot, newUndo, newRedo] = result;
  assertEquals(snapshot, "state-2");
  assertEquals(newUndo.length, 1);
  assertEquals(newUndo[0], "state-1");
  assertEquals(newRedo.length, 1);
  assertEquals(newRedo[0], "current");
});

Deno.test("undo returns undefined on empty stack", () => {
  const result = undo([], [], "current");
  assertEquals(result, undefined);
});

// -- redo tests --

Deno.test("redo pops last redo snapshot", () => {
  const result = redo(["state-1"], ["state-2", "state-3"], "current");
  assertEquals(Array.isArray(result), true);
  const [snapshot, newUndo, newRedo] = result;
  assertEquals(snapshot, "state-3");
  assertEquals(newUndo.length, 2);
  assertEquals(newRedo.length, 1);
});

Deno.test("redo returns undefined on empty redo stack", () => {
  const result = redo(["state-1"], [], "current");
  assertEquals(result, undefined);
});

// -- canUndo / canRedo tests --

Deno.test("canUndo returns true for non-empty stack", () => {
  assertEquals(canUndo(["state-1"]), true);
});

Deno.test("canUndo returns false for empty stack", () => {
  assertEquals(canUndo([]), false);
});

Deno.test("canRedo returns true for non-empty stack", () => {
  assertEquals(canRedo(["state-1"]), true);
});

Deno.test("canRedo returns false for empty stack", () => {
  assertEquals(canRedo([]), false);
});

// -- undo/redo roundtrip --

Deno.test("undo then redo restores original state", () => {
  const undoResult = undo(["state-1"], [], "state-2");
  const [restored, newUndo, newRedo] = undoResult;
  assertEquals(restored, "state-1");

  const redoResult = redo(newUndo, newRedo, restored);
  const [reRestored, _, __] = redoResult;
  assertEquals(reRestored, "state-2");
});
