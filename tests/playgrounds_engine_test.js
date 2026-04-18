// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * PlaygroundsEngine Tests — categories, languages, extensions, snippets, state
 */

import { assertEquals } from "jsr:@std/assert";
import {
  categoryLabel,
  languageLabel,
  languageExt,
  isDbLanguage,
  defaultSnippets,
  defaultState,
} from "../src/core/PlaygroundsEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("PlayEditor"), "Editor");
  assertEquals(categoryLabel("PlayNqc"), "NQC Console");
  assertEquals(categoryLabel("PlaySnippets"), "Snippets");
  assertEquals(categoryLabel("PlayTutorials"), "Tutorials");
});

// -- languageLabel --

Deno.test("languageLabel returns correct labels", () => {
  assertEquals(languageLabel("LangVcl"), "VCL");
  assertEquals(languageLabel("LangKql"), "KQL");
  assertEquals(languageLabel("LangGql"), "GQL");
  assertEquals(languageLabel("LangRescript"), "ReScript");
  assertEquals(languageLabel("LangGleam"), "Gleam");
  assertEquals(languageLabel("LangIdris2"), "Idris2");
  assertEquals(languageLabel("LangNickel"), "Nickel");
});

// -- languageExt --

Deno.test("languageExt returns correct extensions", () => {
  assertEquals(languageExt("LangVcl"), ".vcl");
  assertEquals(languageExt("LangRescript"), ".res");
  assertEquals(languageExt("LangIdris2"), ".idr");
  assertEquals(languageExt("LangNickel"), ".ncl");
});

// -- isDbLanguage --

Deno.test("isDbLanguage returns true for DB languages", () => {
  assertEquals(isDbLanguage("LangVcl"), true);
  assertEquals(isDbLanguage("LangKql"), true);
  assertEquals(isDbLanguage("LangGql"), true);
});

Deno.test("isDbLanguage returns false for non-DB languages", () => {
  assertEquals(isDbLanguage("LangRescript"), false);
  assertEquals(isDbLanguage("LangGleam"), false);
  assertEquals(isDbLanguage("LangIdris2"), false);
});

// -- defaultSnippets --

Deno.test("defaultSnippets has 3 tutorial snippets", () => {
  assertEquals(defaultSnippets.length, 3);
  assertEquals(defaultSnippets[0].language, "LangVcl");
  assertEquals(defaultSnippets[1].language, "LangKql");
  assertEquals(defaultSnippets[2].language, "LangGql");
  assertEquals(defaultSnippets.every(s => s.isTutorial), true);
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.activeCategory, "PlayEditor");
  assertEquals(defaultState.activeLanguage, "LangVcl");
  assertEquals(defaultState.editorContent, "");
  assertEquals(defaultState.executing, false);
  assertEquals(defaultState.nqcConnected, false);
  assertEquals(defaultState.snippets.length, 3);
});
