// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * PlaygroundsEngine REPL Tests — wrapForExecution, preflightCheck,
 * formatOutput, needsNqcProxy, language helpers.
 */

import { assertEquals, assert, assertExists } from "jsr:@std/assert";
import {
  wrapForExecution,
  preflightCheck,
  formatOutput,
  needsNqcProxy,
  categoryLabel,
  languageLabel,
  languageExt,
  isDbLanguage,
  defaultSnippets,
  defaultState,
} from "../src/core/PlaygroundsEngine.res.js";

// -- wrapForExecution --

Deno.test("wrapForExecution prepends VQL prefix for LangVql", () => {
  const result = wrapForExecution("SELECT * FROM octads;", "LangVql");
  assert(result.startsWith("// VeriSimDB VQL query\n"));
  assert(result.includes("SELECT * FROM octads;"));
});

Deno.test("wrapForExecution prepends KQL prefix for LangKql", () => {
  const result = wrapForExecution("MATCH (q:Quandle)", "LangKql");
  assert(result.startsWith("// Knowledge Query Language\n"));
});

Deno.test("wrapForExecution prepends GQL prefix for LangGql", () => {
  const result = wrapForExecution("{ query }", "LangGql");
  assert(result.startsWith("// Graph Query Language\n"));
});

Deno.test("wrapForExecution prepends ReScript prefix", () => {
  const result = wrapForExecution("let x = 1", "LangRescript");
  assert(result.startsWith("// ReScript (compiled to JS)\n"));
});

Deno.test("wrapForExecution prepends Gleam prefix", () => {
  const result = wrapForExecution("pub fn main()", "LangGleam");
  assert(result.startsWith("// Gleam (compiled to JS)\n"));
});

Deno.test("wrapForExecution prepends Idris2 prefix", () => {
  const result = wrapForExecution("total main : IO ()", "LangIdris2");
  assert(result.startsWith("// Idris2 (interpreted)\n"));
});

Deno.test("wrapForExecution prepends Nickel prefix", () => {
  const result = wrapForExecution("{ x = 1 }", "LangNickel");
  assert(result.startsWith("// Nickel configuration\n"));
});

// -- preflightCheck --

Deno.test("preflightCheck returns error for empty code", () => {
  const result = preflightCheck("", "LangVql");
  assertExists(result);
  assert(result.includes("Empty code"));
});

Deno.test("preflightCheck returns error for whitespace-only code", () => {
  const result = preflightCheck("   \n  ", "LangVql");
  assertExists(result);
  assert(result.includes("Empty code"));
});

Deno.test("preflightCheck returns error for code exceeding 50k chars", () => {
  const longCode = "x".repeat(50001);
  const result = preflightCheck(longCode, "LangRescript");
  assertExists(result);
  assert(result.includes("50,000"));
});

Deno.test("preflightCheck detects while(true) infinite loop", () => {
  const result = preflightCheck("while(true) { doStuff(); }", "LangRescript");
  assertExists(result);
  assert(result.includes("infinite loop"));
});

Deno.test("preflightCheck detects for(;;) infinite loop", () => {
  const result = preflightCheck("for(;;) { doStuff(); }", "LangRescript");
  assertExists(result);
  assert(result.includes("infinite loop"));
});

Deno.test("preflightCheck returns undefined for valid code", () => {
  const result = preflightCheck("SELECT * FROM octads LIMIT 10;", "LangVql");
  assertEquals(result, undefined);
});

// -- formatOutput --

Deno.test("formatOutput appends execution time", () => {
  const result = formatOutput("OK: 10 rows", 42.5);
  assert(result.includes("OK: 10 rows"));
  assert(result.includes("42.5ms"));
  assert(result.includes("executed in"));
});

Deno.test("formatOutput handles zero elapsed time", () => {
  const result = formatOutput("done", 0.0);
  assert(result.includes("0.0ms"));
});

// -- needsNqcProxy --

Deno.test("needsNqcProxy returns true for database languages", () => {
  assertEquals(needsNqcProxy("LangVql"), true);
  assertEquals(needsNqcProxy("LangKql"), true);
  assertEquals(needsNqcProxy("LangGql"), true);
});

Deno.test("needsNqcProxy returns false for non-database languages", () => {
  assertEquals(needsNqcProxy("LangRescript"), false);
  assertEquals(needsNqcProxy("LangGleam"), false);
  assertEquals(needsNqcProxy("LangIdris2"), false);
  assertEquals(needsNqcProxy("LangNickel"), false);
});

// -- Language helpers --

Deno.test("languageLabel maps all languages", () => {
  assertEquals(languageLabel("LangVql"), "VQL");
  assertEquals(languageLabel("LangKql"), "KQL");
  assertEquals(languageLabel("LangGql"), "GQL");
  assertEquals(languageLabel("LangRescript"), "ReScript");
  assertEquals(languageLabel("LangGleam"), "Gleam");
  assertEquals(languageLabel("LangIdris2"), "Idris2");
  assertEquals(languageLabel("LangNickel"), "Nickel");
});

Deno.test("languageExt returns correct file extensions", () => {
  assertEquals(languageExt("LangVql"), ".vql");
  assertEquals(languageExt("LangRescript"), ".res");
  assertEquals(languageExt("LangIdris2"), ".idr");
});

Deno.test("isDbLanguage returns true for VQL, KQL, GQL only", () => {
  assertEquals(isDbLanguage("LangVql"), true);
  assertEquals(isDbLanguage("LangKql"), true);
  assertEquals(isDbLanguage("LangGql"), true);
  assertEquals(isDbLanguage("LangRescript"), false);
  assertEquals(isDbLanguage("LangGleam"), false);
});

// -- Default state / snippets --

Deno.test("defaultSnippets contains 3 tutorial snippets", () => {
  assertEquals(defaultSnippets.length, 3);
  for (const s of defaultSnippets) {
    assertEquals(s.isTutorial, true);
  }
});

Deno.test("defaultState has expected initial values", () => {
  assertEquals(defaultState.activeCategory, "PlayEditor");
  assertEquals(defaultState.activeLanguage, "LangVql");
  assertEquals(defaultState.editorContent, "");
  assertEquals(defaultState.executing, false);
  assertEquals(defaultState.nqcConnected, false);
});
