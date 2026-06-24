// SPDX-License-Identifier: MPL-2.0

/**
 * A2mlEngine Tests — parsing, validation, extraction, summary
 */

import { assertEquals } from "jsr:@std/assert";
import {
  parseA2mlContent,
  validateManifest,
  extractTestCoveragePolicy,
  generateTestCoverageSection,
  summariseManifest,
} from "../src/core/A2mlEngine.res.js";

// -- parseA2mlContent --

Deno.test("parseA2mlContent returns invalid for empty content", () => {
  const result = parseA2mlContent("");
  assertEquals(result.isValid, false);
  assertEquals(result.errors.length, 1);
  assertEquals(result.errors[0], "Empty content");
});

Deno.test("parseA2mlContent parses sectioned key-value format", () => {
  const content = `[identity]
name = "test-project"
version = "1.0"

[canonical-locations]
state = ".machine_readable/STATE.scm"`;
  const result = parseA2mlContent(content);
  assertEquals(result.isValid, true);
  assertEquals(result.sections.length, 2);
  assertEquals(result.sections[0].key, "identity");
});

Deno.test("parseA2mlContent parses s-expression format", () => {
  const content = `; comment
(metadata
  (name "test")
  (version "1.0"))`;
  const result = parseA2mlContent(content);
  assertEquals(result.isValid, true);
  assertEquals(result.sections.length >= 1, true);
});

Deno.test("parseA2mlContent parses trustfile format", () => {
  const content = `### [META]
name = "test"
---
### [TRUSTFILE]
level = "yard"
---`;
  const result = parseA2mlContent(content);
  assertEquals(result.isValid, true);
  assertEquals(result.sections.length, 2);
});

// -- validateManifest --

Deno.test("validateManifest validates identity manifest with canonical-locations", () => {
  const manifest = parseA2mlContent(`[identity]
name = "test"

[canonical-locations]
state = ".machine_readable/"

[critical-invariants]
rule = "no root scm files"

[purpose]
desc = "testing"

[lifecycle]
on-enter = "read manifest"`);
  const result = validateManifest(manifest);
  assertEquals(result.valid, true);
  assertEquals(result.errors.length, 0);
});

Deno.test("validateManifest flags missing canonical-locations", () => {
  const manifest = parseA2mlContent(`[identity]
name = "test"`);
  const result = validateManifest(manifest);
  assertEquals(result.valid, false);
  assertEquals(result.errors.some(e => e.includes("canonical-locations")), true);
});

// -- extractTestCoveragePolicy --

Deno.test("extractTestCoveragePolicy returns defaults when no section", () => {
  const manifest = parseA2mlContent(`[identity]
name = "test"`);
  const [coverage, types, notes] = extractTestCoveragePolicy(manifest);
  assertEquals(coverage, 0);
  assertEquals(types.length, 0);
  assertEquals(notes, "");
});

// -- generateTestCoverageSection --

Deno.test("generateTestCoverageSection generates correct output", () => {
  const result = generateTestCoverageSection(80, ["unit", "integration"], "all engines covered");
  assertEquals(result.includes("test-coverage = 80"), true);
  assertEquals(result.includes("unit | integration"), true);
  assertEquals(result.includes("all engines covered"), true);
});

Deno.test("generateTestCoverageSection handles empty notes", () => {
  const result = generateTestCoverageSection(90, ["unit"], "");
  assertEquals(result.includes("test-notes"), false);
});

// -- summariseManifest --

Deno.test("summariseManifest produces summary string", () => {
  const manifest = parseA2mlContent(`[identity]
name = "my-project"

[canonical-locations]
state = ".machine_readable/"`);
  const summary = summariseManifest(manifest);
  assertEquals(summary.includes("my-project"), true);
  assertEquals(summary.includes("Valid"), true);
  assertEquals(summary.includes("Sections: 2"), true);
});
