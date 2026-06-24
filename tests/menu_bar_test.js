// SPDX-License-Identifier: MPL-2.0

/**
 * MenuBar Tests — menu item arrays (file, edit, view, panel, tools, help),
 * item structure, separator handling, and shortcut presence.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  fileMenuItems,
  editMenuItems,
  viewMenuItems,
  panelMenuItems,
  toolsMenuItems,
  helpMenuItems,
} from "../src/components/MenuBar.res.js";

// -- Helper to count actions and separators --

function countActions(items) {
  return items.filter((item) => typeof item === "object" && item.TAG === "Action").length;
}

function countSeparators(items) {
  return items.filter((item) => item === "Separator").length;
}

// -- fileMenuItems --

Deno.test("fileMenuItems contains expected number of items", () => {
  assert(fileMenuItems.length > 0, "fileMenuItems should not be empty");
  assert(countActions(fileMenuItems) >= 8, "should have at least 8 action items");
});

Deno.test("fileMenuItems first action is New Workspace", () => {
  const first = fileMenuItems[0];
  assertEquals(first.TAG, "Action");
  assertEquals(first._0, "New Workspace");
  assertEquals(first._1, "file:new-workspace");
  assertEquals(first._2, "Ctrl+N");
});

Deno.test("fileMenuItems contains Separator entries", () => {
  assert(countSeparators(fileMenuItems) >= 3, "should have at least 3 separators");
});

Deno.test("fileMenuItems Save State has Ctrl+S shortcut", () => {
  const save = fileMenuItems.find(
    (item) => typeof item === "object" && item._1 === "file:save-state",
  );
  assert(save !== undefined, "Save State should exist");
  assertEquals(save._2, "Ctrl+S");
});

// -- editMenuItems --

Deno.test("editMenuItems contains Undo and Redo", () => {
  const undo = editMenuItems.find(
    (item) => typeof item === "object" && item._1 === "edit:undo",
  );
  const redo = editMenuItems.find(
    (item) => typeof item === "object" && item._1 === "edit:redo",
  );
  assert(undo !== undefined, "Undo should exist");
  assert(redo !== undefined, "Redo should exist");
  assertEquals(undo._2, "Ctrl+Z");
  assertEquals(redo._2, "Ctrl+Shift+Z");
});

Deno.test("editMenuItems contains Find in Panel", () => {
  const find = editMenuItems.find(
    (item) => typeof item === "object" && item._1 === "edit:find",
  );
  assert(find !== undefined, "Find in Panel should exist");
  assertEquals(find._2, "Ctrl+F");
});

// -- viewMenuItems --

Deno.test("viewMenuItems contains toggle commands for all three panels", () => {
  const toggleL = viewMenuItems.find(
    (item) => typeof item === "object" && item._1 === "view:toggle-pane-l",
  );
  const toggleN = viewMenuItems.find(
    (item) => typeof item === "object" && item._1 === "view:toggle-pane-n",
  );
  const toggleW = viewMenuItems.find(
    (item) => typeof item === "object" && item._1 === "view:toggle-pane-w",
  );
  assert(toggleL !== undefined, "Toggle Panel-L should exist");
  assert(toggleN !== undefined, "Toggle Panel-N should exist");
  assert(toggleW !== undefined, "Toggle Panel-W should exist");
});

Deno.test("viewMenuItems contains Fullscreen with F11 shortcut", () => {
  const fullscreen = viewMenuItems.find(
    (item) => typeof item === "object" && item._1 === "view:fullscreen",
  );
  assert(fullscreen !== undefined, "Fullscreen should exist");
  assertEquals(fullscreen._2, "F11");
});

Deno.test("viewMenuItems contains Accessibility Settings", () => {
  const a11y = viewMenuItems.find(
    (item) => typeof item === "object" && item._1 === "view:accessibility",
  );
  assert(a11y !== undefined, "Accessibility Settings should exist");
});

// -- panelMenuItems --

Deno.test("panelMenuItems has entries for key panels", () => {
  const expectedIds = [
    "panel:ai",
    "panel:vab",
    "panel:cloudguard",
    "panel:hypatia",
    "panel:reposystem",
    "panel:echidna",
    "panel:typell",
    "panel:workspace",
    "panel:boj",
    "panel:provenance",
  ];
  for (const id of expectedIds) {
    const found = panelMenuItems.find(
      (item) => typeof item === "object" && item._1 === id,
    );
    assert(found !== undefined, `panelMenuItems missing ${id}`);
  }
});

Deno.test("panelMenuItems Workspace Settings has Ctrl+Shift+K shortcut", () => {
  const ws = panelMenuItems.find(
    (item) => typeof item === "object" && item._1 === "panel:workspace",
  );
  assert(ws !== undefined, "Workspace Settings should exist");
  assertEquals(ws._2, "Ctrl+Shift+K");
});

// -- toolsMenuItems --

Deno.test("toolsMenuItems contains ECHIDNA Theorem Prover", () => {
  const echidna = toolsMenuItems.find(
    (item) => typeof item === "object" && item._1 === "tools:echidna",
  );
  assert(echidna !== undefined, "ECHIDNA should exist in tools");
});

Deno.test("toolsMenuItems contains Panic Attacker", () => {
  const panic = toolsMenuItems.find(
    (item) => typeof item === "object" && item._1 === "tools:panic-attack",
  );
  assert(panic !== undefined, "Panic Attacker should exist in tools");
});

Deno.test("toolsMenuItems contains Protocol Squisher", () => {
  const ps = toolsMenuItems.find(
    (item) => typeof item === "object" && item._1 === "tools:protocol-squisher",
  );
  assert(ps !== undefined, "Protocol Squisher should exist in tools");
});

// -- helpMenuItems --

Deno.test("helpMenuItems contains Welcome Tour", () => {
  const tour = helpMenuItems.find(
    (item) => typeof item === "object" && item._1 === "help:tour",
  );
  assert(tour !== undefined, "Welcome Tour should exist");
});

Deno.test("helpMenuItems contains Glossary", () => {
  const glossary = helpMenuItems.find(
    (item) => typeof item === "object" && item._1 === "help:glossary",
  );
  assert(glossary !== undefined, "Glossary should exist");
});

Deno.test("helpMenuItems contains About PanLL", () => {
  const about = helpMenuItems.find(
    (item) => typeof item === "object" && item._1 === "help:about",
  );
  assert(about !== undefined, "About PanLL should exist");
});

Deno.test("helpMenuItems has 5 entries total", () => {
  assertEquals(helpMenuItems.length, 5);
});

// -- All menu item action IDs are unique within their menu --

Deno.test("all action IDs within each menu are unique", () => {
  const menus = [
    fileMenuItems,
    editMenuItems,
    viewMenuItems,
    panelMenuItems,
    toolsMenuItems,
    helpMenuItems,
  ];
  for (const menu of menus) {
    const ids = menu
      .filter((item) => typeof item === "object" && item.TAG === "Action")
      .map((item) => item._1);
    const uniqueIds = new Set(ids);
    assertEquals(ids.length, uniqueIds.size, "Duplicate action IDs found in menu");
  }
});
