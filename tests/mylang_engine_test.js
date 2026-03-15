// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * MyLangEngine Tests — dialect labels, colours, parsing, compilation, defaults
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  dialectLabel,
  dialectDescription,
  dialectColour,
  allDialects,
  categoryLabel,
  allCategories,
  parseDialect,
  parseCompilation,
  dialectExtension,
  dialectExample,
  defaultState,
} from "../src/core/MyLangEngine.res.js";

// -- dialectLabel --

Deno.test("dialectLabel returns correct strings", () => {
  assertEquals(dialectLabel("Solo"), "Solo");
  assertEquals(dialectLabel("Duet"), "Duet");
  assertEquals(dialectLabel("Ensemble"), "Ensemble");
  assertEquals(dialectLabel("Me"), "Me");
});

// -- dialectDescription --

Deno.test("dialectDescription returns correct strings", () => {
  assertEquals(dialectDescription("Solo"), "Dependable systems programming");
  assertEquals(dialectDescription("Duet"), "AI-assisted with verification");
  assertEquals(dialectDescription("Ensemble"), "AI as first-class component");
  assertEquals(dialectDescription("Me"), "Personal AI agent");
});

// -- dialectColour --

Deno.test("dialectColour returns Tailwind classes for each dialect", () => {
  assertEquals(dialectColour("Solo"), "text-slate-300 bg-slate-800/50");
  assertEquals(dialectColour("Duet"), "text-sky-400 bg-sky-900/30");
  assertEquals(dialectColour("Ensemble"), "text-violet-400 bg-violet-900/30");
  assertEquals(dialectColour("Me"), "text-amber-400 bg-amber-900/30");
});

// -- allDialects --

Deno.test("allDialects has 4 entries", () => {
  assertEquals(allDialects.length, 4);
});

Deno.test("allDialects contains all dialect variants", () => {
  assertEquals(allDialects[0], "Solo");
  assertEquals(allDialects[1], "Duet");
  assertEquals(allDialects[2], "Ensemble");
  assertEquals(allDialects[3], "Me");
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings", () => {
  assertEquals(categoryLabel("MlEditor"), "Editor");
  assertEquals(categoryLabel("MlRepl"), "REPL");
  assertEquals(categoryLabel("MlCompile"), "Compile");
  assertEquals(categoryLabel("MlDialects"), "Dialects");
});

// -- allCategories --

Deno.test("allCategories has 4 entries", () => {
  assertEquals(allCategories.length, 4);
});

Deno.test("allCategories contains all category variants", () => {
  assertEquals(allCategories[0], "MlEditor");
  assertEquals(allCategories[1], "MlRepl");
  assertEquals(allCategories[2], "MlCompile");
  assertEquals(allCategories[3], "MlDialects");
});

// -- parseDialect --

Deno.test("parseDialect parses known dialects case-insensitively", () => {
  assertEquals(parseDialect("solo"), "Solo");
  assertEquals(parseDialect("Solo"), "Solo");
  assertEquals(parseDialect("SOLO"), "Solo");
  assertEquals(parseDialect("duet"), "Duet");
  assertEquals(parseDialect("Duet"), "Duet");
  assertEquals(parseDialect("ensemble"), "Ensemble");
  assertEquals(parseDialect("Ensemble"), "Ensemble");
  assertEquals(parseDialect("me"), "Me");
  assertEquals(parseDialect("Me"), "Me");
});

Deno.test("parseDialect returns Solo for unknown input", () => {
  assertEquals(parseDialect("bogus"), "Solo");
  assertEquals(parseDialect(""), "Solo");
  assertEquals(parseDialect("unknown"), "Solo");
});

// -- parseCompilation --

Deno.test("parseCompilation parses valid JSON object", () => {
  const json = JSON.stringify({
    success: true,
    output: "compiled OK",
    diagnostics: "",
    error_count: 0,
    warning_count: 2,
    compile_time_ms: 150,
  });
  const result = parseCompilation(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.success, true);
  assertEquals(result._0.output, "compiled OK");
  assertEquals(result._0.diagnostics, "");
  assertEquals(result._0.errorCount, 0);
  assertEquals(result._0.warningCount, 2);
  assertEquals(result._0.compileTimeMs, 150);
});

Deno.test("parseCompilation handles failure result", () => {
  const json = JSON.stringify({
    success: false,
    output: "",
    diagnostics: "type error on line 3",
    error_count: 1,
    warning_count: 0,
    compile_time_ms: 42,
  });
  const result = parseCompilation(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.success, false);
  assertEquals(result._0.errorCount, 1);
  assertEquals(result._0.diagnostics, "type error on line 3");
});

Deno.test("parseCompilation defaults missing fields", () => {
  const json = JSON.stringify({});
  const result = parseCompilation(json);
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.success, false);
  assertEquals(result._0.output, "");
  assertEquals(result._0.diagnostics, "");
  assertEquals(result._0.errorCount, 0);
  assertEquals(result._0.warningCount, 0);
  assertEquals(result._0.compileTimeMs, 0);
});

Deno.test("parseCompilation returns Ok with defaults for non-object JSON", () => {
  const result = parseCompilation('"just a string"');
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.success, false);
  assertEquals(result._0.output, "");
});

Deno.test("parseCompilation returns Ok with defaults for JSON array", () => {
  const result = parseCompilation("[1, 2, 3]");
  assertEquals(result.TAG, "Ok");
  assertEquals(result._0.success, false);
  assertEquals(result._0.output, "");
});

Deno.test("parseCompilation returns Error for invalid JSON", () => {
  const result = parseCompilation("not json at all");
  assertEquals(result.TAG, "Error");
  assertEquals(result._0, "Invalid JSON");
});

// -- dialectExtension --

Deno.test("dialectExtension returns correct file extensions", () => {
  assertEquals(dialectExtension("Solo"), ".solo");
  assertEquals(dialectExtension("Duet"), ".duet");
  assertEquals(dialectExtension("Ensemble"), ".ens");
  assertEquals(dialectExtension("Me"), ".me");
});

// -- dialectExample --

Deno.test("dialectExample returns non-empty strings for each dialect", () => {
  for (const d of allDialects) {
    const example = dialectExample(d);
    assert(example.length > 0, `dialectExample for ${d} should be non-empty`);
  }
});

Deno.test("dialectExample Solo starts with Solo comment", () => {
  assert(dialectExample("Solo").startsWith("// Solo"));
});

Deno.test("dialectExample Duet starts with Duet comment", () => {
  assert(dialectExample("Duet").startsWith("// Duet"));
});

Deno.test("dialectExample Ensemble starts with Ensemble comment", () => {
  assert(dialectExample("Ensemble").startsWith("// Ensemble"));
});

Deno.test("dialectExample Me starts with Me comment", () => {
  assert(dialectExample("Me").startsWith("// Me"));
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.cliAvailable, false);
  assertEquals(defaultState.loading, false);
  assertEquals(defaultState.error, undefined);
  assertEquals(defaultState.activeCategory, "MlEditor");
  assertEquals(defaultState.activeDialect, "Solo");
  assertEquals(defaultState.replInput, "");
  assertEquals(defaultState.lspConnected, false);
});

Deno.test("defaultState editorContent matches Solo dialect example", () => {
  assertEquals(defaultState.editorContent, dialectExample("Solo"));
});

Deno.test("defaultState collections are empty arrays", () => {
  assertEquals(defaultState.replHistory.length, 0);
  assertEquals(defaultState.lspDiagnostics.length, 0);
  assertEquals(defaultState.replSessions.length, 0);
});

Deno.test("defaultState lastCompilation and lastTypeCheck are undefined", () => {
  assertEquals(defaultState.lastCompilation, undefined);
  assertEquals(defaultState.lastTypeCheck, undefined);
});
