// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * KeybindingsEngine Tests — lookup, conflict detection, rebind, reset
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  chord,
  bind,
  defaults,
  lookup,
  detectConflicts,
  rebind,
  resetBinding,
  resetAll,
  defaultState,
} from "../src/core/KeybindingsEngine.res.js";

// ReScript compiles option<T> as: Some(x) → x, None → undefined

Deno.test("defaults has 19 keybindings", () => {
  assertExists(defaults);
  assertEquals(defaults.length, 19);
});

Deno.test("defaultState has bindings array", () => {
  assertExists(defaultState);
  assertEquals(defaultState.bindings.length, defaults.length);
  assertEquals(defaultState.recording, false);
  assertEquals(defaultState.conflicts.length, 0);
});

Deno.test("lookup finds Ctrl+Z = ActionUndo", () => {
  const action = lookup(defaults, true, false, false, false, "z");
  assertEquals(action, "ActionUndo");
});

Deno.test("lookup finds Ctrl+Shift+Z = ActionRedo", () => {
  const action = lookup(defaults, true, true, false, false, "Z");
  assertEquals(action, "ActionRedo");
});

Deno.test("lookup finds Ctrl+S = ActionSave", () => {
  const action = lookup(defaults, true, false, false, false, "s");
  assertEquals(action, "ActionSave");
});

Deno.test("lookup finds Escape = ActionCloseOverlay", () => {
  const action = lookup(defaults, false, false, false, false, "Escape");
  assertEquals(action, "ActionCloseOverlay");
});

Deno.test("lookup finds F11 = ActionFullscreen", () => {
  const action = lookup(defaults, false, false, false, false, "F11");
  assertEquals(action, "ActionFullscreen");
});

Deno.test("lookup returns undefined for unbound key", () => {
  const action = lookup(defaults, false, false, false, false, "q");
  assertEquals(action, undefined);
});

Deno.test("lookup returns undefined for wrong modifiers", () => {
  const action = lookup(defaults, false, false, false, false, "z");
  assertEquals(action, undefined);
});

Deno.test("detectConflicts returns empty for defaults", () => {
  const conflicts = detectConflicts(defaults);
  assertEquals(conflicts.length, 0);
});

Deno.test("detectConflicts finds duplicate chords", () => {
  const dupes = [
    bind(["Ctrl"], "z", "ActionUndo"),
    bind(["Ctrl"], "z", "ActionSave"),
  ];
  const conflicts = detectConflicts(dupes);
  assertEquals(conflicts.length, 1);
  assertEquals(conflicts[0][0], "ActionUndo");
  assertEquals(conflicts[0][1], "ActionSave");
});

Deno.test("rebind replaces existing binding", () => {
  const newChord = chord(["Ctrl", "Shift"], "U");
  const result = rebind(defaults, "ActionUndo", newChord);
  assertEquals(result.length, defaults.length);
  const undoBinding = result.find((b) => b.action === "ActionUndo");
  assertEquals(undoBinding.chord.key, "U");
  assertEquals(undoBinding.custom, true);
});

Deno.test("rebind adds new binding for unknown action", () => {
  const newChord = chord(["Ctrl"], "x");
  const result = rebind(defaults, "ActionCustom", newChord);
  assertEquals(result.length, defaults.length + 1);
  const custom = result.find((b) => b.action === "ActionCustom");
  assertExists(custom);
  assertEquals(custom.chord.key, "x");
  assertEquals(custom.custom, true);
});

Deno.test("resetBinding restores default chord", () => {
  const newChord = chord(["Alt"], "u");
  const modified = rebind(defaults, "ActionUndo", newChord);
  const undoBefore = modified.find((b) => b.action === "ActionUndo");
  assertEquals(undoBefore.chord.key, "u");

  const reset = resetBinding(modified, "ActionUndo");
  const undoAfter = reset.find((b) => b.action === "ActionUndo");
  assertEquals(undoAfter.chord.key, "z");
  assertEquals(undoAfter.custom, false);
});

Deno.test("resetAll returns defaults", () => {
  const result = resetAll();
  assertEquals(result.length, defaults.length);
  assertEquals(result, defaults);
});

Deno.test("chord creates correct structure", () => {
  const c = chord(["Ctrl", "Shift"], "X");
  assertEquals(c.modifiers, ["Ctrl", "Shift"]);
  assertEquals(c.key, "X");
});

Deno.test("bind creates non-custom binding", () => {
  const b = bind(["Ctrl"], "s", "ActionSave");
  assertEquals(b.chord.key, "s");
  assertEquals(b.action, "ActionSave");
  assertEquals(b.custom, false);
});
