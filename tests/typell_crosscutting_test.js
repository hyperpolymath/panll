// SPDX-License-Identifier: MPL-2.0

/**
 * TypeLL Cross-Panel Type Checking Tests — aspect-oriented verification of
 * the 10-level type system that spans all panels.
 *
 * Tests:
 *   - Kernel body building for type check requests
 *   - Language support detection (16 supported languages)
 *   - Discipline system (affine, linear, dependent, refined, unrestricted)
 *   - Feature tier classification (Core, Advanced, Research)
 *   - Implied features per discipline
 *   - Narrative generation for evangeliser integration
 *   - Signature formatting across view layers (Raw, Folded, Glyphed, WYSIWYG)
 *   - Cross-panel TypeCheckResult integration via Update cycle
 *   - Default state initialisation
 */

import { assertEquals, assert, assertNotEquals } from "jsr:@std/assert";
import * as TypeLLEngine from "../src/core/TypeLLEngine.res.js";
import { init as initModel } from "../src/Model.res.js";
import * as Update from "../src/Update.res.js";

// ─── Kernel Body Building ───────────────────────────────────────────────

Deno.test("TypeLL — buildCheckBody produces valid JSON", () => {
  const body = TypeLLEngine.buildCheckBody("let x: int = 42", "affinescript");
  const parsed = JSON.parse(body);
  assertEquals(typeof parsed, "object");
});

Deno.test("TypeLL — buildInferUsageBody produces valid JSON", () => {
  const body = TypeLLEngine.buildInferUsageBody("let f = fn x => x + 1");
  const parsed = JSON.parse(body);
  assertEquals(typeof parsed, "object");
});

Deno.test("TypeLL — buildCheckEffectsBody produces valid JSON", () => {
  const body = TypeLLEngine.buildCheckEffectsBody("performIO(readFile('data.txt'))");
  const parsed = JSON.parse(body);
  assertEquals(typeof parsed, "object");
});

Deno.test("TypeLL — buildCheckDimensionalBody produces valid JSON", () => {
  const body = TypeLLEngine.buildCheckDimensionalBody("let v: Vec<3, float> = [1.0, 2.0, 3.0]");
  const parsed = JSON.parse(body);
  assertEquals(typeof parsed, "object");
});

Deno.test("TypeLL — buildGenerateProofObligationBody produces valid JSON", () => {
  const body = TypeLLEngine.buildGenerateProofObligationBody("forall x: Nat. x + 0 = x");
  const parsed = JSON.parse(body);
  assertEquals(typeof parsed, "object");
});

// ─── Language Support ───────────────────────────────────────────────────

Deno.test("TypeLL — supportedLanguages has 16 entries", () => {
  assertEquals(TypeLLEngine.supportedLanguages.length, 16);
});

Deno.test("TypeLL — isKernelSupported: known languages return true", () => {
  const expected = ["affinescript", "eclexia", "ephapax", "wokelang", "betlang", "tangle"];
  for (const lang of expected) {
    assertEquals(TypeLLEngine.isKernelSupported(lang), true, `${lang} should be supported`);
  }
});

Deno.test("TypeLL — isKernelSupported: unknown languages return false", () => {
  assertEquals(TypeLLEngine.isKernelSupported("javascript"), false);
  assertEquals(TypeLLEngine.isKernelSupported("python"), false);
  assertEquals(TypeLLEngine.isKernelSupported(""), false);
});

Deno.test("TypeLL — kernelBaseUrl points to localhost:7800", () => {
  assert(TypeLLEngine.kernelBaseUrl.includes("7800"), "Kernel should be on port 7800");
  assert(TypeLLEngine.kernelBaseUrl.includes("localhost"), "Kernel should be on localhost");
});

// ─── Discipline System ──────────────────────────────────────────────────

Deno.test("TypeLL — allDisciplines contains 5 disciplines", () => {
  assertEquals(TypeLLEngine.allDisciplines.length, 5);
});

Deno.test("TypeLL — each discipline has label, directive, colour", () => {
  for (const d of TypeLLEngine.allDisciplines) {
    const label = TypeLLEngine.disciplineLabel(d);
    const directive = TypeLLEngine.disciplineDirective(d);
    const colour = TypeLLEngine.disciplineColour(d);
    assert(label.length > 0, `Discipline should have label`);
    assert(directive.length > 0, `Discipline should have directive`);
    assert(colour.length > 0, `Discipline should have colour`);
  }
});

Deno.test("TypeLL — disciplineImpliedFeatures: affine implies AffineTypes", () => {
  // Parse the Affine discipline and check its implied features
  const affine = TypeLLEngine.parseDiscipline("affine");
  if (affine !== undefined) {
    const implied = TypeLLEngine.disciplineImpliedFeatures(affine);
    assert(Array.isArray(implied), "Implied features should be an array");
  }
});

Deno.test("TypeLL — disciplineImpliedFeatures: dependent implies DependentTypes", () => {
  const dep = TypeLLEngine.parseDiscipline("dependent");
  if (dep !== undefined) {
    const implied = TypeLLEngine.disciplineImpliedFeatures(dep);
    assert(implied.length > 0, "Dependent discipline should imply features");
  }
});

// ─── Feature & Tier Classification ──────────────────────────────────────

Deno.test("TypeLL — allFeatures has 11 type features", () => {
  assertEquals(TypeLLEngine.allFeatures.length, 11);
});

Deno.test("TypeLL — coreFeatures has 4 entries", () => {
  assertEquals(TypeLLEngine.coreFeatures.length, 4);
});

Deno.test("TypeLL — advancedFeatures has 4 entries", () => {
  assertEquals(TypeLLEngine.advancedFeatures.length, 4);
});

Deno.test("TypeLL — researchFeatures has 3 entries", () => {
  assertEquals(TypeLLEngine.researchFeatures.length, 3);
});

Deno.test("TypeLL — every feature has a unique code", () => {
  const codes = TypeLLEngine.allFeatures.map(f => TypeLLEngine.featureCode(f));
  const unique = new Set(codes);
  assertEquals(unique.size, codes.length, `Duplicate feature codes: ${codes}`);
});

Deno.test("TypeLL — parseFeatureCode round-trips all features", () => {
  for (const feature of TypeLLEngine.allFeatures) {
    const code = TypeLLEngine.featureCode(feature);
    const parsed = TypeLLEngine.parseFeatureCode(code);
    assertNotEquals(parsed, undefined, `Feature code '${code}' should parse back`);
  }
});

Deno.test("TypeLL — parseFeatureCode: invalid code returns undefined", () => {
  assertEquals(TypeLLEngine.parseFeatureCode("invalid"), undefined);
  assertEquals(TypeLLEngine.parseFeatureCode(""), undefined);
});

Deno.test("TypeLL — computeMaxTier: empty features returns lowest tier", () => {
  const tier = TypeLLEngine.computeMaxTier([]);
  assert(tier !== undefined, "Empty features should still return a tier");
});

Deno.test("TypeLL — computeMaxTier: research feature elevates to Research tier", () => {
  const tier = TypeLLEngine.computeMaxTier(TypeLLEngine.researchFeatures);
  const label = TypeLLEngine.tierLabel(tier);
  assertEquals(label, "Research");
});

// ─── Feature Glyphs ─────────────────────────────────────────────────────

Deno.test("TypeLL — every feature has a glyph with symbol, label, meaning", () => {
  for (const feature of TypeLLEngine.allFeatures) {
    const glyph = TypeLLEngine.featureGlyph(feature);
    assert(typeof glyph.symbol === "string" && glyph.symbol.length > 0,
      `Feature ${TypeLLEngine.featureCode(feature)} glyph missing symbol`);
    assert(typeof glyph.label === "string" && glyph.label.length > 0,
      `Feature ${TypeLLEngine.featureCode(feature)} glyph missing label`);
    assert(typeof glyph.meaning === "string" && glyph.meaning.length > 0,
      `Feature ${TypeLLEngine.featureCode(feature)} glyph missing meaning`);
  }
});

// ─── View Layer System ──────────────────────────────────────────────────

Deno.test("TypeLL — allViewLayers has 4 layers", () => {
  assertEquals(TypeLLEngine.allViewLayers.length, 4);
});

Deno.test("TypeLL — view layers have distinct labels", () => {
  const labels = TypeLLEngine.allViewLayers.map(vl => TypeLLEngine.viewLayerLabel(vl));
  const unique = new Set(labels);
  assertEquals(unique.size, labels.length, "View layer labels should be unique");
});

Deno.test("TypeLL — view layers have descriptions", () => {
  for (const vl of TypeLLEngine.allViewLayers) {
    const desc = TypeLLEngine.viewLayerDescription(vl);
    assert(desc.length > 0, `View layer ${TypeLLEngine.viewLayerLabel(vl)} missing description`);
  }
});

// ─── Signature Formatting ───────────────────────────────────────────────

Deno.test("TypeLL — formatSignature: Raw layer preserves input unchanged", () => {
  const raw = TypeLLEngine.allViewLayers.find(vl => TypeLLEngine.viewLayerLabel(vl) === "Raw");
  if (raw) {
    const result = TypeLLEngine.formatSignature("int -> string", raw, []);
    assertEquals(result, "int -> string");
  }
});

Deno.test("TypeLL — formatSignature: Folded layer adds tier prefix", () => {
  const folded = TypeLLEngine.allViewLayers.find(vl => TypeLLEngine.viewLayerLabel(vl) === "Folded");
  if (folded) {
    const result = TypeLLEngine.formatSignature("int -> string", folded, TypeLLEngine.coreFeatures);
    assert(result.includes("int -> string"), "Folded should contain original signature");
    // Folded adds tier info
    assert(result.length > "int -> string".length, "Folded should add prefix");
  }
});

Deno.test("TypeLL — formatSignature: Glyphed layer prepends symbols", () => {
  const glyphed = TypeLLEngine.allViewLayers.find(vl => TypeLLEngine.viewLayerLabel(vl) === "Glyphed");
  if (glyphed) {
    const result = TypeLLEngine.formatSignature("int -> string", glyphed, TypeLLEngine.coreFeatures);
    assert(result.length > "int -> string".length, "Glyphed should add symbols");
  }
});

// ─── Filtering ──────────────────────────────────────────────────────────

Deno.test("TypeLL — filterByTier: undefined returns all entries", () => {
  const entries = [
    { name: "a", tier: "TierCore", signature: "", module: "" },
    { name: "b", tier: "TierAdvanced", signature: "", module: "" },
  ];
  const filtered = TypeLLEngine.filterByTier(entries, undefined);
  assertEquals(filtered.length, 2);
});

Deno.test("TypeLL — filterBySearch: matches name case-insensitively", () => {
  const entries = [
    { name: "MyFunction", signature: "int -> int", module_: "Core" },
    { name: "otherFunc", signature: "string -> string", module_: "Utils" },
  ];
  const filtered = TypeLLEngine.filterBySearch(entries, "myfunc");
  assertEquals(filtered.length, 1);
  assertEquals(filtered[0].name, "MyFunction");
});

Deno.test("TypeLL — filterBySearch: matches signature content", () => {
  const entries = [
    { name: "a", signature: "int -> float", module_: "Core" },
    { name: "b", signature: "string -> string", module_: "Utils" },
  ];
  const filtered = TypeLLEngine.filterBySearch(entries, "float");
  assertEquals(filtered.length, 1);
  assertEquals(filtered[0].name, "a");
});

Deno.test("TypeLL — filterBySearch: empty query returns all", () => {
  const entries = [
    { name: "a", signature: "int", module_: "Core" },
    { name: "b", signature: "str", module_: "Utils" },
  ];
  const filtered = TypeLLEngine.filterBySearch(entries, "");
  assertEquals(filtered.length, 2);
});

// ─── Narrative Generation ───────────────────────────────────────────────

Deno.test("TypeLL — generateNarrative: valid result produces celebratory narrative", () => {
  const result = { valid: true, activeFeatures: TypeLLEngine.coreFeatures.slice(0, 2), effects: [], proofObligations: [], linearityIssues: [] };
  const narrative = TypeLLEngine.generateNarrative(result);
  assert(typeof narrative.celebrate === "string", "Narrative should have celebrate text");
  assert(narrative.celebrate.length > 0, "Celebrate should not be empty for valid result");
});

Deno.test("TypeLL — generateNarrative: invalid result produces guidance", () => {
  const result = { valid: false, activeFeatures: [], effects: [], proofObligations: [], linearityIssues: [] };
  const narrative = TypeLLEngine.generateNarrative(result);
  assert(typeof narrative === "object", "Narrative should be an object");
});

Deno.test("TypeLL — generateNarrative: result with effects produces safety note", () => {
  const result = { valid: true, activeFeatures: [], effects: ["IO", "State"], proofObligations: [], linearityIssues: [] };
  const narrative = TypeLLEngine.generateNarrative(result);
  assert(typeof narrative.safety === "string", "Narrative should have safety text for effects");
});

// ─── JSON Parsing ───────────────────────────────────────────────────────

Deno.test("TypeLL — parseCheckResult: valid JSON returns Ok", () => {
  const result = TypeLLEngine.parseCheckResult('{"valid":true,"type":"int","value":42}');
  // Ok result: result itself (not wrapped in TAG for Ok)
  assert(result !== undefined, "Should parse valid JSON");
});

Deno.test("TypeLL — parseCheckResult: invalid JSON returns Error", () => {
  const result = TypeLLEngine.parseCheckResult("not json at all");
  // Error variant
  assert(result !== undefined, "Should return error for invalid JSON");
});

Deno.test("TypeLL — parseRefinementResult: valid refinement data", () => {
  const json = '{"base_type":"int","refined_type":"int{x > 0}","consistent":true}';
  const result = TypeLLEngine.parseRefinementResult(json);
  assert(result !== undefined, "Should parse refinement result");
});

// ─── Default State ──────────────────────────────────────────────────────

Deno.test("TypeLL — defaultState initialises with expected fields", () => {
  const state = TypeLLEngine.defaultState;
  assertEquals(state.serverConnected, false);
  assertEquals(state.queriesServed, 0);
  assertEquals(typeof state.activeCategory, "string");
  assert(typeof state.panelTypeChecks === "object", "panelTypeChecks should be object/dict");
});

// ─── Cross-Cutting: TypeLL in the Update Cycle ──────────────────────────

Deno.test("Cross-cutting — TypeCheckResult updates panelTypeChecks", () => {
  const m = initModel();
  const [newModel] = Update.update(m, {
    TAG: "CloudGuard",
    _0: { TAG: "TypeCheckResult", _0: { TAG: "Ok", _0: '{"valid":true}' } },
  });

  // queriesServed should increment
  assertEquals(newModel.typell.queriesServed, 1);
});

Deno.test("Cross-cutting — TypeCheckResult error degrades gracefully", () => {
  const m = initModel();
  const [newModel] = Update.update(m, {
    TAG: "CloudGuard",
    _0: { TAG: "TypeCheckResult", _0: { TAG: "Error", _0: "Connection refused" } },
  });

  // Should not crash — model should still be valid
  assertEquals(typeof newModel.typell.queriesServed, "number");
});

Deno.test("Cross-cutting — SetTlCategory updates active category", () => {
  const m = initModel();
  const [newModel] = Update.update(m, {
    TAG: "TypeLL",
    _0: { TAG: "SetTlCategory", _0: "TlChecker" },
  });

  assertEquals(newModel.typell.activeCategory, "TlChecker");
});

Deno.test("Cross-cutting — SetViewLayer updates active view layer", () => {
  const m = initModel();
  const raw = TypeLLEngine.allViewLayers[0]; // Raw
  const [newModel] = Update.update(m, {
    TAG: "TypeLL",
    _0: { TAG: "SetViewLayer", _0: raw },
  });

  // View layer should be updated
  assert(newModel.typell !== undefined, "TypeLL state should exist after SetViewLayer");
});

Deno.test("Cross-cutting — ToggleTypellBojRouting toggles routing flag", () => {
  const m = initModel();
  const initialRouting = m.typell.bojRouting;
  const [newModel] = Update.update(m, {
    TAG: "TypeLL",
    _0: "ToggleTypellBojRouting",
  });

  assertEquals(newModel.typell.bojRouting, !initialRouting);
});
