// SPDX-License-Identifier: MPL-2.0

/**
 * ScriptGistEngine tests — Minskian cardfile gist management.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import * as SG from "../src/core/ScriptGistEngine.res.js";

Deno.test("defaultState has empty gists", () => {
  assertEquals(SG.defaultState.gists.length, 0);
});

Deno.test("allCategories has entries", () => {
  assert(SG.allCategories.length > 0);
});

Deno.test("categoryLabel covers all categories", () => {
  for (const cat of SG.allCategories) {
    assert(SG.categoryLabel(cat).length > 0);
  }
});

Deno.test("languageLabel covers common languages", () => {
  assert(SG.languageLabel("GistReScript").length > 0);
  assert(SG.languageLabel("GistGleam").length > 0);
  assert(SG.languageLabel("GistIdris2").length > 0);
});

Deno.test("languageExt returns file extensions", () => {
  assert(SG.languageExt("GistReScript").includes("."));
});

Deno.test("languageColour returns non-empty string", () => {
  assert(SG.languageColour("GistReScript").length > 0);
});

Deno.test("estimateTokens returns positive for non-empty text", () => {
  assert(SG.estimateTokens("hello world foo bar") > 0);
});

Deno.test("estimateTokens returns 0 for empty text", () => {
  assertEquals(SG.estimateTokens(""), 0);
});

Deno.test("newGist creates gist with correct fields", () => {
  const gist = SG.newGist("test-1", "Test Gist", "GistReScript");
  assertEquals(gist.id, "test-1");
  assertEquals(gist.title, "Test Gist");
  assertEquals(gist.language, "GistReScript");
  assertEquals(gist.code, "");
});

Deno.test("generateMcpToolJson returns valid JSON", () => {
  const gist = SG.newGist("t1", "My Tool", "GistReScript");
  const json = SG.generateMcpToolJson(gist);
  assert(json.includes("My Tool"));
  const parsed = JSON.parse(json);
  assert(parsed.name !== undefined);
});

Deno.test("filterBySearch with empty returns all", () => {
  const gists = [SG.newGist("a", "Alpha", "GistReScript"), SG.newGist("b", "Beta", "GistGleam")];
  assertEquals(SG.filterBySearch(gists, "").length, 2);
});

Deno.test("filterBySearch narrows results", () => {
  const gists = [SG.newGist("a", "Alpha", "GistReScript"), SG.newGist("b", "Beta", "GistGleam")];
  assertEquals(SG.filterBySearch(gists, "alpha").length, 1);
});

Deno.test("findGist returns matching gist", () => {
  const gists = [SG.newGist("a", "Alpha", "GistReScript")];
  const found = SG.findGist(gists, "a");
  assert(found !== undefined);
  assertEquals(found.title, "Alpha");
});

Deno.test("findGist returns undefined for missing", () => {
  assertEquals(SG.findGist([], "nope"), undefined);
});

Deno.test("visibilityLabel returns non-empty", () => {
  assert(SG.visibilityLabel("Private").length > 0);
  assert(SG.visibilityLabel("Local").length > 0);
  assert(SG.visibilityLabel("Repo").length > 0);
});

Deno.test("builtinTemplates has entries", () => {
  assert(SG.builtinTemplates.length > 0);
});

Deno.test("newCardfile creates empty cardfile", () => {
  const cf = SG.newCardfile("cf1", "My Cardfile");
  assertEquals(cf.id, "cf1");
  assertEquals(cf.name, "My Cardfile");
  assertEquals(cf.gistIds.length, 0);
});

Deno.test("addGistToCardfile adds gist ID", () => {
  const cf = SG.newCardfile("cf1", "Test");
  const updated = SG.addGistToCardfile(cf, "gist-1");
  assertEquals(updated.gistIds.length, 1);
});

Deno.test("removeGistFromCardfile removes gist ID", () => {
  const cf = SG.addGistToCardfile(SG.newCardfile("cf1", "Test"), "gist-1");
  const updated = SG.removeGistFromCardfile(cf, "gist-1");
  assertEquals(updated.gistIds.length, 0);
});

Deno.test("expandTemplate replaces placeholders", () => {
  const tpl = SG.builtinTemplates[0];
  if (tpl.placeholders.length > 0) {
    const key = tpl.placeholders[0];
    const result = SG.expandTemplate(tpl, [[key, "TestValue"]]);
    assert(result.includes("TestValue") || !tpl.templateCode.includes("{{" + key + "}}"));
  }
});
